(:~
 : Test API functions.
 :)
import module namespace api = 'api/api';

import module namespace di = 'data/intermediate';
import module namespace e  = 'restxq/error';

declare namespace tt  = 'http://www.w3.org/ns/ttml';
declare namespace sas = 'http://basex.io/sas';

declare variable $local:SQ := 
<sasquatch xmlns:sas="http://basex.io/sas">
  <meta>
    <id>01e5a76e-bfff-4685-8c8e-8498268ce3fd</id>
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
      <tt:div sas:id="54732bd5-first-subtitle-id" sas:subtitleScore="13" begin="00:00:01.200" end="00:00:06.960">
        <tt:p>Today after two years of negotiations</tt:p>
        <tt:p>the United States together with our international</tt:p>
      </tt:div>
      <tt:div sas:id="f403541b-id-previous" begin="00:00:01.000" end="00:00:02.000">
        <tt:p></tt:p>
        <tt:p></tt:p>
      </tt:div>
      <tt:div sas:id="021fcfc5-id-current" begin="00:00:03.000" end="00:00:05.000">
        <tt:p>  a  b c  </tt:p>
        <tt:p>  z </tt:p>
      </tt:div>
      <tt:div sas:id="e403416d-id-next" begin="00:00:10.000" end="00:00:15.000">
        <tt:p></tt:p>
        <tt:p></tt:p>
      </tt:div>
      <tt:div sas:id="move-word-to-previous-adjust-timing-target" begin="00:00:01.200" end="00:00:01.680">
        <tt:p>1</tt:p>
      </tt:div>
      <tt:div sas:id="move-word-to-previous-adjust-timing-source" begin="00:00:02.130" end="00:00:03.720">
        <tt:p>2 3 4 5 6</tt:p>
      </tt:div>
      <tt:div sas:id="move-word-to-next-adjust-timing-source" begin="00:03:13.560" end="00:03:16.110">
        <tt:p>1 2 3 4</tt:p>
        <tt:p>5 6 7 8 9</tt:p>
      </tt:div>
      <tt:div sas:id="move-word-to-next-adjust-timing-target" begin="00:03:16.500" end="00:03:18.900">
        <tt:p>10 11 12 13 14</tt:p>
      </tt:div>
      <tt:div sas:id="e403416d-subtitle-without-words-id" begin="00:00:06.000" end="00:00:07.000">
        <tt:p></tt:p>
        <tt:p></tt:p>
      </tt:div>
      <tt:div sas:id="keep-newline" begin="00:00:07.500" end="00:00:08.500">
        <tt:p>1 2 3</tt:p>
        <tt:p>4 5 6</tt:p>
      </tt:div>
      <tt:div sas:id="last-subtitle" begin="00:00:09.000" end="00:00:10.000">
        <tt:p>a b c</tt:p>
        <tt:p>x y z</tt:p>
      </tt:div>
    </tt:body>
  </tt:tt>
</sasquatch>;

(:~
 : api:first-word-to-previous()
 :
 : Check: If there is no word in the referenced subtitle an error should be raised.
 :)
declare 
  %unit:test
function local:test-first-word-to-previous-no-word-in-subtitle()
{
  try {
    api:first-word-to-previous($local:SQ, 'e403416d-subtitle-without-words-id'),
    unit:fail()
  } catch * {
    unit:assert-equals($err:code, $e:NOTFOUND),
    unit:assert-equals($err:description, 'No word found. Subtitle is empty: e403416d-subtitle-without-words-id')
  }
};

(:~
 : api:first-word-to-previous()
 :
 : Check: If the function is called with the first subtitle, there will be no previous subtitle the word can be
 : pushed to and an error should be raised.
 :)
declare 
  %unit:test
function local:test-first-word-to-previous-with-first-subtitle()
{ 
  try {
    api:first-word-to-previous($local:SQ, '54732bd5-first-subtitle-id'),
    unit:fail()
  } catch * {
    unit:assert-equals($err:code, $e:NOTFOUND),
    unit:assert-equals($err:description, 'No previous subtitle. Subtitle is first? 54732bd5-first-subtitle-id')
  }
};

(:~
 : api:last-word-to-next()
 :
 : Check: If there is no word in the referenced subtitle an error should be raised.
 :)
declare 
  %unit:test
