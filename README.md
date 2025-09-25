# ColdFusion Microsoft Graph / Azure Demo App

A lightweight Adobe ColdFusion (CFML) demo application showcasing authentication flows with Microsoft Entra ID (Azure AD), use of the Azure Instance Metadata Service (IMDS) for managed identity, interactions with Azure Key Vault, Microsoft Graph API (users, photo, To Do), and Azure Management API.

It is intended as a learning/reference project illustrating how to:
- Load environment / secret configuration from a local `.env` JSON file or Azure Key Vault.
- Perform OAuth 2.0 authorization code flow against Microsoft identity platform.
- Store tokens in session and use them to call Microsoft Graph.
- Obtain access tokens using Managed Identity via IMDS (no client secret on the box).
- Work with Azure Key Vault: list, create, update, and delete secrets.
- Query Microsoft Graph (users, profile photo, To Do lists & tasks) through a reusable `graphClient`.
- Call Azure Management API & Resource Graph (wrapper component `mgmt.cfc`).

---
## Table of Contents
1. Quick Start
2. Folder / File Overview
3. Environment Configuration (`.env`)
4. Application Lifecycle (`Application.cfc`)
5. Authentication Flow
6. Session Structure & Tokens
7. Components in `/com`
8. Demos Overview (`/demos/*`)
9. Key Vault Integration Options
10. Azure Setup (App Registration / Permissions)
11. Security Considerations
12. Troubleshooting
13. Extending the App

---
## 1. Quick Start

1. Clone or copy the project into a ColdFusion-enabled web root, e.g. `c:\Sites\summit.az.m3-llc.net`.
2. Ensure Adobe ColdFusion (or Lucee with minor adjustments) is running and the web server maps this directory.
3. Create a JSON `.env` file in the app root (same level as `Application.cfc`). See sample below.
4. Browse to `http://localhost/` (or your mapped host). The app will:
   - Load `.env`
   - Build an authorization URL
   - Redirect you to Microsoft for consent (on first access / new session)
5. After login you'll see a user photo (Graph) and demo cards.

If `.env` is missing the app aborts with an error on startup.

### Example `.env` (minimal)
```json
{
  "credentials": {
    "clientId": "YOUR_CLIENT_ID",
    "clientSecret": "YOUR_CLIENT_SECRET (optional if using only managed identity)",
    "redirectUri": "https://localhost/",
    "scope": "User.Read openid profile offline_access Tasks.ReadWrite Todo.ReadWrite",
    "providerConfig": {
      "tenant": "YOUR_TENANT_ID_OR_DOMAIN"
    }
  }
}
```
You may expand this with additional scopes (e.g. `Mail.Read`, `Calendars.Read`). Keep them space-delimited.

> NOTE: This project uses an authorization code flow but the actual token exchange helper (function `GetOauthAccessToken`) is referenced in `Application.cfc` yet not included in the provided snippets. Ensure you implement or include that utility to exchange `code` for tokens and store them in `Session.Tokens` (described below). If you already have that helper in another file, nothing further is needed.

---
## 2. Folder / File Overview

| Path | Purpose |
|------|---------|
| `Application.cfc` | Core CFML application component handling startup, session init, request lifecycle, OAuth redirect handling. |
| `index.cfm` | Landing page: login control, user photo fetch, demo navigation. |
| `com/graphClient.cfc` | Reusable Microsoft Graph REST client. |
| `com/ims.cfc` | Wrapper to get tokens from Azure Instance Metadata Service (Managed Identity). |
| `com/keyVault.cfc` | Key Vault secrets CRUD abstraction. |
| `com/mgmt.cfc` | Azure Management API + Resource Graph wrapper. |
| `demos/ims/` | Shows raw IMDS token retrieval. |
| `demos/vault/` | Manage (list/add/update/delete) Key Vault secrets. |
| `demos/graph/` | Lists users via Graph. |
| `demos/todo/` | Interactive Microsoft To Do (Lists & Tasks) UI using AJAX + Graph API. |
| `assets/` | Static JS/CSS (Bootstrap, jQuery, Font Awesome via CDN). |

---
## 3. Environment Configuration (`.env`)

