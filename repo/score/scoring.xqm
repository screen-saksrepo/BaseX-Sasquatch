module namespace s = 'score/scoring';
import module namespace di = 'data/intermediate';
declare namespace tt  = "http://www.w3.org/ns/ttml";
declare namespace sas = "http://basex.io/sas";


(:~
 : Project total score.
 :
 : For the project as a whole, the overall score is expressed as the worst value
 : of the top level score values for Coverage, Text Accuracy, Readability and Layout.
 : 
 : @param $doc intermediate sasquatch document
 : @return project total score (0..100)
 :)
declare function s:project-score(
    $coverage as xs:integer,
    $text-accuracy as xs:integer,
    $readability as xs:integer,
    $layout as xs:integer
  ) as xs:integer
{
  min((
    $coverage, $text-accuracy, $readability, $layout
  ))
};

(:~
 : ToDo: https://git.dev.basex.org/screen-systems/speech-to-subtitle/issues/61
 : 
 : For the project as a whole, the project text accuracy score is expressed as a percentage
 : of the total number of subtitles in the project that are accurate (have a score of 1).
 :
 : @param $doc intermediate sasquatch document
 : @return project coverage score (0..100)
 :)
declare function s:project-coverage(
    $doc as element(sasquatch)
  ) as xs:integer
{
  let $filled := $doc//*:div[@sas:markedAsCorrect eq "true" or tt:p[text()]] => count()
  let $empty := $doc//*:div[not(@sas:markedAsCorrect eq "true" or tt:p[text()])] => count()
  let $percentage := $empty div ($filled + $empty)
  return 100 - xs:integer($percentage * 100)
};

(: Ignore empty subtitles. :)
declare function s:project-text-accuracy(
    $doc as element(sasquatch)
  ) as xs:integer
{
  $doc//*:div[not(s:empty(.))] => for-each(s:subtitle-text-accuracy#1) => min()
};

(: Ignore empty subtitles. :)
declare function s:project-readability(
    $doc as element(sasquatch)
  ) as xs:integer
{
  $doc//*:div[not(s:empty(.))] => for-each(s:subtitle-readability#1) => min()
};

(: Ignore empty subtitles. :)
declare function s:project-layout(
    $doc as element(sasquatch)
  ) as xs:integer
{
  $doc//*:div[not(s:empty(.))] => for-each(s:subtitle-layout#1) => min()
};

declare function s:subtitle-score(
  $div as element(tt:div)
) as xs:integer {
  s:subtitle-score(
    s:subtitle-text-accuracy($div),
    s:subtitle-readability($div),
    s:subtitle-layout($div)
  )
};
declare function s:subtitle-score(
    $text-accuracy as xs:integer,
    $readability as xs:integer,
    $layout as xs:integer
  ) as xs:integer
{
  min((
    $text-accuracy, $readability, $layout
  ))
};

declare function s:subtitle-text-accuracy(
    $div as element(tt:div)
  ) as xs:integer
{ 
  if($div//@sas:markedAsCorrect = "true") then 100 else 
  if(s:empty($div)) then 0 else
  min($div//@sas:confidence/number()) => s:confidence-to-int()
};

declare function s:subtitle-readability(
    $div as element(tt:div)
  ) as xs:integer
{
  if($div//@sas:markedAsCorrect = "true") then 100 else 
  if(s:empty($div)) then 0 else
  let $words := di:to-words($div) => count()
  let $wps := try {
    (di:duration($div) div $words) div xs:dayTimeDuration('PT1S')
  } catch * {
    0
  }
  return if(
    $wps  <= 0.3
  ) then xs:integer(math:pow($wps,2) * 900)  else 100
};

declare function s:subtitle-layout(
    $div as element(tt:div)
  ) as xs:integer
{
  let $max-chars := 37
  return
  if($div//@sas:markedAsCorrect = "true") then 100 else 
  if(s:empty($div)) then 0 else
  let $overlength := min(
    (0,$max-chars - $div/*:p/string-length() => max())
  )
  let $score := (100 + ((1 div $max-chars) * 100 * $overlength)) => floor()
  return max((0, $score)) => xs:integer()

};
(:~
 : Converts "NaN" to 0
 : @param $number candidate
 : @return $number as 0 if it were "NaN"
 :)
declare function s:confidence-to-int(
  $number as xs:numeric?
  ) as xs:integer
{
  if(string(number($number)) eq "NaN") then 0 else xs:integer($number)
};
declare function s:empty(
  $div as element(tt:div)
) as xs:boolean{
  $div[empty(tt:p[text()])] => exists()
};