#!/usr/bin/env node

/**
 * MCP System Status Checker
 * 
 * Quick health check and status report for the MCP orchestration system
 */

const http = require('http');
const fs = require('fs');
const { spawn } = require('child_process');

class SystemStatusChecker {
    constructor() {
        this.checks = [];
        this.processes = [];
    }

    async checkAll() {
        console.log('🔍 MCP System Status Check');
        console.log('=' * 30);
        console.log('');

        // Check 1: Node.js processes
        await this.checkNodeProcesses();
        
        // Check 2: MCP Server endpoints
        await this.checkMCPEndpoints();
        
        // Check 3: File system
        await this.checkFileSystem();
        
        // Check 4: Recent activity
        await this.checkRecentActivity();
        
        // Summary
        this.showSummary();
    }

    async checkNodeProcesses() {
        console.log('🔧 Checking Node.js processes...');
        
        try {
            // Get all node processes
            const { spawn } = require('child_process');
            const tasklist = spawn('tasklist', ['/FI', 'IMAGENAME eq node.exe', '/FO', 'CSV'], {
                shell: true,
                stdio: ['pipe', 'pipe', 'pipe']
            });

            let output = '';
            tasklist.stdout.on('data', (data) => {
                output += data.toString();
            });

            await new Promise((resolve) => {
                tasklist.on('close', (code) => {
                    if (code === 0 && output.includes('node.exe')) {
                        const lines = output.split('\n').filter(line => line.includes('node.exe'));
                        console.log(`   ✅ Found ${lines.length - 1} Node.js processes running`);
                        this.checks.push({ name: 'Node Processes', status: 'OK', details: `${lines.length - 1} running` });
                    } else {
                        console.log('   ❌ No Node.js processes found');
                        this.checks.push({ name: 'Node Processes', status: 'FAIL', details: 'None found' });
                    }
                    resolve();
                });
            });

        } catch (error) {
            console.log(`   ❌ Process check failed: ${error.message}`);
            this.checks.push({ name: 'Node Processes', status: 'ERROR', details: error.message });
        }
    }

    async checkMCPEndpoints() {
        console.log('🌐 Checking MCP endpoints...');
        
        const endpoints = [
            { name: 'Enhanced MCP Health', url: 'http://localhost:3006/health', port: 3006 },
            { name: 'Enhanced MCP SSE', url: 'http://localhost:3006/sse', port: 3006 }
        ];

        for (const endpoint of endpoints) {
            try {
                const accessible = await this.testEndpoint(endpoint.url, 3000);
                if (accessible) {
                    console.log(`   ✅ ${endpoint.name}: Accessible`);
                    this.checks.push({ name: endpoint.name, status: 'OK', details: 'Responding' });
                } else {
                    console.log(`   ❌ ${endpoint.name}: Not accessible`);
                    this.checks.push({ name: endpoint.name, status: 'FAIL', details: 'No response' });
                }
            } catch (error) {
                console.log(`   ❌ ${endpoint.name}: Error - ${error.message}`);
                this.checks.push({ name: endpoint.name, status: 'ERROR', details: error.message });
            }
        }
    }

    testEndpoint(url, timeout = 3000) {
        return new Promise((resolve) => {
            const urlObj = new URL(url);
            const options = {
                hostname: urlObj.hostname,
                port: urlObj.port,
                path: urlObj.pathname,
                method: 'GET',
                timeout: timeout
            };

            const req = http.request(options, (res) => {
                resolve(res.statusCode < 400);
            });

            req.on('error', () => resolve(false));
            req.on('timeout', () => resolve(false));
            req.end();
        });
    }

    async checkFileSystem() {
        console.log('📁 Checking file system...');
        
        const importantFiles = [
            'enhanced-mcp-server.js',
            'multi-server-mcp-proxy.js',
            'simple-mcp-orchestrator.js',
            'fetchAllAfrica.js',
            'package.json'
        ];

        let foundFiles = 0;
        for (const file of importantFiles) {
            if (fs.existsSync(file)) {
                foundFiles++;
            }
        }

        if (foundFiles === importantFiles.length) {
            console.log(`   ✅ All ${foundFiles} required files present`);
            this.checks.push({ name: 'Required Files', status: 'OK', details: `${foundFiles}/${importantFiles.length}` });
        } else {
            console.log(`   ⚠️  Only ${foundFiles}/${importantFiles.length} required files found`);
            this.checks.push({ name: 'Required Files', status: 'WARN', details: `${foundFiles}/${importantFiles.length}` });
        }

        // Check directories
        const dirs = ['logs', 'cache', 'output', 'data'];
        let foundDirs = 0;
        for (const dir of dirs) {
            if (fs.existsSync(dir)) {
                foundDirs++;
            }
        }

        console.log(`   📂 Directory structure: ${foundDirs}/${dirs.length} directories exist`);
        this.checks.push({ name: 'Directory Structure', status: foundDirs > 0 ? 'OK' : 'WARN', details: `${foundDirs}/${dirs.length}` });
    }

    async checkRecentActivity() {
        console.log('⏰ Checking recent activity...');
        
        const logFiles = ['orchestrator-startup.log', 'allafrica-headlines.txt'];
        let recentActivity = false;
        const now = Date.now();
        const oneHourAgo = now - (60 * 60 * 1000);

        for (const logFile of logFiles) {
            try {
                if (fs.existsSync(logFile)) {
                    const stats = fs.statSync(logFile);
                    const modifiedTime = stats.mtime.getTime();
                    
                    if (modifiedTime > oneHourAgo) {
                        console.log(`   ✅ Recent activity in ${logFile} (${new Date(modifiedTime).toLocaleTimeString()})`);
                        recentActivity = true;
                    } else {
                        console.log(`   📄 ${logFile} exists but no recent activity`);
                    }
                }
            } catch (error) {
                console.log(`   ⚠️  Could not check ${logFile}: ${error.message}`);
            }
        }

        this.checks.push({ 
            name: 'Recent Activity', 
            status: recentActivity ? 'OK' : 'WARN', 
            details: recentActivity ? 'Active within 1 hour' : 'No recent activity' 
        });
    }

    showSummary() {
        console.log('');
        console.log('📊 STATUS SUMMARY');
        console.log('=' * 20);
        
        const okChecks = this.checks.filter(c => c.status === 'OK').length;
        const totalChecks = this.checks.length;
        
        console.log(`Overall Status: ${okChecks}/${totalChecks} checks passed`);
        console.log('');
        
        for (const check of this.checks) {
            const icon = check.status === 'OK' ? '✅' : check.status === 'WARN' ? '⚠️' : '❌';
            console.log(`${icon} ${check.name}: ${check.status} (${check.details})`);
        }
        
        console.log('');
        
        if (okChecks === totalChecks) {
            console.log('🎉 System appears to be running well!');
            console.log('🔗 Try connecting to: http://localhost:3006/health');
        } else if (okChecks > totalChecks / 2) {
            console.log('⚡ System is partially operational');
            console.log('🔧 Some components may need attention');
        } else {
            console.log('🚨 System appears to have significant issues');
            console.log('🛠️  Restart recommended: run start-orchestrator.bat');
        }
        
        console.log('');
        console.log('🔍 For more details, check:');
        console.log('   • orchestrator-startup.log');
        console.log('   • Run: Get-Process node (PowerShell)');
        console.log('   • Test: curl http://localhost:3006/health');
    }
}

// Run the status check
if (require.main === module) {
    const checker = new SystemStatusChecker();
    checker.checkAll().catch(error => {
        console.error('Status check failed:', error);
        process.exit(1);
    });
}

module.exports = SystemStatusChecker;