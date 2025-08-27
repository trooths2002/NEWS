# 📁 Geopolitical Intelligence System - Folder Paths Reference

## 🏠 Main Workspace Directory

```text
c:\Users\tjd20.LAPTOP-PCMC2SUO\news
```

## 📊 Data Output Locations

### 📰 News Headlines

```text
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\allafrica-headlines.txt
```

- **Content**: Latest AllAfrica headlines collected daily
- **Updated**: Every morning at 8:00 AM
- **Format**: Plain text, one headline per line

### 🖼️ Image Collection

```text
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\trending-intelligence\images\
```

**Subdirectories:**

- `headlines\` - Images scraped from news articles
- `regional\african\` - African geopolitical images
- `regional\caribbean\` - Caribbean region images  
- `regional\afro-latino\` - Afro-Latino region images

**Metadata Files:**

```text
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\trending-intelligence\images\image-metadata-2025-08-26.json
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\trending-intelligence\images\enhanced-metadata-2025-08-26.json
```

### 📋 Intelligence Reports

```text
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\trending-intelligence\
```

- **Content**: Comprehensive geopolitical analysis reports
- **Format**: Structured intelligence summaries
- **Regional Focus**: African, Caribbean, Afro-Latino geopolitics

### 📜 System Logs

```text
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\logs\
```

**Log Files:**

- `automation-YYYY-MM-DD.log` - Daily automation execution logs
- `automation-errors-YYYY-MM-DD.log` - Error tracking logs
- `mcp-server.log` - MCP server operational logs

## 🔧 Configuration Files

### 🌍 Environment Configuration

```text
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\.env
```

- **Contains**: API keys, configuration settings
- **Template**: `.env.template` (safe reference copy)

### 📦 Package Configuration

```text
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\package.json
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\package-lock.json
```

### 🔗 MCP Configuration

```text
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\production-config.json
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\mcp.config.json
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\multi-server-mcp-config.json
```

## 🤖 Automation Scripts

### 🌅 Daily 8 AM Automation

```text
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\Start-8AM-Automation.ps1
```

- **Purpose**: Main daily automation workflow
- **Schedule**: Runs every day at 8:00 AM
- **Task Name**: "GeopoliticalIntelligence-8AM-Daily"

### 🔧 Setup Scripts

```text
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\Setup-8AM-Scheduler.ps1
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\setup-automation.ps1
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\setup-advanced-automation.ps1
```

### 🧪 Testing Scripts

```text
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\test-simple-no-api.ps1
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\Show-ImageExamples.ps1
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\Test-GeopoliticalIntelligence.ps1
```

## 🌐 Core Server Files

### 📡 MCP Geopolitical Intelligence Server

```text
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\geopolitical-intelligence-server.js
```

- **Port**: 3007
- **Features**: Image scraping, news analysis, intelligence reports
- **Version**: 2.1.0 (with enhanced image capabilities)

### 📊 News Collection

```text
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\fetchAllAfrica.js
```

- **Purpose**: Collects AllAfrica news headlines
- **Output**: allafrica-headlines.txt

### 🔗 Additional MCP Servers

```text
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\enhanced-mcp-server.js
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\simple-mcp-orchestrator.js
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\start-mcp-orchestrator.js
```

## 📚 Documentation

### 📖 Guides and Setup

```text
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\COMPREHENSIVE-GEOPOLITICAL-INTELLIGENCE-SYSTEM.md
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\IMAGE_SCRAPING_IMPLEMENTATION_COMPLETE.md
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\PRODUCTION-DEPLOYMENT-GUIDE.md
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\GOOGLE_CSE_SETUP_GUIDE.md
```

### 🔧 Configuration Guides

```text
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\MCP-ORCHESTRATOR-ARCHITECTURE.md
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\OPTIMIZED-MCP-CONFIG.md
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\WORKFLOW-GUIDE.md
```

## 📦 Dependencies

### 📚 Node Modules

```text
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\node_modules\
```

- **Contains**: All Node.js dependencies
- **Key Dependencies**: express, cheerio, node-fetch, dotenv

## 🗃️ Archive and Cache

### 📁 Archive Directory

```text
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\archives\
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\news-archive\
```

### 💾 Cache Directory

```text
c:\Users\tjd20.LAPTOP-PCMC2SUO\news\cache\
```

## 🎯 Quick Access Commands

### 📂 Navigate to Main Directory

```powershell
cd "c:\Users\tjd20.LAPTOP-PCMC2SUO\news"
```

### 📊 View Latest Headlines

```powershell
Get-Content "c:\Users\tjd20.LAPTOP-PCMC2SUO\news\allafrica-headlines.txt"
```

### 🖼️ Check Image Collection

```powershell
Get-ChildItem "c:\Users\tjd20.LAPTOP-PCMC2SUO\news\trending-intelligence\images\headlines" -File
```

### 📜 View Automation Logs

```powershell
Get-Content "c:\Users\tjd20.LAPTOP-PCMC2SUO\news\logs\automation-$(Get-Date -Format 'yyyy-MM-dd').log"
```

### 🔍 Check Scheduled Task Status

```powershell
Get-ScheduledTask -TaskName "GeopoliticalIntelligence-8AM-Daily"
```

### ▶️ Test Automation Now

```powershell
Start-ScheduledTask -TaskName "GeopoliticalIntelligence-8AM-Daily"
```

## 📅 Automation Schedule Summary


**Task Name**: GeopoliticalIntelligence-8AM-Daily
**Schedule**: Daily at 8:00 AM  
**Next Run**: Tomorrow (8/27/2025) at 8:00:00 AM
**Status**: Ready

**What Runs Automatically:**

1. 🚀 Start MCP Geopolitical Intelligence Server (Port 3007)
2. 📰 Collect latest AllAfrica news headlines
3. 🖼️ Scrape related images using non-API methods
4. 🧠 Generate comprehensive intelligence analysis
5. 📊 Create trending summaries and reports
6. 🔔 Send completion notifications
7. 📝 Log all activities for review

**Output Verification:**

- Headlines saved to: `allafrica-headlines.txt`
- Images saved to: `trending-intelligence\images\`
- Logs saved to: `logs\automation-YYYY-MM-DD.log`
- Intelligence reports in: `trending-intelligence\`

---

**🎉 Your automation is fully configured and will run tomorrow morning at 8:00 AM!**
