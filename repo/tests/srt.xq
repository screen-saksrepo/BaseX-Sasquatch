import module namespace srt = "transform/srt";
import module namespace intermediate = "transform/intermediate";

declare
  %unit:test
function local:test-escape(){
  let $result := fetch:xml('tests/control-files/stt-json-to-sasquatch.xml')/*
    => srt:from-sasquatch()
  let $expected := fetch:text('tests/control-files/stt-sasquatch-to-srt.txt')
  return unit:assert-equals(
    $result,
    $expected
  )
};

(: https://git.dev.basex.org/screen-systems/speech-to-subtitle/issues/45
  10505 Space should not remain before full stop
:)
declare
  %unit:test
function local:test-full-stop(){
  let $doc := fetch:text('tests/control-files/stt-issue-45.json') => json:parse()
  let $srt := intermediate:from-json($doc,"foo", ()) => srt:from-sasquatch()
  return unit:assert-equals(
    $srt,
    fetch:text('tests/control-files/stt-issue-45.srt')
  )
};

()