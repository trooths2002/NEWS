@echo off
title MCP AI Agent Orchestration - Quick Start

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║           MCP AI Agent Orchestration - Quick Start          ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

echo Starting MCP orchestration system...
echo.

REM Try the simplified orchestrator first
echo [1/3] Testing simplified orchestrator...
node simple-mcp-orchestrator.js
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [2/3] Simplified orchestrator failed, trying PowerShell approach...
    powershell -ExecutionPolicy Bypass -File quick-start-orchestrator.ps1
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo [3/3] PowerShell approach failed, trying direct server start...
        start "Enhanced MCP Server" node enhanced-mcp-server.js
        timeout /t 3 /nobreak >nul
        start "News Fetch" node fetchAllAfrica.js
        echo.
        echo ✅ Basic components started manually
        echo 📊 Enhanced MCP Server should be running on http://localhost:3006
        echo 📰 News fetch initiated
        echo.
        echo Press any key to exit...
        pause >nul
    )
) else (
    echo ✅ Simplified orchestrator started successfully!
    echo Press Ctrl+C to stop the system
    pause
)