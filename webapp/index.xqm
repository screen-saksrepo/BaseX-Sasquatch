module namespace u = 'index.xqm';

(: ~~~ REST API / ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ :)

(:~
 : Delivers API specification and (manual) test facility.
 :)
declare
  %rest:path("/")
function u:index()
{
  <rest:forward>static/swagger-ui/index.html</rest:forward>
};

(:~
 : Responds 'alive' to monitors.
 :)
declare
  %rest:path("/ping")
  %rest:GET
function u:ping()
{
  ()
};

(: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ :)