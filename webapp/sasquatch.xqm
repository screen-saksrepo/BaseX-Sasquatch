module namespace s2s = 'sasquatch';

import module namespace api     = 'api/api';
import module namespace di      = 'data/intermediate';
import module namespace dv      = 'data/validate';
import module namespace r       = 'restxq/response';
import module namespace hal     = 'restxq/hal';
import module namespace e       = 'restxq/error';
import module namespace webvtt  = 'transform/webvtt';
import module namespace srt     = 'transform/srt';
import module namespace request = "http://exquery.org/ns/request";
import module namespace ti      = "transform/intermediate";
import module namespace tjson   = "transform/json";
import module namespace tebu-tt = "transform/ebu-tt";

declare namespace sas = 'http://basex.io/sas';
declare namespace tt  = 'http://www.w3.org/ns/ttml';

(: ~~~ REST API /projects ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ :)

(:~
 : Creates project, stores speech-to-text file and returns project id for further reference.
 :
 : ```sh
 : $ curl -v -F "file=@files/iran-deal-speech.json" "categories=foo1,foo2" localhost:8984/v1/projects
 : $ http -v -f POST localhost:8984/v1/projects categories=foo1,foo2 file@files/stt-snippet.json
 : ```
 : @param $file speech-to-text file
 : @param $categories metadata assoc. with the video
 : @return project id as UUID ```json {"id": $project-id}``` and HAL links.
 :)
declare
  %rest:path("/v1/projects")
  %rest:POST
  %updating
  %rest:consumes("multipart/form-data")
  %rest:produces("application/json")
  %output:method("json")
  %rest:form-param("file", "{$file}")
  %rest:form-param("categories", "{$categories}","")
function s2s:create-project(
    $file as map(xs:string, item()),
    $categories as xs:string?
  )
{
  try {
    let $project-id := random:uuid()
    let $categories := $categories => tokenize(",") => for-each(normalize-space#1)
    let $file       := $file(map:keys($file) => head())
      => convert:binary-to-string()
      => json:parse()
     update {
      replace node ./*/words with (
        element words {
          for tumbling window $word in ./*/words/_
          start when true()
          end $e next $wnext when $wnext/name != "." 
        return element _ {
          attribute type {"object"},
          element duration   { $word/duration/number() => head() },
          element confidence { $word/confidence/number() => max() },
          element time { $word/time/text() => head() },
          element name { string-join($word/name) }
        }
      }
      )
    }
    return (
      db:create($project-id, 
        (
          ti:from-json($file, $project-id, $categories) => di:create-gaps(),
          $file
        ),
        (
          $project-id || ".xml",
          "json.xml"
        )
      ),
      update:output(
        element json {
          attribute type {"object"},
          element id { $project-id },
          hal:hal-project($project-id, request:scheme(), request:hostname(), request:port())
        }
      )
    )
  } catch * {
    r:json-text(500,``[`{$err:code}` Unexpected error `{$err:description}`]``) => update:output()
  }
};

(:~
 : List all project-ids.
 :
 : @return project ids as UUID
 :)
declare
  %rest:path("/v1/projects")
  %rest:GET
  %output:method("json")
function s2s:list-projects()
{
  try {
    element json {
      attribute type { "array" },
      for $pid in db:list()
      return element _ { $pid }
    }
  } catch * {
    r:json-text(500,``[`{$err:code}` Unexpected error `{$err:description}`]``)
  }
};

(:~
 : Returns all subtitles for a specific project in IJYI subtitle JSON format.
 :
 : @param project-id 
 : @return subtitle as application/json
 :)
declare
  %rest:path("/v1/projects/{$project-id}")
  %rest:GET
  %rest:produces("application/json")
  %output:method("json")
function s2s:get-project-json(
    $project-id as xs:string
  )
{
  try {
    di:get($project-id) => tjson:from-intermediate()
  } catch Q{sas}NOTFOUND {
    r:json-text(404,``[`{$err:description}`]``)
  } catch * {
    r:json-text(500,``[`{$err:code}` Unexpected error `{$err:description}`]``)
  }
};

