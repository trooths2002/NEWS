#Requires -Version 5.1
<#
.SYNOPSIS
    GitHub CLI Deployment Script for Enhanced Persistent Geopolitical Intelligence Platform
    
.DESCRIPTION
    This script automates the deployment of the enhanced geopolitical intelligence platform using GitHub CLI:
    - Validates system prerequisites and GitHub CLI availability
    - Creates/updates GitHub repository with enhanced components
    - Sets up GitHub Actions workflows for automated deployment
    - Configures secrets and environment variables
    - Deploys to GitHub Pages or other hosting platforms
    - Sets up continuous integration and monitoring
    
.PARAMETER RepositoryName
    Name of the GitHub repository (default: NEWS-Enhanced)
    
.PARAMETER Visibility
    Repository visibility: public or private (default: private)
    
.PARAMETER SetupActions
    Set up GitHub Actions workflows for CI/CD
    
.PARAMETER DeployPages
    Deploy documentation to GitHub Pages
    
.EXAMPLE
    .\Deploy-With-GitHub-CLI.ps1 -RepositoryName "NEWS-Enhanced" -SetupActions -DeployPages
#>

[CmdletBinding()]
param(
    [string]$RepositoryName = "NEWS-Enhanced",
    [ValidateSet("public", "private")]
    [string]$Visibility = "private",
    [switch]$SetupActions,
    [switch]$DeployPages,
    [switch]$Force
)

# Global variables
$script:DeploymentLog = @()
$script:ErrorCount = 0
$script:WarningCount = 0

function Write-DeployLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "SUCCESS" { "Green" }
        "ERROR"   { "Red" }
        "WARNING" { "Yellow" }
        "INFO"    { "Cyan" }
        default   { "White" }
    }
    
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $color
    
    $script:DeploymentLog += @{
        Timestamp = $timestamp
        Level = $Level
        Message = $Message
    }
    
    if ($Level -eq "ERROR") { $script:ErrorCount++ }
    if ($Level -eq "WARNING") { $script:WarningCount++ }
}

function Test-Prerequisites {
    Write-DeployLog "Checking deployment prerequisites..." "INFO"
    
    $prerequisitesPassed = $true
    
    # Check GitHub CLI
    try {
        $ghVersion = & gh --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-DeployLog "GitHub CLI available: $($ghVersion[0])" "SUCCESS"
        } else {
            Write-DeployLog "GitHub CLI not found - please install from https://cli.github.com/" "ERROR"
            $prerequisitesPassed = $false
        }
    } catch {
        Write-DeployLog "GitHub CLI not available - please install from https://cli.github.com/" "ERROR"
        $prerequisitesPassed = $false
    }
    
    # Check GitHub CLI authentication
    try {
        $authStatus = & gh auth status 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-DeployLog "GitHub CLI authenticated successfully" "SUCCESS"
        } else {
            Write-DeployLog "GitHub CLI not authenticated - run 'gh auth login'" "ERROR"
            $prerequisitesPassed = $false
        }
    } catch {
        Write-DeployLog "GitHub CLI authentication check failed" "ERROR"
        $prerequisitesPassed = $false
    }
    
    # Check Git
    try {
        $gitVersion = & git --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-DeployLog "Git available: $gitVersion" "SUCCESS"
        } else {
            Write-DeployLog "Git not found - please install Git" "ERROR"
            $prerequisitesPassed = $false
        }
    } catch {
        Write-DeployLog "Git not available" "ERROR"
        $prerequisitesPassed = $false
    }
    
    # Check Node.js
    try {
        $nodeVersion = & node --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-DeployLog "Node.js available: $nodeVersion" "SUCCESS"
        } else {
            Write-DeployLog "Node.js not found - required for MCP servers" "WARNING"
        }
    } catch {
        Write-DeployLog "Node.js not available" "WARNING"
    }
    
    return $prerequisitesPassed
}

