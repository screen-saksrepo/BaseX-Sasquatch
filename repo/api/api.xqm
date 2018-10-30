(:~
 : API functions.
 :
 : Module supports and implements business logic needed by API calls.
 :)
module namespace api = 'api/api';

import module namespace di = 'data/intermediate';
import module namespace e  = 'restxq/error';
import module namespace t = 'transform/timings';
import module namespace s = 'score/scoring';
declare namespace tt  = 'http://www.w3.org/ns/ttml';
declare namespace sas = 'http://basex.io/sas';

(:~
 : Moves first word of an existing subtitle to the end of the previous subtitle.
 :
 : If there is no word in the referenced subtitle an error is raised.
 : If there is no previous subtitle an error is raised.
 :
 : @param $project-id project-id
 : @param $subtitle-id subtitle-id
 : @return updated subtitles
 : @error NOTFOUND
 :)
declare function api:first-word-to-previous(
    $sasquatch as element(sasquatch),
    $subtitle-id as xs:string
  ) as element(sasquatch)
{
  $sasquatch update {
    let $sub := di:get(., $subtitle-id)
    let $first-line-w-text := ($sub/tt:p[./data()])[1]
    let $words := $first-line-w-text/data() => normalize-space() => tokenize()
    let $first-word := $words => head()
    let $words-remaining := $words => tail()
    
    let $prev := di:get-previous-subtitle(., $subtitle-id, true())
    let $prev-last-line := $prev/tt:p[last()]
    return
      if (not($first-word))
      then error($e:NOTFOUND, "No word found. Subtitle is empty: " || $subtitle-id)
      else
        if (not($prev))
        then error($e:NOTFOUND, "No previous subtitle. Subtitle is first? " || $subtitle-id)
        else (
          (: adjust line values :)
          if ($first-line-w-text)
          then replace value of node $first-line-w-text with $words-remaining
          else error($e:NOTFOUND, "No line in subtitle: " || $subtitle-id)
          ,
          if ($prev-last-line)
          then replace value of node $prev-last-line with concat($prev-last-line, ' ', $first-word) => normalize-space()
          else error($e:NOTFOUND, "No line in previous subtitle: " || $prev/@sas:id/data())
          ,
          (: adjust timings :)
          let $all-words-count := ( for $p in $sub/tt:p return count( $p => normalize-space() => tokenize() ) ) => sum()
          let $d-of-sub  := xs:dayTimeDuration(t:time-from-hhmmssf($sub/@end) - t:time-from-hhmmssf($sub/@begin))
          let $d-of-word := if ($all-words-count > 0) then $d-of-sub div $all-words-count else 0
    
          let $prev-end  := ( t:time-from-hhmmssf($prev/@end)  + $d-of-word )
          let $sub-begin := ( t:time-from-hhmmssf($sub/@begin) + $d-of-word )
          return (
              replace value of node $prev/@end  with $prev-end  => t:time-to-hhmmssf(),
              replace value of node $sub/@begin with $sub-begin => t:time-to-hhmmssf()
            )
        )
  }
};

(:~
 : Moves last word of an existing subtitle at the beginning of the first line of the next subtitle.
 :
 : If there is no word in the referenced subtitle an error is raised.
 : If there is no previous subtitle an error is raised.
 :
 : @param $project-id project-id
 : @param $subtitle-id subtitle-id
 : @return updated subtitles
 : @error NOTFOUND
 :)
declare function api:last-word-to-next(
    $sasquatch as element(sasquatch),
    $subtitle-id as xs:string
  ) as element(sasquatch)
{
  $sasquatch update {
    let $sub := di:get(., $subtitle-id)
    let $last-line-w-text as element(tt:p)? := ($sub/tt:p[./data()])[last()]
    let $words as xs:string* := $last-line-w-text/data() => normalize-space() => tokenize()
    let $last-word := $words => reverse() => head()
    let $words-remaining := $words[position() != last()]
    
    let $next := di:get-next-subtitle(., $subtitle-id, true())
    let $next-first-line as element(tt:p)? := $next/tt:p[1]
    
    return
      if (not($last-word))
      then error($e:NOTFOUND, "No word found. Subtitle is empty: " || $subtitle-id)
      else
        if (not($next))
        then error($e:NOTFOUND, "No next subtitle. Subtitle is last? " || $subtitle-id)
        else (
          (: adjust line values :)
          if ($last-line-w-text)
          then replace value of node $last-line-w-text with $words-remaining
          else error($e:NOTFOUND, "No line in subtitle: " || $subtitle-id)
          ,
          if ($next-first-line)
          then replace value of node $next-first-line with concat($last-word, ' ', $next-first-line) => normalize-space()
          else error($e:NOTFOUND, "No line in next subtitle: " || $next/@sas:id/data())
          ,
          (: adjust timings :)
          let $all-words-count := ( for $p in $sub/tt:p return count( $p => normalize-space() => tokenize() ) ) => sum()
          let $d-of-sub  := xs:dayTimeDuration(t:time-from-hhmmssf($sub/@end) - t:time-from-hhmmssf($sub/@begin))
          let $d-of-word := if ($all-words-count > 0) then $d-of-sub div $all-words-count else 0
          
          let $new-end   := ( t:time-from-hhmmssf($sub/@end)    - $d-of-word )
          let $new-begin := ( t:time-from-hhmmssf($next/@begin) - $d-of-word )
          return (
            replace value of node $sub/@end    with $new-end   => t:time-to-hhmmssf(),
            replace value of node $next/@begin with $new-begin => t:time-to-hhmmssf()
          )
        )
  }
};

