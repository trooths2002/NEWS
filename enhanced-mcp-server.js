#!/usr/bin/env node

const express = require('express');
const cors = require('cors');
const RSSParser = require('rss-parser');
const fs = require('fs');
const path = require('path');

class EnhancedMCPServer {
    constructor() {
        this.app = express();
        this.parser = new RSSParser();
        this.port = 3006;
        this.dbPath = path.join(__dirname, 'news-intelligence.json');
        
        // Initialize database
        this.initializeDatabase();
        
        // Setup middleware
        this.app.use(cors({
            origin: '*',
            methods: ['GET', 'POST', 'OPTIONS'],
            headers: ['Content-Type', 'Accept', 'Authorization']
        }));
        this.app.use(express.json());
        
        // Define all available tools
        this.tools = [
            {
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
            },
            {
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
            },
            {
                name: 'read_file',
                description: 'Read contents of a file',
                inputSchema: {
                    type: 'object',
                    properties: {
                        filename: {
                            type: 'string',
                            description: 'Name of file to read'
                        }
                    },
                    required: ['filename']
                }
            },
            {
                name: 'write_file',
                description: 'Write content to a file',
                inputSchema: {
                    type: 'object',
                    properties: {
                        filename: {
                            type: 'string',
                            description: 'Name of file to write'
                        },
                        content: {
                            type: 'string',
                            description: 'Content to write to file'
                        }
                    },
                    required: ['filename', 'content']
                }
            },
            {
                name: 'list_files',
                description: 'List files in the current directory',
                inputSchema: {
                    type: 'object',
                    properties: {}
                }
            },
            {
                name: 'store_news_data',
                description: 'Store news data in intelligence database',
                inputSchema: {
                    type: 'object',
                    properties: {
                        headlines: {
                            type: 'array',
                            description: 'Array of headline objects to store'
                        },
                        category: {
                            type: 'string',
                            description: 'Category for the news data',
                            default: 'general'
                        }
                    },
                    required: ['headlines']
                }
            },
            {
                name: 'query_news_database',
                description: 'Query the news intelligence database',
                inputSchema: {
                    type: 'object',
                    properties: {
                        query_type: {
                            type: 'string',
                            description: 'Type of query: latest, by_date, by_category, trends',
                            default: 'latest'
                        },
                        limit: {
                            type: 'number',
                            description: 'Number of results to return',
                            default: 10
                        },
                        category: {
                            type: 'string',
                            description: 'Category to filter by'
                        },
                        date: {
                            type: 'string',
                            description: 'Date to filter by (YYYY-MM-DD)'
                        }
                    }
                }
            },
            {
                name: 'generate_report',
                description: 'Generate intelligence report from stored data',
                inputSchema: {
                    type: 'object',
                    properties: {
                        report_type: {
                            type: 'string',
                            description: 'Type of report: daily, weekly, trends, crisis',
                            default: 'daily'
                        },
                        save_to_file: {
                            type: 'boolean',
                            description: 'Whether to save report to file',
                            default: true
                        }
                    }
                }
            }
        ];
        
        this.setupRoutes();
    }

    initializeDatabase() {
        if (!fs.existsSync(this.dbPath)) {
            const initialData = {
                news_entries: [],
                categories: {},
                metadata: {
                    created: new Date().toISOString(),
                    last_updated: new Date().toISOString(),
                    total_entries: 0
                }
            };
            fs.writeFileSync(this.dbPath, JSON.stringify(initialData, null, 2));
        }
    }

    loadDatabase() {
        try {
            const data = fs.readFileSync(this.dbPath, 'utf8');
            return JSON.parse(data);
        } catch (error) {
            console.error('Error loading database:', error);
            return null;
        }
    }

    saveDatabase(data) {
        try {
            data.metadata.last_updated = new Date().toISOString();
            fs.writeFileSync(this.dbPath, JSON.stringify(data, null, 2));
            return true;
        } catch (error) {
            console.error('Error saving database:', error);
            return false;
        }
    }

