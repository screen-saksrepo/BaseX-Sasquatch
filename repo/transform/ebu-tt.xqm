module namespace ebu-tt = 'transform/ebu-tt';

declare namespace tt  = "http://www.w3.org/ns/ttml";

(:~
 : Converts sasquatch intermediate subtitle document to EBU-TT.
 :
 : @param  $doc sasquatch intermediate subtitle document
 : @return EBU-TT
 :)
declare function ebu-tt:from-sasquatch(
    $doc as element(sasquatch)
  ) (: as element(tt:tt) :)
{
    <tt:tt
      xmlns:tt="http://www.w3.org/ns/ttml"
      xmlns:ttp="http://www.w3.org/ns/ttml#parameter"
      xml:lang="en"
      ttp:contentProfiles="http://www.w3.org/ns/ttml/profile/imsc1.1/text">
    {
      ($doc//*:tt update {
        delete node .//@Q{http://basex.io/sas}*,
        delete node .//tt:div[not(tt:p/text())]
      })/* 
    }
    </tt:tt>
};