The app expects a local file `.env` containing JSON (not key=value pairs). It is read at application start:
```cfml
Application.Env = DeserializeJSON( FileRead( expandPath('.\\.env') ) );
```

Structure (high-level):
```json
{
  "credentials": {
    "clientId": "...",
    "clientSecret": "...",           // optional in managed identity-only flow
    "redirectUri": "https://.../",    // must exactly match app registration
    "scope": "User.Read ...",         // space-delimited scopes
    "providerConfig": { "tenant": "TENANT_ID_OR_DOMAIN" }
  }
}
```

Add anything else you want under `Application.Env` — the code only explicitly references `Application.Env.credentials.*`.

### Loading from Azure Key Vault (Optional)
Commented code in `OnApplicationStart` demonstrates:
```cfml
// Application.vault = new com.keyVault(this.vaultConfig)
// variables.secretValue = Application.vault.getSecret(this.vaultSecretConfigName).value
// Application.Env = DeserializeJSON( variables.secretValue );
```
Where `this.vaultConfig = {"vaultName":"m369162"}` and `this.vaultSecretConfigName = "app-config"`.
You would store a secret named `app-config` whose value is the JSON shown above.

---
## 4. Application Lifecycle (`Application.cfc`)
Key methods used:

- `OnApplicationStart()`
  - Loads `.env` JSON.
  - Builds `Application.OauthSignInUrl` from env credentials & tenant.
- `OnSessionStart()`
  - Initializes `Session.LoggedIn = false` and copies credentials to `Session.AuthObject`.
  - Invokes `GetOauthAccessToken(Session.AuthObject)` (implement this to start auth redirect or token exchange).
- `onRequestStart()`
  - Handles `?reinit` to clear / restart application.
  - Handles `logout` / `clearSess` to invalidate session.
  - Detects OAuth redirect w/ `scope` (and implicitly `code` expected) and calls `GetOauthAccessToken` again for token exchange.
- Utility helpers: `base64urlEncode/Decode` for JWT segment processing.

> Missing in provided code: a `GetOauthAccessToken` function. You must supply one that:
> 1. If no `code` param present: redirects to `Application.OauthSignInUrl`.
> 2. If `code` present: POSTs to `https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token` exchanging `code` for `access_token`, `refresh_token`, etc., then populates `Session.Tokens` and sets `Session.LoggedIn = true`.

---
## 5. Authentication Flow
1. User hits root. No session tokens => `OnSessionStart` triggers `GetOauthAccessToken`.
2. User is redirected to Microsoft login/consent page (authorization endpoint built in `OnApplicationStart`).
3. After approval, Microsoft redirects back with `code` (and optionally `scope`, `state`).
4. `onRequestStart` sees query vars and invokes `GetOauthAccessToken` again to exchange `code`.
5. Tokens stored in session (implementation detail left to your `GetOauthAccessToken`).
6. User considered logged in when `Session.LoggedIn` true and `Session.Tokens` exists.

### Expected Token Storage (Example)
```cfml
Session.Tokens = {
  main = { access_token = "...", expires_on = createDateTime(...), refresh_token = "..." },
  graph = { access_token = "..." } // optional separate resource token
};
```
Landing page uses `Session.Tokens.graph.access_token` for photo (adjust or unify if you only store one token).

---
## 6. Session Structure & Flags
- `Session.AuthObject` – initial copy of env credentials / scope (mutable if URL carries new `scope`).
- `Session.Tokens` – struct of access/refresh tokens per resource (your implementation).
- `Session.LoggedIn` – boolean gate for UI and protected requests.

---
## 7. Components in `/com`
### 7.1 `graphClient.cfc`
A fetch-style wrapper for Microsoft Graph.

Key features:
- Properties: `baseUrl` (default `https://graph.microsoft.com`), `apiVersion` (`v1.0`), `access_token`.
- `init(dynamicProperties={})` sets overrides.
- `send(uri, options={})` builds full URL, supports:
  - `options.method` (GET, POST, PATCH, DELETE...)
  - `options.headers`
  - `options.body`
  - `options.query` (struct -> querystring)
  - `options.json` (boolean to force JSON serialization)