    setupRoutes() {
        // Health check
        this.app.get('/health', (req, res) => {
            const db = this.loadDatabase();
            res.json({
                status: 'healthy',
                server: 'Enhanced MCP News Intelligence Server',
                tools: this.tools.length,
                database_entries: db ? db.metadata.total_entries : 0,
                endpoint: `http://localhost:${this.port}/sse`,
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

            res.write(`data: ${JSON.stringify({
                type: 'connection',
                message: 'Connected to Enhanced MCP News Intelligence Server',
                tools: this.tools.length,
                capabilities: ['news_fetching', 'file_operations', 'database_operations', 'intelligence_reports']
            })}\n\n`);

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
                            name: 'Enhanced MCP News Intelligence Server',
                            version: '2.0.0'
                        }
                    },
                    id
                };

            case 'tools/list':
                return {
                    jsonrpc: '2.0',
                    result: { tools: this.tools },
                    id
                };

            case 'tools/call':
                const result = await this.executeTool(params);
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

            default:
                throw new Error(`Unknown method: ${method}`);
        }
    }

    async executeTool(params) {
        const { name, arguments: args } = params;

        switch (name) {
            case 'fetch_news':
                return await this.fetchNews(args);
            case 'save_headlines':
                return await this.saveHeadlines(args);
            case 'read_file':
                return await this.readFile(args);
            case 'write_file':
                return await this.writeFile(args);
            case 'list_files':
                return await this.listFiles();
            case 'store_news_data':
                return await this.storeNewsData(args);
            case 'query_news_database':
                return await this.queryNewsDatabase(args);
            case 'generate_report':
                return await this.generateReport(args);
            default:
                throw new Error(`Unknown tool: ${name}`);
        }
    }

    async fetchNews(args) {
        const limit = args?.limit || 10;
        const feed = await this.parser.parseURL('https://allafrica.com/tools/headlines/rdf/latest/headlines.rdf');
        const headlines = feed.items.slice(0, limit).map((item, index) => ({
            id: `news_${Date.now()}_${index}`,
            title: item.title,
            link: item.link,
            pubDate: item.pubDate,
            description: item.contentSnippet || item.content,
            fetched_at: new Date().toISOString()
        }));
        
        return `✅ Fetched ${headlines.length} headlines:\n\n${headlines.map((h, i) => 
            `${i + 1}. ${h.title}\n   📎 ${h.link}\n   📅 ${h.pubDate}\n`
        ).join('\n')}`;
    }

    async saveHeadlines(args) {
        const filename = args?.filename || 'headlines.txt';
        const feed = await this.parser.parseURL('https://allafrica.com/tools/headlines/rdf/latest/headlines.rdf');
        const headlines = feed.items.map(item => 
            `${item.title}\n${item.link}\n${item.pubDate}\n${item.contentSnippet || ''}\n---\n`
        ).join('\n');
        
        fs.writeFileSync(path.join(__dirname, filename), headlines);
        return `✅ Headlines saved to ${filename}`;
    }

    async readFile(args) {
        const { filename } = args;
        const filePath = path.join(__dirname, filename);
        
        if (!fs.existsSync(filePath)) {
            return `❌ File not found: ${filename}`;
        }
        
        const content = fs.readFileSync(filePath, 'utf8');
        return `📄 Content of ${filename}:\n\n${content}`;
    }

    async writeFile(args) {
        const { filename, content } = args;
        const filePath = path.join(__dirname, filename);
        
        fs.writeFileSync(filePath, content);
        return `✅ Content written to ${filename}`;
    }

    async listFiles() {
        const files = fs.readdirSync(__dirname).filter(file => 
            fs.statSync(path.join(__dirname, file)).isFile()
        );
        
        return `📁 Files in directory:\n\n${files.map((file, i) => 
            `${i + 1}. ${file}`
        ).join('\n')}`;
    }

    async storeNewsData(args) {
        const { headlines, category = 'general' } = args;
        const db = this.loadDatabase();
        
        if (!db) {
            return '❌ Failed to load database';
        }

        const timestamp = new Date().toISOString();
        const stored = headlines.map(headline => ({
            ...headline,
            category,
            stored_at: timestamp
        }));

        db.news_entries.push(...stored);
        db.metadata.total_entries = db.news_entries.length;
        
        if (!db.categories[category]) {
            db.categories[category] = 0;
        }
        db.categories[category] += stored.length;

        if (this.saveDatabase(db)) {
            return `✅ Stored ${stored.length} headlines in category '${category}'. Total entries: ${db.metadata.total_entries}`;
        } else {
            return '❌ Failed to save to database';
        }
    }

