# Universal MCP Configuration for News Intelligence Server

## Server Information

- **Server Name**: News Intelligence MCP Server
- **URL**: <http://localhost:3006>
- **Protocol**: HTTP/SSE
- **Port**: 3006

## MCP Endpoints

- **Health Check**: `GET http://localhost:3006/health`
- **MCP Protocol**: `POST http://localhost:3006/mcp`
- **Server-Sent Events**: `GET http://localhost:3006/sse`
- **News API**: `GET http://localhost:3006/api/headlines`

## Available Tools

1. **fetch_news** - Fetch latest African news headlines
2. **save_headlines** - Save headlines to file
3. **read_file** - Read news files and archives
4. **news_analysis** - Analyze news content and trends

## Connection Configuration

### For Qoder/AI Assistants

```json
{
  "server": "http://localhost:3006",
  "protocol": "http",
  "capabilities": ["fetch_news", "save_headlines", "read_file"]
}
```

### For Browser Extensions

- **URL**: `http://localhost:3006`
- **Connection Type**: Direct HTTP

### For VS Code

- **MCP Config**: `.vscode/mcp.json` (already configured)
- **Settings**: `chat.mcp.enabled: true`

## Usage Examples

### Direct API Calls

```bash
# Check server health
curl http://localhost:3006/health

# Fetch news via MCP
curl -X POST http://localhost:3006/mcp \
  -H "Content-Type: application/json" \
  -d '{"method": "tools/call", "params": {"name": "fetch_news"}}'
```

### AI Assistant Prompts

```text
Use the news intelligence tools to fetch latest headlines
Analyze current African news trends
Save today's headlines to archive
```

## Troubleshooting

1. **Server Not Responding**:

   ```powershell
   # Check if server is running
   curl http://localhost:3006/health
   
   # Restart server if needed
   cd "c:\Users\tjd20.LAPTOP-PCMC2SUO\news"
   node minimal-mcp-server.js
   ```

2. **Port Conflicts**:

   ```powershell
   # Check port usage
   netstat -ano | findstr :3006
   ```

3. **Tool Discovery**:
   - Restart Qoder/AI assistant
   - Clear tool cache if available
   - Verify server is healthy before connecting