function local:test-last-word-to-next-no-word-in-subtitle()
{
  try {
    api:first-word-to-previous($local:SQ, 'e403416d-subtitle-without-words-id'),
    unit:fail()
  } catch * {
    unit:assert-equals($err:code, $e:NOTFOUND),
    unit:assert-equals($err:description, 'No word found. Subtitle is empty: e403416d-subtitle-without-words-id')
  }
};

(:~
 : api:last-word-to-next()
 :
 : Check: If the function is called with the last subtitle, there will be no next subtitle the word can be
 : pushed to and an error should be raised.
 :)
declare 
  %unit:test
function local:test-last-word-to-next-with-last-subtitle()
{ 
  try {
    api:last-word-to-next($local:SQ, 'last-subtitle'),
    unit:fail()
  } catch * {
    unit:assert-equals($err:code, $e:NOTFOUND),
    unit:assert-equals($err:description, 'No next subtitle. Subtitle is last? last-subtitle')
  }
};

(:~
 : api:last-word-to-next()
 :
 : Check: Check if pushing of a single word works as expected.
 :)
declare 
  %unit:test
function local:test-last-word-to-next-push-once()
{ 
  let $result := element result {
      api:last-word-to-next($local:SQ, '021fcfc5-id-current')//tt:div[@sas:id = ('021fcfc5-id-current', 'e403416d-id-next')]
    }
  let $expected :=
      <result>
        <tt:div xmlns:tt="http://www.w3.org/ns/ttml" xmlns:sas="http://basex.io/sas" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" sas:id="021fcfc5-id-current" begin="00:00:03.000" end="00:00:04.500">
          <tt:p>  a  b c  </tt:p>
          <tt:p/>
        </tt:div>
        <tt:div xmlns:tt="http://www.w3.org/ns/ttml" xmlns:sas="http://basex.io/sas" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" sas:id="e403416d-id-next" begin="00:00:09.500" end="00:00:15.000">
          <tt:p>z</tt:p>
          <tt:p/>
        </tt:div>
      </result>
  return
    unit:assert-equals($result, $expected)
};

(:~
 : api:last-word-to-next()
 :
 : Check: Check if pushing of a two words works as expected.
 :)
declare 
  %unit:test
function local:test-last-word-to-next-push-twice()
{ 
  let $result := element result {
      (
        api:last-word-to-next($local:SQ, '021fcfc5-id-current')
        => api:last-word-to-next('021fcfc5-id-current')
      )
      //tt:div[@sas:id = ('021fcfc5-id-current', 'e403416d-id-next')]
    }
  let $expected :=
      <result>
        <tt:div xmlns:tt="http://www.w3.org/ns/ttml" xmlns:sas="http://basex.io/sas" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" sas:id="021fcfc5-id-current" begin="00:00:03.000" end="00:00:04.000">
          <tt:p>a b</tt:p>
          <tt:p/>
        </tt:div>
        <tt:div xmlns:tt="http://www.w3.org/ns/ttml" xmlns:sas="http://basex.io/sas" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" sas:id="e403416d-id-next" begin="00:00:09.000" end="00:00:15.000">
          <tt:p>c z</tt:p>
          <tt:p/>
        </tt:div>
      </result>
  return
    unit:assert-equals($result, $expected)
};

(:~
 : api:last-word-to-next()
 :
 : Check: Check if pushing of a three words works as expected.
 :)
declare 
  %unit:test
function local:test-last-word-to-next-push-three-times()
{ 
  let $result := element result {
      (
        api:last-word-to-next($local:SQ, '021fcfc5-id-current')
        => api:last-word-to-next('021fcfc5-id-current')
        => api:last-word-to-next('021fcfc5-id-current')
      )
      //tt:div[@sas:id = ('021fcfc5-id-current', 'e403416d-id-next')]
    }
  let $expected :=
      <result>
        <tt:div xmlns:tt="http://www.w3.org/ns/ttml" xmlns:sas="http://basex.io/sas" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" sas:id="021fcfc5-id-current" begin="00:00:03.000" end="00:00:03.500">
          <tt:p>a</tt:p>
          <tt:p/>
        </tt:div>
        <tt:div xmlns:tt="http://www.w3.org/ns/ttml" xmlns:sas="http://basex.io/sas" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" sas:id="e403416d-id-next" begin="00:00:08.500" end="00:00:15.000">
          <tt:p>b c z</tt:p>
          <tt:p/>
        </tt:div>
      </result>
  return
    unit:assert-equals($result, $expected)
};

