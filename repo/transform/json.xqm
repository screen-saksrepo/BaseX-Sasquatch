module namespace json = "transform/json";

declare namespace tt  = "http://www.w3.org/ns/ttml";
declare namespace ttp = "http://www.w3.org/ns/ttml#parameter";
declare namespace tts = "http://www.w3.org/ns/ttml#styling";

declare namespace ttm    = "http://www.w3.org/ns/ttml#metadata";
declare namespace ebuttm = "urn:ebu:tt:metadata";
declare namespace ebutts = "urn:ebu:tt:style";

declare namespace sas = "http://basex.io/sas";

import module namespace s = "score/scoring";
import module namespace t = 'transform/timings';
(:~
 : Converts intermediate (aka SASQUATCH document) to IJYI-ST representation.
 :
 : Sasquatch documents are the intermediate format from which
 : - IMSC, EBU-TT, WEBVTT, and (here) IJYT subtitle JSON (IJYI-ST)
 : are generated.
 :
 : @param  element(sasquatch) intermediate representation
 : @return element(json) IJYI subtitle JSON representation
 :)
declare function json:from-intermediate(
    $doc as element(sasquatch)
  ) as element(json)
{
  element json { attribute type { "object" },
    json:from-intermediate-project-score($doc),
    element videoLength { attribute type { "number" },
      let $n := $doc/meta/origin/job/duration/data()
      return if ($n) then $n else 0
    },
    element subtitles { attribute type { "array" },
      for $div in $doc//tt:div
      return element _ {
        attribute type { "object" },
        json:subtitle-from-intermediate($div)
      }
    }
  }
};

(:~
 : Converts intermediate (aka SASQUATCH document) to IJYI-ST representation.
 :
 : Sasquatch documents are the intermediate format from which
 : - IMSC, EBU-TT, WEBVTT, and (here) IJYT subtitle JSON (IJYI-ST)
 : are generated.
 :
 : @param  element(sasquatch) intermediate representation
 : @return element(json) IJYI subtitle JSON representation
 :)
declare function json:from-intermediate-project-score(
    $doc as element(sasquatch)
  )
{
  let $coverage      := s:project-coverage($doc)
  let $text-accuracy := s:project-text-accuracy($doc)
  let $readability   := s:project-readability($doc)
  let $layout        := s:project-layout($doc)
  let $score         := s:project-score($coverage, $text-accuracy, $readability, $layout)
  return (
    element projectId           { $doc/meta/id/string() },
    element projectScore        { attribute type { "number" }, $score },
    element projectCoverage     { attribute type { "number" }, $coverage },
    element projectTextAccuracy { attribute type { "number" }, $text-accuracy },
    element projectReadability  { attribute type { "number" }, $readability },
    element projectLayout       { attribute type { "number" }, $layout }
  )
};

(:~
 : Transforms single subtitle form intermediate (tt:div) to json.
 :
 : @param $div subtitle in intermediate format
 : @return subtitle as sequence of elements to be wrapped in <json type="object"/>
 :)
declare function json:subtitle-from-intermediate(
    $div as element(tt:div)
  )
{ 
  let $text-accuracy := s:subtitle-text-accuracy($div)
  let $readability   := s:subtitle-readability($div)
  let $layout        := s:subtitle-layout($div)
  let $score         := s:subtitle-score($text-accuracy, $readability, $layout)
  return (
    element id {$div/@sas:id/string()},
    element markedAsCorrect      { attribute type { "boolean" }, ($div/@sas:markedAsCorrect/string(), "false")[1]},
    element subtitleScore        { attribute type { "number" }, $score },
    element subtitleTextAccuracy { attribute type { "number" }, $text-accuracy },
    element subtitleReadability  { attribute type { "number" }, $readability },
    element subtitleLayout       { attribute type { "number" }, $layout },
    element start { attribute type { "number" }, $div/@begin => t:seconds-from-hhmmssf() },
    element end   { attribute type { "number" }, $div/@end => t:seconds-from-hhmmssf() },

    $div => json:lines()  ,
    if( count( $div/(@region, @tts:fontSize, @tts:fontFamily) ) >= 1) then  (
      element style {
        attribute type { "object" },
        $div/@region ! element region { string() },
        $div/@tts:fontFamily ! element fontFamily { string() },
        $div/@tts:fontSize ! element fontSize { string() },
        ()
      }
    ) else()
  )
};

declare function json:wrap-object(
    $input
  ) as element(json)
{
  element json {
    attribute type { "object" },
    $input
  }
};

declare function json:wrap-array(
    $input
  ) as element(json)
{
  element json {
    attribute type { "array" },
    for $i in $input
    return
      element _ { 
        attribute type { "object" },
        $i
      }
  }
};

(:~
 : Subtitle line representations.
 :
 : @param tt:div single subtitle of subtitle file
 : @return lines in subtitle
 :)
declare %private function json:lines(
    $div as element(tt:div)
  ) as element(lines)
{
  element lines {
    attribute type { "array" },
    for $p in $div/*:p
    return element _ {
      attribute type { "object" },
      element id { $p/@sas:id/string() },
      element wordsCount { attribute type { "number" }, count($p/string() => tokenize() ) },
      element line { 
      serialize(
        ($p )/(*,text()) (: Serialize childen of tt:p :)
      ) => replace('\s?xmlns:[^=]+="[^"]+"',"") (: *Todo* not so nice :)
     }
    }
  }
};
