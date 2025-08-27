#!/usr/bin/env node

/**
 * Minimal MCP Server - Direct Start
 * 
 * Simplified version that just starts the essential MCP server functionality
 */

const express = require('express');
const cors = require('cors');
const RSSParser = require('rss-parser');
const fs = require('fs');
const path = require('path');

class MinimalMCPServer {
    constructor() {
        this.app = express();
        this.parser = new RSSParser();
        this.port = 3006;
        this.newsCache = [];
        
        this.setupMiddleware();
        this.setupRoutes();
    }

    setupMiddleware() {
        this.app.use(cors({
            origin: '*',
            methods: ['GET', 'POST', 'OPTIONS'],
            headers: ['Content-Type', 'Accept', 'Authorization']
        }));
        this.app.use(express.json());
    }

    setupRoutes() {
        // Health check
        this.app.get('/health', (req, res) => {
            res.json({
                status: 'healthy',
                timestamp: new Date().toISOString(),
                uptime: process.uptime(),
                server: 'Minimal MCP Server',
                version: '1.0.0',
                endpoints: {
                    health: '/health',
                    sse: '/sse', 
                    news: '/api/headlines',
                    fetch: '/api/fetch-news'
                }
            });
        });

        // SSE endpoint for MCP clients
        this.app.get('/sse', (req, res) => {
            res.writeHead(200, {
                'Content-Type': 'text/event-stream',
                'Cache-Control': 'no-cache',
                'Connection': 'keep-alive',
                'Access-Control-Allow-Origin': '*'
            });

            res.write(`data: ${JSON.stringify({
                type: 'connection',
                message: 'Connected to Minimal MCP Server',
                timestamp: Date.now(),
                capabilities: ['fetch_news', 'save_headlines', 'read_file']
            })}\n\n`);

            // Keep alive
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

        // News API
        this.app.get('/api/headlines', (req, res) => {
            res.json({
                headlines: this.newsCache,
                count: this.newsCache.length,
                lastUpdate: this.lastUpdate || null
            });
        });

        // Fetch news endpoint
        this.app.post('/api/fetch-news', async (req, res) => {
            try {
                const result = await this.fetchNews();
                res.json({ success: true, result });
            } catch (error) {
                res.status(500).json({ success: false, error: error.message });
            }
        });

        // Simple MCP protocol endpoint
        this.app.post('/mcp', async (req, res) => {
            try {
                const { method, params } = req.body;
                
                switch (method) {
                    case 'tools/list':
                        res.json({
                            tools: [
                                {
                                    name: 'fetch_news',
                                    description: 'Fetch latest news headlines',
                                    inputSchema: { type: 'object', properties: {} }
                                },
                                {
                                    name: 'save_headlines', 
                                    description: 'Save headlines to file',
                                    inputSchema: { type: 'object', properties: {} }
                                }
                            ]
                        });
                        break;
                        
                    case 'tools/call':
                        if (params.name === 'fetch_news') {
                            const result = await this.fetchNews();
                            res.json({ content: [{ type: 'text', text: JSON.stringify(result) }] });
                        } else {
                            res.json({ content: [{ type: 'text', text: 'Tool not implemented' }] });
                        }
                        break;
                        
                    default:
                        res.status(400).json({ error: 'Unknown method' });
                }
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });
    }

    async fetchNews() {
        try {
            console.log('📰 Fetching news...');
            
            const feed = await this.parser.parseURL('https://allafrica.com/tools/headlines/rdf/latest/headlines.rdf');
            
            this.newsCache = feed.items.slice(0, 10).map((item, index) => ({
                id: index + 1,
                title: item.title,
                link: item.link,
                pubDate: item.pubDate,
                description: item.contentSnippet || item.description,
                source: 'AllAfrica'
            }));
            
            this.lastUpdate = new Date().toISOString();
            
            // Save to file
            const output = this.newsCache.map(item => 
                `${item.id}. ${item.title}\n   ${item.description}\n   ${item.link}\n   Published: ${item.pubDate}\n`
            ).join('\n');
            
            fs.writeFileSync('allafrica-headlines.txt', 
                `News Headlines - Updated: ${this.lastUpdate}\n` +
                '='.repeat(60) + '\n\n' + output
            );
            
            console.log(`✅ Fetched ${this.newsCache.length} headlines`);
            
            return {
                count: this.newsCache.length,
                headlines: this.newsCache,
                lastUpdate: this.lastUpdate
            };
            
        } catch (error) {
            console.error('❌ News fetch failed:', error.message);
            throw error;
        }
    }

    async start() {
        try {
            // Initial news fetch
            await this.fetchNews();
            
            // Start server
            await new Promise((resolve, reject) => {
                this.server = this.app.listen(this.port, (error) => {
                    if (error) reject(error);
                    else resolve();
                });
            });

            console.log(`
╔══════════════════════════════════════════════════════════════╗
║                 Minimal MCP Server Started                  ║
╠══════════════════════════════════════════════════════════════╣
║  🚀 Server: http://localhost:${this.port}                       ║
║  🏥 Health: http://localhost:${this.port}/health                ║
║  📡 SSE: http://localhost:${this.port}/sse                      ║
║  📰 News: ${this.newsCache.length} headlines loaded                     ║
╚══════════════════════════════════════════════════════════════╝
`);

            // Schedule periodic news updates
            setInterval(async () => {
                try {
                    await this.fetchNews();
                    console.log(`🔄 News updated: ${new Date().toLocaleTimeString()}`);
                } catch (error) {
                    console.error('❌ Scheduled update failed:', error.message);
                }
            }, 300000); // Every 5 minutes

            console.log('✅ MCP Server is ready for connections!');
            console.log('🔗 Connect your MCP client to: http://localhost:3006');
            
        } catch (error) {
            console.error('❌ Failed to start server:', error);
            process.exit(1);
        }
    }

    async stop() {
        if (this.server) {
            await new Promise(resolve => this.server.close(resolve));
            console.log('🛑 Server stopped');
        }
    }
}

// Auto-start if run directly
if (require.main === module) {
    const server = new MinimalMCPServer();
    
    server.start().catch(error => {
        console.error('Failed to start minimal MCP server:', error);
        process.exit(1);
    });

    // Graceful shutdown
    process.on('SIGINT', async () => {
        console.log('\n🛑 Shutting down...');
        await server.stop();
        process.exit(0);
    });
}

module.exports = MinimalMCPServer;