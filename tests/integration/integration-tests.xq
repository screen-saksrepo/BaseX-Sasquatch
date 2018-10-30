(: Overwrite with your local machine or append following line to /etc/hosts:
 : 
 : ```
 : 127.0.0.1	sasquatch
 : ```
 :)
declare variable $host := "http://sasquatch:8984";


declare  
  %unit:test
function local:project-create() {
  let $result := local:create("files/stt-snippet.json") => head()
  return unit:assert-equals($result/@status/number(), 200)
};

declare
  %unit:test
function local:project-create-return-as-json() {
  let $url    := ($host||"/v1/projects")
  let $id     := local:create("files/iran-deal-speech.json") => reverse() => head()
  let $id     := $id/*/id/string()
  let $result := local:get-with-content-type("application/json", "projects/"||$id) => head()
  return unit:assert-equals(
  $result/@status/number(), 200
  )
};

declare
  %unit:test
function local:project-create-return-as-webvtt() {
  let $url    := ($host||"/v1/projects")
  let $id     := local:create("files/iran-deal-speech.json") => reverse() => head()
  let $id     := $id/*/id/string()
  let $result := local:get-with-content-type("text/vtt", "projects/"||$id, "GET", "text/plain") => head()
  return unit:assert-equals(
  $result/@status/number(), 200
  )
};


declare
  %unit:test
function local:project-create-return-as-ebutt() {
  let $url    := ($host||"/v1/projects")
  let $id     := local:create("files/iran-deal-speech.json") => reverse() => head()
  let $id     := $id/*/id/string()
  let $result := local:get-with-content-type("application/ebutt+xml", "projects/"||$id) =>  head()
  return unit:assert-equals(
  $result/@status/number(), 200
  )
};

declare
  %unit:test
function local:project-create-return-after-split() {
  let $url      := ($host||"/v1/projects/")
  let $id       := local:create("files/iran-deal-speech.json") => reverse() => head()
  let $id       := $id/*/id/string()
  let $before   := local:get-with-content-type("application/json", "projects/"||$id) => reverse() =>  head()
  let $first-st := $before/json/subtitles/_[1]/id/string()
  let $count-be := $before/json/subtitles/_ => count()
  let $split    := local:get-with-content-type("application/json", "projects/"|| $id ||"/subtitles/"|| $first-st ||"/split", "POST") => prof:void()
  let $after    := local:get-with-content-type("application/json", "projects/"||$id) => reverse() =>  head()
  let $count-af := $after/json/subtitles/_ => count()

  return unit:assert-equals(
    $count-af, $count-be + 1
  )
};

declare
  %unit:test
function local:project-create-return-vtt-after-split() {
  let $url      := ($host||"/v1/projects/")
  let $id       := local:create("files/iran-deal-speech.json") => reverse() => head()
  let $id       := $id/*/id/string()
  let $before   := local:get-with-content-type("application/json", "projects/"||$id) => reverse() =>  head()
  let $first-st := $before/json/subtitles/_[1]/id/string()
  let $split    := local:get-with-content-type("application/json", "projects/"|| $id ||"/subtitles/"|| $first-st ||"/split", "POST") => prof:void()
  let $after    := local:get-with-content-type("text/vtt", "projects/"||$id, 'GET', "text/plain")  => reverse() => head()
  return unit:assert(starts-with($after, "WEBVTT"))
};
declare
  %unit:test
function local:project-create-return-ebutt-after-split() {
  let $url      := ($host||"/v1/projects/")
  let $id       := local:create("files/iran-deal-speech.json") => reverse() => head()
  let $id       := $id/*/id/string()
  let $before   := local:get-with-content-type("application/json", "projects/"||$id) => reverse() =>  head()
  let $first-st := $before/json/subtitles/_[1]/id/string()
  let $split    := local:get-with-content-type("application/json", "projects/"|| $id ||"/subtitles/"|| $first-st ||"/split", "POST") => prof:void()
  let $split    := local:get-with-content-type("application/json", "projects/"|| $id ||"/subtitles/"|| $first-st ||"/split", "POST") => prof:void()
  let $after    := local:get-with-content-type("application/ebutt+xml", "projects/"||$id, 'GET', "application/xml")  => reverse() => head()
  return unit:assert($after//*:div => count() > 0)
};
declare
  %unit:test
function local:project-create-return-as-srt() {
  let $url    := ($host||"/v1/projects")
  let $id     := local:create("files/iran-deal-speech.json") => reverse() => head()
  let $id     := $id/*/id/string()
  let $result := local:get-with-content-type("application/x-subrip", "projects/"||$id,"GET", "text/plain") => head()
  return unit:assert-equals(
  $result/@status/number(), 200
  )
};


declare
  %unit:test
function local:project-fail() {
  let $url := $host||"/v1/projects"

  let $result := 
  <http:request href='{ $url }' method='PUT'>
    <http:header name="Accept" value="application/json"/>
    <http:multipart media-type="multipart/form-data">
    <http:header name="Content-Disposition" value='form-data; name="file"; filename="stt-snippet.json"'/>
    <http:body media-type="application/json">{ fetch:text('files/stt-snippet.json') }</http:body>
    <http:header name="Content-Disposition" value='form-data; name="categories"'/>
    <http:body media-type="text/plain">foo,bar</http:body>
   </http:multipart>
  </http:request>
  => http:send-request()
  => head()
  return unit:assert-equals($result/@status/number(), 404)
};

declare %private function local:create($path-to-file){
  let $url := ($host||"/v1/projects")
  return
  <http:request href='{ $url }' method='post'>
    <http:header name="Accept" value="application/json"/>
    <http:multipart media-type="multipart/form-data">
    <http:header name="Content-Disposition" value='form-data; name="file"; filename="stt-snippet.json"'/>
    <http:body media-type="application/json">{ fetch:text($path-to-file)}</http:body>
    <http:header name="Content-Disposition" value='form-data; name="categories"'/>
    <http:body media-type="text/plain">foo,bar</http:body>
   </http:multipart>
  </http:request>
  => http:send-request()
};
declare %private function local:get-with-content-type($content-type, $path){
  local:get-with-content-type($content-type, $path, (),())
};
declare %private function local:get-with-content-type($content-type, $path, $method){
  local:get-with-content-type($content-type, $path, $method,())
};

declare %private function local:get-with-content-type($content-type, $path, $method, $media-type){
  let $url := ($host||"/v1/"||$path)
  let $result :=   <http:request href='{ $url }'>
  {if($method) then attribute method { $method } else attribute method {"GET"},
  if($media-type) then attribute override-media-type { $media-type } else ()},
    <http:header name="Accept" value="{ $content-type }"/>

  </http:request>
  => http:send-request()
  let $check := unit:assert($result[1]/@status/number()< 400, string($result[2]))
  return $result
};

()
