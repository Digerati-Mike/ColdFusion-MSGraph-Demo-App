component {
	
	this.ApplicationManagement 	= 	true
	this.ApplicationTimeOut 	= 	CreateTimeSpan( 1, 0, 0, 0 )
	
	this.SessionManagement		= 	true
	this.SessionTimeout 		= 	CreateTimeSpan( 0, 1, 0, 0 )
	
	this.LoginStorage 			= 	"Session"
	this.clientManagement 		= 	true
	this.protectScript			=	"all"
	this.requestTimeOut			=	72000
    this.name					=	"cfoauth-demos-v1.0"


	// Custom Application Variables
	// ==========================
	this.vaultConfig = {"vaultName"	: "m369162"}
	this.vaultSecretConfigName = "app-config"


	public boolean function OnApplicationStart() {		
		// Fires when the application is first started.
		

		// Load environment variables
        // ==========================
        // NOTE: These can be loaded via a local file or service such as key vault
		// 
		// Uncomment the line below to load from a local .env file
		// Application.Env = DeserializeJSON( FileRead( expandPath('.\.env') ) );
		// Initialize Key Vault
		// Application.vault = new com.keyVault(this.vaultConfig)
		// Load secrets from Key Vault
		// variables.secretValue = Application.vault.getSecret(this.vaultSecretConfigName).value
		// Parse the JSON secret value into a struct
		// Application.Env = DeserializeJSON( variables.secretValue );

		variables.envFile = expandPath('.\.env')

		if( !FileExists( variables.envFile ) ){
			WriteOutput("Error: .env file not found at #variables.envFile#");
			abort;
		}

		Application.Env = DeserializeJSON( FileRead( variables.envFile ) );
		
		

		// Construct the OAuth Sign-In URL
		UrlParams = ArrayToList( [
			"client_id=#Application.Env.credentials.clientId#",
			"response_type=code",
			"redirect_uri=#Application.Env.credentials.redirectUri#",
			"response_mode=query",
			"scope=#Application.Env.credentials.scope#",
			"state=12345"
		], "&" );

		Application.OauthSignInUrl = "https://login.microsoftonline.com/#Application.Env.credentials.providerConfig.tenant#/oauth2/v2.0/authorize?#urlParams#"
		
		return true;
	}

	public void function OnSessionStart() { 
		// Fires when the session is first created.

		Session.LoggedIn = false


		// Initialize the AuthObject in the session
		Session.AuthObject = Application.Env.Credentials;

		// Start the authentication flow and redirect to microsoft
		GetOauthAccessToken( Session.AuthObject ); 


		return;
	};
	
	
	
	
    public void function onRequestStart( string targetPage ) {
		// Run any code you need to run at the start of each request

		// Get the request data
		variables.requestData = getHTTPRequestData()

		// Determine the remote address, accounting for proxies
		variables.remote_addr = structKeyExists( variables.requestData.headers, "x-forwarded-for" ) && len( variables.requestData.headers["x-forwarded-for"] )
			? variables.requestData.headers["x-forwarded-for"]
			: CGI.REMOTE_ADDR;


		// Handle reinitialization requests
		if( StructKeyExists( url, "reinit" ) ){
			StructClear( Application );
			OnApplicationStart()
		}

		// Handle logout requests (POST or GET)
		if ( structKeyExists(form, "logout") || structKeyExists(url, "logout") || structKeyExists(url, "clearSess") ) {
			try { structClear(session); } catch(any e) {}
			try { sessionInvalidate(); } catch(any e) {}
			// Redirect to root without query params
			location(url="/", addToken=false);
		}

		
		// Handler for OAuth redirect with code
		// This is where we exchange the code for an access token
		if ( structKeyExists(url, "scope") ) {
			
			if( !structKeyExists(Session,"AuthObject") ){
				Session.AuthObject = Application.Env.Credentials;
			}

			// Update the scope if it's provided in the URL
			// This allows for dynamic scope requests
			Session.AuthObject['scope'] = url.scope;


			// Start the authentication flow and redirect to microsoft
			GetOauthAccessToken( Session.AuthObject );
		}



    }
    
    public function OnRequest( required string TargetPage ) {
        // Fire when the page is requested. This is where any routes will take place.
		



        include targetpage
    }

    public void function onRequestEnd() {
        // Run any code you need to run at the end of each request
		
		
		
    }

    public void function onSessionEnd(struct sessionScope, struct applicationScope) {
        // Run any code you need to run at the end of the session
		
				

    }

    public void function onApplicationEnd( struct applicationScope ) {
        // Run any code you need to run at the end of the application
    }
	
    
	
	public void function OnMissingTemplate( required string targetPage = CGI.SCRIPT_NAME ){
		// Runs when a template is missing and being called from within ColdFusion.
		

	};
	


	public void function OnAbort( required string targetPage ) {
		// Triggers when a cfabort or abort function is used from within coldfusion
	}
	
    
	public void function OnError( 
		required any Exception, 
		string EventName=""
	){

		
		WriteOutput( "An error has occurred: #Exception.cause.message#<br/>" );
		
		return;
	}



	
	public string function base64urldecode( required string value ) {
		// First, we need to get this base64url value back to the original base64 format.
		// To do this, we have to re-add the standard base64 characters.
		value = replace( value, "-", "+", "all" );
		value = replace( value, "_", "/", "all" );
		
		
		// Part of the original coding stripped out the padding characters at the end of
		// the base64 value. We need to add these back in, otherwise ColdFusion won't be
		// able to parse the value.
		value &= repeatString( "=", ( 4 - ( len( value ) % 4 ) ) );
		
		
		// Once we have the valid base64 input, we can get the binary representation.
		var bytes = binaryDecode( value, "base64" );
		
		
		// And, from the binary, we can re-encode the value as the original UTF-8 string.
		var decodedValue = charsetEncode( bytes, "utf-8" );
		return( decodedValue );
	}

	public string function base64urlEncode( required string value ) {
		// Get the binary representation of the UTF-8 string.
		var bytes = charsetDecode( value, "utf-8" );
		
		// Encode the binary using the core base64 character set.
		var encodedValue = binaryEncode( bytes, "base64" );
		
		// Replace the characters that are not allowed in the base64url format. The
		// characters [+, /, =] are removed for URL-based base64 values because they
		// have significant meaning in the context of URL paths and query-strings.
		encodedValue = replace( encodedValue, "+", "-", "all" );
		encodedValue = replace( encodedValue, "/", "_", "all" );
		encodedValue = replace( encodedValue, "=", "", "all" );
		return( encodedValue );
	}
}