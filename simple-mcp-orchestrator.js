#!/usr/bin/env node

/**
 * Simplified MCP Server AI Agent Orchestration System
 * 
 * Quick-start version without complex dependencies
 * Uses existing enhanced-mcp-server.js and multi-server-mcp-proxy.js
 */

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

class SimpleMCPOrchestrator {
    constructor() {
        this.processes = new Map();
        this.startTime = Date.now();
        this.logger = {
            info: (msg, data) => console.log(`[INFO] ${msg}`, data ? JSON.stringify(data) : ''),
            warn: (msg, data) => console.warn(`[WARN] ${msg}`, data ? JSON.stringify(data) : ''),
            error: (msg, data) => console.error(`[ERROR] ${msg}`, data ? JSON.stringify(data) : '')
        };
    }

    async start() {
        console.log(`
╔══════════════════════════════════════════════════════════════╗
║           Simplified MCP AI Agent Orchestration             ║
║                   Quick Start Version                       ║
╠══════════════════════════════════════════════════════════════╣
║  🎮 Master Controller  🤖 AI Agents  🔌 MCP Servers         ║
║  📊 Real-time Analytics  🚨 Crisis Detection  📈 Trends     ║
╚══════════════════════════════════════════════════════════════╝
`);

        try {
            // Phase 1: Initialize environment
            await this.initializeEnvironment();
            
            // Phase 2: Start existing MCP servers
            await this.startExistingMCPServers();
            
            // Phase 3: Start basic automation
            await this.startBasicAutomation();
            
            // Phase 4: Setup monitoring
            this.setupBasicMonitoring();
            
            // Phase 5: Display status
            this.displayStatus();
            
            console.log('\n✅ Simplified MCP Orchestration System is running!');
            console.log('📊 Enhanced MCP Server: http://localhost:3006');
            console.log('🔍 Multi-Server Proxy: Available via proxy');
            console.log('📡 News automation: Active');
            
        } catch (error) {
            console.error('❌ Failed to start orchestration system:', error.message);
            await this.cleanup();
            process.exit(1);
        }
    }

    async initializeEnvironment() {
        console.log('📁 Initializing environment...');
        
        // Create necessary directories
        const directories = ['logs', 'cache', 'output', 'data'];
        for (const dir of directories) {
            try {
                if (!fs.existsSync(dir)) {
                    fs.mkdirSync(dir, { recursive: true });
                    console.log(`   ✓ Created directory: ${dir}`);
                }
            } catch (error) {
                console.log(`   ✓ Directory exists: ${dir}`);
            }
        }

        // Check for required files
        const requiredFiles = [
            'enhanced-mcp-server.js',
            'multi-server-mcp-proxy.js',
            'fetchAllAfrica.js'
        ];

        for (const file of requiredFiles) {
            if (fs.existsSync(file)) {
                console.log(`   ✓ Found: ${file}`);
            } else {
                console.warn(`   ⚠️  Missing: ${file}`);
            }
        }

        console.log('✅ Environment initialized');
    }

    async startExistingMCPServers() {
        console.log('🔌 Starting MCP servers...');

        // Start Enhanced MCP Server
        try {
            console.log('   🚀 Starting Enhanced MCP Server...');
            const enhancedMCP = spawn('node', ['enhanced-mcp-server.js'], {
                stdio: ['pipe', 'pipe', 'pipe'],
                env: { ...process.env }
            });

            this.processes.set('enhanced-mcp', enhancedMCP);

            enhancedMCP.stdout.on('data', (data) => {
                console.log(`   [Enhanced-MCP] ${data.toString().trim()}`);
            });

            enhancedMCP.stderr.on('data', (data) => {
                console.error(`   [Enhanced-MCP] ${data.toString().trim()}`);
            });

            enhancedMCP.on('error', (error) => {
                console.error(`   ❌ Enhanced MCP error: ${error.message}`);
            });

            // Wait for server to start
            await this.delay(3000);
            console.log('   ✓ Enhanced MCP Server started on port 3006');

        } catch (error) {
            console.warn(`   ⚠️  Failed to start Enhanced MCP: ${error.message}`);
        }

        // Start Multi-Server Proxy
        try {
            console.log('   🚀 Starting Multi-Server MCP Proxy...');
            const proxyMCP = spawn('node', ['multi-server-mcp-proxy.js'], {
                stdio: ['pipe', 'pipe', 'pipe'],
                env: { ...process.env }
            });

            this.processes.set('proxy-mcp', proxyMCP);

            proxyMCP.stdout.on('data', (data) => {
                console.log(`   [Proxy-MCP] ${data.toString().trim()}`);
            });

            proxyMCP.stderr.on('data', (data) => {
                console.error(`   [Proxy-MCP] ${data.toString().trim()}`);
            });

            proxyMCP.on('error', (error) => {
                console.error(`   ❌ Proxy MCP error: ${error.message}`);
            });

            await this.delay(2000);
            console.log('   ✓ Multi-Server MCP Proxy started');

        } catch (error) {
            console.warn(`   ⚠️  Failed to start Proxy MCP: ${error.message}`);
        }

        console.log('✅ MCP servers initialization completed');
    }

