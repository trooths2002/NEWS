#!/usr/bin/env node

const RSSParser = require('rss-parser');
const fs = require('fs');
const path = require('path');

class NewsServer {
    constructor() {
        this.parser = new RSSParser();
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
            }
        ];
    }

    async handleRequest(request) {
        const { method, params, id } = request;

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
                    break;

                case 'tools/list':
                    result = { tools: this.tools };
                    break;

                case 'tools/call':
                    const { name, arguments: args } = params;
                    
                    if (name === 'fetch_news') {
                        const limit = args?.limit || 10;
                        const feed = await this.parser.parseURL('https://allafrica.com/tools/headlines/rdf/latest/headlines.rdf');
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
                        const feed = await this.parser.parseURL('https://allafrica.com/tools/headlines/rdf/latest/headlines.rdf');
                        const headlines = feed.items.map(item => 
                            `${item.title}\n${item.link}\n${item.pubDate}\n${item.contentSnippet || ''}\n---\n`
                        ).join('\n');
                        
                        fs.writeFileSync(path.join(__dirname, filename), headlines);
                        
                        result = {
                            content: [
                                {
                                    type: 'text',
                                    text: `Headlines saved to ${filename}`
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

            return {
                jsonrpc: '2.0',
                result,
                id
            };

        } catch (error) {
            return {
                jsonrpc: '2.0',
                error: {
                    code: -32603,
                    message: error.message
                },
                id
            };
        }
    }

    start() {
        process.stdin.setEncoding('utf8');
        
        let buffer = '';
        
        process.stdin.on('data', async (chunk) => {
            buffer += chunk;
            
            let newlineIndex;
            while ((newlineIndex = buffer.indexOf('\n')) !== -1) {
                const line = buffer.slice(0, newlineIndex).trim();
                buffer = buffer.slice(newlineIndex + 1);
                
                if (line) {
                    try {
                        const request = JSON.parse(line);
                        const response = await this.handleRequest(request);
                        console.log(JSON.stringify(response));
                    } catch (error) {
                        console.error('Parse error:', error.message, 'for line:', line);
                        const errorResponse = {
                            jsonrpc: '2.0',
                            error: {
                                code: -32700,
                                message: 'Parse error: ' + error.message
                            },
                            id: null
                        };
                        console.log(JSON.stringify(errorResponse));
                    }
                }
            }
        });

        process.stdin.on('end', () => {
            process.exit(0);
        });

        // Send ready signal to stderr
        console.error('MCP News Server ready');
    }
}

const server = new NewsServer();
server.start();