- Automatically attaches `Authorization: Bearer <token>`.
- Attempts to parse `fileContent` JSON and returns parsed struct if JSON, else raw cfhttp result.

Usage:
```cfml
GraphClient = new com.graphClient({ access_token = Session.Tokens.main.access_token });
user = GraphClient.send("/me");
photo = GraphClient.send("/me/photo/$value");
```

### 7.2 `ims.cfc`
Obtains a managed identity token from Azure Instance Metadata Service (IMDS).
- Default `api-version=2019-08-01` and `resource=https://vault.azure.net/`.
- Builds endpoint: `http://169.254.169.254/metadata/identity/oauth2/token?...`
- `Auth()` returns JSON with `access_token`, adds `expires_time` (calculated locally).

Usage:
```cfml
ims = new com.ims({ resource = "https://graph.microsoft.com/" });
tokenStruct = ims.Auth();
```

### 7.3 `keyVault.cfc`
Interact with Azure Key Vault secrets.
- If no `auth` passed in, internally calls IMDS to get one for `https://vault.azure.net/`.
- `getSecrets(pageSize=10, filter_string="prefix")` – auto-follows `nextLink` pages up to `pageSize` loops.
- `getSecret(secretName)` – fetch metadata and then specific version info.
- `getSecretVersions(secretName)` – list all versions.
- `addSecret(secretName, secretValue, tags={})` – PUT secret.
- `deleteSecret(secretName)` – DELETE then purge after sleep.
- Helper date epoch conversion functions.

Usage:
```cfml
vault = new com.keyVault({ vaultName = "myvault" });
secrets = vault.getSecrets();
added = vault.addSecret("demoSecret", "PlainTextValue");
```

### 7.4 `mgmt.cfc`
Wrapper for Azure Management + Resource Graph.
- Properties: `access_token`, `api_version` (default `2021-04-01`), `env` (public/government) sets base URL.
- `init()` builds endpoint and immediately calls `listSubscriptions()`; sets `subscriptionId` to first result.
- `send(method, body)` generic executor.
- `listSubscriptions()` returns subscription list (`response.value` array) and sets endpoint.
- `resourceGraphQuery(query, subscriptions=[...])` for POST to Resource Graph provider.

Usage:
```cfml
mgmt = new com.mgmt({ access_token = Session.Tokens.main.access_token });
subs = mgmt.listSubscriptions();
rg = mgmt.resourceGraphQuery( query = "Resources | project name, type | limit 5" ).getResponse();
```

---
## 8. Demos Overview
| Demo | Path | Highlights |
|------|------|-----------|
| IMDS | `/demos/ims/` | Fetch and display raw managed identity token. |
| Key Vault | `/demos/vault/` | CRUD secrets (simple UI); uses managed identity for auth. |
| Graph Users | `/demos/graph/` | Lists users (name, UPN, etc.). Requires `User.Read.All` or `User.ReadBasic.All` style permissions (app or delegated). |
| To Do | `/demos/todo/` | AJAX-driven To Do list & tasks (create/update/delete/complete). Requires `Tasks.ReadWrite` / `ToDo.ReadWrite` scopes. |

---
## 9. Key Vault Integration Options
You can either:
1. Use Managed Identity (no secrets locally) – ensure the compute (VM / App Service) has access policy (or RBAC role) granting `get/list/set/delete` on secrets.
2. Use an App Registration's client credentials (not currently coded here — would require token acquisition separate from IMDS when `auth` not present).

To use Key Vault for `.env` style secrets:
- Create secret `app-config` with JSON value of your config.
- Uncomment initialization lines in `OnApplicationStart`.
- Remove or ignore local `.env` file (or keep as fallback).

---
## 10. Azure Setup

### 10.1 App Registration
1. Go to Azure Portal > Entra ID > App registrations > New registration.
2. Set redirect URI (web) to match your `.env` `redirectUri` (e.g. `https://localhost/`).
3. Note `Application (client) ID` and `Directory (tenant) ID`.
4. Under Authentication: enable PKCE (optional), set implicit off (using auth code), allow accounts per your scenario.
5. Under Certificates & secrets: create a client secret if you need it (not required for managed identity only scenarios).
6. Under API Permissions add delegated:
   - `User.Read`
   - `Tasks.ReadWrite` / `ToDo.ReadWrite`
   - Additional as needed (`User.Read.All` for full user listing, may require admin consent).
