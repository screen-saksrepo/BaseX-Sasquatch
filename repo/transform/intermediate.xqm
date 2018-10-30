module namespace intermediate = "transform/intermediate";

import module namespace s = "score/scoring";
import module namespace t = "transform/timings";

declare namespace tt  = "http://www.w3.org/ns/ttml";
declare namespace ttp = "http://www.w3.org/ns/ttml#parameter";
declare namespace tts = "http://www.w3.org/ns/ttml#styling";
       
declare namespace ttm    = "http://www.w3.org/ns/ttml#metadata";
declare namespace ebuttm = "urn:ebu:tt:metadata";
declare namespace ebutts = "urn:ebu:tt:style";


declare namespace sas = "http://basex.io/sas";

(:~
 : Converts speech-to-text JSON data to an intermediate (aka SASQUATCH document) representation.
 :
 : Sasquatch Documents are the intermediate format from which
 : - IMSC, EBU-TT & WEBVTT
 : are generated, hence they contain TTML with metadata augmented
 : in the `sas` namespace that allows for easy conversion.
 :
 : @param  $doc stt json data
 : @return element(sasquatch) intermediate representation
 :)
declare function intermediate:from-json(
    $doc as document-node(),
    $id as xs:string,
    $categories as xs:string*
  ) as element(sasquatch)
{
  element sasquatch {
    namespace sas { "http://basex.io/sas" },
    intermediate:metadata($doc, $id, $categories),
    element tt:tt {
      attribute xml:lang {
        "en"
      },
      (: The following metadata is actually only needed to export valid subtitle in EBU-TT: :)
      attribute ttp:contentProfiles {"http://www.w3.org/ns/ttml/profile/imsc1.1/text"},
      element tt:head { 
      <tt:metadata>
         <ebuttm:documentMetadata>
            <ebuttm:conformsToStandard>urn:ebu:tt:distribution:2014-01</ebuttm:conformsToStandard>
            <ebuttm:conformsToStandard>http://www.w3.org/ns/ttml/profile/imsc1/text</ebuttm:conformsToStandard>
         </ebuttm:documentMetadata>
      </tt:metadata>
      },
      (: The body however will be useful :)
      element tt:body {
        let $paragraphs := intermediate:paragraphs($doc)
        return
        for  $ps in $paragraphs
        let $begin := $ps//tt:span/@sas:begin => head()
        let $end := $ps//tt:span/@sas:end => reverse() => head()
        return element tt:div {
          attribute sas:id { random:uuid() },
          attribute sas:subtitleScore { 0 },
          attribute begin { $begin => t:time-from-seconds() => t:time-to-hhmmssf() },
          attribute end   { $end   => t:time-from-seconds() => t:time-to-hhmmssf() },
          (: Remove intermediate tt:spans as they are only needed temporarily. :)
          for $p in $ps
          return $p update {
            replace value of node . with string-join(.//text()," ")
          }
        } update {
          replace value of node @sas:subtitleScore with s:subtitle-score(.)
        }
      } update {
        for $p in .//*:p[text()]
        let $string-length := string-length($p)
        where $string-length > 37
        let $words := tokenize($p)
        let $word-count := $words => count()
        return (
          replace value of node $p with subsequence($words, 1, $word-count idiv 2) ,
          insert node element tt:p {
            $p/@*,
            subsequence($words,  $word-count idiv 2 + 1, $word-count) 
           } after $p
          )
      }
    }
  }
};

(:~
 : Derives metadata from stt json document.
 :
 : @param  $doc stt json data
 : @return metadata element(meta)
 :)
declare %private function intermediate:metadata(
    $doc as document-node(),
    $project-id as xs:string,
    $categories as xs:string*
  ) as element(meta)
{
  element meta {
    element id { $project-id },
    element categories {
      $categories => for-each(function($category){
        element _ {
          $category
        }
      })
    },
    element created {
      
    },
    element modified {
      
    },
    element origin {
      $doc/*/job  
    } 
  }
};

declare function intermediate:should-end(
    $word as element(),
    $next-word as element()?,
    $first-word as element()
  ) as xs:boolean
{
     (: ($next-word/time/number() - ($word/time/number() + $word/duration/number()) > 1.01) :)
     ($next-word/time/number() - $word/time/number() > 1.01)
  or ($next-word/time/number() - $first-word/time/number() > 5.5)
};

(:~
 : Converts a sequence of words to tt:p elements.
 :
 : Attaches the following metadata to tt:p 
 :  => @sas:begin := min begin,
 :  => @sas:end := max end,
 :  => @sas:confiendence := avg confidence
 :
 : @param  $doc stt json data
 : @return zero or more element(tt:p)
 :)
declare %private function intermediate:paragraphs(
    $doc as document-node()
  ) as element(tt:p)*
{
  for tumbling window $words in $doc/*/words/_
  start $first-word when true()
  end $word next $next-word when (
    intermediate:should-end($word, $next-word, $first-word)
  )
  let $spans :=  $words => intermediate:word()  
  
  return element tt:p {
    attribute sas:id { random:uuid() },
    attribute sas:confidence {($spans/@sas:confidence => min() => floor())},
    $spans 
   } 
};
declare
  %private
function intermediate:speaker(
  $word as element(_)
){
  $word/ancestor::json/speakers/_[
    number(time) <= number($word/time)
    and
    (number(time) + number(duration)) >= number($word/time)
  ]/name => head()
};
(:~ 
 : Converts an input word to a tt:span element.
 : *N.B.* These span elements are only used temporarily, and will be removed before 
 : persisting the subtitle.
 :
 : Attaches the following metadata to tt:span
 : => @sas:begin := min begin,
 : => @sas:end := max end,
 : => @sas:confiendence := avg confidence
 : 
 : @param  $word single subtitle word
 : @return word augmented with metadata wrapped in element(tt:span)
 :)
declare
  %private
function intermediate:word(
    $words as element(_)+
  ) as element(tt:span)+
{
  for tumbling window $word in $words
  start when true()
  end $e next $nextword when $nextword /name !="."
  let $first := $word => head()
  let $last := $word => reverse() => head()
  let $pause := $last => intermediate:pause-after()
  let $speaker := $first  => intermediate:speaker()

  return element tt:span {
    attribute sas:id { random:uuid() },
    attribute sas:confidence {
      $first/confidence/number() * 100
    },
    attribute sas:speaker {
      $speaker
    },
    attribute sas:pause-after {
      $pause => format-number("#1.##")
    },
    attribute sas:begin {
      $first/time/number()
    },
    attribute sas:end {
      ($last/time/number() + $last/duration/number()) => format-number("#1.##")
    },
    $word/name/text() => string-join("")
  }
};

(:~ 
 : Computes the pause after a given input word.
 :
 : @param  $word single subtitle word
 : @return duration of pause
 :)
declare %private function intermediate:pause-after(
    $word as element(_)
  ) as xs:double
{
  let $start     := $word/time/number()
  let $end       := ($start + $word/duration/number())
  let $next-word := $word/following-sibling::_ => head()
  let $pause     := (
    if(exists($next-word)) then 
       abs(($next-word/time/number()) - ($end) )
    else 0
  )
  return $pause
};

(: Tests :)

