module namespace di = 'data/intermediate';
import module namespace intermediate = 'transform/intermediate';

import module namespace e    = 'restxq/error';
import module namespace json = 'transform/json';
import module namespace t    = 'transform/timings';
import module namespace s    = 'score/scoring';

declare namespace sas = 'http://basex.io/sas';
declare namespace tt  = 'http://www.w3.org/ns/ttml';
declare namespace ttp = 'http://www.w3.org/ns/ttml#parameter';
declare namespace tts = 'http://www.w3.org/ns/ttml#styling';

(:~ 
 : Returns the intermediate result (sasquatch document) for a given project-id.
 :
 : @param $project-id project-id
 : @return element(sasquatch) intermediate subtitle file.
 : @error NOTFOUND
 :)
declare function di:get(
    $project-id as xs:string
  ) as element(sasquatch)
{
  try {
    db:open($project-id, $project-id || ".xml")/sasquatch
  } catch * {
    error($e:NOTFOUND, "Project not found: " || $project-id)
  }
};

(:~ 
 : Replace an intermediate result (sasquatch document) for a given project-id.
 :
 : @param $project-id project-id
 : @error NOTFOUND
 :)
declare updating function di:replace(
    $project-id as xs:string,
    $sq as element(sasquatch)
  )
{
  if (db:exists($project-id))
  then (
    delete node db:open($project-id, $project-id || ".xml")/sasquatch,
    insert node $sq into db:open($project-id, $project-id || ".xml")
  )
  else error($e:NOTFOUND, "Project not found: " || $project-id)
};

(:~
 : Returns subtitle from sasquatch document or throws an error.
 :
 : @param $project-id project-id
 : @param $subtitle-id subtitle-id
 : @return element(sasquatch) intermediate subtitle file.
 : @error NOTFOUND
 :)
declare function di:get-by-ids(
    $project-id as xs:string,
    $subtitle-id as xs:string
  ) as element(tt:div)
{
  let $sq as element(sasquatch) := di:get($project-id)
  return di:get($sq, $subtitle-id)
};

(:~
 : Returns subtitle line from sasquatch document or throws an error.
 :
 : @param $project-id project-id
 : @param $subtitle-id subtitle-id
 : @param $line-id line-id
 : @return element(sasquatch) intermediate subtitle file.
 : @error NOTFOUND
 :)
declare function di:get-by-ids(
    $project-id as xs:string,
    $subtitle-id as xs:string,
    $line-id as xs:string
  ) as element(tt:p)
{
  let $sq as element(sasquatch) := di:get($project-id)
  return di:get($sq, $subtitle-id, $line-id)
};

(:~
 : Returns subtitle from sasquatch document or throws an error.
 :
 : @param $project element(sasquatch) document
 : @param $subtitle-id subtitle-id
 : @return element(sasquatch) intermediate subtitle file.
 : @error NOTFOUND
 :)
declare function di:get(
    $project as element(sasquatch),
    $subtitle-id as xs:string
  ) as element(tt:div)
{
  let $st as element(tt:div)? := $project//tt:div[@sas:id = $subtitle-id]
  return
    if ($st) then $st
    else error($e:NOTFOUND, "Subtitle not found: " || $subtitle-id)
};

(:~
 : Returns subtitle line from sasquatch document or throws an error.
 :
 : @param $project element(sasquatch) document
 : @param $subtitle-id subtitle-id
 : @param $line-id line-id
 : @return element(sasquatch) intermediate subtitle file.
 : @error NOTFOUND
 :)
declare function di:get(
    $project as element(sasquatch),
    $subtitle-id as xs:string,
    $line-id as xs:string
  ) as element(tt:p)
{
  let $div as element(tt:div)? := di:get($project, $subtitle-id)
  let $ln as element(tt:p)? := $div/tt:p[@sas:id = $line-id]
  return
    if ($ln) then $ln
    else error($e:NOTFOUND, "Line not found: (subtitle: '" || $subtitle-id || "' line: '" || $line-id || "')")
};

