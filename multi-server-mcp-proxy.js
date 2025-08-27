#!/usr/bin/env node

const express = require('express');
const cors = require('cors');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

class MultiServerMCPProxy {
    constructor() {
        this.app = express();
        this.servers = new Map();
        this.tools = new Map();
        this.port = 3006;
        
        // Setup middleware
        this.app.use(cors({
            origin: '*',
            methods: ['GET', 'POST', 'OPTIONS'],
            headers: ['Content-Type', 'Accept', 'Authorization']
        }));
        this.app.use(express.json());
        
        this.setupRoutes();
        this.initializeServers();
    }

    setupRoutes() {
        // Health check
        this.app.get('/health', (req, res) => {
            const serverStatus = {};
            for (const [name, server] of this.servers) {
                serverStatus[name] = server.status || 'unknown';
            }
            
            res.json({
                status: 'healthy',
                servers: serverStatus,
                tools: Array.from(this.tools.keys()),
                totalTools: this.tools.size,
                endpoint: 'http://localhost:3006/sse',
                timestamp: new Date().toISOString()
            });
        });

        // SSE endpoint for MCP SuperAssistant
        this.app.get('/sse', (req, res) => {
            res.writeHead(200, {
                'Content-Type': 'text/event-stream',
                'Cache-Control': 'no-cache',
                'Connection': 'keep-alive',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Accept, Authorization'
            });

            // Send initial connection message
            res.write(`data: ${JSON.stringify({
                type: 'connection',
                message: 'Connected to Multi-Server MCP Proxy',
                servers: Array.from(this.servers.keys()),
                tools: Array.from(this.tools.keys())
            })}\n\n`);

            // Keep connection alive
            const keepAlive = setInterval(() => {
                res.write(`data: ${JSON.stringify({
                    type: 'ping',
                    timestamp: Date.now()
                })}\n\n`);
            }, 30000);

            req.on('close', () => {
                clearInterval(keepAlive);
            });
        });

        // MCP protocol endpoint
        this.app.post('/mcp', async (req, res) => {
            try {
                const response = await this.handleMCPRequest(req.body);
                res.json(response);
            } catch (error) {
                res.status(500).json({
                    jsonrpc: '2.0',
                    error: {
                        code: -32603,
                        message: error.message
                    },
                    id: req.body.id
                });
            }
        });
    }

    async initializeServers() {
        const configs = {
            'news-fetcher': {
                command: 'node',
                args: ['simple-mcp-server.js'],
                cwd: process.cwd()
            },
            'filesystem': {
                command: 'npx',
                args: ['-y', '@modelcontextprotocol/server-filesystem', process.cwd()]
            },
            'sqlite': {
                command: 'npx',
                args: ['-y', '@modelcontextprotocol/server-sqlite', '--db-path', path.join(process.cwd(), 'news-intelligence.db')]
            }
        };

        for (const [name, config] of Object.entries(configs)) {
            try {
                console.log(`🚀 Starting ${name} server...`);
                await this.startServer(name, config);
            } catch (error) {
                console.warn(`⚠️ Failed to start ${name}: ${error.message}`);
            }
        }

        // Initialize built-in news tools
        this.tools.set('fetch_news', {
            server: 'news-fetcher',
            name: 'fetch_news',
            description: 'Fetch latest news headlines from AllAfrica',
            inputSchema: {
                type: 'object',
                properties: {
                    limit: {
                        type: 'number',
                        description: 'Number of headlines to fetch (default: 10)',
                        default: 10
                    }
                }
            }
        });

        this.tools.set('save_headlines', {
            server: 'news-fetcher', 
            name: 'save_headlines',
            description: 'Save headlines to a text file',
            inputSchema: {
                type: 'object',
                properties: {
                    filename: {
                        type: 'string',
                        description: 'Filename to save headlines to',
                        default: 'headlines.txt'
                    }
                }
            }
        });

        console.log(`✅ Multi-Server MCP Proxy ready with ${this.tools.size} tools`);
    }

