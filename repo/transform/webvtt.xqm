module namespace webvtt = 'transform/webvtt';
import module namespace ti = 'transform/intermediate';

declare namespace tt  = "http://www.w3.org/ns/ttml";
declare namespace ttp = "http://www.w3.org/ns/ttml#parameter";
declare namespace tts = "http://www.w3.org/ns/ttml#styling";
       
declare namespace ttm    = "http://www.w3.org/ns/ttml#metadata";
declare namespace ebuttm = "urn:ebu:tt:metadata";
declare namespace ebutts = "urn:ebu:tt:style";

(:~
 : Converts sasquatch intermediate subtitle document to WebVTT text.
 :
 : @param  $doc sasquatch intermediate subtitle document
 : @return WebVTT text
 :)
declare function webvtt:from-sasquatch(
    $doc as element(sasquatch)
  ) as xs:string
{
``[WEBVTT
`{
  for $ttdiv in $doc//*:tt/*/tt:div[tt:p[text()]]
  return concat(
    out:nl(),
    $ttdiv/@begin => webvtt:convert-timecode() || " --> " || $ttdiv/@end => webvtt:convert-timecode(),
    out:nl(),
    $ttdiv/tt:p => 
    for-each(function($ttp){
      $ttp//text() => string-join(" ")
      => normalize-space()
      (: Escape characters inline: :)
      => serialize()
    }) => string-join(out:nl()),
  
  out:nl()
)
}`
]``
};

declare function webvtt:convert-timecode(
  $timecode as xs:string
  ){
    let $components := $timecode => tokenize("\.")
    let $timecode := string-join(
      (
        $components[1],
        $components[2] => substring(1,3) => xs:integer() => format-integer("000")
      ),
      "."
    )
    return $timecode 


};