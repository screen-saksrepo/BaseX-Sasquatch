(:~ 
 : Creates inital databases.
 :)
let $dbs := (
    'stts' (: raw speech-to-text files. :)  
  )
for $db in $dbs
return (
  if (db:exists($db))
  then (db:output('dropped db: ' || $db || '.'), db:drop($db))
  else ()
  , (db:output('created db: ' || $db || '.'), db:create($db))
  )