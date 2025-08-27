# Google Custom Search Engine - Step-by-Step Setup Guide

## 🎯 **Your Progress So Far**

✅ **Google API Key**: AIzaSyB8yvuzAdDx1GDsdRp4ulReaC7Y9BTEBdw (Configured)
✅ **Server Integration**: Ready and waiting for CSE ID
⏳ **Custom Search Engine ID**: Need to create (this guide)

---

## **STEP 1: Open Google Custom Search Engine**

1. **Open your web browser**
2. **Go to**: <https://cse.google.com/cse/>
3. **Sign in** with your Google account (the same one used for the API key)

---

## **STEP 2: Create New Search Engine**

1. **Click**: "Add" or "New Search Engine" button
2. **In the form that appears**:

   **Sites to search**:
   - **LEAVE THIS BLANK** ✅
   - This allows searching the entire web (what we want for image search)

   **Name**:
   - Enter: `Geopolitical Image Search`

   **Language**:
   - Select: `English`

3. **Click**: "Create"

---

## **STEP 3: Enable Image Search (CRITICAL)**

After creating the search engine:

1. **Click**: "Control Panel"
2. **Go to**: "Setup" → "Basics"
3. **Find**: "Image Search" setting
4. **Turn ON**: Image Search ✅ (This is essential!)
5. **Find**: "Search the entire web"
6. **Turn ON**: Search the entire web ✅
7. **Click**: "Update"

---

## **STEP 4: Get Your Search Engine ID**

1. **Still in Control Panel** → "Setup" → "Basics"
2. **Look for**: "Search Engine ID"
3. **Copy the ID**: It looks like `abc123def456:ghijklmnop`
4. **Save this ID** - you'll need it in the next step

---

## **STEP 5: Update Your Configuration**

**Open file**: `c:\Users\tjd20.LAPTOP-PCMC2SUO\news\.env`

**Find this line**:

```text
GOOGLE_CSE_ID=your_custom_search_engine_id_here
```

**Replace with** (use your actual ID):

```text
GOOGLE_CSE_ID=abc123def456:ghijklmnop
```

**Save the file**

---

## **STEP 6: Restart Server**

Open PowerShell and run:

```powershell
# Stop current server
taskkill /f /im node.exe

# Start server with your new configuration
node geopolitical-intelligence-server.js
```

---

## **STEP 7: Test Integration**

After server starts (wait 10 seconds), test:

```powershell
# Test Google Images integration
curl -X GET http://localhost:3007/health
```

You should see your Google integration is now active!

---

## **🎯 Expected Results**

Once configured, your image scraping will be able to:

✅ **Search Google Images** for related article images
✅ **Download and organize** images by region
✅ **Provide fallback** when article pages don't have images
✅ **Track metadata** for all collected images

---

## **📊 Verification**

After setup, run this test:

```powershell
powershell -File "test-comprehensive-integration.ps1"
```

You should see:

- ✅ Google Images API: WORKING
- ✅ Enhanced Image Scraping: OPERATIONAL
- ✅ Multiple strategies: ACTIVE

---

## **💡 Troubleshooting**

**If you get errors**:

1. **Check CSE ID format** - should include the colon `:`
2. **Verify image search is enabled** in CSE settings
3. **Make sure you saved the .env file** properly
4. **Restart the server** after changing .env

---

## **🚀 Next Steps After Setup**

1. **Test the integration** with real news articles
2. **Add more API keys** (Bing, News API) for enhanced capabilities
3. **Monitor usage** at <https://console.developers.google.com/apis/dashboard>
4. **Enjoy enhanced image collection** for your geopolitical intelligence!

---

### **Ready to start? Begin with Step 1 above! 🎯**

