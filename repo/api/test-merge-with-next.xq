(:~
 : Test API: /mergeWithNext
 :)
import module namespace api = 'api/api';

import module namespace di = 'data/intermediate';
import module namespace e  = 'restxq/error';

declare namespace tt  = 'http://www.w3.org/ns/ttml';
declare namespace sas = 'http://basex.io/sas';

declare variable $local:SQ := 
<sasquatch xmlns:sas="http://basex.io/sas">
  <tt:tt xmlns:tt="http://www.w3.org/ns/ttml" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" xml:lang="en" ttp:contentProfiles="http://www.w3.org/ns/ttml/profile/imsc1.1/text">
    <tt:body>
      <!-- t1 -->
      <tt:div sas:id="id-first" begin="10.00" end="15.00"  sas:subtitleScore="16">
        <tt:p sas:confidence="1">Lorem Ipsum dolor </tt:p>
        <tt:p sas:confidence="0.9">sit amet</tt:p>
      </tt:div>
      <tt:div sas:id="id-second" begin="16.00" end="20.00" sas:subtitleScore="16">
        <tt:p sas:confidence="1">stri king the entire library</tt:p>
      </tt:div>
      <tt:div sas:id="id-third" begin="20.10" end="20.90" sas:subtitleScore="16">
        <tt:p sas:confidence="1">next after t1 two line merge</tt:p>
      </tt:div>
      <!-- t2: merging single lines -->
      <tt:div sas:id="id-single-line-a" begin="21.00" end="25.00" sas:subtitleScore="36">
        <tt:p sas:confidence="1">one two</tt:p>
      </tt:div>
      <tt:div sas:id="id-single-line-b" begin="26.00" end="30.00" sas:subtitleScore="26">
        <tt:p sas:confidence="1">three four</tt:p>
      </tt:div>
      <tt:div sas:id="id-single-line-next" sas:subtitleScore="66">
        <tt:p sas:confidence="1">next after single line merge</tt:p>
      </tt:div>
      <tt:div sas:id="id-last">
        <tt:p sas:confidence="1">last subtitle</tt:p>
      </tt:div>
    </tt:body>
  </tt:tt>
</sasquatch>;

(:~
 : api:merge
 :
 : Check: Normal operation
 : - Second subtitle is incorporated into first one.
 : - Second is deleted.
 : - Retrieval of first and second and next(first) should return first and formerly third, now second subtitle.
 :)
declare 
  %unit:ignore
  %unit:test
function local:test-merge-with-next-t1()
{
  let $result := api:merge($local:SQ, 'id-first') => di:get("id-first") update {
    delete node .//@*:id
  }
  let $expected := <tt:div xmlns:sas="http://basex.io/sas" xmlns:tt="http://www.w3.org/ns/ttml" sas:subtitleScore="16" begin="10.00" end="20.00">
  <tt:p sas:confidence="0.9">Lorem Ipsum dolor sit amet stri</tt:p>
  <tt:p sas:confidence="0.9">king the entire library</tt:p>
</tt:div>
  return
    unit:assert-equals($result, $expected)
};

(:~
 : api:merge
 :
 : Check: Merge of two single lines
 : - merging two single line subtitles will result in a two line subtitle with two lines,
 :   one from each source subtitle in sequence.
 :)
declare 
  %unit:test
function local:test-merge-with-next-t2()
{
  let $result := api:merge($local:SQ, 'id-single-line-a') => di:get("id-single-line-a")

  let $expected := <tt:div sas:id="id-single-line-a" sas:subtitleScore="26" begin="21.00" end="30.00">
        <tt:p sas:confidence="1">one two</tt:p>
        <tt:p sas:confidence="1">three four</tt:p>
      </tt:div>
  return
    unit:assert-equals($result, $expected)
};

()