/**
* @author       Michael Hayes - Media3 Technologies, LLC
* @description  Wrapper for Azure Management API calls
* @hint         Azure Management Component
* @name         Mgmt
*/
component accessors = true {
   
    
    property name="access_token"    required="true" type="string" description="The bearer token use for the api request.";
    property name="api_version"     required="true" type="string" default="2021-04-01" description="The api version to use for the request.";
    property name="api_endpoint"    required="true" type="string" default="/subscriptions" description="The endpoint to send the api requests to.";

    

    property name="env"             type="string" default="public"  description="The environment to use for the API calls. Allowed values are 'public' and 'government'.";


    property name="base_url"        type="string" default="https://management.azure.com" description="The base URL for the API calls. This will get derived automatically from the env.";
    property name="endpoint"        type="string" description="The final constructed endpoint to send the request to.";
    property name="subscriptionId"  type="string" description="The subscription ID to use for the API calls. This is optional and can be set later.";
    property name="provider"        type="string" description="The provider to use for sending api request.";
    property name="resourceType"    type="string" description="The resource type to use for the api request. If you run the setResourceType method it will automatically obtain the api-version for you with the default-version set.";
    property name="response"        type="string" description="The response from the api.";
    

    this.management_endpoints = {
        public = "https://management.azure.com",
        government = "https://management.usgovcloudapi.net"
    };
    

    /**
     * Initializes component properties.
     * @param dynamicProperties Struct containing configuration overrides.
     * @return Mgmt The initialized instance.
     */
    public Mgmt function init( struct dynamicProperties = {} ){
        try {
            

            for( var key in dynamicProperties ) {
                variables[ Trim( key ) ] = dynamicProperties[ key ];
            }


            if( !StructKeyExists( arguments.dynamicProperties, "endpoint" ) ){
                variables.endpoint = this.management_endpoints[ variables.env ] & variables.api_endpoint & "?api-version=" & variables.api_version;
            }


            local.subs = listSubscriptions();


            variables.subscriptionId = local.value[1].SubscriptionId;
            


        } catch (any e) {
            // Store error details in response and rethrow or handle as needed
            variables.response = {
                error = true,
                message = e.message,
                detail = e.detail ?: "",
                stackTrace = e.stackTrace ?: ""
            };
            // Optionally rethrow or log
            // rethrow;
        }
        // Return the initialized instance
        return this;
    };


    /**
     * Sends an HTTP request to the Azure Management API.
     * @param method The HTTP method (GET, POST, etc.). Default is "GET".
     * @param body Optional request body for POST/PUT requests.
     * @return Mgmt The current instance with updated response.
     */
    public Mgmt function send(string method="GET", any body="") {
        try {
            var m = uCase(arguments.method ?: "GET");
            var hasBody = len(arguments.body ?: "") AND listFindNoCase("POST,PUT,PATCH,DELETE", m);

            // Set up headers
            var headers = {
                "Authorization" = "Bearer " & toString(variables.access_token),
                "Accept" = "application/json"
            };
            if (hasBody) {
                headers["Content-Type"] = "application/json";
            }

            // Perform cfhttp request
            cfhttp(
                url = variables.endpoint,
                method = m,
                result = "httpResult",
                timeout = 30
            ) {
                // Add headers
                for (var h in headers) {
                    cfhttpparam(type="header", name=h, value=headers[h]);
                }
                // Add body if needed
                if (hasBody) {
                    cfhttpparam(type="body", value=arguments.body);
                }
            }

            // Parse response
            if (structKeyExists(httpResult, "fileContent") && isJSON(httpResult.fileContent)) {
                variables.response = deserializeJSON(httpResult.fileContent);
            } else {
                variables.response = {
                    error = true,
                    message = "Request failed or response was not JSON",
                    statusCode = httpResult.statusCode ?: "",
                    responseHeader = httpResult.responseHeader ?: "",
                    raw = httpResult.fileContent ?: ""
                };
            }
        } catch (any e) {
            variables.response = {
                error = true,
                message = e.message,
                detail = e.detail ?: "",
                stackTrace = e.stackTrace ?: ""
            };
        }
        return this;
    }

    /**
     * Lists all subscriptions available for the current bearer token.
     * Sets the endpoint to /subscriptions and invokes send().
     * @return Mgmt The current instance with response populated (response.value is an array of subscriptions on success).
     */
    public any function listSubscriptions(){
        try {
            // Construct endpoint for listing subscriptions; reuse configured api_version.
            // Azure common API version for subscriptions: 2020-01-01 (we'll fall back to user provided api_version if set differently)
            var subsApiVersion = len(variables.api_version) ? variables.api_version : "2020-01-01";
            variables.endpoint = this.management_endpoints[ variables.env ] & "/subscriptions?api-version=" & subsApiVersion;
            return send("GET").getResponse()
        } catch(any e){
            variables.response = {
                error = true,
                message = e.message,
                detail = e.detail ?: "",
                stackTrace = e.stackTrace ?: ""
            };
            return variables.response;
        }
    }

    /**
     * Executes an Azure Resource Graph query.
     * @param query The Kusto query to execute.
     * @param subscriptions (optional) Array of subscription IDs. Falls back to set subscriptionId if none provided.
     * @return Mgmt (response contains data or error struct)
     */
    public Mgmt function resourceGraphQuery( required string query, array subscriptions = [ GetSubscriptionid() ] ){
        try {
            var apiVersion = "2021-03-01"; // Resource Graph API version
            // Determine subscriptions list
            if( !arrayLen( arguments.subscriptions ) && len( variables.subscriptionId ?: "" ) ){
                arguments.subscriptions = [ variables.subscriptionId ];
            }
            // Endpoint for resource graph
            variables.endpoint = this.management_endpoints[ variables.env ] & "/providers/Microsoft.ResourceGraph/resources?api-version=" & apiVersion;
            // Build body
            var bodyStruct = {
                subscriptions = arguments.subscriptions,
                query = arguments.query,
                options = { resultFormat = "objectArray" }
            };
            var bodyJSON = serializeJSON( bodyStruct );
            return send( "POST", bodyJSON );
        } catch( any e ){
            variables.response = {
                error = true,
                message = e.message,
                detail = e.detail ?: "",
                stackTrace = e.stackTrace ?: ""
            };
            return this;
        }
    }

    
}