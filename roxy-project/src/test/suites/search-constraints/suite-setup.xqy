xquery version "1.0-ml";

import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";
      
xdmp:document-insert(
    "/test/search-constraints/triples.xml",
    <sem:triples>
        <sem:triple>
        <sem:subject>http://www.w3.org/ns/prov#influencer</sem:subject>
        <sem:predicate>http://www.w3.org/ns/prov#editorsDefinition</sem:predicate>
        <sem:object xml:lang="en">This property is used as part of the qualified influence pattern. Subclasses of prov:Influence use these subproperties to reference the resource (Entity, Agent, or Activity) whose influence is being qualified.</sem:object>
        </sem:triple>
        <sem:triple>
        <sem:subject>http://www.w3.org/ns/prov#invalidated</sem:subject>
        <sem:predicate>http://www.w3.org/2000/01/rdf-schema#isDefinedBy</sem:predicate>
        <sem:object>http://www.w3.org/ns/prov-o#</sem:object>
        </sem:triple>
        <sem:triple>
        <sem:subject>http://www.w3.org/ns/prov#invalidated</sem:subject>
        <sem:predicate>http://www.w3.org/2000/01/rdf-schema#label</sem:predicate>
        <sem:object datatype="http://www.w3.org/2001/XMLSchema#string">invalidated</sem:object>
        </sem:triple>
        <sem:triple>
        <sem:subject>http://marklogic.com/semantics/blank/18234284292844143335</sem:subject>
        <sem:predicate>http://www.w3.org/2002/07/owl#qualifiedCardinality</sem:predicate>
        <sem:object datatype="http://www.w3.org/2001/XMLSchema#nonNegativeInteger">1</sem:object>
        </sem:triple>
        <sem:triple>
        <sem:subject>https://data.ea.com/graph/thing/f582a95e-1126-4715-a455-500b8aeeadeb</sem:subject>
        <sem:predicate>https://schema.ea.com/ns/raf/checkedout</sem:predicate>
        <sem:object datatype="http://www.w3.org/2001/XMLSchema#boolean">true</sem:object>
        </sem:triple>
        <sem:triple>
        <sem:subject>https://data.ea.com/graph/thing/f582a95e-1126-4715-a455-500b8aeeadeb/1</sem:subject>
        <sem:predicate>https://schema.ea.com/ns/raf/version</sem:predicate>
        <sem:object datatype="http://www.w3.org/2001/XMLSchema#int">1</sem:object>
        </sem:triple>
        <sem:triple>
        <sem:subject>https://data.ea.com/graph/thing/f582a95e-1126-4715-a455-500b8aeeadeb/1</sem:subject>
        <sem:predicate>https://schema.ea.com/ns/raf/long</sem:predicate>
        <sem:object datatype="http://www.w3.org/2001/XMLSchema#long">1480675862373</sem:object>
        </sem:triple>
        <sem:triple>
        <sem:subject>https://data.ea.com/graph/thing/f582a95e-1126-4715-a455-500b8aeeadeb/1</sem:subject>
        <sem:predicate>https://schema.ea.com/ns/raf/datetime</sem:predicate>
        <sem:object datatype="http://www.w3.org/2001/XMLSchema#dateTime">2002-05-30T09:00:00</sem:object>
        </sem:triple>
        <sem:triple>
        <sem:subject>https://data.ea.com/graph/thing/dateGreater/1</sem:subject>
        <sem:predicate>https://schema.ea.com/ns/raf/datetime</sem:predicate>
        <sem:object datatype="http://www.w3.org/2001/XMLSchema#dateTime">2005-05-30T09:00:00</sem:object>
        </sem:triple>
        <sem:triple>
        <sem:subject>https://data.ea.com/graph/thing/dateLesser/1</sem:subject>
        <sem:predicate>https://schema.ea.com/ns/raf/datetime</sem:predicate>
        <sem:object datatype="http://www.w3.org/2001/XMLSchema#dateTime">2001-05-30T09:00:00</sem:object>
        </sem:triple>
    </sem:triples>
)
