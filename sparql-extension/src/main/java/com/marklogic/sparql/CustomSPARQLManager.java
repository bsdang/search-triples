package com.marklogic.sparql;

import com.marklogic.client.DatabaseClient;
import com.marklogic.client.extensions.ResourceManager;
import com.marklogic.client.extensions.ResourceServices;
import com.marklogic.client.impl.CombinedQueryBuilderImpl;
import com.marklogic.client.impl.CombinedQueryDefinition;
import com.marklogic.client.io.Format;
import com.marklogic.client.io.StringHandle;
import com.marklogic.client.io.marker.AbstractWriteHandle;
import com.marklogic.client.io.marker.SPARQLResultsReadHandle;
import com.marklogic.client.io.marker.StructureWriteHandle;
import com.marklogic.client.query.QueryDefinition;
import com.marklogic.client.query.RawCombinedQueryDefinition;
import com.marklogic.client.query.RawStructuredQueryDefinition;
import com.marklogic.client.query.StringQueryDefinition;
import com.marklogic.client.query.StructuredQueryBuilder;
import com.marklogic.client.query.StructuredQueryDefinition;
import com.marklogic.client.semantics.Capability;
import com.marklogic.client.semantics.GraphPermissions;
import com.marklogic.client.semantics.SPARQLBinding;
import com.marklogic.client.semantics.SPARQLBindings;
import com.marklogic.client.semantics.SPARQLQueryDefinition;
import com.marklogic.client.semantics.SPARQLRuleset;
import com.marklogic.client.util.RequestParameters;

public class CustomSPARQLManager extends ResourceManager {

    static final public String NAME = "cs-ea-docs";

    public CustomSPARQLManager(DatabaseClient client) {
        super();

        // Initialize the Resource Manager via the Database Client
        client.init(NAME, this);
    }

    // TODO: there are other argument variations that this should handle too
    // (transactions, etc.)

    public <T extends SPARQLResultsReadHandle> T executeSelect(SPARQLQueryDefinition qdef, T handle, long start,
            long pageLength, boolean countTotal) {
        if (qdef == null)
            throw new IllegalArgumentException("qdef cannot be null");
        if (handle == null)
            throw new IllegalArgumentException("handle cannot be null");

        // get the initialized service object from the base class
        ResourceServices services = getServices();
        RequestParameters params = getParams(qdef, start, pageLength, countTotal);
        AbstractWriteHandle input = getWriteHandle(qdef, params, false);
        
        // input is a fully-formed XML request so it could be passed via an invoke instead to see if that's faster

        return services.post(params, input, handle);
    }

    private RequestParameters getParams(SPARQLQueryDefinition qdef, long start, long pageLength, boolean countTotal) {
        RequestParameters params = new RequestParameters();
        if (start > 1)
            params.add("start", Long.toString(start));
        if (pageLength >= 0)
            params.add("pageLength", Long.toString(pageLength));

        params.add("count", Boolean.toString(countTotal));
        
        if (qdef.getOptimizeLevel() >= 0) {
            params.add("optimize", Integer.toString(qdef.getOptimizeLevel()));
        }
        if (qdef.getCollections() != null) {
            for (String collection : qdef.getCollections()) {
                params.add("collection", collection);
            }
        }
        addPermsParams(params, qdef.getUpdatePermissions());

        SPARQLBindings bindings = qdef.getBindings();
        for (String bindingName : bindings.keySet()) {
            String paramName = "bind:" + bindingName;
            String typeOrLang = "";
            for (SPARQLBinding binding : bindings.get(bindingName)) {
                if (binding.getDatatype() != null) {
                    typeOrLang = ":" + binding.getDatatype();
                } else if (binding.getLanguageTag() != null) {
                    typeOrLang = "@" + binding.getLanguageTag().toLanguageTag();
                }
                params.add(paramName + typeOrLang, binding.getValue());
            }
        }

        if (qdef.getBaseUri() != null) {
            params.add("base", qdef.getBaseUri());
        }
        if (qdef.getDefaultGraphUris() != null) {
            for (String defaultGraphUri : qdef.getDefaultGraphUris()) {
                params.add("default-graph-uri", defaultGraphUri);
            }
        }
        if (qdef.getNamedGraphUris() != null) {
            for (String namedGraphUri : qdef.getNamedGraphUris()) {
                params.add("named-graph-uri", namedGraphUri);
            }
        }
        if (qdef.getUsingGraphUris() != null) {
            for (String usingGraphUri : qdef.getUsingGraphUris()) {
                params.add("using-graph-uri", usingGraphUri);
            }
        }
        if (qdef.getUsingNamedGraphUris() != null) {
            for (String usingNamedGraphUri : qdef.getUsingNamedGraphUris()) {
                params.add("using-named-graph-uri", usingNamedGraphUri);
            }
        }

        // rulesets
        if (qdef.getRulesets() != null) {
            for (SPARQLRuleset ruleset : qdef.getRulesets()) {
                params.add("ruleset", ruleset.getName());
            }
        }
        if (qdef.getIncludeDefaultRulesets() != null) {
            params.add("default-rulesets", qdef.getIncludeDefaultRulesets() ? "include" : "exclude");
        }

        return params;
    }