(:~
 : Returns all subtitles for a specific project in webvtt format.
 :
 : @param project-id 
 : @return subtitle in text/vtt
 :)
declare
  %rest:path("/v1/projects/{$project-id}")
  %rest:GET
  %rest:produces("text/vtt")
  %output:method("basex")
function s2s:get-project-webvtt(
    $project-id as xs:string
  )
{
  try {
    di:get($project-id) => webvtt:from-sasquatch()
  } catch Q{sas}NOTFOUND {
    r:json-text(404,``[`{$err:description}`]``)
  } catch * {
    r:json-text(500,``[`{$err:code}` Unexpected error `{$err:description}`]``)
  }
};

(:~
 : Returns all subtitles for a specific project in SRT (SubRip) format.
 :
 : @param project-id
 : @return subtitle in application/x-subrip
 :)
declare
  %rest:path("/v1/projects/{$project-id}")
  %rest:GET
  %rest:produces("application/x-subrip")
  %output:method("text")
function s2s:get-project-as-srt(
    $project-id as xs:string
  )
{
   try {
    di:get($project-id) => srt:from-sasquatch()
  } catch Q{sas}NOTFOUND {
    r:json-text(404,``[`{$err:description}`]``)
  } catch * {
    r:json-text(500,``[`{$err:code}` Unexpected error `{$err:description}`]``)
  }
};

declare
  %rest:path("/v1/projects/{$project-id}")
  %rest:GET
  %rest:produces("text/html")
  %output:method("html")
function s2s:get-project-help(
    $project-id as xs:string
  )
{
  element html {
    element head {
    element title { "Multiple Choices" }
    },
    element body {
      <h2>This ressource is availabe with the following Request headers:</h2>,
      element dl {
        element dt { "HTML"},
        element dd { element code {"Accept: text/html"}, " this page"},
        element dt { "JSON"},
        element dd { element code {"Accept: application/json"}},
        element dt { "WEBVTT"},
        element dd { element code {"Accept: text/vtt"}},
        element dt { "EBU-TT-D"},
        element dd { element code {"Accept: application/ebutt+xml"}},
        element dt { "IMSC1"},
        element dd { element code {"Accept: application/imsc1+xml"}},
        ()
      }
    }
  }
};

(:~
 : Returns all subtitles for a specific project in EBU-TT-D format.
 : @param project-id 
 : @return subtitle in EBU-TT-D
 :)
declare
  %rest:path("/v1/projects/{$project-id}")
  %rest:GET
  %rest:produces("application/ebutt+xml")
  %output:method("xml")
function s2s:get-project-as-ebutt(
    $project-id as xs:string
  )
{
  try {
    let $sq := di:get($project-id)
    return tebu-tt:from-sasquatch($sq)
  } catch Q{sas}NOTFOUND {
    r:json-text(404,``[`{$err:description}`]``)
  } catch * {
    r:json-text(500,``[`{$err:code}` Unexpected error `{$err:description}`]``)
  }
};

(:~
 : Returns all subtitles for a specific project in IMSC1 format.
 :
 : @param project-id
 : @return subtitle in application/imsc1+xml
 :)
declare
  %rest:path("/v1/projects/{$project-id}")
  %rest:GET
  %rest:produces("application/imsc1+xml")
  %output:method("xml")
function s2s:get-project-as-imsc1(
    $project-id as xs:string
  )
{
  try {
    <tt xml:lang="en"
      xmlns="http://www.w3.org/ns/ttml"
      xmlns:ttm="http://www.w3.org/ns/ttml#metadata" 
      xmlns:tts="http://www.w3.org/ns/ttml#styling"
      xmlns:ttp="http://www.w3.org/ns/ttml#parameter" 
      ttp:displayAspectRatio="4 3"
      ttp:contentProfiles="http://www.w3.org/ns/ttml/profile/imsc1.1/text">
      
      <head>
          <layout>
              <region xml:id="area1" tts:origin="10% 10%" tts:extent="80% 10%" tts:backgroundColor="black" tts:displayAlign="center" tts:color="red"/>
          </layout>
      </head>
      <body>
          <div>
              <p region="area1" begin="0s" end="6s">Lorem ipsum dolor.</p>
          </div>
      </body>
    </tt>
  } catch * {
    r:json-text(500,``[`{$err:code}` Unexpected error `{$err:description}`]``)
  }
};


