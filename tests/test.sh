#!/bin/bash
#
# Poor man's test script for basic API calls.
#
# (C) 2018, Alexander Holupirek <ah@basex.org>
#
#set -x
set -e # fail on any error

HOST=http://localhost:8984
#HOST=http://109.239.48.124
#HOST=http://sasquatch:8984
FILE=../files/iran-deal-speech.json

pwd | grep /tests$ || cd tests

# Create project
UUID=$(curl -s -X POST "${HOST}/v1/projects" -H "accept: application/json" -H "Content-Type: multipart/form-data" -F "file=@${FILE};type=application/json" | grep id | cut -d: -f2 | sed -e s/\"//g | sed -e s/,//)
echo POST /project
echo ${UUID}

# Get project
DIR=tmp-files
rm -rf ${DIR}
mkdir ${DIR} 2>/dev/null
curl -s -X GET "${HOST}/v1/projects/${UUID}" -H "accept: application/json"      >${DIR}/GET-test.json.orig
cat ${DIR}/GET-test.json.orig | gsed -E 's/(")(id|projectId|projectScore|projectCoverage|projectTextAccuracy|projectReadability|projectLayout|subtitleScore|subtitleTextAccuracy|subtitleReadability|subtitleLayout)(":).*(,)/\1\2\3\4/' >${DIR}/GET-test.json
curl -s -X GET "${HOST}/v1/projects/${UUID}" -H "accept: text/vtt"              >${DIR}/GET-test.webvtt
curl -s -X GET "${HOST}/v1/projects/${UUID}" -H "accept: application/ebutt+xml" >${DIR}/GET-test.ebutt.xml
curl -s -X GET "${HOST}/v1/projects/${UUID}" -H "accept: application/imsc1+xml" >${DIR}/GET-test.imsc1.xml
echo GET  /projects/${UUID} as json,vtt,ebu-tt,imsc
tree --noreport ${DIR}

CNT=control-files
diff -q ${CNT}/GET-test.json      ${DIR}/GET-test.json
diff -q ${CNT}/GET-test.webvtt    ${DIR}/GET-test.webvtt   
diff -q ${CNT}/GET-test.ebutt.xml ${DIR}/GET-test.ebutt.xml
diff -q ${CNT}/GET-test.imsc1.xml ${DIR}/GET-test.imsc1.xml

# Update existing subtitle
STID=$(grep id ${DIR}/GET-test.json.orig | tail -n 3 | head -n 1 | sed -e s/\"id\":\"// | sed -e s/\",// | sed -e s/\ //g)
echo PUT /projects/${UUID}/subtitles/${STID}
#curl -s -X PUT "${HOST}/v1/projects/${UUID}/subtitles/${STID}" -H "accept: application/json" -H "Content-Type: application/json" -d "{ \"id\": \"f3be5009-9db0-4486-91ce-d77074fb250b\", \"score\": 99.99999, \"start\": 842.68, \"end\": 843.01, \"lines\": [ { \"id\": \"14e5a3ae-6708-46cb-a190-3704e9c547ba\", \"score\": 100, \"words\": [ { \"id\": \"afbd7ace-915a-4f59-b3ab-baa2db88ab33\", \"score\": 100, \"start\": 842.68, \"end\": 843.01, \"word\": \"Foobar\" } ] } ]}" | tail -n 19 | gsed -E 's/(")(id|projectId|projectScore|projectCoverage|projectTextAccuracy|projectReadability|projectLayout|subtitleScore|subtitleTextAccuracy|subtitleReadability|subtitleLayout)(":).*(,)/\1\2\3\4/'  >${DIR}/PUT-subtitle-test.json
#curl -s -X PUT "${HOST}/v1/projects/84904808-79e3-4f1e-b6bd-72ad5525cad8/subtitles/d7dd3568-b429-4ebf-a199-279352f6dd9a" -H "accept: application/json" -H "Content-Type: application/json" -d "{ \"id\": \"\", \"subtitleTextAccuracy\": 0, \"subtitleReadability\": 0, \"subtitleLayout\": 0, \"start\": 0.0, \"end\": 0.0, \"lines\": [ { \"id\": \"\", \"wordsCount\": 0, \"line\": \"a b c\" }, { \"id\": \"\", \"wordsCount\": 0, \"line\": \" xyz \" } ]}" | tail -n 19 | gsed -E 's/(")(id|projectId|projectScore|projectCoverage|projectTextAccuracy|projectReadability|projectLayout|subtitleScore|subtitleTextAccuracy|subtitleReadability|subtitleLayout)(":).*(,)/\1\2\3\4/'  >${DIR}/PUT-subtitle-test.json
curl -s -X PUT "http://localhost:8984/v1/projects/e6860762-a8c4-40e5-bb40-e1fbf563b4f5/subtitles/923e260a-4f58-4f12-b96b-6bdd6f24122c" -H "accept: application/json" -H "Content-Type: application/json" -d "{ \"id\": \"f3be5009-9db0-4486-91ce-d77074fb250b\", \"subtitleTextAccuracy\": 13.01, \"subtitleReadability\": 80.123221, \"subtitleLayout\": 17.7102, \"start\": 842.68, \"end\": 843.01, \"markedAsCorrect\": true, \"style\": { \"fontFamily\": \"Arial Narrow\", \"fontSize\": \"12px\", \"region\": \"bottom\" }, \"lines\": [ { \"id\": \"14e5a3ae-6708-46cb-a190-3704e9c547ba\", \"wordsCount\": 7, \"line\": \"a b\" }, { \"id\": \"14e5a3ae-6708-46cb-a190-3704e9c547ba\", \"wordsCount\": 7, \"line\": \"z\" } ]}" | gsed -E 's/(")(id|projectId|projectScore|projectCoverage|projectTextAccuracy|projectReadability|projectLayout|subtitleScore|subtitleTextAccuracy|subtitleReadability|subtitleLayout)(":).*(,)/\1\2\3\4/'  >${DIR}/PUT-subtitle-test.json
diff -q ${CNT}/PUT-subtitle-test.json ${DIR}/PUT-subtitle-test.json

# Get scores
## -s = Silent cURL's output
## -L = Follow redirects
## -w = Custom output format
## -o = Redirects the HTML output to /dev/null
echo GET /projects/${UUID}/scores
curl -sL -w "%{http_code}\\n" "${HOST}/v1/projects/${UUID}/scores" -o /dev/null | grep 200

echo GET /projects/${UUID}/worstSubtitle
curl -sL -w "%{http_code}\\n" "${HOST}/v1/projects/${UUID}/worstSubtitle" -o /dev/null | grep 200

echo GET /projects/${UUID}/subtitles?time=hh:mm:ss.f
curl -sL -w "%{http_code}\\n" "${HOST}/v1/projects/${UUID}/subtitles?time=00:01:12.01"  -o /dev/null | grep 200
curl -sL -w "%{http_code}\\n" "${HOST}/v1/projects/${UUID}/subtitles?time=23:59:59.999" -o /dev/null | grep 404 
curl -sL -w "%{http_code}\\n" "${HOST}/v1/projects/${UUID}/subtitles?time=AAAAAAAAAAA"  -o /dev/null | grep 400

echo GET /projects/${UUID}/subtitles/${STID}/next
curl -sL -w "%{http_code}\\n" "${HOST}/v1/projects/${UUID}/subtitles/${STID}/next"      -o /dev/null | grep 200
echo GET /projects/${UUID}/subtitles/${STID}/previous
curl -sL -w "%{http_code}\\n" "${HOST}/v1/projects/${UUID}/subtitles/${STID}/previous"  -o /dev/null | grep 200

echo TESTS SUCCESSFUL
