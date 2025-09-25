<cfscript>
// Handle logout requests (POST or GET)
if ( structKeyExists(form, "logout") || structKeyExists(url, "logout") ) {
    try { structClear(session); } catch(any e) {}
    try { sessionInvalidate(); } catch(any e) {}
    // Redirect to root without query params
    location(url="/", addToken=false);
}
// Determine login state
isLoggedIn = structKeyExists(session, "LoggedIn") && !!session.LoggedIn && structKeyExists(session, "Tokens");


// Non-recursive directory list returns only immediate subdirectories
Demos = DirectoryList(
	path     = ExpandPath('demos\'),
	recurse  = false,
	listInfo = "query",
	type     = "dir"
);

// Convert query to array of structs for consistency with other DAO output
Demos = QueryExecute(
	"
	SELECT * from Demos 
	",
	{},
	{ DBType = "query", returnType = "array" }
);

DemoProperties = {
	"ims" : {
		"icon" : "fa fa-id-badge",
		"title" : "Instance Metadata Service",
		"description" : "Show how to authenticate using the Azure IMDS service."
	},
	"vault" : {
		"icon" : "fa fa-key",
		"title" : "Key Vault",
		"description" : "Browse and manage secrets from Azure Key Vault using managed identity."
	},
	"graph" : {
		"icon" : "fa fa-chart-line",
		"title" : "Microsoft Graph",
		"description" : "Query Microsoft Graph API for user and organizational data."
	},
	"todo" : {
		"icon" : "fa fa-list-check",
		"title" : "To-Do List",
		"description" : "Manage and track tasks using Microsoft To Do integration."
	}
}

</cfscript>


<!doctype html>
<html lang="en">
<head>
	<meta charset="utf-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1" />
	<title>Welcome</title>
	<!-- Bootstrap 5 CSS -->
	<link href="/assets/bootstrap.min.css" rel="stylesheet" >
	<!-- Font Awesome 6 -->
	<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" rel="stylesheet"/>
	<style>
		body { background: #f8f9fa; }
	</style>
	<!-- jQuery (optional, requested) -->
	<script src="/assets/jquery.min.js" ></script>
</head>
<body>
	<nav class="navbar navbar-expand-lg bg-dark navbar-dark">
		<div class="container">
			<a class="navbar-brand" href="/">
				<i class="fa-solid fa-mountain-sun me-2"></i>
				CFSummit Demo
			</a>
		
			<form method="post" class="d-inline">
				<button name="logout" value="1" class="btn btn-sm btn-outline-light">Logout</button>
			</form>
		</div>
	</nav>

	<main class="container py-5">
		<div class="row justify-content-center">
			<div class="col-md-8 col-lg-6">
				<div class="card shadow-sm">
					<div class="card-body p-4 text-center">
						<cfif NOT isLoggedIn>
							<h1 class="h3 mb-3">
								<i class="fa-solid fa-right-to-bracket text-primary me-2"></i>
								Sign in
							</h1>
							<p class="text-muted">You are not signed in. Start the login process to continue.</p>
							<cfif len(Application.OauthSignInUrl)>
								<a class="btn btn-primary btn-lg" href="<cfoutput>#Application.OauthSignInUrl#</cfoutput>">
									<i class="fa-brands fa-microsoft me-2"></i>
									Sign in with Microsoft
								</a>
							<cfelse>
								<div class="alert alert-warning text-start" role="alert">
									<strong>Configuration issue:</strong> Missing or invalid credentials. Ensure <code>.env</code> is loaded in <code>Application.Env.credentials</code>.
								</div>
							</cfif>
						<cfelse>
							<cfscript>





								GraphClient = new com.graphClient({
									"access_token" : Session.Tokens.graph.access_token
								})

								Photo = GraphClient.send('me/photo/$value').fileContent
								// Convert the ByteArrayOutputStream to a Base64-encoded image string
								if ( isObject(Photo) && Photo.getClass().getName() eq "java.io.ByteArrayOutputStream" ) {
									// Get the byte array from the ByteArrayOutputStream
									bytes = Photo.toByteArray();
									// Encode to Base64
									encoder = createObject("java", "java.util.Base64").getEncoder();
									base64String = encoder.encodeToString(bytes);
									// Build the data URI for embedding in an <img> tag
									imgDataUri = "data:image/jpeg;base64," & base64String;


								}

							</cfscript>
							<cfoutput>
								<img src='#imgDataUri#' class='rounded-circle mb-3' alt='User Photo' style='max-width: 96px; max-height: 96px;'>
							</cfoutput>
							<h1 class="h3 mb-3">
								<i class="fa-solid fa-circle-check text-success me-2"></i>
								You're signed in
							</h1>

							<p class="text-muted mb-4">Session is active. You can proceed to app features.</p>
							<div class="d-flex gap-2 justify-content-center mb-4">
							
								<a class="btn btn-outline-secondary" href="/">
									<i class="fa-solid fa-rotate me-2"></i>
									Refresh
								</a>
								<form method="post" class="d-inline">
									<input type="hidden" name="logout" value="1" />
									<button type="submit" class="btn btn-danger">
										<i class="fa-solid fa-right-from-bracket me-2"></i>
										Log out
									</button>
								</form>
							</div>
						</cfif>
					</div>
				</div>
			</div>
		</div>

		<!-- Demo Cards: Only show when logged in -->
		<cfif isLoggedIn>
			<div class="row row-cols-1 row-cols-md-2 row-cols-lg-4 g-4 mt-4 text-start">
				<cfloop from="1" to="#ArrayLen( Demos )#" index="i">
					<cfoutput>
						<cfset Properties = DemoProperties[ Demos[i].name ]>
						
						<div class="col">
							<div class="card h-100">
								<div class="card-body d-flex flex-column">
									<h5 class="card-title"><i class="fa-solid #Properties.icon# text-primary me-2"></i>#Properties.title#</h5>
									<p class="card-text">#Properties.description#</p>
									<div class="mt-auto">
										<a href="/demos/#Demos[i].name#/" class="btn btn-primary">Open #Properties.title#</a>
									</div>
								</div>
							</div>
						</div>
					</cfoutput>
				</cfloop>
				
			</div>
		</cfif>
	</main>

	<!-- Bootstrap 5 JS Bundle -->
	<script src="/assets/bootstrap.bundle.min.js" ></script>

	<script>
		// Example: small UX hint using jQuery
		$(function(){
			$('[data-bs-toggle="tooltip"]').tooltip();
		});
	</script>
</body>
</html>