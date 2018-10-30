module namespace v = 'data/validate';

import module namespace e = 'restxq/error';

(:~
 : Validates json-subtitle-object or throws an error.
 :
 : @param json-subtitle-object JSON document
 : @return empty-sequence if validates.
 : @error CONFLICT
 :)
declare function v:validate-json-subtitle-object(
    $json as document-node()
  ) as empty-sequence()
{
  (: TODO: Validate input :)
  if(true())
  then (: Input is valid, return empty-sequence :) ()
  else error($e:CONFLICT, "Input invalid: json-subtitle-object does not validate.")
};