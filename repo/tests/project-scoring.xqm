import module namespace api = 'api/api';
declare namespace tt  = 'http://www.w3.org/ns/ttml';
import module namespace di = 'data/intermediate';
import module namespace s = 'score/scoring';
import module namespace tjson = "transform/json";
declare namespace sas = 'http://basex.io/sas';


declare %unit:test
function local:readability(){
  let $div :=<sasquatch>
  <tt:div sas:subtitleScore="62" begin="00:00:01.000" end="00:00:02.000">
    <tt:p sas:confidence="100">Today</tt:p>
    <tt:p sas:confidence="100">the a</tt:p>
  </tt:div>
  <tt:div sas:subtitleScore="62" begin="00:00:01.000" end="00:00:02.000">
    <tt:p sas:confidence="100">Today</tt:p>
    <tt:p sas:confidence="100">the a</tt:p>
  </tt:div>
</sasquatch>
  let $score := s:project-readability($div)
   return unit:assert-equals( $score, 100 )
};
declare %unit:test
function local:non-readable(){
  let $div :=<sasquatch>
  <tt:div sas:subtitleScore="62" begin="00:00:01.000" end="00:00:02.000">
    <tt:p sas:confidence="100">Today</tt:p>
    <tt:p sas:confidence="100">the a a aa  a</tt:p>
  </tt:div>
  <tt:div sas:subtitleScore="62" begin="00:00:01.000" end="00:00:02.000">
    <tt:p sas:confidence="100">Today</tt:p>
    <tt:p sas:confidence="100">the a</tt:p>
  </tt:div>
</sasquatch>
  let $score := s:project-readability($div)
   return unit:assert-equals( $score, 25 )
};

declare %unit:test
function local:readability-overriden(){
  let $div :=<sasquatch>
  <tt:div sas:subtitleScore="62" sas:markedAsCorrect="true" begin="00:00:01.000" end="00:00:02.000">
    <tt:p sas:confidence="100">Today</tt:p>
    <tt:p sas:confidence="100">the a a aa  a</tt:p>
  </tt:div>
  <tt:div sas:subtitleScore="62" begin="00:00:01.000" end="00:00:02.000">
    <tt:p sas:confidence="100">Today</tt:p>
    <tt:p sas:confidence="100">the a</tt:p>
  </tt:div>
</sasquatch>
  let $score := s:project-readability($div)
   return unit:assert-equals( $score, 100 )
};

declare %unit:test
function local:coverage-100(){
  let $div :=<sasquatch>
  <tt:div sas:subtitleScore="62" sas:markedAsCorrect="true" begin="00:00:01.000" end="00:00:02.000">
    <tt:p sas:confidence="100">Today</tt:p>
    <tt:p sas:confidence="100">the a a aa  a</tt:p>
  </tt:div>
  <tt:div sas:subtitleScore="62" begin="00:00:01.000" end="00:00:02.000">
    <tt:p sas:confidence="100">a</tt:p>
    <tt:p sas:confidence="100"/>
  </tt:div>
</sasquatch>
  let $score := s:project-coverage($div)
  return unit:assert-equals( $score, 100 )
};
declare %unit:test
function local:coverage-50(){
  let $div :=<sasquatch>
  <tt:div sas:subtitleScore="62" sas:markedAsCorrect="true" begin="00:00:01.000" end="00:00:02.000">
    <tt:p sas:confidence="100">Today</tt:p>
    <tt:p sas:confidence="100">the a a aa  a</tt:p>
  </tt:div>
  <tt:div sas:subtitleScore="62" begin="00:00:01.000" end="00:00:02.000">
    <tt:p sas:confidence="100"></tt:p>
    <tt:p sas:confidence="100"/>
  </tt:div>
</sasquatch>
  let $score := s:project-coverage($div)
  return unit:assert-equals( $score, 50 )
};

declare %unit:test
function local:coverage-100-overriden(){
  let $div :=<sasquatch>
  <tt:div sas:subtitleScore="62" sas:markedAsCorrect="true" begin="00:00:01.000" end="00:00:02.000">
    <tt:p sas:confidence="100">Today</tt:p>
    <tt:p sas:confidence="100">the a a aa  a</tt:p>
  </tt:div>
  <tt:div sas:subtitleScore="62" sas:markedAsCorrect="true" begin="00:00:01.000" end="00:00:02.000">
    <tt:p sas:confidence="100"></tt:p>
    <tt:p sas:confidence="100"/>
  </tt:div>
</sasquatch>
  let $score := s:project-coverage($div)
  return unit:assert-equals( $score, 100)
 };

declare %unit:test
function local:coverage-0(){
  let $div := <sasquatch>
  <tt:div sas:subtitleScore="62" begin="00:00:01.000" end="00:00:02.000">
    <tt:p sas:confidence="100"></tt:p>
    <tt:p sas:confidence="100"></tt:p>
  </tt:div>
  <tt:div sas:subtitleScore="62" sas:markedAsCorrect="false" begin="00:00:01.000" end="00:00:02.000">
    <tt:p sas:confidence="100"></tt:p>
    <tt:p sas:confidence="100"></tt:p>
  </tt:div>
  <tt:div sas:subtitleScore="62" sas:markedAsCorrect="false" begin="00:00:04.000" end="00:00:02.000">
    <tt:p sas:confidence="100"></tt:p>
    <tt:p sas:confidence="100"></tt:p>
  </tt:div>
</sasquatch>
  let $score := s:project-coverage($div)
  return unit:assert-equals( $score, 0 )
};


()