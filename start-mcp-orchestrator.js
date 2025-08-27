#!/usr/bin/env node

/**
 * MCP Server AI Agent Orchestration Startup Script
 * 
 * This script initializes and starts the complete MCP orchestration system
 * including the Master Controller, AI Agents, and MCP Servers
 */

const MasterController = require('./src/orchestrator/master-controller');
const { spawn } = require('child_process');
const fs = require('fs').promises;
const path = require('path');

class MCPOrchestrator {
    constructor() {
        this.masterController = null;
        this.processes = new Map();
        this.config = {
            masterController: {
                port: process.env.ORCHESTRATOR_PORT || 3000,
                maxAgents: 10,
                healthCheckInterval: 30000
            },
            agents: {
                autoStart: ['news-fetcher', 'intelligence', 'monitor'],
                configuration: {
                    'news-fetcher': {
                        sources: [
                            {
                                name: 'AllAfrica Latest',
                                url: 'https://allafrica.com/tools/headlines/rdf/latest/headlines.rdf',
                                category: 'general',
                                priority: 1,
                                enabled: true
                            }
                        ],
                        fetchInterval: 300000, // 5 minutes
                        autoMonitor: true
                    },
                    'intelligence': {
                        analysisTypes: ['sentiment', 'trends', 'crisis'],
                        crisisThreshold: 0.3
                    }
                }
            },
            mcpServers: {
                autoStart: ['news-mcp', 'filesystem-mcp'],
                configuration: {
                    'news-mcp': {
                        port: 3006,
                        endpoint: '/mcp'
                    },
                    'filesystem-mcp': {
                        command: 'npx',
                        args: ['-y', '@modelcontextprotocol/server-filesystem', process.cwd()]
                    }
                }
            }
        };
    }

    async start() {
        console.log('🚀 Starting MCP Server AI Agent Orchestration System...');
        console.log('='.repeat(60));

        try {
            // Phase 1: Initialize environment
            await this.initializeEnvironment();
            
            // Phase 2: Start Master Controller
            await this.startMasterController();
            
            // Phase 3: Start MCP Servers
            await this.startMCPServers();
            
            // Phase 4: Start AI Agents
            await this.startAIAgents();
            
            // Phase 5: Setup monitoring and health checks
            await this.setupMonitoring();
            
            // Phase 6: Display system status
            await this.displaySystemStatus();
            
            console.log('✅ MCP Orchestration System started successfully!');
            console.log('📊 Dashboard available at: http://localhost:3000/status');
            console.log('🔍 Health check: http://localhost:3000/health');
            console.log('📡 Events stream: http://localhost:3000/events');
            
        } catch (error) {
            console.error('❌ Failed to start MCP Orchestration System:', error.message);
            await this.cleanup();
            process.exit(1);
        }
    }

    async initializeEnvironment() {
        console.log('📁 Initializing environment...');
        
        // Create necessary directories
        const directories = [
            'logs',
            'cache',
            'output',
            'temp',
            'data'
        ];

        for (const dir of directories) {
            try {
                await fs.mkdir(dir, { recursive: true });
                console.log(`   ✓ Created directory: ${dir}`);
            } catch (error) {
                console.log(`   ✓ Directory exists: ${dir}`);
            }
        }

        // Validate dependencies
        console.log('   📦 Validating dependencies...');
        const requiredModules = [
            '@modelcontextprotocol/sdk',
            'express',
            'cors',
            'winston',
            'rss-parser',
            'axios'
        ];

        for (const module of requiredModules) {
            try {
                require.resolve(module);
                console.log(`   ✓ ${module}`);
            } catch (error) {
                throw new Error(`Missing required module: ${module}. Run 'npm install' first.`);
            }
        }

        // Check system requirements
        console.log('   🔧 Checking system requirements...');
        const nodeVersion = process.version;
        const requiredVersion = 'v18.0.0';
        
        if (nodeVersion < requiredVersion) {
            console.warn(`   ⚠️  Node.js ${requiredVersion}+ recommended (current: ${nodeVersion})`);
        } else {
            console.log(`   ✓ Node.js version: ${nodeVersion}`);
        }

        console.log('✅ Environment initialized');
    }

    async startMasterController() {
        console.log('🎮 Starting Master Controller...');
        
        this.masterController = new MasterController(this.config.masterController);
        
        await this.masterController.start();
        
        console.log(`✅ Master Controller started on port ${this.config.masterController.port}`);
    }

    async startMCPServers() {
        console.log('🔌 Starting MCP Servers...');
        
        for (const serverId of this.config.mcpServers.autoStart) {
            try {
                console.log(`   🚀 Starting ${serverId}...`);
                
                if (serverId === 'news-mcp') {
                    // Start the enhanced MCP server
                    const mcpProcess = spawn('node', ['enhanced-mcp-server.js'], {
                        stdio: ['pipe', 'pipe', 'pipe'],
                        env: { ...process.env }
                    });
                    
                    this.processes.set(serverId, mcpProcess);
                    
                    mcpProcess.stdout.on('data', (data) => {
                        console.log(`   [${serverId}] ${data.toString().trim()}`);
                    });
                    
                    mcpProcess.stderr.on('data', (data) => {
                        console.error(`   [${serverId}] ${data.toString().trim()}`);
                    });
                    
                    // Wait for server to start
                    await this.delay(3000);
                    
                } else if (serverId === 'filesystem-mcp') {
                    const config = this.config.mcpServers.configuration[serverId];
                    const mcpProcess = spawn(config.command, config.args, {
                        stdio: ['pipe', 'pipe', 'pipe'],
                        env: { ...process.env }
                    });
                    
                    this.processes.set(serverId, mcpProcess);
                    
                    mcpProcess.on('error', (error) => {
                        console.warn(`   ⚠️  ${serverId} error: ${error.message}`);
                    });
                }
                
                console.log(`   ✓ ${serverId} started`);
                
            } catch (error) {
                console.warn(`   ⚠️  Failed to start ${serverId}: ${error.message}`);
            }
        }
        
        console.log('✅ MCP Servers initialization completed');
    }