    private void addPermsParams(RequestParameters params, GraphPermissions permissions) {
        if (permissions != null) {
            for (String role : permissions.keySet()) {
                if (permissions.get(role) != null) {
                    for (Capability capability : permissions.get(role)) {
                        params.add("perm:" + role, capability.toString().toLowerCase());
                    }
                }
            }
        }
    }

    private AbstractWriteHandle getWriteHandle(SPARQLQueryDefinition qdef, RequestParameters params, boolean isUpdate) {
        String sparql = qdef.getSparql();
        QueryDefinition constrainingQuery = qdef.getConstrainingQueryDefinition();
        
        // default to create an empty query for now as the service only supports the XML request
        if (constrainingQuery == null) {
            constrainingQuery = new StructuredQueryBuilder().and();
        }
        
        StructureWriteHandle input;
        if (constrainingQuery != null) {
            if (qdef.getOptionsName() != null && qdef.getOptionsName().length() > 0) {
                params.add("options", qdef.getOptionsName());
            }
            if (constrainingQuery instanceof RawCombinedQueryDefinition) {
                CombinedQueryDefinition combinedQdef = new CombinedQueryBuilderImpl()
                        .combine((RawCombinedQueryDefinition) constrainingQuery, null, null, sparql);
                Format format = combinedQdef.getFormat();
                input = new StringHandle(combinedQdef.serialize()).withFormat(format);
            } else if (constrainingQuery instanceof RawStructuredQueryDefinition) {
                CombinedQueryDefinition combinedQdef = new CombinedQueryBuilderImpl()
                        .combine((RawStructuredQueryDefinition) constrainingQuery, null, null, sparql);
                Format format = combinedQdef.getFormat();
                input = new StringHandle(combinedQdef.serialize()).withFormat(format);
            } else if (constrainingQuery instanceof StringQueryDefinition
                    || constrainingQuery instanceof StructuredQueryDefinition) {
                String stringQuery = constrainingQuery instanceof StringQueryDefinition
                        ? ((StringQueryDefinition) constrainingQuery).getCriteria() : null;
                StructuredQueryDefinition structuredQuery = constrainingQuery instanceof StructuredQueryDefinition
                        ? (StructuredQueryDefinition) constrainingQuery : null;
                CombinedQueryDefinition combinedQdef = new CombinedQueryBuilderImpl().combine(structuredQuery, null,
                        stringQuery, sparql);
                input = new StringHandle(combinedQdef.serialize()).withMimetype("application/xml");
            } else {
                throw new IllegalArgumentException(
                        "Constraining query must be of type SPARQLConstrainingQueryDefinition");
            }
        } else {
            String mimetype = isUpdate ? "application/sparql-update" : "application/sparql-query";
            input = new StringHandle(sparql).withMimetype(mimetype);
        }
        return input;
    }
}
