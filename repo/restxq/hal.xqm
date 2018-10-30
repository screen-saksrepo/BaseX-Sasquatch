module namespace hal = 'restxq/hal';

import module namespace di = 'data/intermediate';

(:~
 : Creates HAL URL representation.
 :
 : @param $project id
 : @return element(__links) HAL hyperlink between resources in our API
 :)
declare function hal:hal-project(
    $project-id as xs:string,
    $scheme, 
    $hostname, 
    $port
  ) as element(__links)
{
  let $host := concat($scheme,"://",$hostname, ":",$port,"/v1")
  return element __links {
    attribute type {"object"},
    element self { 
      attribute type {"object"},
      element href { ``[`{$host}`/projects/`{ $project-id }`]`` }
      }
    (:  ,
    element webvtt {
      attribute type {"object"},
      element href { ``[`{$host}`/projects/`{ $project-id }`]`` }
    },
    element ebutt {
      attribute type {"object"},
      element href { ``[`{$host}`/projects/`{ $project-id }`]`` }
    },
    element imsc1 {
      attribute type {"object"},
      element href { ``[`{$host}`/projects/`{ $project-id }`]`` }
    }
    :)
  }
};

(:~
 : Creates HAL representation to be returned together with a single subtitle.
 :
 : @param $project id
 : @param $subtitle id
 : @return element(__links) HAL hyperlink between resources in our API
 :)
declare function hal:hal-get-subtitle(
    $project-id as xs:string,
    $subtitle-id as xs:string,
    $scheme, 
    $hostname, 
    $port
  ) as element(__links)
{
  let $host := concat($scheme,"://",$hostname, ":",$port,"/v1")
  let $first-subtitle-id := di:get-first-subtitle($project-id)/@*:id/data()
  let $last-subtitle-id := di:get-last-subtitle($project-id)/@*:id/data()
  let $previous-subtitle-id := di:get-previous-subtitle-id-by-ids($project-id, $subtitle-id, false())
  let $next-subtitle-id := di:get-next-subtitle-by-ids($project-id, $subtitle-id, false())/@*:id/data()
  let $previous-worst-subtitle-id := di:get-previous-worst-subtitle($project-id, $subtitle-id)/@*:id/data()
  let $next-worst-subtitle-id := di:get-next-worst-subtitle($project-id, $subtitle-id)/@*:id/data()
  let $worst-subtitle-id := di:get-worst-subtitle($project-id)/@*:id/data()
  return element __links {
    attribute type { "object" },
    element self { 
      attribute type { "object" },
      element href { ``[`{$host}`/projects/`{ $project-id }`]/subtitle/`{ $subtitle-id }`]`` }
    },
    element firstSubtitle {
      attribute type { "object" },
      if ($first-subtitle-id)
      then element href { ``[`{$host}`/projects/`{ $project-id }`/subtitle/`{ $first-subtitle-id }`]`` }
      else ()
    },
    element lastSubtitle {
      attribute type { "object" },
      if ($last-subtitle-id)
      then element href { ``[`{$host}`/projects/`{ $project-id }`/subtitle/`{ $last-subtitle-id }`]`` }
      else ()
    },
    element previousSubtitle {
      attribute type { "object" },
      if ($previous-subtitle-id)
      then element href { ``[`{$host}`/projects/`{ $project-id }`/subtitle/`{ $previous-subtitle-id }`]`` }
      else ()
    },
    element nextSubtitle {
      attribute type { "object" },
      if ($next-subtitle-id)
      then element href { ``[`{$host}`/projects/`{ $project-id }`/subtitle/`{ $next-subtitle-id }`]`` }
      else ()
    },
    element previousWorstSubtitle {
      attribute type { "object" },
      if ($previous-worst-subtitle-id)
      then element href { ``[`{$host}`/projects/`{ $project-id }`/subtitle/`{ $previous-worst-subtitle-id }`]`` }
      else ()
    },
    element nextWorstSubtitle {
      attribute type { "object" },
      if ($next-worst-subtitle-id)
      then element href { ``[`{$host}`/projects/`{ $project-id }`/subtitle/`{ $next-worst-subtitle-id }`]`` }
      else ()
    },
    element worstSubtitle {
      attribute type { "object" },
      if ($worst-subtitle-id)
      then element href { ``[`{$host}`/projects/`{ $project-id }`/subtitle/`{ $worst-subtitle-id }`]`` }
      else ()
    }
  }
};