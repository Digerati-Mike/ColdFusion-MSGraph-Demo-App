<cfscript>
    


    Token = GetOauthAccessToken( Application.Env.credentials );


    if( structKeyExists(token, "id_token") ){
        

        SplitIdTOken = ListToArray( Token.id_token, "." );


        IdObject = DeserializeJSON(base64urldecode(splitIdToken[2]))


        Session.IdObject = IdObject;

    }


    


    if( !structKeyExists(Session, "tokens") ){

        Session.Tokens = {}
        Session['tokens']['main'] = Token
    }


    if( Token.scope contains "user" ){
        Session.Tokens['graph'] = Token;
    } 


    if( Token.scope contains "management" ){
        Session.Tokens['mgmt'] = Token;
    } 

    if( Token.scope contains "vault" ){
        Session.Tokens['vault'] = Token;
    } 


    Session.LoggedIn = true;


    location(url="/", addtoken=false)



</cfscript>