    async startServer(name, config) {
        return new Promise((resolve, reject) => {
            const server = spawn(config.command, config.args, {
                cwd: config.cwd || process.cwd(),
                stdio: ['pipe', 'pipe', 'pipe'],
                env: { ...process.env, ...config.env }
            });

            server.status = 'starting';
            this.servers.set(name, server);

            server.on('spawn', () => {
                server.status = 'running';
                console.log(`✅ ${name} server started`);
                resolve(server);
            });

            server.on('error', (error) => {
                server.status = 'error';
                console.error(`❌ ${name} server error:`, error.message);
                reject(error);
            });

            server.on('exit', (code) => {
                server.status = 'stopped';
                console.log(`🔄 ${name} server exited with code ${code}`);
            });

            // Set timeout for server startup
            setTimeout(() => {
                if (server.status === 'starting') {
                    server.status = 'running';
                    resolve(server);
                }
            }, 3000);
        });
    }

    async handleMCPRequest(request) {
        const { method, params, id } = request;

        switch (method) {
            case 'initialize':
                return {
                    jsonrpc: '2.0',
                    result: {
                        protocolVersion: '2024-11-05',
                        capabilities: { tools: {} },
                        serverInfo: {
                            name: 'Multi-Server MCP Proxy',
                            version: '1.0.0'
                        }
                    },
                    id
                };

            case 'tools/list':
                return {
                    jsonrpc: '2.0',
                    result: {
                        tools: Array.from(this.tools.values())
                    },
                    id
                };

            case 'tools/call':
                return await this.executeTool(params, id);

            default:
                throw new Error(`Unknown method: ${method}`);
        }
    }

    async executeTool(params, id) {
        const { name, arguments: args } = params;
        const tool = this.tools.get(name);

        if (!tool) {
            throw new Error(`Unknown tool: ${name}`);
        }

        // Handle news fetcher tools directly
        if (tool.server === 'news-fetcher') {
            const result = await this.executeNewsTool(name, args);
            return {
                jsonrpc: '2.0',
                result: {
                    content: [{
                        type: 'text',
                        text: result
                    }]
                },
                id
            };
        }

        // For other servers, delegate to the appropriate server
        throw new Error(`Tool execution for ${tool.server} not yet implemented`);
    }

    async executeNewsTool(toolName, args) {
        const RSSParser = require('rss-parser');
        const fs = require('fs');
        const path = require('path');
        const parser = new RSSParser();

        if (toolName === 'fetch_news') {
            const limit = args?.limit || 10;
            const feed = await parser.parseURL('https://allafrica.com/tools/headlines/rdf/latest/headlines.rdf');
            const headlines = feed.items.slice(0, limit).map(item => ({
                title: item.title,
                link: item.link,
                pubDate: item.pubDate,
                description: item.contentSnippet || item.content
            }));
            
            return `Fetched ${headlines.length} headlines:\n\n${headlines.map((h, i) => 
                `${i + 1}. ${h.title}\n   ${h.link}\n   ${h.pubDate}\n`
            ).join('\n')}`;

        } else if (toolName === 'save_headlines') {
            const filename = args?.filename || 'headlines.txt';
            const feed = await parser.parseURL('https://allafrica.com/tools/headlines/rdf/latest/headlines.rdf');
            const headlines = feed.items.map(item => 
                `${item.title}\n${item.link}\n${item.pubDate}\n${item.contentSnippet || ''}\n---\n`
            ).join('\n');
            
            fs.writeFileSync(path.join(process.cwd(), filename), headlines);
            return `Headlines saved to ${filename}`;
        }

        throw new Error(`Unknown news tool: ${toolName}`);
    }

    start() {
        this.app.listen(this.port, () => {
            console.log(`🌟 Multi-Server MCP Proxy running on http://localhost:${this.port}`);
            console.log(`📡 SSE Endpoint: http://localhost:${this.port}/sse`);
            console.log(`🔧 Health Check: http://localhost:${this.port}/health`);
            console.log(`🛠️ Available servers: ${Array.from(this.servers.keys()).join(', ')}`);
            console.log(`🔨 Available tools: ${Array.from(this.tools.keys()).join(', ')}`);
        });
    }
}

const proxy = new MultiServerMCPProxy();
proxy.start();