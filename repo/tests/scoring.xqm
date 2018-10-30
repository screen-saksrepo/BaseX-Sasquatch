import module namespace api = 'api/api';
declare namespace tt  = 'http://www.w3.org/ns/ttml';
import module namespace di = 'data/intermediate';
import module namespace s = 'score/scoring';
import module namespace tjson = "transform/json";
declare namespace sas = 'http://basex.io/sas';


declare %unit:test
function local:readability(){
  let $div :=<tt:div sas:subtitleScore="62" begin="00:00:01.000" end="00:00:02.000">
        <tt:p sas:confidence="100">Today</tt:p>
        <tt:p sas:confidence="100">the a</tt:p>
      </tt:div>
  let $score := s:subtitle-readability($div)
  return unit:assert-equals(
    $score,
    100
  )
};
declare %unit:test
function local:readability2(){
  let $div := <tt:div sas:subtitleScore="62" begin="00:00:01.000" end="00:00:02.000">
        <tt:p sas:confidence="100">Today a</tt:p>
        <tt:p sas:confidence="100">the a</tt:p>
      </tt:div>
  let $score := s:subtitle-readability($div)
  return unit:assert-equals(
    $score,
    56
  )
};
declare %unit:test
function local:empty-overall(){
  let $div := <tt:div sas:subtitleScore="2" begin="00:00:01.000" end="00:00:02.000">
        <tt:p sas:confidence="100"></tt:p>
        <tt:p sas:confidence="100"></tt:p>
      </tt:div>
  let $score := s:subtitle-score($div)
  return unit:assert-equals(
    $score,
    0
  )
};
declare %unit:test
function local:empty-readability(){
  let $div := <tt:div sas:subtitleScore="62" begin="00:00:01.000" end="00:00:02.000">
        <tt:p sas:confidence=""></tt:p>
        <tt:p sas:confidence=""></tt:p>
      </tt:div>
  let $score := s:subtitle-readability($div)
  return unit:assert-equals(
    $score,
    0
  )
};
declare %unit:test
function local:empty-layout(){
  let $div := <tt:div sas:subtitleScore="62" begin="00:00:01.000" end="00:00:02.000">
        <tt:p sas:confidence=""></tt:p>
        <tt:p sas:confidence=""></tt:p>
      </tt:div>
  let $score := s:subtitle-layout($div)
  return unit:assert-equals(
    $score,
    0
  )
};
declare %unit:test
function local:empty-subtitle-text-accuracy(){
  let $div := <tt:div sas:subtitleScore="62" begin="00:00:01.000" end="00:00:02.000">
        <tt:p sas:confidence=""></tt:p>
        <tt:p sas:confidence=""></tt:p>
      </tt:div>
  let $score := s:subtitle-text-accuracy($div)
  return unit:assert-equals(
    $score,
    0
  )
};
declare %unit:test
function local:readability-override-markAsCorrect(){
  let $div := <tt:div sas:markedAsCorrect="true" begin="00:00:01.000" end="00:00:02.000">
        <tt:p sas:confidence="100">Today a</tt:p>
        <tt:p sas:confidence="100">the a  asd as das d asd</tt:p>
      </tt:div>
  let $score := s:subtitle-readability($div)
  return unit:assert-equals(
    $score,
    100
  )
};
declare %unit:test
function local:readability-false-markAsCorrect(){
  let $div := <tt:div sas:markedAsCorrect="false" begin="00:00:01.000" end="00:00:02.000">
        <tt:p sas:confidence="100">Today a</tt:p>
        <tt:p sas:confidence="100">the a  asd as das d asd</tt:p>
      </tt:div>
  let $score := s:subtitle-readability($div)
  return unit:assert-equals(
    $score,
    11
  )
};

declare %unit:test
function local:confidence(){
  let $div := <tt:div sas:markedAsCorrect="false" begin="00:00:01.000" end="00:00:02.000">
        <tt:p sas:confidence="100">Today a</tt:p>
        <tt:p sas:confidence="100">the a  asd as das d asd</tt:p>
      </tt:div>
  let $score := s:subtitle-text-accuracy($div)
  return unit:assert-equals(
    $score,
    100
  )
};
declare %unit:test
function local:confidence-correct(){
  let $div := <tt:div sas:markedAsCorrect="true" begin="00:00:01.000" end="00:00:02.000">
        <tt:p sas:confidence="50">Today a</tt:p>
        <tt:p sas:confidence="100">the a  asd as das d asd</tt:p>
      </tt:div>
  let $score := s:subtitle-text-accuracy($div)
  return unit:assert-equals(
    $score,
    100
  )
};
declare %unit:test
function local:confidence-low(){
  let $div := <tt:div sas:markedAsCorrect="false" begin="00:00:01.000" end="00:00:02.000">
        <tt:p sas:confidence="50">Today a</tt:p>
        <tt:p sas:confidence="100">the a  asd as das d asd</tt:p>
      </tt:div>
  let $score := s:subtitle-text-accuracy($div)
  return unit:assert-equals(
    $score,
    50
  )
};

declare %unit:test
function local:layout(){
  let $div := <tt:div sas:markedAsCorrect="false" begin="00:00:01.000" end="00:00:02.000">
        <tt:p sas:confidence="100">Today a</tt:p>
        <tt:p sas:confidence="100">Four Four Four Four Four Four Fouraaa</tt:p>
      </tt:div>
  let $score := s:subtitle-layout($div)
  return unit:assert-equals(
    $score,
    100
  )
};
declare %unit:test
function local:layout-correct(){
  let $div := <tt:div sas:markedAsCorrect="true" begin="00:00:01.000" end="00:00:02.000">
        <tt:p sas:confidence="100">Four Four Four Four Four Four Fouraaaa</tt:p>
        <tt:p sas:confidence="100">Four Four Four Four Four Four Fouraaa</tt:p>
      </tt:div>
  let $score := s:subtitle-layout($div)
  return unit:assert-equals(
    $score,
    100
  )
};
declare %unit:test
function local:layout-one-char-too-many(){
  let $div := <tt:div sas:markedAsCorrect="false" begin="00:00:01.000" end="00:00:02.000">
        <tt:p sas:confidence="100">Four Four Four Four Four Four Fouraaaa</tt:p>
        <tt:p sas:confidence="100">Four Four Four Four Four Four Fouraaa</tt:p>
      </tt:div>
  let $score := s:subtitle-layout($div)
  return unit:assert-equals(
    $score,
    97
  )
};
declare %unit:test
function local:layout-many-char-too-many(){
  let $div := <tt:div sas:markedAsCorrect="false" begin="00:00:01.000" end="00:00:02.000">
        <tt:p sas:confidence="100">Four Four Four Four Four Four Fouraaaa>Four Four Four Four Four Four Fouraaa</tt:p>
      </tt:div>
  let $score := s:subtitle-layout($div)
  return unit:assert-equals(
    $score,
    0
  )
};
()