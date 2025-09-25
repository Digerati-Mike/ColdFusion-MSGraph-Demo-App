<cfscript>


// Instantiate KeyVault client
keyVaultClient = new com.keyVault({
    "vaultName" : "m369162"
});

// Handle Add Secret
if (structKeyExists(form, "addSecret")) {
    if (len(trim(form.secretName)) && len(trim(form.secretValue))) {
        keyVaultClient.addSecret(secretName=form.secretName, secretValue=form.secretValue);
        flashMessage = "Secret added.";
    } else {
        flashMessage = "Secret name and value required.";
    }
}

// Handle Delete Secret
if (structKeyExists(form, "deleteSecret")) {
    if (len(trim(form.secretName))) {
        keyVaultClient.deleteSecret(secretName=form.secretName);
        flashMessage = "Secret deleted.";
    }
}

// Handle Update Secret (delete then add)
if (structKeyExists(form, "updateSecret")) {
    if (len(trim(form.secretName)) && len(trim(form.secretValue))) {
        keyVaultClient.deleteSecret(secretName=form.secretName);
        keyVaultClient.addSecret(secretName=form.secretName, secretValue=form.secretValue);
        flashMessage = "Secret updated.";
    } else {
        flashMessage = "Secret name and value required for update.";
    }
}

// Always get latest secrets
Secrets = keyVaultClient.getSecrets();

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
                        <strong>Secrets</strong>
                    </div>
                    <div class="card-body">
                        <!-- Flash Message -->
                        <cfif structKeyExists(variables, 'flashMessage')>
                            <cfoutput>
                                <div class="alert alert-info">#encodeForHtml(flashMessage)#</div>
                            </cfoutput>
                        </cfif>
                        <!-- Add Secret Form -->
                        <form method="post" class="mb-4">
                            <div class="row g-2 align-items-end">
                                <div class="col-md-5">
                                    <label for="secretName" class="form-label mb-0">Secret Name</label>
                                    <input type="text" class="form-control" id="secretName" name="secretName" required>
                                </div>
                                <div class="col-md-5">
                                    <label for="secretValue" class="form-label mb-0">Secret Value</label>
                                    <input type="text" class="form-control" id="secretValue" name="secretValue" required>
                                </div>
                                <div class="col-md-2">
                                    <button type="submit" name="addSecret" value="1" class="btn btn-primary w-100">Add Secret</button>
                                </div>
                            </div>
                        </form>
                        <!-- Secrets Table -->
                        <div class="table-responsive">
                            <table class="table table-striped table-hover align-middle">
                                <thead class="table-dark">
                                    <tr>
                                        <th>Name</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <cfoutput>
                                        <cfloop array="#secrets.value#" index="secret">
                                            <tr>
                                                <td>#encodeForHtml(secret.id)#</td>
                                                <td>
                                                    <!-- Edit Button triggers modal -->
                                                    <button type="button" class="btn btn-sm btn-warning me-1" data-bs-toggle="modal" data-bs-target="##editModal_#replace(secret.id, '-', '_', 'all')#">Edit</button>
                                                
                                                    <!-- Edit Modal -->
                                                    <div class="modal fade" id="editModal_#replace(secret.id, '-', '_', 'all')#" tabindex="-1" aria-labelledby="editModalLabel_#replace(secret.id, '-', '_', 'all')#" aria-hidden="true">
                                                      <div class="modal-dialog">
                                                        <div class="modal-content">
                                                          <div class="modal-header">
                                                            <h5 class="modal-title" id="editModalLabel_#replace(secret.id, '-', '_', 'all')#">Edit Secret</h5>
                                                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                                                          </div>
                                                          <form method="post">
                                                            <div class="modal-body">
                                                              <input type="hidden" name="secretName" value="#encodeForHtml(secret.id)#">
                                                              <div class="mb-3">
                                                                <label for="editSecretValue_#replace(secret.id, '-', '_', 'all')#" class="form-label">Secret Value</label>
                                                                <input type="text" class="form-control" id="editSecretValue_#replace(secret.id, '-', '_', 'all')#" name="secretValue" value="" required>
                                                                <small class="text-muted">Enter new value for secret.</small>
                                                              </div>
                                                            </div>
                                                            <div class="modal-footer">
                                                              <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                                                              <button type="submit" name="updateSecret" value="1" class="btn btn-primary">Update</button>
                                                            </div>
                                                          </form>
                                                        </div>
                                                      </div>
                                                    </div>
                                                </td>
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