(:~
 : Returns subtitle with worst score.
 :
 : @param project-id
 : @return subtitle as json-subtitle-object
 :)
declare
  %rest:path("/v1/projects/{$project-id}/worstSubtitle")
  %rest:GET
  %rest:produces("application/json")
  %output:method("json")
function s2s:get-project-worst-subtitle(
    $project-id as xs:string
  )
{
  try {
    element json {
      attribute type { "object" },
      di:get-worst-subtitle($project-id) => tjson:subtitle-from-intermediate()
    }
  } catch Q{sas}NOTFOUND {
    r:json-text(404,``[`{$err:description}`]``)
  } catch * {
    r:json-text(500,``[`{$err:code}` Unexpected error `{$err:description}`]``)
  }
};

(:~
 : Returns project scores.
 :
 : @param project-id
 : @return subtitle in application/x-subrip
 :)
declare
  %rest:path("/v1/projects/{$project-id}/scores")
  %rest:GET
  %rest:produces("application/json")
  %output:method("json")
function s2s:get-project-scores(
    $project-id as xs:string
  )
{
  try {
    element json {
      attribute type { "object" },
      di:get($project-id) => tjson:from-intermediate-project-score()
    }
  } catch Q{sas}NOTFOUND {
    r:json-text(404,``[`{$err:description}`]``)
  } catch * {
    r:json-text(500,``[`{$err:code}` Unexpected error `{$err:description}`]``)
  }
};

(: ~~~ REST API /projects/{projectId}/subtitles/{subtitleId} ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ :)

(:~
 : Updates existing subtitle.
 :
 : @param project-id
 : @param subtitle-id
 : @param json-subtitle-object
 : @return json-subtitle-object with updated subtitle
 : @error 404 for project, subtitle is not found
 : (TODO @error 409 if input structure does not validate)
 : @error 500 for unexpected errors
 :)
declare
  %rest:PUT("{$file}")
  %updating
  %rest:path("/v1/projects/{$project-id}/subtitles/{$subtitle-id}")
  %rest:consumes("application/json")
  %rest:produces("application/json")
  %output:method("json")
function s2s:put-project-subtitle(
    $project-id as xs:string,
    $subtitle-id as xs:string,
    $file as document-node()
  )
{
  try {
    (: dv:validate-json-subtitle-object($file), :)
    let $updated-subtitle := di:update-prepare-subtitle($subtitle-id, $file/json)
    return (
     $updated-subtitle => tjson:subtitle-from-intermediate() => tjson:wrap-object() => db:output(),
     replace node di:get(di:get($project-id), $subtitle-id) with $updated-subtitle
    )
  } catch Q{sas}NOTFOUND {
    r:json-text(404,``[`{$err:description}`]``) => db:output()
  } catch Q{sas}CONFLICT {
    r:json-text(409,``[`{$err:description}`]``) => db:output()
  } catch * {
    r:json-text(500,``[`{$err:code}` Unexpected error. `{$err:description}`, `{$err:module}`:`{$err:line-number}`]``) => db:output()
  }
};

(:~
 : Get existing subtitle (by id).
 :
 : @param project-id
 : @param subtitle-id
 : @return json-subtitle-object
 :) 
declare
  %rest:GET
  %rest:path("/v1/projects/{$project-id}/subtitles/{$subtitle-id}")
  %rest:produces("application/json")
  %output:method("json")
function s2s:get-project-subtitle(
    $project-id as xs:string,
    $subtitle-id as xs:string
  )
{
  try {
    element json {
      attribute type { "object" },
      di:get-by-ids($project-id, $subtitle-id) => tjson:subtitle-from-intermediate()
    }
  } catch Q{sas}NOTFOUND {
    r:json-text(404,``[`{$err:description}`]``)
  } catch Q{sas}CONFLICT {
    r:json-text(409,``[`{$err:description}`]``)
  } catch * {
    r:json-text(500,``[`{$err:code}` Unexpected error. `{$err:description}`]``)
  }
};

