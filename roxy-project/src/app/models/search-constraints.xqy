xquery version "1.0-ml";

module namespace constraint = "http://ea.com/content/models/search-constraints";

import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare function constraint:triple-range-query (
  $query as element(),
  $options as element(search:options)
) as cts:query
{
  let $_log := xdmp:log(fn:string-join(("constraint:triple-range-query ** search ", xdmp:quote($query)), " ") ,"debug")

  let $triple-query := $query/search:text/node()

  (: the text element should actually be just text so if we want to handle XML, we need to parse it :)
  let $triple-query :=
    if ($triple-query instance of text()) then
      xdmp:unquote($triple-query)/constraint:triple-range-query
    else
      $triple-query

  (: We want this to return the actual cts object instead of the XML as the ast library will just pass it through :)
  (: This is required because there is a bug that causes a seg fault when constructing a cts:query with XML :)
  (: from a cts:triple-range-query with only the object present. :)
  return
    cts:triple-range-query(
      if($triple-query/constraint:triple-subject/text()) then sem:iri($triple-query/constraint:triple-subject) else (),
      if($triple-query/constraint:triple-predicate/text()) then sem:iri($triple-query/constraint:triple-predicate) else (),
      if($triple-query/constraint:triple-object/@datatype) then
        sem:typed-literal($triple-query/constraint:triple-object,$triple-query/constraint:triple-object/@datatype)
      else if($triple-query/constraint:triple-object/text()) then
        sem:iri($triple-query/constraint:triple-object)
      else
        (),
      if($triple-query/constraint:triple-query-operator/text()) then $triple-query/constraint:triple-query-operator/text() else ()
    )
} ;
