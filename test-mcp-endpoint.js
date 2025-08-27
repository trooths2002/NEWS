const https = require('https');
const http = require('http');

const testMCPEndpoint = () => {
    const data = JSON.stringify({
        jsonrpc: '2.0',
        method: 'tools/list',
        id: 1
    });

    const options = {
        hostname: 'localhost',
        port: 3006,
        path: '/mcp',
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json, text/event-stream',
            'Content-Length': data.length
        }
    };

    const req = http.request(options, (res) => {
        console.log(`Status: ${res.statusCode}`);
        console.log(`Headers:`, res.headers);
        
        let body = '';
        res.on('data', (chunk) => {
            body += chunk;
        });
        
        res.on('end', () => {
            console.log('Response Body:');
            try {
                const response = JSON.parse(body);
                console.log(JSON.stringify(response, null, 2));
            } catch (e) {
                console.log('Raw response:', body);
            }
        });
    });

    req.on('error', (e) => {
        console.error(`Problem with request: ${e.message}`);
    });

    req.write(data);
    req.end();
};

console.log('Testing MCP endpoint...');
testMCPEndpoint();