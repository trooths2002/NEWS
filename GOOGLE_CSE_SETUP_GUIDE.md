# Google Custom Search Engine Setup Guide

## Security prerequisite

The previously committed Google API key must be treated as compromised. Rotate or revoke it in Google Cloud before configuring this integration. Never place an API key in this repository, documentation, shell history, screenshots, or issue comments.

Use one of these secure locations:

- A local `.env` file copied from `.env.template` and excluded by `.gitignore`
- A user/process environment variable named `GOOGLE_API_KEY`
- GitHub Actions or Codespaces secrets for hosted workflows
- An approved secret manager for production

## Step 1: Create or select a restricted API key

In Google Cloud Console:

1. Select the intended active project.
2. Create a new key only after the exposed key has been revoked or confirmed unusable.
3. Restrict the key to the Custom Search JSON API.
4. Add application restrictions appropriate to the deployment environment.
5. Review quota and billing alerts.

Do not reuse the exposed key.

## Step 2: Create the Custom Search Engine

1. Visit the Google Programmable Search Engine control panel.
2. Create a search engine named `Geopolitical Image Search`.
3. Enable image search.
4. Enable whole-web search only when consistent with the intended use and policy.
5. Copy the Search Engine ID.

## Step 3: Configure the local environment

Copy the template and edit the local file only:

```powershell
Copy-Item .env.template .env
notepad .env
```

Set these values locally:

```text
GOOGLE_API_KEY=YOUR_ROTATED_AND_RESTRICTED_KEY
GOOGLE_CSE_ID=YOUR_SEARCH_ENGINE_ID
```

Confirm that `.env` remains ignored:

```powershell
git check-ignore .env
```

The command should report `.env`.

## Step 4: Test without displaying the key

Check that configuration loads without printing the credential:

```powershell
node -e "require('dotenv').config(); console.log('API key:', process.env.GOOGLE_API_KEY ? 'Loaded' : 'Missing'); console.log('CSE ID:', process.env.GOOGLE_CSE_ID ? 'Loaded' : 'Missing');"
```

Run the integration tests:

```powershell
powershell -File test-comprehensive-integration.ps1
```

For a direct API test, reference environment variables rather than placing secrets in the command:

```powershell
$uri = "https://www.googleapis.com/customsearch/v1?key=$env:GOOGLE_API_KEY&cx=$env:GOOGLE_CSE_ID&q=test"
Invoke-RestMethod -Uri $uri -Method Get
```

Be aware that command history and process inspection may expose command-line arguments. Prefer application-level tests that read environment variables internally.

## Step 5: Production controls

- Keep `.env` untracked.
- Restrict the key to the minimum API and application scope.
- Enable quota and billing alerts.
- Rotate keys on a defined schedule and after any suspected exposure.
- Use secret scanning and pre-commit checks.
- Do not log complete request URLs when they contain credentials.

## Incident response

When a credential is committed:

1. Revoke or rotate it first.
2. Remove it from every current branch and tag.
3. Search the repository for additional copies.
4. Assess Git history and cached forks.
5. Replace local and hosted workflow configuration.
6. Document the incident without reproducing the secret.