7. Grant admin consent.

### 10.2 Managed Identity (If hosting in Azure)
- Enable the system-assigned managed identity for your Web App / VM.
- Assign Key Vault access or Azure RBAC roles (e.g., `Key Vault Secrets User`).
- For Graph via managed identity you'd need application permissions + proper token acquisition (not currently coded—this demo relies on delegated tokens for Graph except when using IMDS strictly for Key Vault access).

### 10.3 Key Vault
- Create a Key Vault named matching `this.vaultConfig.vaultName` (e.g., `m369162`).
- Add access policy or role assignment for your managed identity.
- Add secret `app-config` containing JSON config.

---
## 11. Security Considerations
- Do NOT commit real `.env` with client secrets or tenant info to source control.
- Consider storing refresh tokens securely or rotating them.
- Validate `state` parameter for CSRF protection (currently hard-coded `state=12345` – improve for production by generating per-session and validating on return).
- Add proper error handling / logging around HTTP calls; avoid leaking tokens in logs or UI.
- Use HTTPS in production (redirect HTTP -> HTTPS).
- Sanitize all dynamic output (some encoding helpers already present in demos).

---
## 12. Troubleshooting
| Issue | Cause | Fix |
|-------|-------|-----|
| ".env file not found" abort | Missing file | Create `.env` with JSON structure (see sample). |
| Redirect loop | `GetOauthAccessToken` missing or mis-implemented | Ensure it only redirects when no `code` present. |
| Graph 401 / 403 | Missing scope or consent | Add correct delegated scopes, re-consent, verify token claims. |
| Photo not showing | User has no photo or token missing | Check `Session.Tokens.graph` vs `main`; unify token usage. |
| Key Vault 403 | Managed identity lacks access | Add access policy / RBAC assignment. |
| To Do list returns empty | User has no lists | Create one via UI. |
| Users list empty | Need broader permission like `User.Read.All` | Add permission & admin consent. |

---
## 13. Extending the App
Ideas:
- Implement refresh token logic (track expiry & silently renew).
- Add caching for Key Vault secrets to reduce calls.
- Add error boundary page for `OnError` with logging to App Insights / Log Analytics.
- Implement PKCE for public client scenarios.
- Add Graph endpoints: calendar, mail, teams presence.
- Convert `GetOauthAccessToken` to a dedicated service component for clarity & testability.
- Introduce a lightweight router instead of direct folder includes.

---
## Appendix: Sample `GetOauthAccessToken` Pseudocode
```cfml
function GetOauthAccessToken(auth){
    if( NOT structKeyExists(url, "code") ){
        location( url = Application.OauthSignInUrl, addToken = false );
    }
    // Exchange code
    cfhttp( url = "https://login.microsoftonline.com/" & auth.providerConfig.tenant & "/oauth2/v2.0/token", method = "POST", result = "tokenResult" ) {
        cfhttpparam( type="formfield", name="client_id", value=auth.clientId );
        cfhttpparam( type="formfield", name="scope", value=auth.scope );
        cfhttpparam( type="formfield", name="code", value=url.code );
        cfhttpparam( type="formfield", name="redirect_uri", value=auth.redirectUri );
        cfhttpparam( type="formfield", name="grant_type", value="authorization_code" );
        // optional client_secret if confidential client
        if( structKeyExists(auth, "clientSecret") )
            cfhttpparam( type="formfield", name="client_secret", value=auth.clientSecret );
    }
    if( isJSON(tokenResult.fileContent) ){
        tokens = deserializeJSON(tokenResult.fileContent);
        Session.Tokens = { main = tokens, graph = tokens };
        Session.LoggedIn = true;
    }
}
```
Tailor this to your security and refresh requirements.

---
## License
This demo is provided for educational use. Add an explicit license file if you plan to redistribute.

---
## Support
Questions / improvements: open an issue or extend the README with clarifications relevant to your deployment environment.

Enjoy building with ColdFusion + Azure! 🚀