(:~
 : Updates an existing subtitle and return json subtitle document.
 :
 : @param $project-id  project-id
 : @param $subtitle-id subtitle-id
 : @param $json        json-subtitle-object
 : @return json-subtitle-document (sasquatch file)
 :)
declare function di:update-prepare-subtitle(
   $subtitle-id as xs:string,
   $json as element(json)
 ) as element(tt:div)
{
  element tt:div {
    attribute sas:id { $subtitle-id },
    $json/markedAsCorrect ! attribute sas:markedAsCorrect { if($json/markedAsCorrect="true") then "true" else "false" },
    attribute sas:subtitleScore { if($json/markedAsCorrect="true") then 100 else if($json/subtitleScore) then $json/subtitleScore else 50 },
    $json/style/fontFamily ! attribute tts:fontFamily { . },
    $json/style/fontSize   ! attribute tts:fontSize { . },
    $json/style/region     ! attribute region { . },

    attribute begin { t:time-from-seconds($json/start)},
    attribute end   { t:time-from-seconds($json/end)},
    $json/lines/_ ! element tt:p {
      attribute sas:id { random:uuid() },
      attribute sas:confidence { 100 },
      line => parse-xml-fragment()
    }
  } update {
    replace value of node @sas:subtitleScore with s:subtitle-score(.)
  }
};

