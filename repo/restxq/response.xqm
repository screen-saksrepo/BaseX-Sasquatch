module namespace response = 'restxq/response';

declare variable $response:json-200-txt := response:json-text(200, ?);
declare variable $response:json-200-obj := response:json-object(200, ?);

declare function response:json-text($code as xs:integer, $text as xs:string)
{
  <rest:response>
    <output:serialization-parameters>
      <output:media-type value='application/json'/>
    </output:serialization-parameters>
    <http:response status="{$code}">
      <http:header name="Content-Language" value="en"/>
      <http:header name="Content-Type" value="application/json; charset=utf-8"/>
    </http:response>
  </rest:response>,
  <json type="object">
    <code type="number">{$code}</code>
    <message>{$text}</message>
  </json>
};

declare function response:json-object($code as xs:integer, $json-xml as element(json))
{
  <rest:response>
    <output:serialization-parameters>
      <output:media-type value='application/json'/>
    </output:serialization-parameters>
    <http:response status="{$code}">
      <http:header name="Content-Language" value="en"/>
      <http:header name="Content-Type" value="application/json; charset=utf-8"/>
    </http:response>
  </rest:response>,
  $json-xml
};

declare function response:text($code as xs:integer, $text as xs:string)
{
  <rest:response>
    <output:serialization-parameters>
      <output:media-type value='application/text'/>
    </output:serialization-parameters>
    <http:response status="{$code}">
      <http:header name="Content-Language" value="en"/>
      <http:header name="Content-Type" value="application/text; charset=utf-8"/>
    </http:response>
  </rest:response>,
  $text
};