(:~
 : Returns ids (next, previous, ...) relative to subtitle.
 :
 : @param project-id
 : @param subtitle-id
 : @return hal-links-object
 :) 
declare
  %rest:GET
  %rest:path("/v1/projects/{$project-id}/subtitles/{$subtitle-id}/hal")
  %rest:produces("application/json")
  %output:method("json")
function s2s:get-project-subtitle-hal(
    $project-id as xs:string,
    $subtitle-id as xs:string
  )
{
  try {
    hal:hal-get-subtitle($project-id, $subtitle-id, request:scheme(), request:hostname(), request:port())
    => tjson:wrap-object()
  } catch Q{sas}NOTFOUND {
    r:json-text(404,``[`{$err:description}`]``)
  } catch Q{sas}CONFLICT {
    r:json-text(409,``[`{$err:description}`]``)
  } catch * {
    r:json-text(500,``[`{$err:code}` Unexpected error. `{$err:description}`]``)
  }
};

(:~
 : Get existing subtitle (by point in time).
 :
 : @param project-id
 : @param point in time (in video)
 : @return json-subtitle-object
 :) 
declare
  %rest:GET
  %rest:path("/v1/projects/{$project-id}/subtitles")
  %rest:query-param("time", "{$time}")
  %rest:produces("application/json")
  %output:method("json")
function s2s:get-project-subtitle-by-time(
    $project-id as xs:string,
    $time as xs:string (: Do not cast to xs:time here as it throws uncatchable error. :)
  )
{
  try {
    element json {
      attribute type { "object" },
      di:get-subtitle-at-point-in-time($project-id, $time) => tjson:subtitle-from-intermediate()
    }
  } catch Q{http://www.w3.org/2005/xqt-errors}FORG0001 {
    r:json-text(400,``[`{$err:description}`]``)
  } catch Q{sas}NOTFOUND {
    r:json-text(404,``[`{$err:description}`]``)
  } catch Q{sas}CONFLICT {
    r:json-text(409,``[`{$err:description}`]``)
  } catch * {
    r:json-text(500,``[`{$err:code}` Unexpected error. `{$err:description}`]``)
  }
};

(:~
 : Get next subtitle relative to existing subtitle (by id).
 :
 : @param project-id
 : @param subtitle-id
 : @return json-subtitle-object
 :) 
declare
  %rest:GET
  %rest:path("/v1/projects/{$project-id}/subtitles/{$subtitle-id}/next")
  %rest:produces("application/json")
  %output:method("json")
function s2s:get-project-subtitle-next(
    $project-id as xs:string,
    $subtitle-id as xs:string
  )
{
  try {
    element json {
      attribute type { "object" },
      di:get-next-subtitle-by-ids($project-id, $subtitle-id, false()) ! tjson:subtitle-from-intermediate(.)
    }
  } catch Q{sas}NOTFOUND {
    r:json-text(404,``[`{$err:description}`]``)
  } catch * {
    r:json-text(500,``[`{$err:module}`:`{$err:line-number}`:`{$err:code}` Unexpected error. `{$err:description}`]``)
  }
};

(:~
 : Get previous subtitle relative to existing subtitle (by id).
 :
 : @param project-id
 : @param subtitle-id
 : @return json-subtitle-object
 :) 
declare
  %rest:GET
  %rest:path("/v1/projects/{$project-id}/subtitles/{$subtitle-id}/previous")
  %rest:produces("application/json")
  %output:method("json")
function s2s:get-project-subtitle-previous(
    $project-id as xs:string,
    $subtitle-id as xs:string
  )
{
  try {
    element json {
      attribute type { "object" },
      di:get-previous-subtitle-by-ids($project-id, $subtitle-id, false()) ! tjson:subtitle-from-intermediate(.)
    }
  } catch Q{sas}NOTFOUND {
    r:json-text(404,``[`{$err:description}`]``)
  } catch * {
    r:json-text(500,``[`{$err:code}` Unexpected error. `{$err:description}`]``)
  }
};

