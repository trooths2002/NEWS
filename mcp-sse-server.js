const express = require('express');
const cors = require('cors');
const RSSParser = require('rss-parser');
const fs = require('fs');
const path = require('path');

const app = express();
const parser = new RSSParser();
const PORT = 3006;

// Enable CORS for all routes
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept']
}));

app.use(express.json());

// MCP Tools registry
const mcpTools = [
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
    }
];

// SSE endpoint for MCP communication - this is what the browser extension expects
app.get('/sse', (req, res) => {
    console.log('SSE connection established from:', req.headers['user-agent'] || 'Unknown');
    
    res.writeHead(200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Cache-Control',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
    });

    // Send initial connection message
    res.write(`data: ${JSON.stringify({
        jsonrpc: '2.0',
        method: 'notifications/initialized',
        params: {
            protocolVersion: '2024-11-05',
            capabilities: {
                tools: {}
            },
            serverInfo: {
                name: 'News Fetcher MCP Server',
                version: '1.0.0'
            }
        }
    })}\n\n`);

    // Send available tools
    res.write(`data: ${JSON.stringify({
        jsonrpc: '2.0',
        method: 'tools/list',
        result: {
            tools: mcpTools
        }
    })}\n\n`);

    // Keep connection alive with periodic pings
    const pingInterval = setInterval(() => {
        res.write(`data: ${JSON.stringify({
            jsonrpc: '2.0',
            method: 'notifications/ping',
            params: { timestamp: new Date().toISOString() }
        })}\n\n`);
    }, 30000);

    req.on('close', () => {
        console.log('SSE connection closed');
        clearInterval(pingInterval);
    });

    req.on('error', (err) => {
        console.error('SSE connection error:', err);
        clearInterval(pingInterval);
    });
});

// POST endpoint for MCP tool calls
app.post('/sse', async (req, res) => {
    console.log('Received MCP request:', req.body);
    
    const { method, params, id } = req.body;
    
    try {
        let result;
        
        switch (method) {
            case 'tools/list':
                result = { tools: mcpTools };
                break;
                
            case 'tools/call':
                const { name, arguments: args } = params;
                
                if (name === 'fetch_news') {
                    const limit = args?.limit || 10;
                    console.log(`Fetching ${limit} news headlines...`);
                    const feed = await parser.parseURL('https://allafrica.com/tools/headlines/rdf/latest/headlines.rdf');
                    const headlines = feed.items.slice(0, limit).map(item => ({
                        title: item.title,
                        link: item.link,
                        pubDate: item.pubDate,
                        description: item.contentSnippet || item.content
                    }));
                    
                    result = {
                        content: [
                            {
                                type: 'text',
                                text: `Fetched ${headlines.length} headlines:\n\n${headlines.map((h, i) => 
                                    `${i + 1}. ${h.title}\n   ${h.link}\n   ${h.pubDate}\n`
                                ).join('\n')}`
                            }
                        ]
                    };
                } else if (name === 'save_headlines') {
                    const filename = args?.filename || 'headlines.txt';
                    console.log(`Saving headlines to ${filename}...`);
                    const feed = await parser.parseURL('https://allafrica.com/tools/headlines/rdf/latest/headlines.rdf');
                    const headlines = feed.items.map(item => 
                        `${item.title}\n${item.link}\n${item.pubDate}\n${item.contentSnippet || ''}\n---\n`
                    ).join('\n');
                    
                    fs.writeFileSync(path.join(__dirname, filename), headlines);
                    
                    result = {
                        content: [
                            {
                                type: 'text',
                                text: `Headlines saved to ${filename} (${feed.items.length} articles)`
                            }
                        ]
                    };
                } else {
                    throw new Error(`Unknown tool: ${name}`);
                }
                break;
                
            default:
                throw new Error(`Unknown method: ${method}`);
        }
        
        const response = {
            jsonrpc: '2.0',
            result,
            id
        };
        
        console.log('Sending response:', response);
        res.json(response);
        
    } catch (error) {
        console.error('MCP Error:', error);
        const errorResponse = {
            jsonrpc: '2.0',
            error: {
                code: -32603,
                message: error.message
            },
            id
        };
        res.json(errorResponse);
    }
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        timestamp: new Date().toISOString(),
        tools: mcpTools.length,
        endpoint: '/sse'
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`\n🚀 MCP SSE Server running on http://localhost:${PORT}`);
    console.log(`📡 SSE endpoint: http://localhost:${PORT}/sse`);
    console.log(`❤️  Health check: http://localhost:${PORT}/health`);
    console.log(`🔧 Available tools: ${mcpTools.length}`);
    console.log(`\n✅ Ready for browser extension connection!`);
});