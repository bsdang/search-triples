package com.marklogic.sparql;

import java.net.URI;

import org.junit.AfterClass;
import org.junit.BeforeClass;
import org.junit.Test;

import com.marklogic.client.DatabaseClient;
import com.marklogic.client.DatabaseClientFactory;
import com.marklogic.client.DatabaseClientFactory.Authentication;
import com.marklogic.client.eval.EvalResultIterator;
import com.marklogic.client.eval.ServerEvaluationCall;
import com.marklogic.xcc.ContentSource;
import com.marklogic.xcc.ContentSourceFactory;
import com.marklogic.xcc.ModuleInvoke;
import com.marklogic.xcc.ResultSequence;
import com.marklogic.xcc.Session;

public class DocFetchTest {
    public static final String OPTIONS_NAME = "api";
    public static final String TEST_DIR = "/test/";
    
    @BeforeClass
    public static void setUpBeforeClass() throws Exception {
    }

    @AfterClass
    public static void tearDownAfterClass() throws Exception {
    }
    
    @Test
    public void testXccDocFetch() throws Exception {
        URI serverUri = new URI("xcc://admin:admin-jkerr@ec2-52-42-217-69.us-west-2.compute.amazonaws.com:8041");
        ContentSource cs = ContentSourceFactory.newContentSource(serverUri);
        Session session = cs.newSession();
        
        String uris = "/content/gin/Person/lewis-johnston.json,/content/gin/Publisher/ea.json,/content/gin/Publisher/ea/auxiliary.json,/content/gin/VideoGame/fifa-16.json,/content/gin/VideoGame/fifa-16/auxiliary.json,/content/gin/Topic/topic-3.json";
        ModuleInvoke module = session.newModuleInvoke("/app/docs.xqy");
        module.setNewStringVariable("uris-string", uris);
        
        ResultSequence response1 = session.submitRequest(module);
        
        long t1 = System.currentTimeMillis();
        ResultSequence response2 = session.submitRequest(module);
        long t2 = System.currentTimeMillis();
        System.out.println("size: " + response2.asString().length());
        System.out.println("elapsed: " + (t2 - t1));
    }

    @Test
    public void testRestDocFetch() throws Exception {
    	DatabaseClient client = DatabaseClientFactory.newClient("ec2-52-42-217-69.us-west-2.compute.amazonaws.com", 8000, "content-service-live-content", "admin", "admin-jkerr", Authentication.DIGEST);
        
        String uris = "/content/gin/Person/lewis-johnston.json,/content/gin/Publisher/ea.json,/content/gin/Publisher/ea/auxiliary.json,/content/gin/VideoGame/fifa-16.json,/content/gin/VideoGame/fifa-16/auxiliary.json,/content/gin/Topic/topic-3.json";
    	ServerEvaluationCall eval = client.newServerEval().modulePath("/app/docs.xqy").addVariable("uris-string", uris);
        
        eval.eval();
        
        long t1 = System.currentTimeMillis();
        EvalResultIterator response2 = eval.eval();
        long t2 = System.currentTimeMillis();
        System.out.println("rest size: " + response2.next().getString().length());
        System.out.println("rest elapsed: " + (t2 - t1));
    }
    
}
