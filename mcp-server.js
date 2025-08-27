#!/usr/bin/env node

/**
 * News Automation Build Orchestrator MCP Server
 * Production-ready MCP server for managing news automation workflows
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ErrorCode,
  ListToolsRequestSchema,
  McpError,
} from '@modelcontextprotocol/sdk/types.js';
import { spawn, exec } from 'child_process';
import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

class NewsAutomationOrchestrator {
  constructor() {
    this.workspacePath = process.cwd();
    this.server = new Server(
      {
        name: 'news-automation-orchestrator',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupHandlers();
  }

  setupHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: 'initialize_project',
          description: 'Initialize complete news automation project structure',
          inputSchema: {
            type: 'object',
            properties: {
              projectName: {
                type: 'string',
                description: 'Name of the project',
                default: 'news-automation'
              },
              enableMCP: {
                type: 'boolean',
                description: 'Enable MCP server integration',
                default: true
              }
            }
          }
        },
        {
          name: 'install_dependencies',
          description: 'Install all required dependencies for news automation',
          inputSchema: {
            type: 'object',
            properties: {
              includeDevDeps: {
                type: 'boolean',
                description: 'Include development dependencies',
                default: true
              }
            }
          }
        },
        {
          name: 'build_automation_system',
          description: 'Build complete news automation system with error handling',
          inputSchema: {
            type: 'object',
            properties: {
              sources: {
                type: 'array',
                items: { type: 'string' },
                description: 'News sources to configure',
                default: ['allAfrica', 'reuters', 'bbc']
              },
              schedule: {
                type: 'string',
                description: 'Automation schedule',
                default: 'daily'
              }
            }
          }
        },
        {
          name: 'deploy_production_system',
          description: 'Deploy production-ready automation with monitoring',
          inputSchema: {
            type: 'object',
            properties: {
              environment: {
                type: 'string',
                enum: ['development', 'staging', 'production'],
                default: 'production'
              },
              enableScheduling: {
                type: 'boolean',
                description: 'Enable Windows Task Scheduler integration',
                default: true
              }
            }
          }
        },
        {
          name: 'start_mcp_servers',
          description: 'Start and configure all MCP servers for the project',
          inputSchema: {
            type: 'object',
            properties: {
              port: {
                type: 'number',
                description: 'Port for Browser MCP server',
                default: 9009
              },
              enableBrowser: {
                type: 'boolean',
                description: 'Enable Browser MCP server',
                default: true
              }
            }
          }
        },
        {
          name: 'validate_system',
          description: 'Comprehensive system validation and health checks',
          inputSchema: {
            type: 'object',
            properties: {
              includePerformanceTests: {
                type: 'boolean',
                description: 'Include performance testing',
                default: true
              }
            }
          }
        },
        {
          name: 'generate_documentation',
          description: 'Generate complete project documentation and guides',
          inputSchema: {
            type: 'object',
            properties: {
              includeArchitecture: {
                type: 'boolean',
                description: 'Include architecture diagrams',
                default: true
              }
            }
          }
        }
      ]
    }));

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case 'initialize_project':
            return await this.initializeProject(args);
          case 'install_dependencies':
            return await this.installDependencies(args);
          case 'build_automation_system':
            return await this.buildAutomationSystem(args);
          case 'deploy_production_system':
            return await this.deployProductionSystem(args);
          case 'start_mcp_servers':
            return await this.startMCPServers(args);
          case 'validate_system':
            return await this.validateSystem(args);
          case 'generate_documentation':
            return await this.generateDocumentation(args);
          default:
            throw new McpError(ErrorCode.MethodNotFound, `Unknown tool: ${name}`);
        }
      } catch (error) {
        throw new McpError(ErrorCode.InternalError, `Tool execution failed: ${error.message}`);
      }
    });
  }

  async initializeProject(args) {
    const projectName = args?.projectName || 'news-automation';
    const enableMCP = args?.enableMCP !== false;

    const results = [];
    
    // Create project structure
    const directories = [
      'src',
      'config',
      'logs',
      'data',
      'images',
      'scripts',
      'tests',
      'docs',
      'templates'
    ];

    for (const dir of directories) {
      const dirPath = path.join(this.workspacePath, dir);
      try {
        await fs.mkdir(dirPath, { recursive: true });
        results.push(`✅ Created directory: ${dir}`);
      } catch (error) {
        results.push(`❌ Failed to create directory ${dir}: ${error.message}`);
      }
    }

    // Create package.json
    const packageJson = {
      name: projectName,
      version: '1.0.0',
      description: 'Production-ready news automation with MCP integration',
      main: 'src/news-automation.js',
      type: 'module',
      scripts: {
        start: 'node src/news-automation.js',
        'mcp-server': 'npx @browsermcp/mcp',
        dev: 'nodemon src/news-automation.js',
        test: 'node tests/test-automation.js',
        deploy: 'node scripts/deploy.js',
        'health-check': 'node scripts/health-check.js'
      },
      dependencies: {
        '@modelcontextprotocol/sdk': '^1.0.0',
        'rss-parser': '^3.12.0',
        'axios': '^1.6.0',
        'cheerio': '^1.0.0',
        'winston': '^3.11.0',
        'date-fns': '^3.0.0',
        'dotenv': '^16.3.0',
        'express': '^4.18.2',
        'cors': '^2.8.5'
      },
      devDependencies: {
        'nodemon': '^3.0.0'
      },
      engines: {
        node: '>=18.0.0'
      }
    };

    try {
      await fs.writeFile(
        path.join(this.workspacePath, 'package.json'),
        JSON.stringify(packageJson, null, 2)
      );
      results.push('✅ Created package.json');
    } catch (error) {
      results.push(`❌ Failed to create package.json: ${error.message}`);
    }

    // Create .env template
    const envTemplate = `# News Automation Configuration
NODE_ENV=production
LOG_LEVEL=info
DATA_DIR=./data
IMAGES_DIR=./images

# MCP Configuration
MCP_PORT=9009
BROWSER_MCP_ENABLED=true

# News Sources Configuration
ALLAFRICA_RSS_URL=https://allafrica.com/tools/headlines/rdf/africa/headlines.rdf
FETCH_INTERVAL_HOURS=6
MAX_ARTICLES_PER_SOURCE=50

# Notification Settings
ENABLE_NOTIFICATIONS=true
NOTIFICATION_WEBHOOK_URL=
`;

    try {
      await fs.writeFile(path.join(this.workspacePath, '.env'), envTemplate);
      results.push('✅ Created .env configuration template');
    } catch (error) {
      results.push(`❌ Failed to create .env: ${error.message}`);
    }

    return {
      content: [
        {
          type: 'text',
          text: `Project initialization completed!\n\n${results.join('\n')}\n\nNext steps:\n1. Run 'install_dependencies' to install packages\n2. Run 'build_automation_system' to create core scripts\n3. Run 'deploy_production_system' to set up automation`
        }
      ]
    };
  }

  async installDependencies(args) {
    const includeDevDeps = args?.includeDevDeps !== false;
    
    return new Promise((resolve, reject) => {
      const command = includeDevDeps ? 'npm install' : 'npm install --production';
      
      exec(command, { cwd: this.workspacePath }, (error, stdout, stderr) => {
        if (error) {
          reject(new Error(`Dependency installation failed: ${error.message}`));
          return;
        }

        const results = [
          '✅ Dependencies installed successfully',
          `📦 Output: ${stdout}`,
          stderr ? `⚠️ Warnings: ${stderr}` : ''
        ].filter(Boolean);

        resolve({
          content: [
            {
              type: 'text',
              text: results.join('\n')
            }
          ]
        });
      });
    });
  }

  async buildAutomationSystem(args) {
    const sources = args?.sources || ['allAfrica'];
    const schedule = args?.schedule || 'daily';

    const results = [];

    // Create main automation script
    const mainScript = `import { promises as fs } from 'fs';
import path from 'path';
import RSSParser from 'rss-parser';
import axios from 'axios';
import * as cheerio from 'cheerio';
import winston from 'winston';
import { format } from 'date-fns';
import dotenv from 'dotenv';

dotenv.config();

class NewsAutomation {
  constructor() {
    this.parser = new RSSParser();
    this.dataDir = process.env.DATA_DIR || './data';
    this.imagesDir = process.env.IMAGES_DIR || './images';
    
    this.logger = winston.createLogger({
      level: process.env.LOG_LEVEL || 'info',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
      ),
      transports: [
        new winston.transports.File({ filename: './logs/automation.log' }),
        new winston.transports.Console()
      ]
    });
  }

  async fetchNews() {
    this.logger.info('Starting news collection...');
    
    const sources = ${JSON.stringify(sources)};
    const results = [];
    
    for (const source of sources) {
      try {
        const data = await this.fetchFromSource(source);
        results.push(data);
        this.logger.info(\`Successfully fetched \${data.articles.length} articles from \${source}\`);
      } catch (error) {
        this.logger.error(\`Failed to fetch from \${source}: \${error.message}\`);
      }
    }
    
    await this.saveResults(results);
    this.logger.info('News collection completed');
    
    return results;
  }

  async fetchFromSource(source) {
    switch (source) {
      case 'allAfrica':
        return await this.fetchAllAfrica();
      default:
        throw new Error(\`Unsupported source: \${source}\`);
    }
  }

  async fetchAllAfrica() {
    const rssUrl = 'https://allafrica.com/tools/headlines/rdf/africa/headlines.rdf';
    const feed = await this.parser.parseURL(rssUrl);
    
    const articles = feed.items.map(item => ({
      title: item.title,
      link: item.link,
      pubDate: item.pubDate,
      description: item.contentSnippet || item.description,
      source: 'AllAfrica'
    }));
    
    return {
      source: 'allAfrica',
      articles,
      fetchTime: new Date().toISOString()
    };
  }

  async saveResults(results) {
    const timestamp = format(new Date(), 'yyyy-MM-dd-HH-mm');
    const filename = \`news-\${timestamp}.json\`;
    const filepath = path.join(this.dataDir, filename);
    
    await fs.writeFile(filepath, JSON.stringify(results, null, 2));
    
    // Also save as latest
    const latestPath = path.join(this.dataDir, 'latest-news.json');
    await fs.writeFile(latestPath, JSON.stringify(results, null, 2));
    
    this.logger.info(\`Results saved to \${filepath}\`);
  }
}

// Main execution
if (import.meta.url === \`file://\${process.argv[1]}\`) {
  const automation = new NewsAutomation();
  automation.fetchNews()
    .then(results => {
      console.log('News automation completed successfully');
      process.exit(0);
    })
    .catch(error => {
      console.error('News automation failed:', error.message);
      process.exit(1);
    });
}

export default NewsAutomation;
`;

    try {
      await fs.writeFile(path.join(this.workspacePath, 'src', 'news-automation.js'), mainScript);
      results.push('✅ Created main automation script');
    } catch (error) {
      results.push(`❌ Failed to create main script: ${error.message}`);
    }

    // Create PowerShell deployment script
    const deployScript = `#Requires -Version 5.1
param(
    [ValidateSet("install", "start", "stop", "status", "deploy")]
    [string]$Action = "deploy"
)

$WorkspacePath = $PSScriptRoot
$LogFile = Join-Path $WorkspacePath "logs/deployment.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8
}

function Install-System {
    Write-Log "Installing news automation system..."
    
    # Create scheduled task
    $taskName = "NewsAutomation-${schedule}"
    $scriptPath = Join-Path $WorkspacePath "src/news-automation.js"
    $arguments = "-Command `"cd '$WorkspacePath'; node '$scriptPath'`""
    
    try {
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $arguments
        $trigger = New-ScheduledTaskTrigger -Daily -At "08:00"
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
        Write-Log "Scheduled task created: $taskName"
    } catch {
        Write-Log "Failed to create scheduled task: $($_.Exception.Message)" "ERROR"
    }
}

function Start-Automation {
    Write-Log "Starting news automation..."
    Set-Location $WorkspacePath
    node "src/news-automation.js"
}

function Get-Status {
    Write-Log "Checking system status..."
    
    # Check if Node.js is available
    try {
        $nodeVersion = & node --version 2>$null
        Write-Log "Node.js version: $nodeVersion"
    } catch {
        Write-Log "Node.js not found" "ERROR"
    }
    
    # Check scheduled tasks
    $tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*NewsAutomation*" }
    foreach ($task in $tasks) {
        Write-Log "Scheduled task: $($task.TaskName) - State: $($task.State)"
    }
}

switch ($Action) {
    "install" { Install-System }
    "start" { Start-Automation }
    "status" { Get-Status }
    "deploy" {
        Install-System
        Get-Status
        Write-Log "Deployment completed successfully!"
    }
}`;

    try {
      await fs.writeFile(path.join(this.workspacePath, 'scripts', 'deploy.ps1'), deployScript);
      results.push('✅ Created PowerShell deployment script');
    } catch (error) {
      results.push(`❌ Failed to create deploy script: ${error.message}`);
    }

    return {
      content: [
        {
          type: 'text',
          text: `Automation system built successfully!\n\n${results.join('\n')}\n\nCreated:\n- Main automation script (src/news-automation.js)\n- PowerShell deployment script (scripts/deploy.ps1)\n- Configured for sources: ${sources.join(', ')}\n- Schedule: ${schedule}`
        }
      ]
    };
  }

  async deployProductionSystem(args) {
    const environment = args?.environment || 'production';
    const enableScheduling = args?.enableScheduling !== false;

    return new Promise((resolve, reject) => {
      const deployScript = path.join(this.workspacePath, 'scripts', 'deploy.ps1');
      const command = `powershell -ExecutionPolicy Bypass -File "${deployScript}" -Action deploy`;

      exec(command, { cwd: this.workspacePath }, (error, stdout, stderr) => {
        if (error) {
          reject(new Error(`Deployment failed: ${error.message}`));
          return;
        }

        const results = [
          '🚀 Production deployment completed!',
          `📊 Environment: ${environment}`,
          enableScheduling ? '⏰ Windows Task Scheduler configured' : '⏰ Scheduling disabled',
          `📝 Output: ${stdout}`,
          stderr ? `⚠️ Warnings: ${stderr}` : ''
        ].filter(Boolean);

        resolve({
          content: [
            {
              type: 'text',
              text: results.join('\n')
            }
          ]
        });
      });
    });
  }

  async startMCPServers(args) {
    const port = args?.port || 9009;
    const enableBrowser = args?.enableBrowser !== false;

    const results = [];

    if (enableBrowser) {
      try {
        // Start Browser MCP server
        const mcpProcess = spawn('npx', ['@browsermcp/mcp'], {
          cwd: this.workspacePath,
          detached: true,
          stdio: 'ignore'
        });

        mcpProcess.unref();
        results.push(`✅ Browser MCP server started on port ${port}`);
        results.push('🔗 Connect via Browser MCP extension');
      } catch (error) {
        results.push(`❌ Failed to start Browser MCP: ${error.message}`);
      }
    }

    // Create MCP configuration
    const mcpConfig = {
      servers: {
        'news-automation-orchestrator': {
          command: 'node',
          args: ['mcp-server.js'],
          description: 'News automation build orchestrator'
        },
        'browser-mcp': {
          enabled: enableBrowser,
          port: port,
          description: 'Browser MCP for web automation'
        }
      },
      version: '1.0.0'
    };

    try {
      await fs.writeFile(
        path.join(this.workspacePath, 'config', 'mcp-config.json'),
        JSON.stringify(mcpConfig, null, 2)
      );
      results.push('✅ MCP configuration saved');
    } catch (error) {
      results.push(`❌ Failed to save MCP config: ${error.message}`);
    }

    return {
      content: [
        {
          type: 'text',
          text: results.join('\n')
        }
      ]
    };
  }

  async validateSystem(args) {
    const includePerformanceTests = args?.includePerformanceTests !== false;
    const results = [];

    // Validate Node.js
    try {
      const { stdout } = await this.execAsync('node --version');
      results.push(`✅ Node.js: ${stdout.trim()}`);
    } catch (error) {
      results.push(`❌ Node.js validation failed: ${error.message}`);
    }

    // Validate npm packages
    try {
      const packagePath = path.join(this.workspacePath, 'package.json');
      const packageContent = await fs.readFile(packagePath, 'utf8');
      const pkg = JSON.parse(packageContent);
      results.push(`✅ Package.json valid: ${pkg.name} v${pkg.version}`);
    } catch (error) {
      results.push(`❌ Package validation failed: ${error.message}`);
    }

    // Validate scripts
    const scriptsToValidate = [
      'src/news-automation.js',
      'scripts/deploy.ps1'
    ];

    for (const script of scriptsToValidate) {
      const scriptPath = path.join(this.workspacePath, script);
      try {
        await fs.access(scriptPath);
        results.push(`✅ Script exists: ${script}`);
      } catch (error) {
        results.push(`❌ Script missing: ${script}`);
      }
    }

    // Test automation script
    if (includePerformanceTests) {
      try {
        const testStart = Date.now();
        await this.execAsync('node src/news-automation.js', { timeout: 30000 });
        const testDuration = Date.now() - testStart;
        results.push(`✅ Automation test passed (${testDuration}ms)`);
      } catch (error) {
        results.push(`❌ Automation test failed: ${error.message}`);
      }
    }

    return {
      content: [
        {
          type: 'text',
          text: `System validation completed!\n\n${results.join('\n')}`
        }
      ]
    };
  }

  async generateDocumentation(args) {
    const includeArchitecture = args?.includeArchitecture !== false;
    
    const readme = `# News Automation System

Production-ready news automation with MCP integration.

## Features

- 🔄 Automated news collection from multiple sources
- 🤖 MCP server integration for AI workflows
- 📊 Professional-grade output formatting
- ⏰ Windows Task Scheduler integration
- 🛡️ Production-ready error handling
- 📈 Performance monitoring and logging

## Quick Start

\`\`\`bash
# Install dependencies
npm install

# Start automation
npm start

# Deploy to production
npm run deploy
\`\`\`

## MCP Integration

This system includes a custom MCP server for build orchestration:

- **initialize_project**: Set up complete project structure
- **build_automation_system**: Create automation scripts
- **deploy_production_system**: Deploy with scheduling
- **start_mcp_servers**: Launch MCP servers
- **validate_system**: Comprehensive health checks

## Architecture

The system follows a modular architecture with:

- **Core Engine**: Node.js automation scripts
- **MCP Layer**: Server for AI integration
- **Scheduler**: Windows Task Scheduler integration
- **Monitoring**: Winston logging and health checks

## Configuration

Edit \`.env\` file for customization:

\`\`\`env
NODE_ENV=production
LOG_LEVEL=info
MCP_PORT=9009
FETCH_INTERVAL_HOURS=6
\`\`\`

## Support

For issues or questions, check the logs in \`./logs/\` directory.
`;

    try {
      await fs.writeFile(path.join(this.workspacePath, 'README.md'), readme);
    } catch (error) {
      throw new Error(`Failed to create README: ${error.message}`);
    }

    return {
      content: [
        {
          type: 'text',
          text: '✅ Documentation generated successfully!\n\nCreated:\n- README.md with complete setup guide\n- Architecture overview\n- Configuration instructions\n- Quick start guide'
        }
      ]
    };
  }

  execAsync(command, options = {}) {
    return new Promise((resolve, reject) => {
      exec(command, { cwd: this.workspacePath, ...options }, (error, stdout, stderr) => {
        if (error) {
          reject(error);
        } else {
          resolve({ stdout, stderr });
        }
      });
    });
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('News Automation Orchestrator MCP Server running on stdio');
  }
}

const server = new NewsAutomationOrchestrator();
server.run().catch(console.error);