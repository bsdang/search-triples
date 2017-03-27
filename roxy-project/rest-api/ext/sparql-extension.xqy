xquery version "1.0-ml";

module namespace app = "http://marklogic.com/rest-api/resource/sparql-extension";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";
import module namespace ast = "http://marklogic.com/appservices/search-ast" at "/MarkLogic/appservices/search/ast.xqy";


declare namespace roxy = "http://marklogic.com/roxy";
declare namespace rapi = "http://marklogic.com/rest-api";

declare variable $IRI-PREFIX as xs:string := "https://content.ea.com/data/";
declare variable $URI-PREFIX as xs:string := "/content/";


declare variable $app:query-only-options :=
  element search:options {
    element search:return-constraints { fn:false() },
    element search:return-facets { fn:false() },
    element search:return-metrics { fn:false() },
    element search:return-plan { fn:false() },
    element search:return-qtext { fn:false() },
    element search:return-query { fn:true() },
    element search:return-results { fn:false() },
    element search:return-similar { fn:false() },

    element search:constraint {
      attribute name { "triple-range-query" },
      element search:custom {
        attribute facet { "false" },
        element search:parse {
          attribute apply { "triple-range-query" },
          attribute ns { "http://ea.com/content/models/search-constraints" },
          attribute at { "/app/models/search-constraints.xqy" }
        }
      }
    }
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

    (: default the docs to false :)
    let $do-docs := xs:boolean(map:get($params, "docs"))

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
          (: This will seg fault if there are cts:triple-range-query XML with only the object :)
          cts:query($cts-xml)
        else
          let $query-xml := $request//search:query
          return
            (:
              This is using an internal library for now as there is a bug that causes a seg fault
              when constructing a cts:query from a cts:triple-range-query xml with only the object present.
            :)
            map:get(ast:to-query($query-xml, $query-only-options, true()), "query")

            (:
              Another work around would be to get the results from

              let $q := search:resolve($query-xml, $query-only-options)/search:query/*

              and then walk the cts XML, constructing each part individually and looking for
              triple-range query so the cts can be built piecemeal from the XML instead of using
              the cts:query() function...not ideal either
            :)

            (:
              if ($query-xml) then
                (: we have to do this to get a cts query from a structured query :)
                (: it's kind of inefficient though as it goes from XML to cts to cts XML and then back to cts :)
                (: let $_ := dbg:stop() :)
                let $q := search:resolve($query-xml, $query-only-options)/search:query/*
                return cts:query($q)
              else
                ()
            :)

    (: TODO: add support for rulesets :)

    let $bindings := app:make-sparql-bindings($params)

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

    (: Most of the SPARQL queries just return a list of subjects. We can translate each :)
    (: subject into a URI and return the doc for it too. :)
    (: subject: https://content.ea.com/data/NDSArticle/1-ndsArticle-testing-f43a49d3-8388-4a74-bb10-96d5942bae0e :)
    (: URI:     /content/1/NDSArticle/ndsArticle-testing-f43a49d3-8388-4a74-bb10-96d5942bae0e :)
    (: This is an alternating sequence of URI and document to be compatible with the existing code :)
    let $docs :=
      if ($do-docs) then
        let $uris := $results ! app:subject-to-uri(map:get(., "subject"))
        for $i in cts:search(fn:doc(), cts:document-query($uris), "unfiltered")
        return object-node {
          "uri" : xdmp:node-uri($i),
          "doc" : xdmp:from-json($i)
        }
      else
        ()

    let $response := (
      '{ ',
        '"headers" : { ',
            if ($do-count) then ('"count" : ', $count,",") else (),
          '"elapsed" : ', '"', $elapsed, '"',
        ' }, ',
        '"content" : ',
          sem:query-results-serialize($results, "json"),

        if ($do-docs) then (
          ', ',
          '"docs" : ',
            xdmp:to-json-string($docs)
        ) else (),

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

declare private function app:subject-to-uri($subject as xs:string) as xs:string {
  let $parts := fn:tokenize(fn:substring-after($subject, $IRI-PREFIX), "/")
  let $type := $parts[1]
  let $num := fn:substring-before($parts[2], "-")
  let $id := fn:substring-after($parts[2], $num || "-")
  return $URI-PREFIX || $num || "/" || $type || "/" || $id
};

declare private function app:sparql-value-of(
    $string-values as xs:string*,
    $xsd-type-or-lang as xs:string?,
    $is-lang as xs:boolean
) as item()*
{
    if (empty($xsd-type-or-lang))
    then $string-values ! sem:iri(.)
    else
        switch ($xsd-type-or-lang)
        case "string" return $string-values !  xs:string(.)
        case "boolean" return $string-values !  xs:boolean(.)
        case "decimal" return $string-values !  xs:decimal(.)
        case "integer" return $string-values !  xs:integer(.)
        case "double" return $string-values !  xs:double(.)
        case "float" return $string-values !  xs:float(.)
        case "time" return $string-values !  xs:time(.)
        case "date" return $string-values !  xs:date(.)
        case "dateTime" return $string-values !  xs:dateTime(.)
        case "gYear" return $string-values !  xs:gYear(.)
        case "gMonth" return $string-values !  xs:gMonth(.)
        case "gDay" return $string-values !  xs:gDay(.)
        case "gYearMonth" return $string-values !  xs:gYearMonth(.)
        case "gMonthDay" return $string-values !  xs:gMonthDay(.)
        case "duration" return $string-values !  xs:duration(.)
        case "yearMonthDuration" return $string-values !  xs:yearMonthDuration(.)
        case "dayTimeDuration" return $string-values !  xs:dayTimeDuration(.)
        case "byte" return $string-values !  xs:byte(.)
        case "short" return $string-values !  xs:short(.)
        case "int" return $string-values !  xs:int(.)
        case "long" return $string-values !  xs:long(.)
        case "unsignedByte" return $string-values !  xs:unsignedByte(.)
        case "unsignedShort" return $string-values !  xs:unsignedShort(.)
        case "unsignedInt" return $string-values !  xs:unsignedInt(.)
        case "unsignedLong" return $string-values !  xs:unsignedLong(.)
        case "positiveInteger" return $string-values !  xs:positiveInteger(.)
        case "nonNegativeInteger" return $string-values !  xs:nonNegativeInteger(.)
        case "negativeInteger" return $string-values !  xs:negativeInteger(.)
        case "nonPositiveInteger" return $string-values !  xs:nonPositiveInteger(.)
        case "hexBinary" return $string-values !  xs:hexBinary(.)
        case "base64Binary" return $string-values !  xs:base64Binary(.)
        case "anyURI" return $string-values !  xs:anyURI(.)
        case "language" return $string-values !  xs:language(.)
        case "normalizedString" return $string-values !  xs:normalizedString(.)
        case "token" return $string-values !  xs:token(.)
        case "NMTOKEN" return $string-values !  xs:NMTOKEN(.)
        case "Name" return $string-values !  xs:Name(.)
        case "NCName" return $string-values !  xs:NCName(.)
        default return
            if ($is-lang)
            then
                $string-values ! rdf:langString(., $xsd-type-or-lang)
            else error( (), "REST-INVALIDPARAM", "Bind variable type parameter requires XSD type")
};

declare function app:make-sparql-bindings(
    $endpoint-params as map:map
) as map:map
{
    let $sparql-bindings := map:map()
    return (
        for $key in map:keys($endpoint-params)
        return
            if (not(starts-with($key,"bind:"))) then ()
            else
                let $split-string := tokenize($key, "[:@]")
                let $name := subsequence($split-string,2,1)
                let $type := subsequence($split-string,3,1)
                let $_ :=
                    if (exists(subsequence($split-string,4)))
                    then error( (), "REST-INVALIDPARAM", "Could not parse bind parameter " || $key)
                    else ()
                return
                    map:put(
                        $sparql-bindings,
                        $name,
                        app:sparql-value-of(
                            map:get($endpoint-params,$key),
                            $type,
                            contains($key, "@"))),
        $sparql-bindings
    )
};