function Initialize-Repository {
    Write-DeployLog "Initializing GitHub repository..." "INFO"
    
    try {
        # Check if repository already exists
        $repoExists = $false
        try {
            $repoInfo = & gh repo view $RepositoryName 2>$null
            if ($LASTEXITCODE -eq 0) {
                $repoExists = $true
                Write-DeployLog "Repository '$RepositoryName' already exists" "WARNING"
                
                if (-not $Force) {
                    $response = Read-Host "Repository exists. Continue anyway? (y/N)"
                    if ($response -ne "y" -and $response -ne "Y") {
                        throw "Deployment cancelled by user"
                    }
                }
            }
        } catch {
            # Repository doesn't exist, which is fine
        }
        
        # Create repository if it doesn't exist
        if (-not $repoExists) {
            Write-DeployLog "Creating new repository '$RepositoryName'..." "INFO"
            
            $createArgs = @("repo", "create", $RepositoryName, "--$Visibility")
            if ($SetupActions) {
                $createArgs += "--enable-issues", "--enable-wiki"
            }
            
            & gh $createArgs
            
            if ($LASTEXITCODE -eq 0) {
                Write-DeployLog "Repository created successfully" "SUCCESS"
            } else {
                throw "Failed to create repository"
            }
        }
        
        # Initialize local git repository if not already initialized
        if (-not (Test-Path ".git")) {
            Write-DeployLog "Initializing local git repository..." "INFO"
            & git init
            & git branch -M main
        }
        
        # Add remote if not exists
        $remoteExists = & git remote get-url origin 2>$null
        if ($LASTEXITCODE -ne 0) {
            $repoUrl = "https://github.com/$(& gh api user --jq .login)/$RepositoryName.git"
            & git remote add origin $repoUrl
            Write-DeployLog "Added remote origin: $repoUrl" "SUCCESS"
        }
        
        return $true
        
    } catch {
        Write-DeployLog "Failed to initialize repository: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Prepare-DeploymentFiles {
    Write-DeployLog "Preparing deployment files..." "INFO"
    
    try {
        # Create .gitignore
        $gitignoreContent = @"
# Node modules
node_modules/
npm-debug.log*

# Environment variables
.env
.env.local
.env.*.local

# Logs
logs/
*.log

# Runtime data
pids/
*.pid
*.seed

# Coverage directory used by tools like istanbul
coverage/

# Dependency directories
jspm_packages/

# Optional npm cache directory
.npm

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# SQLite databases (keep structure, ignore data)
*.db
*.sqlite
*.sqlite3

# Temporary files
tmp/
temp/
*.tmp

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
.vscode/settings.json
.idea/
*.swp
*.swo

# Backup files
*.backup
*.bak

# Test output
test-results/
coverage/

# Build output
dist/
build/

# Sensitive data
**/secrets/
**/credentials/
**/*-secrets.*
**/*-credentials.*

# Large data files
NEWS-PERSISTENT/current/daily/*/raw-feeds/*.xml
NEWS-PERSISTENT/archives/*/
NEWS-PERSISTENT/backups/*/

# Keep structure but ignore large content
NEWS-PERSISTENT/current/daily/*/collection-sessions/*/raw-feeds/
NEWS-PERSISTENT/logs/*.log
NEWS-PERSISTENT/workflows/health-checks/health-*.json
"@
        
        $gitignoreContent | Out-File ".gitignore" -Encoding UTF8 -Force
        Write-DeployLog "Created .gitignore file" "SUCCESS"
        
        # Create README.md with deployment information
        $readmeContent = @"
# Enhanced Persistent Geopolitical Intelligence Platform

🚀 **Advanced MCP-Based Intelligence Collection System**

## Overview

This repository contains a comprehensive, enterprise-grade geopolitical intelligence platform featuring:

- **Persistent Storage Architecture** with automated organization
- **Multi-Source News Aggregation** from global geopolitical sources
- **Intelligent Processing** with deduplication and categorization
- **Resilient Monitoring** with self-healing capabilities
- **Automated Report Generation** with strategic analysis

## Quick Start

### Prerequisites
- Windows PowerShell 5.1+
- Node.js 16.0.0+
- npm 8.0.0+
- SQLite3 (optional)

### Installation

1. **Clone and Setup**
   \`\`\`powershell
   git clone https://github.com/$(& gh api user --jq .login)/$RepositoryName.git
   cd $RepositoryName
   npm install
   \`\`\`

2. **Initialize Persistent Structure**
   \`\`\`powershell
   .\Enhanced-Persistent-News-Structure.ps1
   \`\`\`

3. **Validate System**
   \`\`\`powershell
   .\Comprehensive-Workflow-Validation.ps1 -TestLevel Standard -GenerateReport
   \`\`\`

4. **Start Intelligence Collection**
   \`\`\`powershell
   # Continuous operation
   .\Enhanced-Persistent-Workflow-Automation.ps1 -Mode Continuous
   
   # Or schedule daily
   .\Enhanced-Persistent-Workflow-Automation.ps1 -Mode ScheduleDaily
   \`\`\`

## Architecture

### Core Components

1. **Intelligent News Aggregator MCP** (\`intelligent-news-aggregator-mcp.js\`)
   - Multi-source collection with deduplication
   - Regional and thematic categorization
   - Sentiment analysis and risk assessment

2. **Resilient Monitoring Agent MCP** (\`resilient-monitoring-agent-mcp.js\`)
   - System health monitoring
   - Automated recovery and alerting
   - Performance metrics collection

3. **Enhanced Workflow Automation** (\`Enhanced-Persistent-Workflow-Automation.ps1\`)
   - Multi-mode operation (Continuous/Scheduled/RunOnce)
   - 5-phase intelligence processing pipeline
   - Automated report generation

### Data Sources

- **African**: AllAfrica, BBC Africa, Reuters Africa, Al Jazeera
- **Caribbean**: Caribbean National Weekly, Jamaica Observer  
- **Middle East**: Middle East Eye, Al Arabiya
- **Global**: Council on Foreign Relations, Foreign Policy, Stratfor

### Intelligence Products

- Executive Briefs
- Regional Situation Reports
- Threat Assessments  
- Trending Topic Analysis
- Strategic Implications Reports

## Configuration

Key configuration files:
- \`production-config.json\` - Production MCP settings
- \`mcp.config.json\` - Basic MCP configuration
- \`multi-server-mcp-config.json\` - Multi-server orchestration

## Monitoring

The platform provides:
- Real-time health monitoring
- Automated failure recovery
- Performance metrics collection
- Predictive alerting with escalation

## Security

- Process isolation and privilege control
- Secure credential management
- Audit logging and compliance tracking
- Path validation and access controls

## Support

For deployment issues:
1. Run the validation suite: \`.\Comprehensive-Workflow-Validation.ps1\`
2. Check system logs in \`NEWS-PERSISTENT/logs/\`
3. Review health reports in \`NEWS-PERSISTENT/workflows/health-checks/\`

## License

Private Repository - Authorized Use Only

---

**Deployed**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')
**Version**: Enhanced Persistent Intelligence Platform v2.0.0
"@
        
        $readmeContent | Out-File "README.md" -Encoding UTF8 -Force
        Write-DeployLog "Created README.md file" "SUCCESS"
        
        # Create package.json for Node.js dependencies
        $packageJson = @{
            name = $RepositoryName.ToLower()
            version = "2.0.0"
            description = "Enhanced Persistent Geopolitical Intelligence Platform"
            main = "intelligent-news-aggregator-mcp.js"
            scripts = @{
                start = "node intelligent-news-aggregator-mcp.js"
                monitor = "node resilient-monitoring-agent-mcp.js"
                validate = "powershell -ExecutionPolicy Bypass -File Comprehensive-Workflow-Validation.ps1"
                setup = "powershell -ExecutionPolicy Bypass -File Enhanced-Persistent-News-Structure.ps1"
                deploy = "powershell -ExecutionPolicy Bypass -File Enhanced-Persistent-Workflow-Automation.ps1 -Mode RunOnce"
            }
            dependencies = @{
                "@modelcontextprotocol/sdk" = "^0.5.0"
                "axios" = "^1.6.0"
                "sqlite3" = "^5.1.0"
                "sqlite" = "^5.1.0"
                "crypto" = "^1.0.1"
            }
            devDependencies = @{
                "@types/node" = "^20.0.0"
            }
            engines = @{
                node = ">=16.0.0"
                npm = ">=8.0.0"
            }
            author = "Enhanced Intelligence Platform"
            license = "PRIVATE"
            repository = @{
                type = "git"
                url = "https://github.com/$(& gh api user --jq .login)/$RepositoryName.git"
            }
            keywords = @(
                "geopolitical",
                "intelligence",
                "news-aggregation", 
                "mcp-server",
                "automation",
                "monitoring"
            )
        }
        
        $packageJson | ConvertTo-Json -Depth 4 | Out-File "package.json" -Encoding UTF8 -Force
        Write-DeployLog "Created package.json file" "SUCCESS"
        
        return $true
        
    } catch {
        Write-DeployLog "Failed to prepare deployment files: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Setup-GitHubActions {
    Write-DeployLog "Setting up GitHub Actions workflows..." "INFO"
    
    if (-not $SetupActions) {
        Write-DeployLog "Skipping GitHub Actions setup (not requested)" "INFO"
        return $true
    }
    
    try {
        # Create .github/workflows directory
        $workflowDir = ".github/workflows"
        New-Item -ItemType Directory -Path $workflowDir -Force | Out-Null
        
        # Create CI/CD workflow
        $ciWorkflow = @"
name: Enhanced Intelligence Platform CI/CD

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    # Run validation daily at 6 AM UTC
    - cron: '0 6 * * *'

jobs:
  validate-system:
    name: System Validation
    runs-on: windows-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'
        
    - name: Install dependencies
      run: npm install
      
    - name: Run system validation
      shell: pwsh
      run: |
        .\Comprehensive-Workflow-Validation.ps1 -TestLevel Standard -GenerateReport
        
    - name: Upload validation report
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: validation-report
        path: NEWS-PERSISTENT/workflows/validation-report-*.json
        
  test-mcp-servers:
    name: Test MCP Servers
    runs-on: windows-latest
    needs: validate-system
    
    strategy:
      matrix:
        server:
          - intelligent-news-aggregator-mcp.js
          - resilient-monitoring-agent-mcp.js
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'
        
    - name: Install dependencies
      run: npm install
      
    - name: Test MCP Server Syntax
      run: node -c `${{ matrix.server }}
      
    - name: Test MCP Server Startup
      shell: pwsh
      run: |
        `$process = Start-Process -FilePath "node" -ArgumentList "`${{ matrix.server }}" -NoNewWindow -PassThru
        Start-Sleep -Seconds 5
        if (`$process.HasExited) {
          Write-Error "Server failed to start"
          exit 1
        }
        Stop-Process -Id `$process.Id -Force
        Write-Host "Server started successfully"

  deploy-docs:
    name: Deploy Documentation
    runs-on: windows-latest
    needs: [validate-system, test-mcp-servers]
    if: github.ref == 'refs/heads/main'
    
    permissions:
      contents: read
      pages: write
      id-token: write
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Pages
      uses: actions/configure-pages@v3
      
    - name: Generate documentation
      shell: pwsh
      run: |
        # Create docs directory
        New-Item -ItemType Directory -Path "docs" -Force
        
        # Copy documentation files
        Copy-Item "README.md" "docs/"
        Copy-Item "ENHANCED-DEPLOYMENT-GUIDE.md" "docs/" -ErrorAction SilentlyContinue
        
        # Create index.html
        @"
        <!DOCTYPE html>
        <html>
        <head>
            <title>Enhanced Intelligence Platform</title>
            <meta charset="UTF-8">
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; }
                .header { background: #2d5016; color: white; padding: 20px; border-radius: 8px; }
                .content { margin-top: 20px; }
                .link { display: block; margin: 10px 0; padding: 10px; background: #f5f5f5; text-decoration: none; color: #333; border-radius: 4px; }
                .link:hover { background: #e0e0e0; }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>🚀 Enhanced Persistent Geopolitical Intelligence Platform</h1>
                <p>Enterprise-grade intelligence collection and analysis system</p>
            </div>
            <div class="content">
                <h2>📖 Documentation</h2>
                <a href="README.html" class="link">📋 System Overview & Quick Start</a>
                <a href="ENHANCED-DEPLOYMENT-GUIDE.html" class="link">🛠️ Complete Deployment Guide</a>
                <h2>🔗 Resources</h2>
                <a href="https://github.com/$(& gh api user --jq .login)/$RepositoryName" class="link">📦 GitHub Repository</a>
                <a href="https://github.com/$(& gh api user --jq .login)/$RepositoryName/actions" class="link">⚡ GitHub Actions</a>
            </div>
        </body>
        </html>
        "@ | Out-File "docs/index.html" -Encoding UTF8
      
    - name: Upload Pages artifact
      uses: actions/upload-pages-artifact@v2
      with:
        path: docs/
        
    - name: Deploy to GitHub Pages
      uses: actions/deploy-pages@v2
"@
        
        $ciWorkflow | Out-File "$workflowDir/ci-cd.yml" -Encoding UTF8 -Force
        Write-DeployLog "Created CI/CD workflow" "SUCCESS"
        
        # Create monitoring workflow
        $monitoringWorkflow = @"
name: System Monitoring

on:
  schedule:
    # Run monitoring every 30 minutes
    - cron: '*/30 * * * *'
  workflow_dispatch:

jobs:
  health-check:
    name: System Health Check
    runs-on: windows-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        
    - name: Run health validation
      shell: pwsh
      run: |
        .\Comprehensive-Workflow-Validation.ps1 -TestLevel Basic
        
    - name: Check system resources
      shell: pwsh
      run: |
        # Check available resources
        Get-WmiObject -Class Win32_LogicalDisk | Where-Object { `$_.DeviceID -eq "C:" } | Select-Object Size, FreeSpace
        Get-WmiObject -Class Win32_ComputerSystem | Select-Object TotalPhysicalMemory
        
    - name: Notify on failure
      if: failure()
      run: |
        echo "::error::System health check failed"
"@
        
        $monitoringWorkflow | Out-File "$workflowDir/monitoring.yml" -Encoding UTF8 -Force
        Write-DeployLog "Created monitoring workflow" "SUCCESS"
        
        return $true
        
    } catch {
        Write-DeployLog "Failed to setup GitHub Actions: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Deploy-ToGitHub {
    Write-DeployLog "Deploying to GitHub repository..." "INFO"
    
    try {
        # Add all files
        Write-DeployLog "Adding files to git..." "INFO"
        & git add .
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to add files to git"
        }
        
        # Create commit
        $commitMessage = "Enhanced Persistent Intelligence Platform Deployment $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        & git commit -m $commitMessage
        
        if ($LASTEXITCODE -ne 0) {
            Write-DeployLog "No changes to commit or commit failed" "WARNING"
        } else {
            Write-DeployLog "Created commit: $commitMessage" "SUCCESS"
        }
        
        # Push to GitHub
        Write-DeployLog "Pushing to GitHub..." "INFO"
        & git push -u origin main
        
        if ($LASTEXITCODE -eq 0) {
            Write-DeployLog "Successfully pushed to GitHub" "SUCCESS"
        } else {
            throw "Failed to push to GitHub"
        }
        
        # Get repository URL
        $repoUrl = "https://github.com/$(& gh api user --jq .login)/$RepositoryName"
        Write-DeployLog "Repository URL: $repoUrl" "INFO"
        
        return $true
        
    } catch {
        Write-DeployLog "Failed to deploy to GitHub: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Setup-GitHubPages {
    Write-DeployLog "Setting up GitHub Pages..." "INFO"
    
    if (-not $DeployPages) {
        Write-DeployLog "Skipping GitHub Pages setup (not requested)" "INFO"
        return $true
    }
    
    try {
        # Enable GitHub Pages via API
        $pagesConfig = @{
            source = @{
                branch = "main"
                path = "/docs"
            }
        } | ConvertTo-Json -Depth 3
        
        $pagesConfig | gh api repos/:owner/$RepositoryName/pages -X POST --input -
        
        if ($LASTEXITCODE -eq 0) {
            Write-DeployLog "GitHub Pages enabled successfully" "SUCCESS"
            $pagesUrl = "https://$(& gh api user --jq .login).github.io/$RepositoryName"
            Write-DeployLog "Pages URL: $pagesUrl" "INFO"
        } else {
            Write-DeployLog "Failed to enable GitHub Pages (may already be enabled)" "WARNING"
        }
        
        return $true
        
    } catch {
        Write-DeployLog "GitHub Pages setup failed: $($_.Exception.Message)" "WARNING"
        return $true  # Not critical for deployment
    }
}

function Set-RepositorySecrets {
    Write-DeployLog "Setting up repository secrets..." "INFO"
    
    try {
        # List of secrets to set (user will be prompted)
        $secrets = @(
            @{ Name = "MCP_API_KEYS"; Description = "API keys for news sources (JSON format)" },
            @{ Name = "ALERT_WEBHOOK_URL"; Description = "Webhook URL for critical alerts" },
            @{ Name = "MONITORING_TOKEN"; Description = "Token for external monitoring services" }
        )
        
        foreach ($secret in $secrets) {
            Write-Host ""
            $value = Read-Host "Enter value for $($secret.Name) (optional - $($secret.Description))" -AsSecureString
            
            if ($value.Length -gt 0) {
                $plainValue = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($value)
                )
                
                & gh secret set $secret.Name --body $plainValue --repo $RepositoryName
                
                if ($LASTEXITCODE -eq 0) {
                    Write-DeployLog "Set secret: $($secret.Name)" "SUCCESS"
                } else {
                    Write-DeployLog "Failed to set secret: $($secret.Name)" "WARNING"
                }
            } else {
                Write-DeployLog "Skipped secret: $($secret.Name)" "INFO"
            }
        }
        
        return $true
        
    } catch {
        Write-DeployLog "Failed to set repository secrets: $($_.Exception.Message)" "WARNING"
        return $true  # Not critical for deployment
    }
}

function Generate-DeploymentReport {
    Write-DeployLog "Generating deployment report..." "INFO"
    
    try {
        $report = @{
            DeploymentSummary = @{
                Timestamp = Get-Date
                RepositoryName = $RepositoryName
                Visibility = $Visibility
                ErrorCount = $script:ErrorCount
                WarningCount = $script:WarningCount
                Status = if ($script:ErrorCount -eq 0) { "SUCCESS" } else { "FAILED" }
            }
            RepositoryInfo = @{
                URL = "https://github.com/$(& gh api user --jq .login)/$RepositoryName"
                PagesURL = if ($DeployPages) { "https://$(& gh api user --jq .login).github.io/$RepositoryName" } else { "Not configured" }
                ActionsURL = "https://github.com/$(& gh api user --jq .login)/$RepositoryName/actions"
            }
            DeploymentLog = $script:DeploymentLog
            NextSteps = @(
                "1. Visit repository: https://github.com/$(& gh api user --jq .login)/$RepositoryName",
                "2. Review GitHub Actions workflows",
                "3. Configure any required secrets",
                "4. Monitor deployment status",
                "5. Access documentation (if Pages enabled)"
            )
        }
        
        # Save report
        $reportPath = "deployment-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $report | ConvertTo-Json -Depth 4 | Out-File $reportPath -Encoding UTF8 -Force
        
        Write-DeployLog "Deployment report saved: $reportPath" "SUCCESS"
        
        return $report
        
    } catch {
        Write-DeployLog "Failed to generate deployment report: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

# Main deployment execution
try {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║             GitHub CLI Deployment Assistant                 ║" -ForegroundColor Green
    Write-Host "║        Enhanced Persistent Intelligence Platform            ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    Write-DeployLog "Starting GitHub CLI deployment for repository: $RepositoryName" "INFO"
    Write-DeployLog "Visibility: $Visibility" "INFO"
    Write-DeployLog "Setup Actions: $SetupActions" "INFO"
    Write-DeployLog "Deploy Pages: $DeployPages" "INFO"
    Write-Host ""
    
    # Execute deployment steps
    $deploymentSteps = @(
        @{ Name = "Prerequisites Check"; Function = { Test-Prerequisites } },
        @{ Name = "Repository Initialization"; Function = { Initialize-Repository } },
        @{ Name = "Deployment Files Preparation"; Function = { Prepare-DeploymentFiles } },
        @{ Name = "GitHub Actions Setup"; Function = { Setup-GitHubActions } },
        @{ Name = "GitHub Deployment"; Function = { Deploy-ToGitHub } },
        @{ Name = "GitHub Pages Setup"; Function = { Setup-GitHubPages } },
        @{ Name = "Repository Secrets Configuration"; Function = { Set-RepositorySecrets } }
    )
    
    $overallSuccess = $true
    
    foreach ($step in $deploymentSteps) {
        Write-Host "Executing: $($step.Name)..." -ForegroundColor Yellow
        $result = & $step.Function
        
        if (-not $result) {
            $overallSuccess = $false
            Write-DeployLog "Step failed: $($step.Name)" "ERROR"
        }
        
        Write-Host ""
    }
    
    # Generate final report
    $deploymentReport = Generate-DeploymentReport
    
    # Display summary
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                    DEPLOYMENT SUMMARY" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    if ($deploymentReport) {
        Write-DeployLog "Repository: $($deploymentReport.RepositoryInfo.URL)" "INFO"
        
        if ($SetupActions) {
            Write-DeployLog "Actions: $($deploymentReport.RepositoryInfo.ActionsURL)" "INFO"
        }
        
        if ($DeployPages -and $deploymentReport.RepositoryInfo.PagesURL -ne "Not configured") {
            Write-DeployLog "Pages: $($deploymentReport.RepositoryInfo.PagesURL)" "INFO"
        }
    }
    
    Write-DeployLog "Errors: $script:ErrorCount" "INFO"
    Write-DeployLog "Warnings: $script:WarningCount" "INFO"
    
    if ($overallSuccess -and $script:ErrorCount -eq 0) {
        Write-DeployLog "DEPLOYMENT: SUCCESSFUL ✅" "SUCCESS"
        Write-Host "Your Enhanced Persistent Intelligence Platform has been deployed to GitHub!" -ForegroundColor Green
    } else {
        Write-DeployLog "DEPLOYMENT: COMPLETED WITH ISSUES ⚠️" "WARNING"
        Write-Host "Deployment completed but some issues were encountered" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Visit your repository: https://github.com/$(& gh api user --jq .login)/$RepositoryName" -ForegroundColor White
    Write-Host "2. Review and configure GitHub Actions workflows" -ForegroundColor White
    Write-Host "3. Set up any required repository secrets" -ForegroundColor White
    Write-Host "4. Monitor the CI/CD pipeline execution" -ForegroundColor White
    
    if ($DeployPages) {
        Write-Host "5. Access documentation at: https://$(& gh api user --jq .login).github.io/$RepositoryName" -ForegroundColor White
    }
    
    Write-Host ""
    
} catch {
    Write-DeployLog "Critical deployment error: $($_.Exception.Message)" "ERROR"
    Write-Host "Deployment failed. Check the error messages above." -ForegroundColor Red
    exit 1
}
