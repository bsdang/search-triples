xquery version "1.0-ml";

(: This is invoked by the CS API to retrieve batcheds of documents. :)
(: Returns an alternating sequence of URI and document. :)

declare variable $uris-string as xs:string external;
declare variable $uris := fn:tokenize($uris-string, ",");

let $search := cts:search(fn:doc(), cts:document-query($uris), ("unfiltered"))
for $s in $search
return (xdmp:node-uri($s), $s)
