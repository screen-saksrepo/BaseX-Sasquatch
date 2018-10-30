# API specification

The current state of the API is documented using swagger to produce an OpenAPI 2 spec.
The spec is served on ${HOST-URL}/.

To edit the spec:

```
docker pull swaggerapi/swagger-editor
docker run -d -p 80:8080 swaggerapi/swagger-editor
```

and load

```
webapp/static/v1/swagger.yaml
```

## Discussions and specification on S2S APIs (with John)

- Related issues: #1

There are two APIs:

- one API-1 to create a set of subtitles from the text received from Speech recognition and the initial audio coverage map.
- second API-2 to manipulate the set of subtitles that are related by a given 'project-id'.

### API-1

API-1 works at the subtitle set level - subtitle file level.

IJYI calls API-1 with:

    input:
    - metadata about the 'project' (Genre, Language, Context, Default layout, Default style)
    - A. JSON 'speech to text output' file containing word timings.
    - B. JSON? File with audio timings (the coverage map).
    
    processing:
    - S2S uses information A to build a set of subtitles, all related together by a subtitle set ID.
    - S2S uses information B and confidence information from A
      - to score this initial set of subtitles (each subtitle has a score)
      - and the set as a whole has an aggregate score.
    
    output:
    - S2S returns the subtitle set ID (and the aggregate score?) for IJYI to use as a reference in API-2.

### API-2    

API-2 (works at the individual subtitle level) to display, edit and mark the subtitles.
Each change to a subtitle changes it's score - and the score for the set of subtitles it belongs to.

Function such as:

- `GetNext`
- `GetPrev`
- `GetNextWorst`
- `ChangeText`
- `ChangeTiming`
- `ChangeStyle`
- `ChangeLayout`

## Discussions and specification on S2S APIs (with IJYI via Brendon)

## Create Project

1. POST JSON as `$json` plus parameters, such as: `$categories as xs:string*, $language as xs:string`
  1. create `$project-id := random:uuid()` => `db:create($project-id)`
  2. convert Intermediate => `db:add(${project-id}, ti:from-json($json, $catgegories, $language))`#
  3. `db:store($project-id, "input.json", $json)` JSON file in ("stt" database) as `${project-id}.json`
2.  return $project-id

### IJYI subtitle JSON Format

- files/sasquatch_models.json
- [API Wishlist by IJYI (via Brendon)](https://git.dev.basex.org/screen-systems/speech-to-subtitle/issues/28)

```json
{
    "projectId" : "27c62f4d-abea-4e69-b239-d083a0ae8555",
    "score" : 78.98, // double
    "videoLength": 327, // seconds
    "subtitles": [{
        "id": "A",
        "score" : "99.12",
        "start": "00:00:00.500",
        "end" : "00:00:02.000",
        "text" : "This is my subtile",
        "region" : {"to_discussed_with_basex_later"}
    }]
}
```

## Update single existing subtitle

- https://ijyi.visualstudio.com/Sasquatch/Sasquatch%20Team/_workitems/edit/10480
