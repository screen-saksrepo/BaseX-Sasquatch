module namespace srt = 'transform/srt';

import module namespace ti = 'transform/intermediate';
import module namespace t = 'transform/timings';

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
declare function srt:from-sasquatch(
    $doc as element(sasquatch)
  ) as xs:string
{
``[`{
  for $ttdiv at $p in $doc//*:tt/*/tt:div[tt:p[text()]]
  return concat(
    out:nl()[$p > 1],
    $p,
    out:nl(),
    $ttdiv/@begin => t:time-to-hhmmssf() => replace('\.', ',') || " --> " || $ttdiv/@end => t:time-to-hhmmssf() => replace('\.', ','),
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