(:~
 : api:last-word-to-next()
 :
 : Check: Check if pushing of a four words works as expected.
 :)
declare 
  %unit:test
function local:test-last-word-to-next-push-four-times()
{ 
  let $result := element result {
      (
        api:last-word-to-next($local:SQ, '021fcfc5-id-current')
        => api:last-word-to-next('021fcfc5-id-current')
        => api:last-word-to-next('021fcfc5-id-current')
        => api:last-word-to-next('021fcfc5-id-current')
      )
      //tt:div[@sas:id = ('021fcfc5-id-current', 'e403416d-id-next')]
    }
  let $expected :=
      <result>
        <tt:div xmlns:tt="http://www.w3.org/ns/ttml" xmlns:sas="http://basex.io/sas" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" sas:id="021fcfc5-id-current" begin="00:00:03.000" end="00:00:03.000">
          <tt:p></tt:p>
          <tt:p/>
        </tt:div>
        <tt:div xmlns:tt="http://www.w3.org/ns/ttml" xmlns:sas="http://basex.io/sas" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" sas:id="e403416d-id-next" begin="00:00:08.000" end="00:00:15.000">
          <tt:p>a b c z</tt:p>
          <tt:p/>
        </tt:div>
      </result>
  return
    unit:assert-equals($result, $expected)
};

(:~
 : api:last-word-to-next()
 :
 : Check: Check if pushing of a five words stops with expected failure.
 :)
declare 
  %unit:test
function local:test-last-word-to-next-push-five-times()
{ 
  try {
    api:last-word-to-next($local:SQ, '021fcfc5-id-current')
    => api:last-word-to-next('021fcfc5-id-current')
    => api:last-word-to-next('021fcfc5-id-current')
    => api:last-word-to-next('021fcfc5-id-current')
    => api:last-word-to-next('021fcfc5-id-current'), (: this should produce the failure :)
    unit:fail() (: make sure to fail in any case :)
  } catch * {
    unit:assert-equals($err:code, $e:NOTFOUND),
    unit:assert-equals($err:description, 'No word found. Subtitle is empty: 021fcfc5-id-current')
  }
};



(:~
 : Push, keep lines:
 :
 : Check: Check if pushing of a five words stops with expected failure.
 :)
declare
  %unit:test
function local:keep-lines-1()
{
    unit:assert-equals(
      element result {
      api:last-word-to-next($local:SQ, 'keep-newline')//*:div[@sas:id=("keep-newline","last-subtitle")]
    },
    <result>
  <tt:div xmlns:tt="http://www.w3.org/ns/ttml" xmlns:sas="http://basex.io/sas" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" sas:id="keep-newline" begin="00:00:07.500" end="00:00:08.333">
    <tt:p>1 2 3</tt:p>
    <tt:p>4 5</tt:p>
  </tt:div>
  <tt:div xmlns:tt="http://www.w3.org/ns/ttml" xmlns:sas="http://basex.io/sas" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" sas:id="last-subtitle" begin="00:00:08.833" end="00:00:10.000">
    <tt:p>6 a b c</tt:p>
    <tt:p>x y z</tt:p>
  </tt:div>
</result>
  )
};
(:~
 : api:last-word-to-next()
 :
 : Check: Check if pushing of a five words stops with expected failure.
 :)
declare
  %unit:test
function local:keep-lines-2()
{
let $doc := api:last-word-to-next($local:SQ, 'keep-newline') => api:last-word-to-next('keep-newline')  => api:last-word-to-next('keep-newline')
return
    unit:assert-equals(
      element result {
      $doc//*:div[@sas:id=("keep-newline","last-subtitle")]
    },
    <result>
  <tt:div xmlns:tt="http://www.w3.org/ns/ttml" xmlns:sas="http://basex.io/sas" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" sas:id="keep-newline" begin="00:00:07.500" end="00:00:07.999">
    <tt:p>1 2 3</tt:p>
    <tt:p/>
  </tt:div>
  <tt:div xmlns:tt="http://www.w3.org/ns/ttml" xmlns:sas="http://basex.io/sas" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" sas:id="last-subtitle" begin="00:00:08.499" end="00:00:10.000">
  <tt:p>4 5 6 a b c</tt:p>
    <tt:p>x y z</tt:p>
  </tt:div>
</result>
  )
};