    async startAIAgents() {
        console.log('🤖 Starting AI Agents...');
        
        for (const agentId of this.config.agents.autoStart) {
            try {
                console.log(`   🚀 Starting ${agentId} agent...`);
                
                const agentConfig = this.config.agents.configuration[agentId] || {};
                
                await this.masterController.startAgent(agentId, agentConfig);
                
                console.log(`   ✓ ${agentId} agent started`);
                
            } catch (error) {
                console.warn(`   ⚠️  Failed to start ${agentId} agent: ${error.message}`);
            }
        }
        
        console.log('✅ AI Agents initialization completed');
    }

    async setupMonitoring() {
        console.log('📊 Setting up monitoring...');
        
        // Setup process monitoring
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

        process.on('uncaughtException', (error) => {
            console.error('💥 Uncaught Exception:', error);
            this.cleanup().then(() => process.exit(1));
        });

        process.on('unhandledRejection', (reason, promise) => {
            console.error('💥 Unhandled Rejection at:', promise, 'reason:', reason);
        });

        // Setup periodic health checks
        setInterval(async () => {
            try {
                const health = await this.performSystemHealthCheck();
                if (!health.healthy) {
                    console.warn('⚠️  System health check failed:', health.issues);
                }
            } catch (error) {
                console.error('❌ Health check error:', error.message);
            }
        }, 60000); // Every minute

        console.log('✅ Monitoring setup completed');
    }

    async displaySystemStatus() {
        console.log('\n📊 System Status:');
        console.log('='.repeat(40));
        
        // Master Controller status
        const controllerStatus = this.masterController.state;
        console.log(`🎮 Master Controller: ${controllerStatus.status} (uptime: ${this.formatUptime(Date.now() - controllerStatus.startTime)})`);
        console.log(`   🤖 Active Agents: ${controllerStatus.activeAgents}`);
        console.log(`   📝 Tasks: ${controllerStatus.completedTasks} completed, ${controllerStatus.failedTasks} failed`);
        
        // MCP Servers status
        console.log(`🔌 MCP Servers: ${this.processes.size} running`);
        for (const [serverId, process] of this.processes) {
            const status = process.killed ? 'stopped' : 'running';
            console.log(`   📡 ${serverId}: ${status}`);
        }
        
        // System resources
        const memUsage = process.memoryUsage();
        console.log(`💾 Memory Usage: ${Math.round(memUsage.heapUsed / 1024 / 1024)}MB`);
        console.log(`⚡ CPU Usage: ${JSON.stringify(process.cpuUsage())}`);
        
        console.log('='.repeat(40));
    }

    async performSystemHealthCheck() {
        const issues = [];
        let healthy = true;

        try {
            // Check Master Controller
            if (!this.masterController || this.masterController.state.status !== 'running') {
                issues.push('Master Controller not running');
                healthy = false;
            }

            // Check MCP Server processes
            let runningServers = 0;
            for (const [serverId, process] of this.processes) {
                if (!process.killed) {
                    runningServers++;
                }
            }
            
            if (runningServers === 0) {
                issues.push('No MCP servers running');
                healthy = false;
            }

            // Check memory usage
            const memUsage = process.memoryUsage();
            const memUsageMB = memUsage.heapUsed / 1024 / 1024;
            if (memUsageMB > 1000) { // 1GB threshold
                issues.push(`High memory usage: ${Math.round(memUsageMB)}MB`);
            }

        } catch (error) {
            issues.push(`Health check error: ${error.message}`);
            healthy = false;
        }

        return { healthy, issues };
    }

    async cleanup() {
        console.log('🧹 Cleaning up...');
        
        try {
            // Stop Master Controller
            if (this.masterController) {
                await this.masterController.stop();
                console.log('   ✓ Master Controller stopped');
            }

            // Stop MCP Server processes
            for (const [serverId, process] of this.processes) {
                if (!process.killed) {
                    process.kill('SIGTERM');
                    console.log(`   ✓ ${serverId} stopped`);
                }
            }

            // Wait for processes to exit
            await this.delay(2000);

        } catch (error) {
            console.error('Error during cleanup:', error.message);
        }
    }

    formatUptime(ms) {
        const seconds = Math.floor(ms / 1000);
        const minutes = Math.floor(seconds / 60);
        const hours = Math.floor(minutes / 60);
        
        if (hours > 0) {
            return `${hours}h ${minutes % 60}m`;
        } else if (minutes > 0) {
            return `${minutes}m ${seconds % 60}s`;
        } else {
            return `${seconds}s`;
        }
    }

    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

// Start the orchestrator if run directly
if (require.main === module) {
    const orchestrator = new MCPOrchestrator();
    
    console.log(`
╔══════════════════════════════════════════════════════════════╗
║                MCP Server AI Agent Orchestration             ║
║                      v1.0.0 - Production Ready              ║
╠══════════════════════════════════════════════════════════════╣
║  🎮 Master Controller  🤖 AI Agents  🔌 MCP Servers         ║
║  📊 Real-time Analytics  🚨 Crisis Detection  📈 Trends     ║
╚══════════════════════════════════════════════════════════════╝
`);
    
    orchestrator.start().catch(error => {
        console.error('Failed to start orchestrator:', error);
        process.exit(1);
    });
}

module.exports = MCPOrchestrator;