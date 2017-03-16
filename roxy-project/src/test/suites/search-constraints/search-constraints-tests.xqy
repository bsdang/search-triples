xquery version "1.0-ml";

import module namespace test="http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";
import module namespace c = "http://marklogic.com/roxy/test-config" at "/test/test-config.xqy";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

import module namespace constraint = "http://ea.com/content/models/search-constraints" at "/app/models/search-constraints.xqy";

declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace h = "xdmp:http";

declare variable $options :=
    <search:options>
    <search:constraint name="triple-range-query">    
    <search:custom facet="false">
        <search:parse apply="triple-range-query" ns="http://ea.com/content/models/search-constraints" at="/app/models/search-constraints.xqy"/>
    </search:custom>
    </search:constraint>
    </search:options>;


declare function local:test-triple-range-query()
{
    let $query := 
      <search:query>
        <search:text>
          <constraint:triple-range-query xmlns:constraint="http://ea.com/content/models/search-constraints">
            <constraint:triple-subject>http://www.w3.org/ns/prov#invalidated</constraint:triple-subject>
            <constraint:triple-predicate>http://www.w3.org/2000/01/rdf-schema#label</constraint:triple-predicate>
            <constraint:triple-object datatype="http://www.w3.org/2001/XMLSchema#string">invalidated</constraint:triple-object>
            <constraint:triple-query-operator>=</constraint:triple-query-operator>
          </constraint:triple-range-query>  
        </search:text>       
      </search:query>
    let $response :=
      search:resolve(
        constraint:triple-range-query($query,$options)
      ,$options)
   return 
     test:assert-equal(xs:integer($response/@total), 1)
};

declare function local:test-triple-range-query-subject-only()
{
    let $query := 
      <search:query>
        <search:text>
          <constraint:triple-range-query xmlns:constraint="http://ea.com/content/models/search-constraints">
            <constraint:triple-subject>http://www.w3.org/ns/prov#invalidated</constraint:triple-subject>
          </constraint:triple-range-query>  
        </search:text>       
      </search:query>
    let $response :=
      search:resolve(
        constraint:triple-range-query($query,$options)
      ,$options)
   return 
     test:assert-equal(xs:integer($response/@total), 1)
};

declare function local:test-triple-range-query-predicate-only()
{
    let $query := 
      <search:query>
        <search:text>
          <constraint:triple-range-query xmlns:constraint="http://ea.com/content/models/search-constraints">
            <constraint:triple-predicate>http://www.w3.org/2000/01/rdf-schema#label</constraint:triple-predicate>
          </constraint:triple-range-query>  
        </search:text>       
      </search:query>
    let $response :=
      search:resolve(
        constraint:triple-range-query($query,$options)
      ,$options)
   return 
     test:assert-equal(xs:integer($response/@total), 1)
};

declare function local:test-triple-range-query-object-only()
{
    let $query := 
      <search:query>
        <search:text>
          <constraint:triple-range-query xmlns:constraint="http://ea.com/content/models/search-constraints">
            <constraint:triple-object datatype="http://www.w3.org/2001/XMLSchema#string">invalidated</constraint:triple-object>
          </constraint:triple-range-query>  
        </search:text>       
      </search:query>
    let $response :=
      search:resolve(
        constraint:triple-range-query($query,$options)
      ,$options)
   return 
     test:assert-equal(xs:integer($response/@total), 1)
};

declare function local:test-triple-range-query-subj-pred()
{
    let $query := 
      <search:query>
        <search:text>
          <constraint:triple-range-query xmlns:constraint="http://ea.com/content/models/search-constraints">
            <constraint:triple-subject>http://www.w3.org/ns/prov#invalidated</constraint:triple-subject>
            <constraint:triple-predicate>http://www.w3.org/2000/01/rdf-schema#label</constraint:triple-predicate>          
          </constraint:triple-range-query>  
        </search:text>       
      </search:query>
    let $response :=
      search:resolve(
        constraint:triple-range-query($query,$options)
      ,$options)
   return 
     test:assert-equal(xs:integer($response/@total), 1)
};