(:~
 : Move first word to previous subtitle.
 :
 : @param project-id
 : @param subtitle-id
 : @return json-subtitle-objects with updated subtitles
 : @error 404 for project, subtitle is not found
 : @error 500 for unexpected errors
 :)
declare
  %rest:POST
  %updating
  %rest:path("/v1/projects/{$project-id}/subtitles/{$subtitle-id}/firstWordToPrevious")
  %rest:consumes("application/json")
  %rest:produces("application/json")
  %output:method("json")
function s2s:project-subtitle-first-word-to-previous(
    $project-id as xs:string,
    $subtitle-id as xs:string
  )
{
  try {
    let $sq := api:first-word-to-previous(di:get($project-id), $subtitle-id)
    let $subs := $sq//*:div[@*:id = ($subtitle-id, di:get-previous-subtitle-id-by-ids($project-id, $subtitle-id, true()))]
    return
    (
      (: Return updated subtitle objects :)
      ( for $sub in $subs return $sub => tjson:subtitle-from-intermediate() => tjson:wrap-object() )
      => tjson:wrap-array() => db:output()
      (: Save to database :)
      , di:replace($project-id, $sq)
    )
  } catch Q{sas}NOTFOUND {
    r:json-text(404,``[`{$err:description}`]``) => db:output()
  } catch Q{sas}CONFLICT {
    r:json-text(409,``[`{$err:description}`]``) => db:output()
  } catch * {
    r:json-text(500,``[`{$err:code}` Unexpected error. `{$err:description}`]``) => db:output()
  }
};

(:~
 : Move last word to next subtitle.
 :
 : @param project-id
 : @param subtitle-id
 : @return json-subtitle-objects with updated subtitles
 : @error 404 for project, subtitle is not found
 : @error 500 for unexpected errors
 :)
declare
  %rest:POST
  %updating
  %rest:path("/v1/projects/{$project-id}/subtitles/{$subtitle-id}/lastWordToNext")
  %rest:consumes("application/json")
  %rest:produces("application/json")
  %output:method("json")
function s2s:project-subtitle-last-word-to-next(
    $project-id as xs:string,
    $subtitle-id as xs:string
  )
{
  try {
    let $sq := api:last-word-to-next(di:get($project-id), $subtitle-id)
    let $subs := $sq//*:div[@*:id = ($subtitle-id, di:get-next-subtitle($sq, $subtitle-id, true())/@sas:id/data() )]
    return
    (
      (: Return updated subtitle objects :)
      ( for $sub in $subs return $sub => tjson:subtitle-from-intermediate() => tjson:wrap-object() )
      => tjson:wrap-array() => db:output()
      (: Save to database :)
      , di:replace($project-id, $sq)
    )
  } catch Q{sas}NOTFOUND {
    r:json-text(404,``[`{$err:description}`]``) => db:output()
  } catch Q{sas}CONFLICT {
    r:json-text(409,``[`{$err:description}`]``) => db:output()
  } catch * {
    r:json-text(500,``[`{$err:code}` Unexpected error. `{$err:description}`]``) => db:output()
  }
};

(:~
 : Merge adjacent subtitles.
 :
 : @param project-id
 : @param subtitle-id
 : @return json-subtitle-objects with updated subtitle and new next one
 : @error 404 for project, subtitle is not found
 : @error 500 for unexpected errors
 :)
declare
  %rest:POST
  %updating
  %rest:path("/v1/projects/{$project-id}/subtitles/{$subtitle-id}/mergeWithNext")
  %rest:consumes("application/json")
  %rest:produces("application/json")
  %output:method("json")
function s2s:project-subtitle-merge-with-next(
    $project-id as xs:string,
    $subtitle-id as xs:string
  )
{
  try {
    let $sq := api:merge(di:get($project-id), $subtitle-id)
    let $subs := $sq//*:div[@*:id = ($subtitle-id, di:get-next-subtitle($sq, $subtitle-id, true())/@sas:id/data())]
    return
    (
      (: Return updated subtitle objects :)
      ( for $sub in $subs return $sub => tjson:subtitle-from-intermediate() => tjson:wrap-object() )
      => tjson:wrap-array() => db:output()
      (: Save to database :)
      , di:replace($project-id, $sq)
    )
  } catch Q{sas}NOTFOUND {
    r:json-text(404,``[`{$err:description}`]``) => db:output()
  } catch Q{sas}CONFLICT {
    r:json-text(409,``[`{$err:description}`]``) => db:output()
  } catch * {
    r:json-text(500,``[`{$err:code}` Unexpected error. `{$err:description}`]``) => db:output()
  }
};

