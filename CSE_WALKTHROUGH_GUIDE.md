# Google Custom Search Engine — Secure Setup Walkthrough

## Current security state

The Google API key previously embedded in this repository must be treated as compromised. Do not use or copy that value. Complete key revocation or rotation in Google Cloud before restoring the integration.

## Step 1: Prepare secure local configuration

From the repository directory:

```powershell
Copy-Item .env.template .env
```

Open the new local `.env` file and set:

```text
GOOGLE_API_KEY=YOUR_ROTATED_AND_RESTRICTED_KEY
GOOGLE_CSE_ID=YOUR_SEARCH_ENGINE_ID
```

Do not commit `.env`. Verify the ignore rule:

```powershell
git check-ignore .env
```

## Step 2: Create the Custom Search Engine

1. Open the Google Programmable Search Engine control panel.
2. Create a search engine named `Geopolitical Image Search`.
3. Enable image search.
4. Configure whole-web search only when appropriate.
5. Copy the Search Engine ID.

## Step 3: Restrict the replacement key

In Google Cloud Console:

1. Limit the replacement key to the Custom Search JSON API.
2. Add application restrictions appropriate to the local or hosted environment.
3. Set quota and billing alerts.
4. Confirm the exposed key is revoked, deleted, or otherwise unusable.

## Step 4: Start the server

```powershell
node geopolitical-intelligence-server.js
```

## Step 5: Verify without printing secrets

```powershell
node -e "require('dotenv').config(); console.log({ googleApiKey: process.env.GOOGLE_API_KEY ? 'Loaded' : 'Missing', googleCseId: process.env.GOOGLE_CSE_ID ? 'Loaded' : 'Missing' });"
```

Then run:

```powershell
powershell -File test-comprehensive-integration.ps1
```

Expected indicators:

- Google Images API configuration is detected.
- The CSE ID is detected.
- The application does not print the credential value.
- Failed authentication is handled without logging complete credential-bearing URLs.

## Troubleshooting

1. Confirm `.env` exists locally but is not tracked.
2. Confirm the CSE ID format is valid.
3. Confirm image search is enabled.
4. Confirm the replacement key is active and restricted to the required API.
5. Restart the server after changing local configuration.

## Repository security checks

```powershell
git status --short
git ls-files .env
git grep -n "AIza"
```

`git ls-files .env` should return nothing. `git grep -n "AIza"` should return no credential values.

## Required follow-up after an exposure

- Remove the credential from every live branch and tag.
- Review Git history because deleting it from the current branch does not erase earlier commits.
- Review forks, caches, build logs and artifacts.
- Rotate any related OAuth client secrets or service-account keys discovered during the audit.
