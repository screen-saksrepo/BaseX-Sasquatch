(:~
 : Test API: /split
 :)
import module namespace api = 'api/api';

import module namespace di = 'data/intermediate';
import module namespace tjson = "transform/json";

import module namespace e  = 'restxq/error';

declare namespace tt  = 'http://www.w3.org/ns/ttml';
declare namespace sas = 'http://basex.io/sas';

declare variable $local:SQ := 
<sasquatch xmlns:sas="http://basex.io/sas">
  <tt:tt xmlns:tt="http://www.w3.org/ns/ttml" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" xml:lang="en" ttp:contentProfiles="http://www.w3.org/ns/ttml/profile/imsc1.1/text">
    <tt:body>
      <tt:div sas:id="id-first" begin="00:00:10.000" end="00:00:15.000">
        <tt:p>one two three four</tt:p>
        <tt:p>four five</tt:p>
      </tt:div>
    </tt:body>
  </tt:tt>
</sasquatch>;

declare variable $local:SQ1 := 
<sasquatch xmlns:sas="http://basex.io/sas">
  <tt:tt xmlns:tt="http://www.w3.org/ns/ttml" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" xml:lang="en" ttp:contentProfiles="http://www.w3.org/ns/ttml/profile/imsc1.1/text">
    <tt:body>
      <tt:div sas:id="id-first" begin="00:00:10.000" end="00:00:15.000">
        <tt:p>one</tt:p>
        <tt:p></tt:p>
      </tt:div>
    </tt:body>
  </tt:tt>
</sasquatch>;

declare variable $local:SQ-EMPTY := 
<sasquatch xmlns:sas="http://basex.io/sas">
  <tt:tt xmlns:tt="http://www.w3.org/ns/ttml" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" xml:lang="en" ttp:contentProfiles="http://www.w3.org/ns/ttml/profile/imsc1.1/text">
    <tt:body>
      <tt:div sas:id="id-first" begin="00:00:10.000" end="00:00:15.000">
        <tt:p></tt:p>
        <tt:p></tt:p>
      </tt:div>
    </tt:body>
  </tt:tt>
</sasquatch>;
(:~
 : api:split
 :
 : Check: Normal operation
 :)
declare 
  %unit:test
function local:test-split-t0()
{
  let $result   := api:split($local:SQ, 'id-first')
  let $sub := $result => di:get('id-first') update {
    delete node .//@*:id
  }
  let $new := $result => di:get-next-subtitle('id-first',false()) 
 
  return
    unit:assert-equals($sub,
    di:tt-div-template(
      element tt:div{attribute sas:id {'id-first'}},
      xs:time("00:00:10.0"),
      xs:time("00:00:12.5"),
      (
        (map{
          "id":"",
          "words": ("one", "two", "three")
        },
        map{})
      )
    ) update { delete node .//@*:id}
  )
};
(:~
 : api:split
 :
 : Check: Single word, should stay in current subtitle.
 :)
declare 
  %unit:test
function local:test-split-t1()
{
  let $result   := api:split($local:SQ1, 'id-first')
  let $sub := $result => di:get('id-first') update {
    delete node .//@*:id
  }
  let $new := $result => di:get-next-subtitle('id-first',false()) 
 
  return
    unit:assert-equals($sub,
    di:tt-div-template(
      element tt:div{attribute sas:id {'id-first'}},
      xs:time("00:00:10.0"),
      xs:time("00:00:12.5"),
      (
        (map{
          "id":"",
          "words": ("one")
        },
        map{})
      )
    ) update { delete node .//@*:id}
  )
};

(:~
 : api:split
 :
 : Check: Single word, should stay in current subtitle but create
 : empty following subtitle.
 :)
declare 
  %unit:test
function local:test-split-t1-1()
{
  let $result   := api:split($local:SQ1, 'id-first')
  let $sub := $result => di:get('id-first')
  let $new := $result => di:get-next-subtitle('id-first',true()) update {
    delete node .//@*:id
  }
 
  return
    unit:assert-equals($new,
    di:tt-div-template(
      $new,
      xs:time("00:00:12.6"),
      xs:time("00:00:15"),
      (
        (map{
          "id":"",
          "words": ("")
        },
        map{})
      )
    ) update { delete node .//@*:id}
  )
};
(:~
 : api:split
 :
 : Splitting empty subtitles will return an error.
 :)
declare 
  %unit:test("expected", "Q{http://basex.io/sas}NOTFOUND")
function local:test-split-empty()
{
  let $result   := api:split($local:SQ-EMPTY, 'id-first') 
  let $sub := $result => di:get('id-first')
  let $new := $result => di:get-next-subtitle('id-first',true()) update {
    delete node .//@*:id
  }
 
  return
    unit:assert-equals($new,
    di:tt-div-template(
      $new,
      xs:time("00:00:12.6"),
      xs:time("00:00:15"),
      (
        (map{
          "id":"",
          "words": ("")
        },
        map{})
      )
    ) update { delete node .//@*:id}
  )
};

declare
  %unit:test
function local:test-split-split-merge-merge-json(){
<sasquatch xmlns:sas="http://basex.io/sas">
  <meta>
    <id>8b4ddaf0-05a8-4605-a2c7-56460a8a4e5e</id>
    <categories/>
    <created/>
    <modified/>
    <origin>
      <job type="object">
        <lang>en-US</lang>
        <user__id type="number">18595</user__id>
        <name>iran deal-speech.mp4</name>
        <duration type="number">844</duration>
        <created__at>Mon Dec 11 10:51:25 2017</created__at>
        <id type="number">5769552</id>
      </job>
    </origin>
  </meta>
  <tt:tt xmlns:tt="http://www.w3.org/ns/ttml" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" xml:lang="en" ttp:contentProfiles="http://www.w3.org/ns/ttml/profile/imsc1.1/text">
    <tt:head>
      <tt:metadata>
        <ebuttm:documentMetadata xmlns:ebuttm="urn:ebu:tt:metadata">
          <ebuttm:conformsToStandard>urn:ebu:tt:distribution:2014-01</ebuttm:conformsToStandard>
          <ebuttm:conformsToStandard>http://www.w3.org/ns/ttml/profile/imsc1/text</ebuttm:conformsToStandard>
        </ebuttm:documentMetadata>
      </tt:metadata>
    </tt:head>
    <tt:body>
      <tt:div sas:id="023243d5-fb61-4824-a84c-7847b5ea4500" sas:subtitleScore="62" begin="00:00:01.200" end="00:00:06.960">
        <tt:p sas:id="2a668509-c073-4913-88ec-dd48a39bd098" sas:confidence="100">Today after two years of negotiations</tt:p>
        <tt:p sas:id="1be06203-c860-41be-9805-edf08e7d4324" sas:confidence="100">the United States together with our international</tt:p>
      </tt:div>
    </tt:body>
  </tt:tt>
</sasquatch>

      => api:split('023243d5-fb61-4824-a84c-7847b5ea4500')
      => api:split('023243d5-fb61-4824-a84c-7847b5ea4500')
      => api:split('023243d5-fb61-4824-a84c-7847b5ea4500')
      => api:merge('023243d5-fb61-4824-a84c-7847b5ea4500')
      => api:merge('023243d5-fb61-4824-a84c-7847b5ea4500')
      => api:merge('023243d5-fb61-4824-a84c-7847b5ea4500')
      => tjson:from-intermediate()
      => json:serialize()
};

()