declare function local:test-triple-range-query-equals()
{
    let $query := 
      <search:query>
        <search:text>
          <constraint:triple-range-query xmlns:constraint="http://ea.com/content/models/search-constraints">
            <constraint:triple-subject>http://www.w3.org/ns/prov#invalidated</constraint:triple-subject>
            <constraint:triple-predicate>http://www.w3.org/2000/01/rdf-schema#label</constraint:triple-predicate>
            <constraint:triple-object datatype="http://www.w3.org/2001/XMLSchema#string">invalidated</constraint:triple-object>
            <constraint:triple-query-operator>=</constraint:triple-query-operator>
          </constraint:triple-range-query>  
        </search:text>       
      </search:query>
    let $response :=
      search:resolve(
        constraint:triple-range-query($query,$options)
      ,$options)
   return 
     test:assert-equal(xs:integer($response/@total), 1)
};

declare function local:test-triple-range-query-all-operators()
{
    let $query := 
      <search:query>
        <search:text>
          <constraint:triple-range-query xmlns:constraint="http://ea.com/content/models/search-constraints">
            <constraint:triple-subject>http://www.w3.org/ns/prov#invalidated</constraint:triple-subject>
            <constraint:triple-predicate>http://www.w3.org/2000/01/rdf-schema#label</constraint:triple-predicate>
            <constraint:triple-object datatype="http://www.w3.org/2001/XMLSchema#string">invalidated</constraint:triple-object>
            <constraint:triple-query-operator>=</constraint:triple-query-operator>
            <constraint:triple-query-operator>=</constraint:triple-query-operator>
            <constraint:triple-query-operator>=</constraint:triple-query-operator>
          </constraint:triple-range-query>  
        </search:text>       
      </search:query>
    let $response :=
      search:resolve(
        constraint:triple-range-query($query,$options)
      ,$options)
   return 
     test:assert-equal(xs:integer($response/@total), 1)
};

declare function local:test-triple-range-query-no-op-uses-default()
{
    let $query := 
      <search:query>
        <search:text>
          <constraint:triple-range-query xmlns:constraint="http://ea.com/content/models/search-constraints">
            <constraint:triple-subject>http://www.w3.org/ns/prov#invalidated</constraint:triple-subject>
            <constraint:triple-predicate>http://www.w3.org/2000/01/rdf-schema#label</constraint:triple-predicate>
            <constraint:triple-object datatype="http://www.w3.org/2001/XMLSchema#string">invalidated</constraint:triple-object>
          </constraint:triple-range-query>  
        </search:text>       
      </search:query>
    let $response :=
      search:resolve(
        constraint:triple-range-query($query,$options)
      ,$options)
   return 
     test:assert-equal(xs:integer($response/@total), 1)
};

declare function local:test-triple-range-query-object-string()
{
    let $query := 
      <search:query>
        <search:text>
          <constraint:triple-range-query xmlns:constraint="http://ea.com/content/models/search-constraints">
            <constraint:triple-subject>http://www.w3.org/ns/prov#invalidated</constraint:triple-subject>
            <constraint:triple-predicate>http://www.w3.org/2000/01/rdf-schema#label</constraint:triple-predicate>
            <constraint:triple-object datatype="http://www.w3.org/2001/XMLSchema#string">invalidated</constraint:triple-object>
          </constraint:triple-range-query>  
        </search:text>       
      </search:query>
    let $response :=
      search:resolve(
        constraint:triple-range-query($query,$options)
      ,$options)
   return 
     test:assert-equal(xs:integer($response/@total), 1)
};

declare function local:test-triple-range-query-object-iri()
{
    let $query := 
      <search:query>
        <search:text>
          <constraint:triple-range-query xmlns:constraint="http://ea.com/content/models/search-constraints">
            <constraint:triple-subject>http://www.w3.org/ns/prov#invalidated</constraint:triple-subject>
            <constraint:triple-predicate>http://www.w3.org/2000/01/rdf-schema#isDefinedBy</constraint:triple-predicate>
            <constraint:triple-object>http://www.w3.org/ns/prov-o#</constraint:triple-object>
          </constraint:triple-range-query>  
        </search:text>       
      </search:query>
    let $response :=
      search:resolve(
        constraint:triple-range-query($query,$options)
      ,$options)
   return 
     test:assert-equal(xs:integer($response/@total), 1)
};

declare function local:test-triple-range-query-object-non-neg-int()
{
    let $query := 
      <search:query>
        <search:text>
          <constraint:triple-range-query xmlns:constraint="http://ea.com/content/models/search-constraints">
            <constraint:triple-subject>http://marklogic.com/semantics/blank/18234284292844143335</constraint:triple-subject>
            <constraint:triple-predicate>http://www.w3.org/2002/07/owl#qualifiedCardinality</constraint:triple-predicate>
            <constraint:triple-object datatype="http://www.w3.org/2001/XMLSchema#nonNegativeInteger">1</constraint:triple-object>
          </constraint:triple-range-query>  
        </search:text>       
      </search:query>
    let $response :=
      search:resolve(
        constraint:triple-range-query($query,$options)
      ,$options)
   return 
     test:assert-equal(xs:integer($response/@total), 1)
};


