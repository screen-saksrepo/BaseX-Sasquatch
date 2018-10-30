module namespace t = 'transform/timings';

import module namespace e = 'restxq/error';

declare variable $t:gap := xs:dayTimeDuration('PT0.1S');

(:~
 : Converts ss or ss.f input string to xs:time or throws an error.
 :
 : '3602.123456' expected result: xs:time(01:00:02.123)
 :)
declare function t:time-from-seconds(
    $seconds as xs:string
  ) as xs:time
{
  let $duration := xs:duration('PT' || $seconds || 'S')
  let $hh := fn:hours-from-duration($duration)   => format-number('00')
  let $mm := fn:minutes-from-duration($duration) => format-number('00')
  let $ss := fn:seconds-from-duration($duration) => format-number('00.000')
  return
    concat($hh, ':', $mm, ':', $ss)
    => xs:time()
};

(:~
 : Converts hh:mm:ss.f input string to xs:time or throws an error.
 :)
declare function t:seconds-from-hhmmssf(
    $time as xs:string
  )
{
  let $time := xs:time($time) 
  return ($time => seconds-from-time()) + (60 * $time => minutes-from-time()) + (60*60* $time => hours-from-time())
};

(:~
 : Converts hh:mm:ss.f input string to xs:time or throws an error.
 :)
declare function t:time-from-hhmmssf(
    $time as xs:string
  ) as xs:time
{
  xs:time($time)
};

(:~
 : Converts hh:mm:ss.f input string to xs:time or throws an error.
 :)
declare function t:time-to-hhmmssf(
    $time as xs:time
  ) as xs:string
{
  $time => format-time("[H01]:[m01]:[s01].[f001]")
};

(:~ 
 : Converts timing input to xs:time or throws an error.
 :
 : @param str-time timing input ('hh:mm:ss.f' or 'ss' or 'ss.f')
 : @return xs:time
 :)
declare function t:string-to-time(
    $str-time as xs:string
  ) as xs:time
{
  if (contains($str-time, ':'))
  then t:time-from-hhmmssf($str-time)
  else t:time-from-seconds($str-time)
};

(:~
 : Computes point in time in between to times.
 :
 : @param begin
 : @param end
 : @return xs:time
 :)
declare function t:midway(
    $begin as xs:time,
    $end as xs:time
  ) as xs:time
{
  $begin + (($end - $begin) div 2)
};

(:~
 : Adds default gap between subtitle to given time.
 :
 : @param time
 : @return xs:time
 :)
declare function t:add-gap(
    $time as xs:time
  ) as xs:time
{
  $time + $t:gap
};
