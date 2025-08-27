# MCP Server Connection Troubleshooting Guide

## Problem Solved ✅

Your MCP server connection issue has been resolved! The server is now running on the correct port (3006) and supporting SSE (Server-Sent Events) protocol.

## What Was Fixed

1. **Port Mismatch**: Changed from port 9010 to 3006 in `mcp.config.json`
2. **Protocol Support**: Created a proper MCP server (`mcp-server.js`) that supports SSE connections
3. **Missing Dependencies**: Added Express.js and CORS support
4. **Server Implementation**: Built a complete MCP server with JSON-RPC support

## Current Server Status

- **Server URL**: `http://localhost:3006`
- **SSE Endpoint**: `http://localhost:3006/sse`
- **MCP Endpoint**: `http://localhost:3006/mcp`
- **Health Check**: `http://localhost:3006/health`
- **Status**: ✅ Running

## Available MCP Tools

1. **fetch_news**: Fetch latest news headlines from AllAfrica
2. **save_headlines**: Save headlines to a text file

## How to Use

### Starting the Server

```powershell
# Option 1: Use npm script
npm run mcp-server

# Option 2: Use PowerShell script
.\start-mcp-server.ps1

# Option 3: Direct node command
node mcp-server.js
```

### Stopping the Server

Press `Ctrl+C` in the terminal where the server is running.

### Testing the Connection

```powershell
# Health check
curl http://localhost:3006/health

# Test SSE endpoint (should stay connected)
curl http://localhost:3006/sse
```

## Client Configuration

Make sure your MCP client is configured to connect to:

- **URL**: `http://localhost:3006/sse`
- **Protocol**: SSE (Server-Sent Events)
- **Connection Type**: HTTP

## Common Issues and Solutions

### Issue 1: Port Already in Use

**Symptoms**: Error "EADDRINUSE" or "Port 3006 is already in use"
**Solution**:

1. Check what's using the port: `netstat -an | findstr :3006`
2. Kill the process or choose a different port

### Issue 2: WebSocket vs SSE Mismatch

**Symptoms**: "Plugin websocket does not support URI"
**Solution**: ✅ Already fixed - server now supports SSE protocol

### Issue 3: CORS Issues

**Symptoms**: Cross-origin request blocked
**Solution**: ✅ Already fixed - CORS is properly configured

### Issue 4: Node.js Not Found

**Symptoms**: "node is not recognized as an internal or external command"
**Solution**: Install Node.js from <https://nodejs.org/>

### Issue 5: Dependencies Missing

**Symptoms**: Module not found errors
**Solution**: Run `npm install` to install dependencies

## File Structure

```text
news/
├── mcp-server.js           # Main MCP server (NEW)
├── start-mcp-server.ps1    # Server startup script (NEW)
├── mcp.config.json         # Updated configuration
├── package.json            # Updated with new dependencies
├── fetchAllAfrica.js       # Original news fetcher
└── README-MCP-TROUBLESHOOTING.md  # This file
```

## Testing the MCP Tools

Once connected, you can test the MCP tools:

### Fetch News Headlines

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "fetch_news",
    "arguments": { "limit": 5 }
  },
  "id": 1
}
```

### Save Headlines to File

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "save_headlines",
    "arguments": { "filename": "latest-news.txt" }
  },
  "id": 2
}
```

## Server Logs

The server provides detailed logging:

- Connection establishments
- Tool calls
- Errors and responses
- SSE events

Monitor the terminal where you started the server to see real-time activity.

## Need Help?

If you encounter any issues:

1. Check the server logs in the terminal
2. Verify the server is running: `curl http://localhost:3006/health`
3. Ensure your client is connecting to the correct SSE endpoint
4. Check Windows firewall settings if needed
5. Restart the server if necessary

## Advanced Configuration

You can modify `mcp-server.js` to:

- Change the port number
- Add more news sources
- Implement additional MCP tools
- Customize CORS settings
- Add authentication if needed

---

**Last Updated**: August 25, 2025
**Server Version**: 1.0.0
**Protocol**: MCP 2024-11-05