(:~
 : Merges two adjacent subtitles.
 :
 : The current subtitle incorporates the subsequent one.
 :
 : TODO: tt:div creation via central function.
 :
 : @param $project-id project-id
 : @param $subtitle-id subtitle-id
 : @return updated subtitle
 : @error NOTFOUND
 :)
declare function api:merge(
    $sasquatch as element(sasquatch),
    $subtitle-id as xs:string
  ) as element(sasquatch)
{
  let $sub as element(tt:div) := di:get($sasquatch, $subtitle-id) 
  let $nxt := try {
    di:get-next-subtitle($sasquatch, $subtitle-id, true()) treat as element(tt:div)
  }catch * {
    error(xs:QName("sas:NOTFOUND"),$subtitle-id||"has no next subtitle.")
  }
  let $nxt-id := $nxt/@sas:id/string()
  let $min-score :=  min((
            $sub/@sas:subtitleScore/number() ,
            $nxt/@sas:subtitleScore/number() 
          ))
  let $min-score := s:confidence-to-int($min-score)
  let $new-div := 
    (: both the current and next subtitle contain no more than 2 lines, join them into one div: :)
    if(count(($sub,$nxt)/*:p) <= 2) then (
      element tt:div {
        attribute sas:id { $subtitle-id },
        attribute sas:subtitleScore { $min-score},
        $sub/@begin,
        $nxt/@end,     
      ($sub,$nxt)/*:p
      }
    ) else (
    (: we have to construct new lines from individual words: :)
    let $words := di:to-words(($sub,$nxt))
      let $half-charlen := (sum($words ! string-length()) idiv 2)
      return element tt:div {
        attribute sas:id { $subtitle-id },
        attribute sas:subtitleScore {
         $min-score
        },
        $sub/@begin,
        $nxt/@end,
        
        for tumbling window $word in $words
        start at $s when true()
        end   at $e when (
          sum($words[position() >= $s and position() <= $e] ! string-length()) >= $half-charlen
        )
        return element tt:p {
          attribute sas:id { random:uuid() },
          attribute sas:confidence {
            min(($sub,$nxt)//@sas:confidence) => s:confidence-to-int()
          },
          $word => string-join(" ") => replace("\s\.",".")
        }
      }  
    )
  return $sasquatch update (
    delete node .//tt:div[@sas:id = $nxt-id],
    replace node .//tt:div[@sas:id = $subtitle-id] with $new-div
  )
};

(:~
 : Split subtitle.
 :
 : The current subtitle is split in two halves.  A new one is created.
 : 
 : @param $project-id project-id
 : @param $subtitle-id subtitle-id
 : @return updated subtitle
 : @error NOTFOUND
 :)
declare function api:split(
    $sasquatch as element(sasquatch),
    $subtitle-id as xs:string
  )
{
  (let $sub := try {
    di:get($sasquatch, $subtitle-id)[*:p/text()] treat as element(tt:div)
  }catch * {
    error(xs:QName("sas:NOTFOUND"), $subtitle-id||" not found.")
  }
  let $words := di:to-words($sub)
  let $end-of-orig := t:midway($sub/@begin => t:time-from-hhmmssf(), $sub/@end => t:time-from-hhmmssf())
  let $begin-of-new := t:add-gap($end-of-orig)

  let $confidence := s:subtitle-text-accuracy($sub)

  let $per-st := ceiling(count($words) div 2)
  let $current := 
    di:tt-div-template($sub,$sub/@begin, $end-of-orig, (
      map {"words": $words[position() <= $per-st], "confidence": $confidence },
      map { "confidence": $confidence }
      )
    )
   let $following := 
    di:tt-div-template((),$begin-of-new,$sub/@end,(
      map {"words": $words[position() > $per-st], "confidence": $confidence },
      map { "confidence": $confidence }
      )
    )
  
  return $sasquatch update {
    replace node . => di:get($subtitle-id) with $current,
    insert node $following after . => di:get($subtitle-id)
  })
  
};