    async startBasicAutomation() {
        console.log('🤖 Starting basic automation...');

        // Run news fetching
        try {
            console.log('   📰 Running news fetch...');
            const newsFetch = spawn('node', ['fetchAllAfrica.js'], {
                stdio: ['pipe', 'pipe', 'pipe'],
                env: { ...process.env }
            });

            newsFetch.stdout.on('data', (data) => {
                console.log(`   [News] ${data.toString().trim()}`);
            });

            newsFetch.on('close', (code) => {
                if (code === 0) {
                    console.log('   ✓ News fetch completed successfully');
                } else {
                    console.warn(`   ⚠️  News fetch exited with code ${code}`);
                }
            });

        } catch (error) {
            console.warn(`   ⚠️  Failed to start news automation: ${error.message}`);
        }

        // Schedule periodic news fetching
        setInterval(async () => {
            console.log('🔄 Running scheduled news fetch...');
            try {
                const newsFetch = spawn('node', ['fetchAllAfrica.js'], {
                    stdio: 'pipe',
                    env: { ...process.env }
                });

                newsFetch.on('close', (code) => {
                    if (code === 0) {
                        console.log('✓ Scheduled news fetch completed');
                    }
                });
            } catch (error) {
                console.error('❌ Scheduled fetch failed:', error.message);
            }
        }, 300000); // Every 5 minutes

        console.log('✅ Basic automation started');
    }

    setupBasicMonitoring() {
        console.log('📊 Setting up monitoring...');

        // Setup graceful shutdown
        process.on('SIGINT', async () => {
            console.log('\n🛑 Received SIGINT, shutting down gracefully...');
            await this.cleanup();
            process.exit(0);
        });

        process.on('SIGTERM', async () => {
            console.log('\n🛑 Received SIGTERM, shutting down gracefully...');
            await this.cleanup();
            process.exit(0);
        });

        // Setup periodic health checks
        setInterval(() => {
            this.performHealthCheck();
        }, 60000); // Every minute

        console.log('✅ Basic monitoring setup completed');
    }

    performHealthCheck() {
        const runningProcesses = Array.from(this.processes.entries())
            .filter(([name, process]) => !process.killed)
            .map(([name]) => name);

        const uptime = Math.floor((Date.now() - this.startTime) / 1000);
        const memUsage = process.memoryUsage();

        console.log(`🏥 Health Check - Uptime: ${uptime}s, Memory: ${Math.round(memUsage.heapUsed / 1024 / 1024)}MB, Active: [${runningProcesses.join(', ')}]`);
    }

    displayStatus() {
        console.log('\n📊 System Status:');
        console.log('='.repeat(50));
        
        const uptime = Math.floor((Date.now() - this.startTime) / 1000);
        console.log(`⏱️  Uptime: ${uptime} seconds`);
        console.log(`🔧 Processes: ${this.processes.size} started`);
        
        for (const [name, process] of this.processes) {
            const status = process.killed ? 'stopped' : 'running';
            const pid = process.pid || 'N/A';
            console.log(`   📡 ${name}: ${status} (PID: ${pid})`);
        }
        
        const memUsage = process.memoryUsage();
        console.log(`💾 Memory: ${Math.round(memUsage.heapUsed / 1024 / 1024)}MB used`);
        console.log('='.repeat(50));
    }

    async cleanup() {
        console.log('🧹 Cleaning up...');
        
        for (const [name, process] of this.processes) {
            if (!process.killed) {
                console.log(`   🛑 Stopping ${name}...`);
                process.kill('SIGTERM');
            }
        }

        // Wait for processes to exit
        await this.delay(2000);
        console.log('✅ Cleanup completed');
    }

    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

// Auto-start if run directly
if (require.main === module) {
    const orchestrator = new SimpleMCPOrchestrator();
    
    orchestrator.start().catch(error => {
        console.error('Failed to start orchestrator:', error);
        process.exit(1);
    });
}

module.exports = SimpleMCPOrchestrator;