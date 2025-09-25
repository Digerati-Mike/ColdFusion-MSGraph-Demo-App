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
	this.vaultConfig = {"vaultName"	: "{{vaultName}}"}
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
		Application.vault = new com.keyVault(this.vaultConfig)

		// Load secrets from Key Vault
		variables.secretValue = Application.vault.getSecret(this.vaultSecretConfigName).value
		
		// Parse the JSON secret value into a struct
		Application.Env = DeserializeJSON( variables.secretValue );


		

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
}