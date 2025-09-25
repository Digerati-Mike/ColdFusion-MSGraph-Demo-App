<cfscript>

    // IMS helper
    ims = new com.ims();

    tmp = ims.Auth();
    tokenToShow = tmp.access_token ?: '';
    
</cfscript>

<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Vault Token - Summit Demo</title>
    <!-- Bootstrap 5 CSS -->
	<link href="/assets/bootstrap.min.css" rel="stylesheet" >
	<!-- Font Awesome 6 -->
	<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" rel="stylesheet"/>
	<style>
		body { background: #f8f9fa; }
	</style>
    <script src="/assets/jquery.min.js"></script>
</head>
<body>
    <nav class="navbar navbar-expand-lg bg-dark navbar-dark">
		<div class="container">
			<a class="navbar-brand" href="/">
				<i class="fa-solid fa-mountain-sun me-2"></i>
				CFSummit Demo - IMS
			</a>
		
			<form method="post" class="d-inline">
				<button name="logout" value="1" class="btn btn-sm btn-outline-light">Logout</button>
			</form>
		</div>
	</nav>

    <main class="container py-4">
        <div class="row justify-content-center">
            <div class="col-md-8">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <strong>Access Token</strong>
                       
                    </div>
                    <div class="card-body">
                        <div class="mb-3">
                            <label class="form-label">Token</label>
                            <cfoutput>
                                <textarea class="form-control" rows="8" readonly id="tokenArea">#ENcodeForHtml(tokenToShow)#</textarea>
                            </cfoutput>
                        </div>
                        <div class="d-flex gap-2">
                            <a class="btn btn-sm btn-outline-secondary" href="/">Back</a>
                        </div>
                        <cfif structKeyExists(variables,'flashMessage')>
                            <cfoutput>
                                <div class="mt-3 alert alert-info">#ENcodeForHtml(flashMessage)#</div>
                            </cfoutput>
                            
                        </cfif>
                    </div>
                </div>
            </div>
        </div>
    </main>

    <script src="/assets/bootstrap.bundle.min.js"></script>
</body>
</html>