(:~
 : api:last-word-to-next()
 :
 : Check: Timings should be adjusted after moving a word.
 :
 : Before:
 : 
 :    <tt:div sas:id="move-word-to-previous-adjust-timing-target" begin="00:00:01.200" end="00:00:01.680">
 :      <tt:p>1</tt:p>
 :    </tt:div>
 :    <tt:div sas:id="move-word-to-previous-adjust-timing-source" begin="00:00:02.130" end="00:00:03.720">
 :      <tt:p>2 3 4 5 6</tt:p>
 :    </tt:div>
 :
 : After:
 :
 :    <tt:div sas:id="move-word-to-previous-adjust-timing-target" begin="00:00:01.200" end="00:00:01.998">
 :      <tt:p>1 2</tt:p>
 :    </tt:div>
 :    <tt:div sas:id="move-word-to-previous-adjust-timing-source" begin="00:00:02.448" end="00:00:03.720">
 :      <tt:p>3 4 5 6</tt:p>
 :    </tt:div>
 : 
 : Calculation:   
 :    (03.720 - 02.130) idiv 5 --> word-count
 :    = PT0.318S               --> duration per word
 :    
 :    new end  : 00:00:01.680 + PT0.318S = 00:00:01.998 (ends later)
 :    new begin: 00:00:02.130 + PT0.318S = 00:00:02.448 (starts later)
 :)
declare
  %unit:test
function local:move-word-timings-previous()
{
  unit:assert-equals(
    element result {
      api:first-word-to-previous($local:SQ, 'move-word-to-previous-adjust-timing-source')//*:div[@sas:id=("move-word-to-previous-adjust-timing-target","move-word-to-previous-adjust-timing-source")]
    },
    <result>
      <tt:div xmlns:tt="http://www.w3.org/ns/ttml" xmlns:sas="http://basex.io/sas" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" sas:id="move-word-to-previous-adjust-timing-target" begin="00:00:01.200" end="00:00:01.998">
        <tt:p>1 2</tt:p>
      </tt:div>
      <tt:div xmlns:tt="http://www.w3.org/ns/ttml" xmlns:sas="http://basex.io/sas" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" sas:id="move-word-to-previous-adjust-timing-source" begin="00:00:02.448" end="00:00:03.720">
        <tt:p>3 4 5 6</tt:p>
      </tt:div>
    </result>
  )
};
(:~
 : api:last-word-to-next()
 :
 : Check: Timings should be adjusted after moving a word.
 : 
 : Calculation:   
 :    (00:03:16.110 - 00:03:13.560) idiv 9 --> word-count
 :    = PT0.2833333333333333S              --> duration per word
 :    
 :    new end  : 00:03:16.110 - PT0.2833333333333333S = 00:03:15.8266666666666667 (ends earlier)
 :    new begin: 00:03:16.500 - PT0.2833333333333333S = 00:03:16.2166666666666667 (starts earlier)
 :)
declare
  %unit:test
function local:move-word-timings-next()
{
  unit:assert-equals(
    element result {
      api:last-word-to-next($local:SQ, 'move-word-to-next-adjust-timing-source')//*:div[@sas:id=("move-word-to-next-adjust-timing-source","move-word-to-next-adjust-timing-target")]
    },
    <result>
      <tt:div  xmlns:tt="http://www.w3.org/ns/ttml" xmlns:sas="http://basex.io/sas" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" sas:id="move-word-to-next-adjust-timing-source" begin="00:03:13.560" end="00:03:15.826">
        <tt:p>1 2 3 4</tt:p>
        <tt:p>5 6 7 8</tt:p>
      </tt:div>
      <tt:div  xmlns:tt="http://www.w3.org/ns/ttml" xmlns:sas="http://basex.io/sas" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" sas:id="move-word-to-next-adjust-timing-target" begin="00:03:16.216" end="00:03:18.900">
        <tt:p>9 10 11 12 13 14</tt:p>
      </tt:div>
    </result>
  )
};

()