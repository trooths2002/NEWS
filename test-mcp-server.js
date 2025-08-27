const { spawn } = require('child_process');

const server = spawn('node', ['mcp-server-stdio.js']);

server.stdout.on('data', (data) => {
    console.log('Response:', data.toString());
});

server.stderr.on('data', (data) => {
    console.log('Server log:', data.toString());
});

// Test initialize
setTimeout(() => {
    const initRequest = JSON.stringify({
        jsonrpc: '2.0',
        method: 'initialize',
        params: {},
        id: 1
    }) + '\n';
    
    console.log('Sending:', initRequest.trim());
    server.stdin.write(initRequest);
}, 1000);

// Test tools/list
setTimeout(() => {
    const toolsRequest = JSON.stringify({
        jsonrpc: '2.0',
        method: 'tools/list',
        params: {},
        id: 2
    }) + '\n';
    
    console.log('Sending:', toolsRequest.trim());
    server.stdin.write(toolsRequest);
}, 2000);

// Close after tests
setTimeout(() => {
    server.stdin.end();
}, 5000);