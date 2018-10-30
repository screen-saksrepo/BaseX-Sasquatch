import module namespace webvtt = "transform/webvtt";
import module namespace intermediate = "transform/intermediate";
declare namespace tt  = "http://www.w3.org/ns/ttml";

declare
  %unit:test
function local:test-escape(){
  let $result := fetch:xml('tests/control-files/stt-json-to-sasquatch.xml')/*
    => webvtt:from-sasquatch()

  let $expected := fetch:text('tests/control-files/stt-sasquatch-to-webvtt.txt')
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
  let $doc     := fetch:text('tests/control-files/stt-issue-45.json') => json:parse()
  let $webvtt  := intermediate:from-json($doc,"foo", ()) => webvtt:from-sasquatch()
  return unit:assert-equals(
    $webvtt,
    fetch:text('tests/control-files/stt-issue-45.webvtt')
  )
};


(:~
 : Ensures basic JSON => Sasquatch-XML Conversion
:)
declare
  %unit:test
function local:test-from-json() {
  let $doc      := fetch:text('tests/control-files/stt.json') => json:parse()
  let $expected := doc('../../tests/control-files/stt-json-to-sasquatch.xml')
  let $sas      := intermediate:from-json($doc,"foo", ())
  return unit:assert(
    deep-equal(
      ($sas//*:tt update delete node (.//@*:id, .//@*:subtitleScore)),
      ($expected//*:tt update delete node (.//@*:id, .//@*:subtitleScore))
    )
  )
};


(:~
 : Ensures basic JSON => Sasquatch-XML Conversion
:)
declare
  %unit:test
function local:test-timecodes() {
  let $doc := element sasquatch {
    element tt:tt {
      element tt:body {
        element tt:div {
          attribute begin { "00:00:01.0"},
          attribute end { "00:00:02.000001"},
          element tt:p { "a" }
        }
      }
    }
  } => webvtt:from-sasquatch()
  
  return unit:assert-equals(
    $doc,
    "WEBVTT

00:00:01.000 --> 00:00:02.000
a

")
  
};

()