declare function local:test-triple-range-query-object-boolean()
{
    let $query := 
      <search:query>
        <search:text>
          <constraint:triple-range-query xmlns:constraint="http://ea.com/content/models/search-constraints">
            <constraint:triple-subject>https://data.ea.com/graph/thing/f582a95e-1126-4715-a455-500b8aeeadeb</constraint:triple-subject>
            <constraint:triple-predicate>https://schema.ea.com/ns/raf/checkedout</constraint:triple-predicate>
            <constraint:triple-object datatype="http://www.w3.org/2001/XMLSchema#boolean">true</constraint:triple-object>
          </constraint:triple-range-query>  
        </search:text>       
      </search:query>
    let $response :=
      search:resolve(
        constraint:triple-range-query($query,$options)
      ,$options)
   return 
     test:assert-equal(xs:integer($response/@total), 1)
};

declare function local:test-triple-range-query-object-datetime()
{
    let $query := 
      <search:query>
        <search:text>
          <constraint:triple-range-query xmlns:constraint="http://ea.com/content/models/search-constraints">
            <constraint:triple-subject>https://data.ea.com/graph/thing/f582a95e-1126-4715-a455-500b8aeeadeb/1</constraint:triple-subject>
            <constraint:triple-predicate>https://schema.ea.com/ns/raf/datetime</constraint:triple-predicate>
            <constraint:triple-object datatype="http://www.w3.org/2001/XMLSchema#dateTime">2002-05-30T09:00:00</constraint:triple-object>
          </constraint:triple-range-query>  
        </search:text>       
      </search:query>
    let $response :=
      search:resolve(
        constraint:triple-range-query($query,$options)
      ,$options)
   return 
     test:assert-equal(xs:integer($response/@total), 1)
};

declare function local:test-triple-range-query-object-datetime-greater()
{
    let $query := 
      <search:query>
        <search:text>
          <constraint:triple-range-query xmlns:constraint="http://ea.com/content/models/search-constraints">
            <constraint:triple-subject>https://data.ea.com/graph/thing/dateGreater/1</constraint:triple-subject>
            <constraint:triple-predicate>https://schema.ea.com/ns/raf/datetime</constraint:triple-predicate>
            <constraint:triple-object datatype="http://www.w3.org/2001/XMLSchema#dateTime">2002-05-30T09:00:00</constraint:triple-object>
            <constraint:triple-query-operator>&gt;</constraint:triple-query-operator>
          </constraint:triple-range-query>  
        </search:text>       
      </search:query>
    let $response :=
      search:resolve(
        constraint:triple-range-query($query,$options)
      ,$options)
   return 
     test:assert-equal(xs:integer($response/@total), 1)
};

declare function local:test-triple-range-query-object-datetime-lesser()
{
    let $query := 
      <search:query>
        <search:text>
          <constraint:triple-range-query xmlns:constraint="http://ea.com/content/models/search-constraints">
            <constraint:triple-subject>https://data.ea.com/graph/thing/dateLesser/1</constraint:triple-subject>
            <constraint:triple-predicate>https://schema.ea.com/ns/raf/datetime</constraint:triple-predicate>
            <constraint:triple-object datatype="http://www.w3.org/2001/XMLSchema#dateTime">2002-05-30T09:00:00</constraint:triple-object>
            <constraint:triple-query-operator>&lt;</constraint:triple-query-operator>
          </constraint:triple-range-query>  
        </search:text>       
      </search:query>
    let $response :=
      search:resolve(
        constraint:triple-range-query($query,$options)
      ,$options)
   return 
     test:assert-equal(xs:integer($response/@total), 1)
};

local:test-triple-range-query(),
local:test-triple-range-query-subject-only(),
local:test-triple-range-query-predicate-only(),
local:test-triple-range-query-subj-pred(),
local:test-triple-range-query-equals(),
local:test-triple-range-query-all-operators(),
local:test-triple-range-query-no-op-uses-default(),
local:test-triple-range-query-object-string(),
local:test-triple-range-query-object-iri(),
local:test-triple-range-query-object-boolean(),
local:test-triple-range-query-object-datetime(),
local:test-triple-range-query-object-datetime-greater(),
local:test-triple-range-query-object-datetime-lesser()


