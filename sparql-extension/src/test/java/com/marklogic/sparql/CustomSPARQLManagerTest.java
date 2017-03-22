package com.marklogic.sparql;

import static org.junit.Assert.*;

import org.junit.AfterClass;
import org.junit.BeforeClass;
import org.junit.Test;

import com.fasterxml.jackson.databind.JsonNode;
import com.marklogic.client.DatabaseClient;
import com.marklogic.client.DatabaseClientFactory;
import com.marklogic.client.DatabaseClientFactory.Authentication;
import com.marklogic.client.document.JSONDocumentManager;
import com.marklogic.client.io.InputStreamHandle;
import com.marklogic.client.io.JacksonHandle;
import com.marklogic.client.query.StructuredQueryBuilder;
import com.marklogic.client.query.StructuredQueryDefinition;
import com.marklogic.client.semantics.SPARQLBindings;
import com.marklogic.client.semantics.SPARQLQueryDefinition;
import com.marklogic.client.semantics.SPARQLQueryManager;
import com.marklogic.sparql.CustomSPARQLManager;

public class CustomSPARQLManagerTest {
    public static final String OPTIONS_NAME = "api";
    public static final String TEST_DIR = "/test/";

    private static DatabaseClient getClient() {
        return DatabaseClientFactory.newClient("localhost", 8042, "admin", "admin-jkerr", Authentication.DIGEST);
    }

    @BeforeClass
    public static void setUpBeforeClass() throws Exception {
        DatabaseClient client = getClient();
        
        client.newServerEval().xquery("xdmp:directory-delete('" + TEST_DIR + "')").eval();

        JSONDocumentManager dm = client.newJSONDocumentManager();        
        dm.write(
                TEST_DIR + "test1.json", 
                new InputStreamHandle(CustomSPARQLManagerTest.class.getResourceAsStream("/triples_doc1.json"))
        );
        dm.write(
                TEST_DIR + "test2.json", 
                new InputStreamHandle(CustomSPARQLManagerTest.class.getResourceAsStream("/triples_doc2.json"))
        );
    }

    @AfterClass
    public static void tearDownAfterClass() throws Exception {
    }
    
    @Test
    public void testCount() {
        DatabaseClient client = getClient();
        
        SPARQLQueryManager sparqlManager = client.newSPARQLQueryManager();
        CustomSPARQLManager customSparql = new CustomSPARQLManager(client);
        
        SPARQLQueryDefinition sparqlDef = sparqlManager.newQueryDefinition();
        String sparql = "SELECT * WHERE { </test1> ?p ?o. }";
        sparqlDef.setSparql(sparql);
        sparqlDef.setOptimizeLevel(0);
        
        SPARQLBindings bindings = sparqlDef.getBindings();
        bindings.bind("a", "x");
        
        StructuredQueryBuilder qb = new StructuredQueryBuilder(OPTIONS_NAME);
        StructuredQueryDefinition queryDef = qb.containerQuery(qb.jsonProperty("name"), qb.term("test name"));
        sparqlDef.setConstrainingQueryDefinition(queryDef);
                
        long start = 1;
        long pageLength = 10;
        JacksonHandle result = customSparql.executeSelect(sparqlDef, new JacksonHandle(), start, pageLength, true);
        //System.out.println(result);
        
        JsonNode resultNode = result.get();
        assertEquals(2, resultNode.get("headers").get("count").asLong()); 
        
        JsonNode triples = resultNode.get("content").get("results");
        assertNotNull(triples);
        
        // make sure we got the right triples
        // they should all have the "/pred1" predicate
        for (JsonNode n : triples.get("bindings")) {
            assertEquals("/pred1", n.get("p").get("value").asText());
        }
    }
    
    @Test
    public void testNoMatch() {
        DatabaseClient client = getClient();
        
        SPARQLQueryManager sparqlManager = client.newSPARQLQueryManager();
        CustomSPARQLManager customSparql = new CustomSPARQLManager(client);
        
        SPARQLQueryDefinition sparqlDef = sparqlManager.newQueryDefinition();
        String sparql = "SELECT * WHERE { </test1> ?p ?o. }";
        sparqlDef.setSparql(sparql);
        sparqlDef.setOptimizeLevel(0);
        
        StructuredQueryBuilder qb = new StructuredQueryBuilder(OPTIONS_NAME);
        StructuredQueryDefinition queryDef = qb.containerQuery(qb.jsonProperty("name"), qb.term("test name2"));
        sparqlDef.setConstrainingQueryDefinition(queryDef);
                
        long start = 1;
        long pageLength = 10;
        JacksonHandle result = customSparql.executeSelect(sparqlDef, new JacksonHandle(), start, pageLength, true);
        
        JsonNode resultNode = result.get();
        assertEquals(0, resultNode.get("headers").get("count").asLong());        
    }

    @Test
    public void testTripleRangeConstraint() {
        DatabaseClient client = getClient();
        
        SPARQLQueryManager sparqlManager = client.newSPARQLQueryManager();
        CustomSPARQLManager customSparql = new CustomSPARQLManager(client);
        
        SPARQLQueryDefinition sparqlDef = sparqlManager.newQueryDefinition();
        String sparql = "SELECT * WHERE { ?s ?p ?o. }";
        sparqlDef.setSparql(sparql);
        sparqlDef.setOptimizeLevel(0);
        
        String subject = null;
        String predicate = null;
        String object = "name1";
        String objectDataType = "http://www.w3.org/2001/XMLSchema#string";
        String operator = "=";
        StructuredQueryBuilder qb = new StructuredQueryBuilder(OPTIONS_NAME);
        StructuredQueryDefinition queryDef =
        		qb.customConstraint(
        				"triple-range-query", 
        				getTripleRangeConstraint(subject, predicate, object, objectDataType, operator)
        		);
        sparqlDef.setConstrainingQueryDefinition(queryDef);
                
        long start = 1;
        long pageLength = 10;
        JacksonHandle result = customSparql.executeSelect(sparqlDef, new JacksonHandle(), start, pageLength, true);
        //System.out.println(result);
        
        JsonNode resultNode = result.get();
        assertEquals(2, resultNode.get("headers").get("count").asLong());        
    }

    // leave the objectDataType as null to match an iri 
	private String getTripleRangeConstraint(String subject, String predicate, String object, String objectDataType, String operator) {
		StringBuffer constraint = 
				new StringBuffer("<triple-range-query xmlns=\"http://ea.com/content/models/search-constraints\">");
		
        if (subject != null) { 
        	constraint.append("<triple-subject>").append(subject).append("</triple-subject>");
        }
        if (predicate != null) { 
        	constraint.append("<triple-predicate>").append(predicate).append("</triple-predicate>");
        }
        if (object != null) { 
        	constraint.append("<triple-object");
        		if (objectDataType != null) {
        			constraint.append(" datatype=\"").append(objectDataType).append("\">");
        		} else {
        			constraint.append(">");
        		}
        		constraint.append(object).
        	append("</triple-object>");
        }
        if (operator != null) { 
        	constraint.append("<triple-query-operator>").append(operator).append("</triple-query-operator>");
        }        
        constraint.append("</triple-range-query>");  

		return constraint.toString();
	}

}