(:~ 
  Convert subtitle lines to sequence of words.
:)
declare function di:to-words(
  $subtitle as element(tt:div)+
) as xs:string* {
  ($subtitle)/*:p//text() => for-each(tokenize#1) => for-each(normalize-space#1)
};

(:~
  Creates a new empty subtitle.

  @param $original optional, to keep orginal score and id
  @param begin 
  @param end
  @param lines sequence of maps items, map has two properties: `map{ "id":(), "words":(), "confidence": ()}`
:)
declare function di:tt-div-template(
  $original as element(tt:div)?,
  $begin as xs:time,
  $end as xs:time,
  $lines as map(*)+
){
  element tt:div {
      attribute sas:id { ($original/@sas:id, random:uuid())=>head() },
      attribute sas:subtitleScore { if($original/@sas:subtitleScore/number() > 0) then $original/@sas:subtitleScore/number() else 0 },
      attribute begin { $begin },
      attribute end   { $end },
      for $line in $lines 
      return
      element tt:p {
        attribute sas:id { ($line?id, random:uuid()) => head() },
        attribute sas:confidence { $line?confidence => s:confidence-to-int() },
        $line?words
        => string-join(" ")
        => replace("\s\.",".")
      }
    }
};

(:~
 : Returns first subtitle in document or throws an error.
 :
 : @param $project element(sasquatch) document
 : @param $subtitle-id subtitle-id
 : @return id of next subtitle or nothing if $subtitle-id is last in document.
 : @error NOTFOUND
 :)
declare function di:get-first-subtitle(
    $project-id as xs:string
  ) as element(tt:div)?
{
  let $doc as element(sasquatch) := di:get($project-id)
  return $doc//tt:div => head()
};

(:~
 : Returns last subtitle in document or throws an error.
 :
 : @param $project element(sasquatch) document
 : @param $subtitle-id subtitle-id
 : @return id of next subtitle or nothing if $subtitle-id is last in document.
 : @error NOTFOUND
 :)
declare function di:get-last-subtitle(
    $project-id as xs:string
  ) as element(tt:div)?
{
  let $doc as element(sasquatch) := di:get($project-id)
  return $doc//tt:div => reverse() => head()
};

(:~
 : Returns previous subtitle (relative to given subtitle-id) or throws an error.
 :
 : @param $project element(sasquatch) document
 : @param $subtitle-id subtitle-id
 : @return id of next subtitle or nothing if $subtitle-id is last in document.
 : @error NOTFOUND
 :)
declare function di:get-previous-subtitle-by-ids(
    $project-id as xs:string,
    $subtitle-id as xs:string,
    $including-empty as xs:boolean
  ) as element(tt:div)?
{
  let $sq as element(sasquatch) := di:get($project-id)
  return di:get-previous-subtitle($sq, $subtitle-id, $including-empty)
};

(:~
 : Returns previous subtitle (relative to given subtitle-id) or throws an error.
 :
 : @param $project element(sasquatch) document
 : @param $subtitle-id subtitle-id
 : @return id of next subtitle or nothing if $subtitle-id is last in document.
 : @error NOTFOUND
 :)
declare function di:get-previous-subtitle(
    $sq as element(sasquatch),
    $subtitle-id as xs:string,
    $including-empty as xs:boolean
  ) as element(tt:div)?
{
  let $sub as element(tt:div) := di:get($sq, $subtitle-id)
  return ($sub/preceding-sibling::tt:div[$including-empty or exists(*:p/text())]) => reverse() => head()
};

(:~
 : Returns previous subtitle id or throws an error.
 :
 : @param $project element(sasquatch) document
 : @param $subtitle-id subtitle-id
 : @return id of next subtitle or nothing if $subtitle-id is last in document.
 : @error NOTFOUND
 :)
declare function di:get-previous-subtitle-id-by-ids(
    $project-id as xs:string,
    $subtitle-id as xs:string,
    $including-empty as xs:boolean
  ) as xs:string
{
  di:get-previous-subtitle-by-ids($project-id, $subtitle-id, $including-empty)/@sas:id/data()
};

(:~
 : Returns next subtitle (relative to given subtitle-id) or throws an error.
 :
 : @param $project element(sasquatch) document
 : @param $subtitle-id subtitle-id
 : @return id of next subtitle or nothing if $subtitle-id is last in document.
 : @error NOTFOUND
 :)
declare function di:get-next-subtitle-by-ids(
    $project-id as xs:string,
    $subtitle-id as xs:string,
    $including-empty as xs:boolean
  ) as element(tt:div)?
{
  let $sq as element(sasquatch) := di:get($project-id)
  return di:get-next-subtitle($sq, $subtitle-id, $including-empty)
};

(:~
 : Returns next subtitle (relative to given subtitle-id) or throws an error.
 :
 : @param $project element(sasquatch) document
 : @param $subtitle-id subtitle-id
 : @return id of next subtitle or nothing if $subtitle-id is last in document.
 : @error NOTFOUND
 :)
declare function di:get-next-subtitle(
    $sq as element(sasquatch),
    $subtitle-id as xs:string,
    $including-empty as xs:boolean
  ) as element(tt:div)?
{
  let $sub as element(tt:div) := di:get($sq, $subtitle-id)
  return ($sub/following-sibling::tt:div[$including-empty or exists(*:p/text())]) => head()
};

(:~
 : Returns next worst subtitle (relative to given subtitle-id) or throws an error.
 :
 : @param $project element(sasquatch) document
 : @param $subtitle-id subtitle-id
 : @return id of next subtitle or nothing if $subtitle-id is last in document.
 : @error NOTFOUND
 :)
declare function di:get-next-worst-subtitle(
    $project-id as xs:string,
    $subtitle-id as xs:string
  ) as element(tt:div)?
{
  let $sub as element(tt:div) := di:get-by-ids($project-id, $subtitle-id)
  let $next-subs as element(tt:div)* := $sub/following-sibling::tt:div
  let $worst-score as xs:double? := min($next-subs/@*:subtitleScore/number())
  return $next-subs[@sas:subtitleScore = $worst-score] => head()
};

(:~
 : Returns previous worst subtitle (relative to given subtitle-id) or throws an error.
 :
 : @param $project element(sasquatch) document
 : @param $subtitle-id subtitle-id
 : @return subtitle or nothing
 : @error NOTFOUND
 :)
declare function di:get-previous-worst-subtitle(
    $project-id as xs:string,
    $subtitle-id as xs:string
  ) as element(tt:div)?
{
  let $sub as element(tt:div) := di:get-by-ids($project-id, $subtitle-id)
  let $prev-subs as element(tt:div)* := $sub/preceding-sibling::tt:div
  let $worst-score as xs:double? := min($prev-subs/@*:subtitleScore/number())
  return $prev-subs[@sas:subtitleScore = $worst-score] => head()
};

(:~
 : Returns overall worst subtitle or throws an error.
 :
 : If there are more than one the first in document-order is returned.
 :
 : @param $project element(sasquatch) document
 : @param $subtitle-id subtitle-id
 : @return subtitle or nothing
 : @error NOTFOUND
 :)
declare function di:get-worst-subtitle(
    $project-id as xs:string
  ) as element(tt:div)?
{
  let $doc as element(sasquatch) := di:get($project-id)
  let $subs as element(tt:div)* := $doc//tt:div
  let $worst-score as xs:double? := min($subs/@*:subtitleScore/number())
  return $subs[@sas:subtitleScore = $worst-score] => head()
};

(:~
 : Returns subtitle at a specific point in time or throws an error.
 :
 : @param $project element(sasquatch) document
 : @param $time point in time
 : @return id of subtitle at that point in time
 : @error NOTFOUND
 :)
declare function di:get-subtitle-at-point-in-time(
    $project-id as xs:string,
    $str-time as xs:string
  ) as element(tt:div)?
{
  let $time := t:string-to-time($str-time)
  let $doc as element(sasquatch) := di:get($project-id)
  let $div :=
    for $sub in $doc//*:div
    let $begin := xs:time($sub/@begin)
    let $end   := xs:time($sub/@end)
    where $begin <= $time and $time <= $end
    return $sub
  return
    if ($div) then $div
    else error($e:NOTFOUND, "No subtitle found at position: " || $time)
};

(: :)


declare function di:create-gaps(
  $sasquatch as element(sasquatch)
){
  $sasquatch update {
    insert node (
    let $max-len := 5
    for $subtitle in .//*:div
    let $following := $subtitle/following-sibling::*:div => head()
    where $following
    let $subtitle-end     := $subtitle/@end => t:time-from-hhmmssf()
    let $following-begin  := $following/@begin => t:time-from-hhmmssf()
    let $pause-between    := ($following-begin - $subtitle-end)
    where $pause-between > xs:dayTimeDuration("PT1S")
    let $seconds := ($pause-between div xs:dayTimeDuration('PT1S'))
    let $buckets := ($seconds div $max-len) => ceiling() => xs:integer()
    let $step    :=  (($seconds div $buckets) - 0.1)
    for $i in 1 to $buckets
    let $begin := $subtitle-end + xs:dayTimeDuration("PT"|| 0.1 + ($i - 1) * $step ||"S")
    let $end   := $subtitle-end + xs:dayTimeDuration("PT"|| $i * $step ||"S")
    return <tt:div xmlns:tt="http://www.w3.org/ns/ttml" xmlns:sas="http://basex.io/sas" sas:id="{ random:uuid() }" sas:subtitleScore="0" begin="{
      $begin => t:time-to-hhmmssf()
    }" end="{
      $end => t:time-to-hhmmssf()
    }">
      <tt:p sas:id="{ random:uuid() }" sas:confidence="0"></tt:p>
      <tt:p sas:id="{ random:uuid() }" sas:confidence="0"></tt:p>
    </tt:div>) as last into ./*/tt:body
  } update {
    replace node ./*/tt:body with (
      element tt:body {
        for $div in .//*:div
        order by $div/@begin => t:time-from-hhmmssf()
        return $div
      }
    )
  }
};

declare function di:duration(
  $subtitle as element(tt:div))
as xs:dayTimeDuration {
    let $begin := $subtitle/@begin => t:time-from-hhmmssf()
    let $end   := $subtitle/@end => t:time-from-hhmmssf()
    return $end - $begin
};