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
import com.marklogic.client.eval.EvalResult;
import com.marklogic.client.eval.EvalResultIterator;
import com.marklogic.client.eval.ServerEvaluationCall;
import com.marklogic.client.io.InputStreamHandle;
import com.marklogic.client.io.JacksonHandle;
import com.marklogic.client.query.StructuredQueryBuilder;
import com.marklogic.client.query.StructuredQueryDefinition;
import com.marklogic.client.semantics.SPARQLBindings;
import com.marklogic.client.semantics.SPARQLQueryDefinition;
import com.marklogic.client.semantics.SPARQLQueryManager;
import com.marklogic.sparql.CustomSPARQLManager;

public class DocFetchModuleTest {
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
                "/content/1/DocType1/id1", 
                new InputStreamHandle(DocFetchModuleTest.class.getResourceAsStream("/content_1.json"))
        );        
        dm.write(
                "/content/1/DocType1/id2", 
                new InputStreamHandle(DocFetchModuleTest.class.getResourceAsStream("/content_2.json"))
        );        
    }

    @AfterClass
    public static void tearDownAfterClass() throws Exception {
    }
    
    @Test
    public void testGetDocs() {
        DatabaseClient client = getClient();
        String uris = "/content/1/DocType1/id1,/content/1/DocType1/id2";
    	ServerEvaluationCall eval = client.newServerEval().modulePath("/app/docs.xqy").addVariable("uris-string", uris);
        EvalResultIterator results = eval.eval();

        assertTrue(results.hasNext());
        
        EvalResult result = results.next();
        assertEquals("/content/1/DocType1/id1", result.getString());
        // should be the document
        results.next();
        
        result = results.next();
        assertEquals("/content/1/DocType1/id2", result.getString());
        // should be the document        
        results.next();
    }
}
