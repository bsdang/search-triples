xquery version "1.0-ml";

module namespace constraint = "http://ea.com/content/models/search-constraints";

import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare function constraint:triple-range-query (
  $query as element(),
  $options as element(search:options)
) as schema-element(cts:query)
{
    let $final-query :=
    <root>{
      let $triple-query := $query/search:text/node()
      let $_log := xdmp:log(fn:string-join(("constraint:triple-range-query ** search text ", xdmp:quote($triple-query)), " ") ,"debug")
      return 
        cts:triple-range-query(
          if($triple-query/constraint:triple-subject/text()) then sem:iri($triple-query/constraint:triple-subject) else (), 
          if($triple-query/constraint:triple-predicate) then sem:iri($triple-query/constraint:triple-predicate) else (), 
          if($triple-query/constraint:triple-object/text()) then sem:typed-literal($triple-query/constraint:triple-object,$triple-query/constraint:triple-object/@datatype) else (), 
          if($triple-query/constraint:triple-query-operator/text()) then $triple-query/constraint:triple-query-operator/text() else ()
          )
        }
    </root>/*
    let $_log := xdmp:log(fn:string-join((" constraint:triple-range-query ** query is ", xdmp:quote($final-query)), " ") ,"info")
    return
        (: not added qtextconst attribute as this is for structured query and we can get more than 1 search:text :)
        element { fn:node-name($final-query) }
          {
            $final-query/@*,
            $final-query/node()
         }
} ;
