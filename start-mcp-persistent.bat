@echo off
title MCP AI Agent Orchestration - Persistent Mode

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║           MCP AI Agent Orchestration - Persistent           ║
echo ║                      Quick Start                             ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

echo [INFO] Starting MCP Server in persistent mode...
echo [INFO] Press Ctrl+C to stop the server
echo.

REM Kill any existing node processes on port 3006
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3006') do (
    echo [INFO] Stopping existing process on port 3006...
    taskkill /F /PID %%a >nul 2>&1
)

echo [INFO] Starting Minimal MCP Server...
echo [INFO] Server will be available at: http://localhost:3006
echo [INFO] Health check: http://localhost:3006/health
echo [INFO] SSE endpoint: http://localhost:3006/sse
echo.

REM Start the server and keep it running
:START
node minimal-mcp-server.js
echo.
echo [WARN] Server stopped unexpectedly. Restarting in 5 seconds...
echo [INFO] Press Ctrl+C to exit completely
timeout /t 5 /nobreak >nul
goto START