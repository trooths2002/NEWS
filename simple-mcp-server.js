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

// Handle preflight requests
app.options('*', (req, res) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, Accept');
    res.sendStatus(200);
});

// SSE endpoint for MCP communication
app.get('/sse', (req, res) => {
    console.log('🔗 SSE connection established');
    
    res.writeHead(200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Cache-Control',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
    });

    // Send server info
    res.write(`data: ${JSON.stringify({
        type: 'server_info',
        name: 'News Fetcher MCP Server',
        version: '1.0.0',
        tools: [
            {
                name: 'fetch_news',
                description: 'Fetch latest African news headlines',
                parameters: {
                    limit: { type: 'number', description: 'Number of headlines (default: 10)' }
                }
            },
            {
                name: 'save_headlines',
                description: 'Save headlines to file',
                parameters: {
                    filename: { type: 'string', description: 'Filename to save to' }
                }
            }
        ]
    })}\n\n`);

    // Keep connection alive
    const pingInterval = setInterval(() => {
        res.write(`data: ${JSON.stringify({ type: 'ping', timestamp: new Date().toISOString() })}\n\n`);
    }, 30000);

    req.on('close', () => {
        console.log('🔌 SSE connection closed');
        clearInterval(pingInterval);
    });
});

// POST endpoint for MCP tool calls
app.post('/sse', async (req, res) => {
    console.log('📞 MCP Request:', req.body);
    
    const { method, params, id } = req.body;
    
    try {
        let result;
        
        switch (method) {
            case 'initialize':
                result = {
                    protocolVersion: '2024-11-05',
                    capabilities: {
                        tools: {}
                    },
                    serverInfo: {
                        name: 'News Fetcher MCP Server',
                        version: '1.0.0'
                    }
                };
                console.log('✅ Initialize successful');
                break;
                
            case 'tools/list':
                result = {
                    tools: [
                        {
                            name: 'fetch_news',
                            description: 'Fetch latest African news headlines from AllAfrica',
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
                    ]
                };
                console.log('📋 Tools list sent');
                break;
                
            case 'tools/call':
                const { name, arguments: args } = params;
                console.log(`🛠️ Calling tool: ${name}`);
                
                if (name === 'fetch_news') {
                    const limit = args?.limit || 10;
                    console.log(`📰 Fetching ${limit} headlines...`);
                    
                    const feed = await parser.parseURL('https://allafrica.com/tools/headlines/rdf/latest/headlines.rdf');
                    const headlines = feed.items.slice(0, limit).map((item, index) => ({
                        title: item.title,
                        link: item.link,
                        pubDate: item.pubDate,
                        description: item.contentSnippet || item.content
                    }));
                    
                    const formattedOutput = headlines.map((h, i) => 
                        `${i + 1}. ${h.title}\n   🔗 ${h.link}\n   📅 ${h.pubDate}\n`
                    ).join('\n');
                    
                    result = {
                        content: [
                            {
                                type: 'text',
                                text: `Successfully fetched ${headlines.length} latest African news headlines:\n\n${formattedOutput}\n📊 Total headlines available: ${feed.items.length}\n📡 Source: AllAfrica.com RSS feed\n⏰ Retrieved: ${new Date().toLocaleString()}`
                            }
                        ]
                    };
                    
                    console.log(`✅ Fetched ${headlines.length} headlines`);
                    
                } else if (name === 'save_headlines') {
                    const filename = args?.filename || `headlines-${new Date().toISOString().split('T')[0]}.txt`;
                    console.log(`💾 Saving headlines to: ${filename}`);
                    
                    const feed = await parser.parseURL('https://allafrica.com/tools/headlines/rdf/latest/headlines.rdf');
                    const content = `African News Headlines - ${new Date().toLocaleString()}\nSource: AllAfrica.com\nTotal Headlines: ${feed.items.length}\n\n` +
                        feed.items.map((item, index) => 
                            `${index + 1}. ${item.title}\n   Link: ${item.link}\n   Date: ${item.pubDate}\n   Description: ${item.contentSnippet || 'No description'}\n\n`
                        ).join('');
                    
                    fs.writeFileSync(path.join(__dirname, filename), content, 'utf8');
                    
                    result = {
                        content: [
                            {
                                type: 'text',
                                text: `✅ Successfully saved ${feed.items.length} headlines to "${filename}"\n\n📂 File location: ${path.join(__dirname, filename)}\n📊 File size: ${(content.length / 1024).toFixed(2)} KB\n⏰ Saved at: ${new Date().toLocaleString()}`
                            }
                        ]
                    };
                    
                    console.log(`✅ Saved to ${filename}`);
                    
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
        
        console.log('📤 Sending response');
        res.json(response);
        
    } catch (error) {
        console.error('❌ MCP Error:', error.message);
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
        tools: 2,
        endpoint: '/sse',
        server: 'News Fetcher MCP'
    });
});

// Root endpoint info
app.get('/', (req, res) => {
    res.json({
        name: 'News Fetcher MCP Server',
        version: '1.0.0',
        endpoints: {
            health: '/health',
            sse: '/sse (GET for connection, POST for requests)'
        },
        tools: ['fetch_news', 'save_headlines'],
        status: 'Ready for MCP SuperAssistant connection'
    });
});

// Start server
app.listen(PORT, () => {
    console.log('🚀 News Fetcher MCP Server Started!');
    console.log('================================');
    console.log(`📡 Server URL: http://localhost:${PORT}`);
    console.log(`🔗 SSE Endpoint: http://localhost:${PORT}/sse`);
    console.log(`❤️ Health Check: http://localhost:${PORT}/health`);
    console.log('🛠️ Available Tools:');
    console.log('   • fetch_news - Get latest African news headlines');
    console.log('   • save_headlines - Save headlines to text file');
    console.log('');
    console.log('✅ Ready for MCP SuperAssistant browser extension!');
    console.log('🌐 Connect to: http://localhost:3006/sse');
    console.log('');
});