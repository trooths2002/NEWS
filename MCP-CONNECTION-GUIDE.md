# 🔗 MCP SuperAssistant Connection Guide

## ✅ **Your MCP Server Status**

- **Server Running**: ✅ Yes  
- **URL**: <http://localhost:3006>
- **SSE Endpoint**: <http://localhost:3006/sse>
- **Tools Available**: 2 (fetch_news, save_headlines)

---

## 🚀 **Step 1: Install Browser Extension**

### **Chrome/Edge Users:**

1. Open Chrome or Edge
2. Go to: <https://chrome.google.com/webstore>
3. Search: "MCP SuperAssistant"
4. Click "Add to Chrome" / "Add to Edge"
5. Click "Add Extension" to confirm
6. Pin the extension icon to your toolbar

### **Firefox Users:**

1. Open Firefox
2. Go to: <https://addons.mozilla.org>
3. Search: "MCP SuperAssistant"
4. Click "Add to Firefox"
5. Confirm installation

---

## 🔧 **Step 2: Connect to Your Server**

### **Method 1: Extension Settings**

1. **Click the MCP SuperAssistant icon** in your browser toolbar
2. **Look for "Server Settings" or "Configure"**
3. **Add new server** with these details:
   - **Name**: News Intelligence Server
   - **URL**: `http://localhost:3006/sse`
   - **Type**: SSE / StreamableHttp
   - **Enable**: ✅ Checked

### **Method 2: Direct Connection**

1. **Click MCP SuperAssistant icon**
2. **Find "Connect" or "Add Server"**
3. **Enter URL**: `http://localhost:3006/sse`
4. **Click "Connect"**

---

## 🎯 **Step 3: Verify Connection**

### **What You Should See:**

- ✅ **"Connected" status** in the extension
- ✅ **2 tools available**:
  - `fetch_news` - Get African news headlines
  - `save_headlines` - Save headlines to file
- ✅ **Green connection indicator**

### **If Connection Fails:**

Run this in PowerShell to check server:

```powershell
curl http://localhost:3006/health
```

Should return: `{"status":"OK","timestamp":"...","tools":2}`

---

## 🌐 **Step 4: Test with AI Chat Platform**

### **Go to one of these platforms:**

- **ChatGPT**: <https://chat.openai.com>
- **Claude**: <https://claude.ai>
- **Perplexity**: <https://perplexity.ai>
- **Google AI Studio**: <https://aistudio.google.com>

### **Use this test prompt:**

```text
I have MCP SuperAssistant connected to my news intelligence server. Please:

1. Acknowledge the connection and list available tools
2. Use fetch_news to get 3 latest African headlines
3. Save these headlines to 'connection-test.txt'

My system: Professional African news intelligence with local image storage and comprehensive archives.
```

---

## 🛠️ **Troubleshooting**

### **"No Connection" / "Server Not Found":**

1. **Check server is running**:

   ```powershell
   netstat -ano | findstr :3006
   ```

2. **Restart server if needed**:

   ```powershell
   node simple-mcp-server.js
   ```

### **"Tools Not Visible":**

1. **Refresh browser page**
2. **Disconnect and reconnect** in extension
3. **Check URL is exactly**: `http://localhost:3006/sse`

### **"Extension Not Working":**

1. **Disable/re-enable** the extension
2. **Check browser permissions**
3. **Try different AI platform**

---

## 🎯 **Expected Results After Connection**

### **In MCP SuperAssistant Extension:**

- ✅ Connected status
- ✅ 2 tools visible
- ✅ Server name: "News Intelligence Server"

### **In AI Chat:**

- ✅ AI can detect and use your news tools
- ✅ Headlines fetched from AllAfrica.com
- ✅ Files saved to your news directory
- ✅ Professional intelligence analysis

---

## 🔥 **Pro Tips**

1. **Keep server running** - Don't close the PowerShell window
2. **Use descriptive filenames** - Include dates in saved files
3. **Leverage your advantages** - Mention local images and archives
4. **Start with instructions** - Always begin AI sessions with MCP context

---

## 📊 **What You'll Get**

### **Professional Capabilities:**

- ✅ **Real-time news fetching** from African sources
- ✅ **Automated file saving** with timestamps
- ✅ **Executive briefings** combining current + historical data
- ✅ **Crisis monitoring** with severity assessment
- ✅ **Content strategy** using your local image library
- ✅ **Market intelligence** reports

### **Your Competitive Edge:**

- 🏆 **Local image storage** (most users don't have this)
- 🏆 **Historical archives** for trend analysis
- 🏆 **Professional automation** via Windows Task Scheduler
- 🏆 **Comprehensive data sources** (automated + real-time)

---

## 🎉 **Success Confirmation**

**You'll know it's working when:**

1. ✅ Extension shows "Connected"
2. ✅ AI chat recognizes 2 news tools
3. ✅ Headlines fetch successfully
4. ✅ Files save to your directory
5. ✅ AI provides professional analysis

**Now you have enterprise-grade news intelligence!** 🌍📰🚀

---

**Last Updated**: August 25, 2025  
**Server URL**: <http://localhost:3006/sse>  
**Status**: Ready for connection