    async queryNewsDatabase(args) {
        const { query_type = 'latest', limit = 10, category, date } = args;
        const db = this.loadDatabase();
        
        if (!db) {
            return '❌ Failed to load database';
        }

        let results = [...db.news_entries];

        // Apply filters
        if (category) {
            results = results.filter(entry => entry.category === category);
        }
        
        if (date) {
            results = results.filter(entry => 
                entry.stored_at.startsWith(date)
            );
        }

        // Apply query type
        switch (query_type) {
            case 'latest':
                results = results.sort((a, b) => new Date(b.stored_at) - new Date(a.stored_at));
                break;
            case 'trends':
                const categoryCount = {};
                results.forEach(entry => {
                    categoryCount[entry.category] = (categoryCount[entry.category] || 0) + 1;
                });
                return `📊 Trend Analysis:\n\n${Object.entries(categoryCount)
                    .sort(([,a], [,b]) => b - a)
                    .map(([cat, count]) => `${cat}: ${count} articles`)
                    .join('\n')}`;
        }

        results = results.slice(0, limit);

        return `📊 Database Query Results (${results.length} entries):\n\n${results.map((entry, i) => 
            `${i + 1}. ${entry.title}\n   📂 Category: ${entry.category}\n   📅 Stored: ${entry.stored_at}\n`
        ).join('\n')}`;
    }

    async generateReport(args) {
        const { report_type = 'daily', save_to_file = true } = args;
        const db = this.loadDatabase();
        
        if (!db) {
            return '❌ Failed to load database';
        }

        const today = new Date().toISOString().split('T')[0];
        const todayEntries = db.news_entries.filter(entry => 
            entry.stored_at.startsWith(today)
        );

        let report = '';
        
        switch (report_type) {
            case 'daily':
                report = `📊 DAILY INTELLIGENCE REPORT - ${today}\n\n`;
                report += `📈 Summary:\n`;
                report += `- Total articles today: ${todayEntries.length}\n`;
                report += `- Total articles in database: ${db.metadata.total_entries}\n\n`;
                
                const categories = {};
                todayEntries.forEach(entry => {
                    categories[entry.category] = (categories[entry.category] || 0) + 1;
                });
                
                report += `📂 Category Breakdown:\n`;
                Object.entries(categories).forEach(([cat, count]) => {
                    report += `- ${cat}: ${count} articles\n`;
                });
                
                report += `\n🔍 Latest Headlines:\n`;
                todayEntries.slice(0, 5).forEach((entry, i) => {
                    report += `${i + 1}. ${entry.title}\n`;
                });
                break;
                
            case 'weekly':
                const weekAgo = new Date();
                weekAgo.setDate(weekAgo.getDate() - 7);
                const weekEntries = db.news_entries.filter(entry => 
                    new Date(entry.stored_at) >= weekAgo
                );
                
                report = `📊 WEEKLY INTELLIGENCE REPORT\n\n`;
                report += `📈 Summary:\n`;
                report += `- Articles this week: ${weekEntries.length}\n`;
                report += `- Daily average: ${Math.round(weekEntries.length / 7)}\n\n`;
                break;
        }

        if (save_to_file) {
            const filename = `intelligence-report-${report_type}-${today}.txt`;
            fs.writeFileSync(path.join(__dirname, filename), report);
            report += `\n✅ Report saved to ${filename}`;
        }

        return report;
    }

    start() {
        this.app.listen(this.port, () => {
            console.log(`🌟 Enhanced MCP News Intelligence Server running on http://localhost:${this.port}`);
            console.log(`📡 SSE Endpoint: http://localhost:${this.port}/sse`);
            console.log(`🔧 Health Check: http://localhost:${this.port}/health`);
            console.log(`🛠️ Available tools: ${this.tools.length}`);
            console.log(`📊 Tools: ${this.tools.map(t => t.name).join(', ')}`);
        });
    }
}

const server = new EnhancedMCPServer();
server.start();