(:~
 : Split subtitle.
 :
 : @param project-id
 : @param subtitle-id
 : @return json-subtitle-objects with updated subtitle and new next one
 : @error 404 for project, subtitle is not found
 : @error 500 for unexpected errors
 :)
declare
  %rest:POST
  %updating
  %rest:path("/v1/projects/{$project-id}/subtitles/{$subtitle-id}/split")
  %rest:consumes("application/json")
  %rest:produces("application/json")
  %output:method("json")
function s2s:project-subtitle-split(
    $project-id as xs:string,
    $subtitle-id as xs:string
  )
{
  try {
    let $sq := api:split(di:get($project-id), $subtitle-id)
    let $subs := (
       $sq => di:get($subtitle-id),
      ($sq => di:get($subtitle-id))/following-sibling::tt:div => head()
    )
    return
    (
      (: Return updated subtitle objects :)
      ( for $sub in $subs 
      return $sub
              => tjson:subtitle-from-intermediate()
              => tjson:wrap-object() 
      )
      => tjson:wrap-array() => db:output()
      (: Save to database :)
      , di:replace($project-id, $sq)
    )
  } catch Q{sas}NOTFOUND {
    r:json-text(404,``[`{$err:description}`]``) => db:output()
  } catch Q{sas}CONFLICT {
    r:json-text(409,``[`{$err:description}`]``) => db:output()
  } catch * {
    r:json-text(500,``[`{$err:code}` Unexpected error. `{$err:additional}`]``) => db:output()
  }
};

(:~
 : Archive database.
 :
 : @param project-id
 : @return 201 CREATE with path to zipped archive
 : @error 404 for project, subtitle is not found
 : @error 500 for unexpected errors
 :)
declare
  %rest:POST
  %updating
  %rest:path("/v1/projects/{$project-id}/archive")
  %rest:consumes("application/json")
  %rest:produces("application/json")
  %output:method("json")
function s2s:project-archive(
    $project-id as xs:string
  )
{
  try {
    let $sq := di:get($project-id) return (), (: Throws error, if does not exist. :)
    db:create-backup($project-id),
    db:drop($project-id),
    for $f in file:list(db:option('dbpath')) 
    where matches($f, $project-id || '.*zip')
    return error($e:CREATE, 'Archive created: ' || $f)
  } catch Q{sas}CREATE {
    r:json-text(201,``[`{$err:description}`]``) => db:output()
  } catch Q{sas}NOTFOUND {
    r:json-text(404,``[`{$err:description}`]``) => db:output()
  } catch * {
    r:json-text(500,``[`{$err:code}` Unexpected error. `{$err:description}`]``) => db:output()
  }
};

(:~
 : Restore database.
 :
 : @param project-id
 : @return path to zipped archive
 : @error 404 for project, subtitle is not found
 : @error 500 for unexpected errors
 :)
declare
  %rest:POST
  %updating
  %rest:path("/v1/projects/{$project-id}/restore")
  %rest:consumes("application/json")
  %rest:produces("application/json")
  %output:method("json")
function s2s:project-restore(
    $project-id as xs:string
  )
{
  try {
    db:restore($project-id), 
    r:json-object(201, 
      <json type="object">
        <code>201</code>
        <message>Archive restored.</message>
        <id>{ $project-id }</id>
      </json>
    ) => db:output()
  } catch db:no-backup {
    r:json-text(404,``[`{$err:description}`]``) => db:output()
  } catch Q{sas}NOTFOUND {
    r:json-text(404,``[`{$err:description}`]``) => db:output()
  } catch * {
    r:json-text(500,``[`{$err:code}` Unexpected error. `{$err:description}`]``) => db:output()
  }
};

(: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ :)
