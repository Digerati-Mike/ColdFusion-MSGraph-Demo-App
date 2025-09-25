<cfscript>

    graphclient = new com.graphClient({
        "access_token" : session.Tokens.main.access_token
    });


    users = GraphClient.send('/users')

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
            <div class="col-md-12">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <strong>Users</strong>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-striped table-hover align-middle">
                                <thead class="table-dark">
                                    <tr>
                                        <th>Name</th>
                                        <th>Email</th>
                                        <th>Username</th>
                                        <th>Job Title</th>
                                        <th>Office</th>
                                        <th>Mobile</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <cfoutput>
                                    <cfloop array="#users.value#" index="user">
                                        <tr>
                                            <td>#encodeForHtml(user.displayName)#</td>
                                            <td>#encodeForHtml(user.mail ?: "")#</td>
                                            <td>#encodeForHtml(user.userPrincipalName)#</td>
                                            <td>#encodeForHtml(user.jobTitle ?: "")#</td>
                                            <td>#encodeForHtml(user.officeLocation ?: "")#</td>
                                            <td>#encodeForHtml(user.mobilePhone ?: "")#</td>
                                        </tr>
                                    </cfloop>
                                    </cfoutput>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </main>

    <script src="/assets/bootstrap.bundle.min.js"></script>
</body>
</html>