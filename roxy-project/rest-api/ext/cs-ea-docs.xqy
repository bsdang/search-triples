xquery version "1.0-ml";

module namespace app = "http://marklogic.com/rest-api/resource/cs-ea-docs";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";
declare namespace roxy = "http://marklogic.com/roxy";
declare namespace rapi = "http://marklogic.com/rest-api";

declare variable $app:query-only-options :=
  element search:options {
    element search:return-constraints { fn:false() },
    element search:return-facets { fn:false() },
    element search:return-metrics { fn:false() },
    element search:return-plan { fn:false() },
    element search:return-qtext { fn:false() },
    element search:return-query { fn:true() },
    element search:return-results { fn:false() },
    element search:return-similar { fn:false() }
  }
;


declare
%roxy:params("start=xs:integer", "pageLength=xs:integer", "optimize=xs:integer", "count=xs:string", "default-graph-uri=xs:string", "named-graph-uri=xs:string", "base=xs:string")
%rapi:transaction-mode("update")
function app:post(
    $context as map:map,
    $params  as map:map,
    $input as document-node()? (:document-node(element(search:search)) :)
) as document-node()*
{
    let $_ := (xdmp:log($params, "debug"), xdmp:log($context, "debug"))
    let $begin := xdmp:elapsed-time()
    let $accept := map:get($context, "accept-types")

    let $startParam := map:get($params, "start")
    let $start := if (fn:exists($startParam)) then xs:long($startParam) else 1
    let $start := if ($start gt 0) then $start else 1

    let $page-length := map:get($params, "pageLength")
    let $page-length := if (fn:empty($page-length)) then () else xs:long($page-length)

    (: default the count to false :)
    let $do-count := xs:boolean(map:get($params, "count"))
    let $sparql-options := (
      map:get($params,"default-graph-uri") ! ("default-graph=" || .),
      map:get($params,"named-graph-uri") ! ("named-graph=" || .),
      map:get($params,"optimize") ! ("optimize=" || .),
      map:get($params,"base") ! ("base=" || .)
    )
    let $request := $input
    let $sparql := $request//search:sparql
    let $sparql-type := $sparql/@type/fn:normalize-space()
    let $cts-xml := $request//cts:query/*
    let $cts-query :=
        if ($cts-xml) then
            cts:query($cts-xml)
        else
            let $query-xml := $request//search:query
            return
                if ($query-xml) then
                  (: we have to do this to get a cts query from a structured query :)
                  search:resolve($query-xml, $query-only-options)/search:query/* ! cts:query(.)
                else
                  ()

    let $_ := xdmp:log("constraining query: " || $cts-query, "debug")

    let $bindings := map:new(
        for $b in $sparql/search:bindings/search:binding
        return
            map:entry(
                $b/search:name/fn:normalize-space(),
                if ($b/search:language) then
                    rdf:langString($b/search:language/fn:normalize-space(), $b/search:language/@xml:lang/fn:normalize-space())
                else if ($b/search:datatype) then
                    sem:typed-literal($b/search:datatype/fn:normalize-space(), sem:iri($b/search:datatype/@iri/fn:normalize-space()))
                else
                    sem:iri($b/search:iri/fn:normalize-space())
            )
    )
    let $sem-store := sem:store((), $cts-query)
    let $results := sem:sparql(fn:string($sparql), $bindings, $sparql-options, $sem-store)
    let $sparql-response-mime :=
        if (fn:matches($sparql-type, "SELECT", "i")) then
            "application/sparql-results+json"
        else
            "application/json"
    (: the results could be a sequence of maps, triples or a single boolean depending on the SPARQL :)
    (: Assume SELECT for now :)
    let $count :=
        if ($do-count eq fn:true()) then
            fn:count($results)
        else
            ()
    let $results :=
        if (fn:empty($page-length)) then
            fn:subsequence($results, $start)
        else
            fn:subsequence($results, $start, $page-length)
    let $elapsed := xdmp:elapsed-time() - $begin

    (: I'm thinking that it is probably best, at least for SPARQL responses, to leave the response format unchanged :)
    (: Maybe return any custom values like "count" that we need in private response headers if that will work. :)
    (: This perhaps reduces any chance of upstream parsing issues for Jena. :)

    (: The header idea is a good one but it is very hard (as far as I can tell) to get to the HTTP :)
    (: response headers in the Java Client API. :)
    (: Therefore, it seems easier to just wrap the response. The current client is consuming the response :)
    (: as a JacksonHandle anyway so that is easiest. :)

    (: Using this method to construct the reponse so we can take advantage of the sem:query-results-serialize :)
    (: function without having to serialize, parse and serialize again. I know, string concats are ugly! :)
    (:

    It's not clear if it's faster to concat the string or return a sequence in the document node

    let $response :=
      '{ ' ||
        '"headers" : { ' ||
            (if ($do-count) then '"count" : ' || $count || "," else ()) ||
          '"elapsed" : ' || '"' || $elapsed || '"' ||
        ' }, ' ||
        '"content" : ' ||
          sem:query-results-serialize($results, "json") ||
      ' }'
    :)

    let $response := (
      '{ ',
        '"headers" : { ',
            if ($do-count) then ('"count" : ', $count,",") else (),
          '"elapsed" : ', '"', $elapsed, '"',
        ' }, ',
        '"content" : ',
          sem:query-results-serialize($results, "json"),
      ' }'
    )

    return (
        map:put($context, "output-types", $sparql-response-mime),
        map:put($context, "output-status", (200, "OK")),
        (: map:put($context, "output-headers", map:new((map:entry("X-Count", $count), map:entry("X-Elapsed", $elapsed)))), :)
        xdmp:log("SPARQL executed in: " || $elapsed, "debug"),
        document { $response }
    )
};
