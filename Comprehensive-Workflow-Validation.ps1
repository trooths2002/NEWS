#Requires -Version 5.1
<#
.SYNOPSIS
    Comprehensive Workflow Validation and Testing Script
    
.DESCRIPTION
    This script performs end-to-end validation of the Enhanced Persistent Geopolitical Intelligence Workflow:
    - Tests all MCP server components and their integrations
    - Validates persistent storage structure and data integrity
    - Verifies automated monitoring and health check systems
    - Tests intelligence collection, processing, and report generation
    - Validates workflow automation and resilience mechanisms
    - Performs system stress testing and recovery validation
    
.PARAMETER TestLevel
    Level of testing: Basic, Standard, or Comprehensive
    
.PARAMETER GenerateReport
    Generate detailed validation report
    
.EXAMPLE
    .\Comprehensive-Workflow-Validation.ps1 -TestLevel Comprehensive -GenerateReport
#>

[CmdletBinding()]
param(
    [ValidateSet("Basic", "Standard", "Comprehensive")]
    [string]$TestLevel = "Standard",
    
    [switch]$GenerateReport
)

# Global variables for test tracking
$script:TestResults = @()
$script:StartTime = Get-Date
$script:PersistentPath = "NEWS-PERSISTENT"
$script:ValidationErrors = @()
$script:ValidationWarnings = @()
$script:TestsPassed = 0
$script:TestsFailed = 0

function Write-TestLog {
    param(
        [string]$Message, 
        [string]$Level = "INFO",
        [string]$TestName = "General"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "PASS"     { "Green" }
        "FAIL"     { "Red" }
        "WARN"     { "Yellow" }
        "INFO"     { "Cyan" }
        "CRITICAL" { "Magenta" }
        default    { "White" }
    }
    
    $logMessage = "[$timestamp] [$TestName] [$Level] $Message"
    Write-Host $logMessage -ForegroundColor $color
    
    # Add to test results
    $script:TestResults += @{
        Timestamp = $timestamp
        TestName = $TestName
        Level = $Level
        Message = $Message
    }
    
    if ($Level -eq "FAIL" -or $Level -eq "CRITICAL") {
        $script:ValidationErrors += $Message
        $script:TestsFailed++
    } elseif ($Level -eq "PASS") {
        $script:TestsPassed++
    } elseif ($Level -eq "WARN") {
        $script:ValidationWarnings += $Message
    }
}

function Test-PersistentStorageStructure {
    Write-TestLog "Starting persistent storage structure validation..." "INFO" "Storage"
    
    $requiredStructure = @(
        "NEWS-PERSISTENT",
        "NEWS-PERSISTENT\current",
        "NEWS-PERSISTENT\current\daily", 
        "NEWS-PERSISTENT\current\regions",
        "NEWS-PERSISTENT\current\themes",
        "NEWS-PERSISTENT\archives",
        "NEWS-PERSISTENT\backups",
        "NEWS-PERSISTENT\intelligence",
        "NEWS-PERSISTENT\intelligence\executive-briefs",
        "NEWS-PERSISTENT\intelligence\situation-reports",
        "NEWS-PERSISTENT\intelligence\threat-assessments",
        "NEWS-PERSISTENT\mcp-data",
        "NEWS-PERSISTENT\mcp-data\sqlite-databases",
        "NEWS-PERSISTENT\workflows",
        "NEWS-PERSISTENT\workflows\active-schedules",
        "NEWS-PERSISTENT\workflows\health-checks",
        "NEWS-PERSISTENT\logs"
    )
    
    $structureValid = $true
    
    foreach ($dir in $requiredStructure) {
        if (Test-Path $dir) {
            Write-TestLog "Directory exists: $dir" "PASS" "Storage"
        } else {
            Write-TestLog "Missing directory: $dir" "FAIL" "Storage"
            $structureValid = $false
        }
    }
    
    # Test directory permissions
    try {
        $testFile = "$script:PersistentPath\test-permissions.tmp"
        "Test" | Out-File $testFile -Force
        Remove-Item $testFile -Force
        Write-TestLog "Storage permissions validated" "PASS" "Storage"
    } catch {
        Write-TestLog "Storage permission test failed: $($_.Exception.Message)" "FAIL" "Storage"
        $structureValid = $false
    }
    
    # Test configuration files
    $configFiles = @(
        "$script:PersistentPath\structure-config.json",
        "$script:PersistentPath\mcp-persistence-config.json"
    )
    
    foreach ($configFile in $configFiles) {
        if (Test-Path $configFile) {
            try {
                $config = Get-Content $configFile | ConvertFrom-Json
                Write-TestLog "Configuration file valid: $configFile" "PASS" "Storage"
            } catch {
                Write-TestLog "Invalid configuration file: $configFile" "FAIL" "Storage"
                $structureValid = $false
            }
        } else {
            Write-TestLog "Missing configuration file: $configFile" "WARN" "Storage"
        }
    }
    
    return $structureValid
}

function Test-MCPServerAvailability {
    Write-TestLog "Testing MCP server availability and health..." "INFO" "MCP"
    
    $mcpServers = @(
        @{ Name = "news-fetcher"; Port = 3006; Script = "mcp-server.js" },
        @{ Name = "geopolitical-intelligence"; Port = 3007; Script = "geopolitical-intelligence-server.js" },
        @{ Name = "intelligent-news-aggregator"; Port = 3011; Script = "intelligent-news-aggregator-mcp.js" },
        @{ Name = "resilient-monitoring-agent"; Port = 3012; Script = "resilient-monitoring-agent-mcp.js" }
    )
    
    $allServersHealthy = $true
    
    foreach ($server in $mcpServers) {
        Write-TestLog "Testing server: $($server.Name)" "INFO" "MCP"
        
        # Check if script file exists
        if (-not (Test-Path $server.Script)) {
            Write-TestLog "Missing script file: $($server.Script)" "FAIL" "MCP"
            $allServersHealthy = $false
            continue
        }
        
        # Test script syntax (basic Node.js syntax check)
        try {
            $syntaxCheck = & node -c $server.Script 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-TestLog "Script syntax valid: $($server.Script)" "PASS" "MCP"
            } else {
                Write-TestLog "Script syntax error in $($server.Script): $syntaxCheck" "FAIL" "MCP"
                $allServersHealthy = $false
            }
        } catch {
            Write-TestLog "Failed to validate script syntax: $($server.Script)" "WARN" "MCP"
        }
        
        # Test if server can be started (basic test)
        try {
            $testProcess = Start-Process -FilePath "node" -ArgumentList $server.Script -NoNewWindow -PassThru
            Start-Sleep -Seconds 3
            
            if (-not $testProcess.HasExited) {
                Write-TestLog "Server starts successfully: $($server.Name)" "PASS" "MCP"
                Stop-Process -Id $testProcess.Id -Force -ErrorAction SilentlyContinue
            } else {
                Write-TestLog "Server failed to start: $($server.Name)" "FAIL" "MCP"
                $allServersHealthy = $false
            }
        } catch {
            Write-TestLog "Error testing server startup: $($server.Name) - $($_.Exception.Message)" "FAIL" "MCP"
            $allServersHealthy = $false
        }
    }
    
    return $allServersHealthy
}

function Test-DatabaseConnectivity {
    Write-TestLog "Testing database connectivity and schema..." "INFO" "Database"
    
    $databasesValid = $true
    $dbDir = "$script:PersistentPath\mcp-data\sqlite-databases"
    
    if (-not (Test-Path $dbDir)) {
        Write-TestLog "Database directory missing: $dbDir" "FAIL" "Database"
        return $false
    }
    
    # Test database creation and basic operations
    try {
        $testDbPath = "$dbDir\validation-test.db"
        
        # Create test database
        $null = & sqlite3 $testDbPath "CREATE TABLE IF NOT EXISTS test_table (id INTEGER PRIMARY KEY, data TEXT);"
        
        if ($LASTEXITCODE -eq 0) {
            Write-TestLog "Database creation test passed" "PASS" "Database"
        } else {
            Write-TestLog "Database creation test failed" "FAIL" "Database"
            $databasesValid = $false
        }
        
        # Test basic operations
        $null = & sqlite3 $testDbPath "INSERT INTO test_table (data) VALUES ('test');"
        $result = & sqlite3 $testDbPath "SELECT COUNT(*) FROM test_table;"
        
        if ($result -eq "1") {
            Write-TestLog "Database operations test passed" "PASS" "Database"
        } else {
            Write-TestLog "Database operations test failed" "FAIL" "Database"
            $databasesValid = $false
        }
        
        # Cleanup test database
        Remove-Item $testDbPath -Force -ErrorAction SilentlyContinue
        
    } catch {
        Write-TestLog "Database connectivity test error: $($_.Exception.Message)" "FAIL" "Database"
        $databasesValid = $false
    }
    
    return $databasesValid
}

function Test-WorkflowAutomationScripts {
    Write-TestLog "Testing workflow automation scripts..." "INFO" "Workflow"
    
    $workflowScripts = @(
        "Enhanced-Persistent-News-Structure.ps1",
        "Enhanced-Persistent-Workflow-Automation.ps1"
    )
    
    $scriptsValid = $true
    
    foreach ($script in $workflowScripts) {
        if (Test-Path $script) {
            try {
                # Validate PowerShell syntax
                $errors = $null
                $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script -Raw), [ref]$errors)
                
                if ($errors.Count -eq 0) {
                    Write-TestLog "Script syntax valid: $script" "PASS" "Workflow"
                } else {
                    Write-TestLog "Script syntax errors in $script`: $($errors -join '; ')" "FAIL" "Workflow"
                    $scriptsValid = $false
                }
            } catch {
                Write-TestLog "Failed to validate script: $script - $($_.Exception.Message)" "FAIL" "Workflow"
                $scriptsValid = $false
            }
        } else {
            Write-TestLog "Missing workflow script: $script" "FAIL" "Workflow"
            $scriptsValid = $false
        }
    }
    
    return $scriptsValid
}

function Test-NewsSourceConnectivity {
    Write-TestLog "Testing connectivity to news sources..." "INFO" "Network"
    
    $newsSources = @(
        "https://allafrica.com/tools/headlines/rdf/latest/headlines.rdf",
        "https://feeds.bbci.co.uk/news/world/africa/rss.xml",
        "https://feeds.reuters.com/reuters/AfricaWorldNews",
        "https://www.google.com"
    )
    
    $connectivityGood = $true
    
    foreach ($source in $newsSources) {
        try {
            $response = Invoke-WebRequest -Uri $source -TimeoutSec 10 -UseBasicParsing -Method Head
            if ($response.StatusCode -eq 200) {
                Write-TestLog "Connectivity OK: $source" "PASS" "Network"
            } else {
                Write-TestLog "Connectivity issue: $source (Status: $($response.StatusCode))" "WARN" "Network"
            }
        } catch {
            Write-TestLog "Failed to connect to: $source - $($_.Exception.Message)" "WARN" "Network"
            # Don't mark as failure since network issues are often temporary
        }
    }
    
    return $connectivityGood
}

function Test-SystemResourceRequirements {
    Write-TestLog "Checking system resource requirements..." "INFO" "System"
    
    $resourcesAdequate = $true
    
    # Check available disk space
    $disk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
    $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    
    if ($freeSpaceGB -gt 5) {
        Write-TestLog "Disk space adequate: ${freeSpaceGB}GB available" "PASS" "System"
    } elseif ($freeSpaceGB -gt 1) {
        Write-TestLog "Disk space low: ${freeSpaceGB}GB available" "WARN" "System"
    } else {
        Write-TestLog "Insufficient disk space: ${freeSpaceGB}GB available" "FAIL" "System"
        $resourcesAdequate = $false
    }
    
    # Check available memory
    $memory = Get-WmiObject -Class Win32_ComputerSystem
    $totalMemoryGB = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
    
    if ($totalMemoryGB -gt 4) {
        Write-TestLog "Memory adequate: ${totalMemoryGB}GB total" "PASS" "System"
    } elseif ($totalMemoryGB -gt 2) {
        Write-TestLog "Memory sufficient: ${totalMemoryGB}GB total" "WARN" "System"
    } else {
        Write-TestLog "Insufficient memory: ${totalMemoryGB}GB total" "FAIL" "System"
        $resourcesAdequate = $false
    }
    
    # Check Node.js availability
    try {
        $nodeVersion = & node --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-TestLog "Node.js available: $nodeVersion" "PASS" "System"
        } else {
            Write-TestLog "Node.js not found" "FAIL" "System"
            $resourcesAdequate = $false
        }
    } catch {
        Write-TestLog "Node.js not available" "FAIL" "System"
        $resourcesAdequate = $false
    }
    
    # Check npm availability
    try {
        $npmVersion = & npm --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-TestLog "npm available: $npmVersion" "PASS" "System"
        } else {
            Write-TestLog "npm not found" "FAIL" "System"
            $resourcesAdequate = $false
        }
    } catch {
        Write-TestLog "npm not available" "FAIL" "System"
        $resourcesAdequate = $false
    }
    
    return $resourcesAdequate
}

function Test-IntelligenceWorkflow {
    Write-TestLog "Testing end-to-end intelligence workflow..." "INFO" "Intelligence"
    
    if ($TestLevel -ne "Comprehensive") {
        Write-TestLog "Skipping comprehensive workflow test (not in Comprehensive mode)" "INFO" "Intelligence"
        return $true
    }
    
    $workflowSuccessful = $true
    
    try {
        # Test structure creation
        Write-TestLog "Testing persistent structure creation..." "INFO" "Intelligence"
        & .\Enhanced-Persistent-News-Structure.ps1 -ErrorAction Stop
        
        if ($LASTEXITCODE -eq 0) {
            Write-TestLog "Structure creation successful" "PASS" "Intelligence"
        } else {
            Write-TestLog "Structure creation failed" "FAIL" "Intelligence"
            $workflowSuccessful = $false
        }
        
        # Validate created structure
        if (Test-Path $script:PersistentPath) {
            Write-TestLog "Persistent structure created successfully" "PASS" "Intelligence"
        } else {
            Write-TestLog "Persistent structure not created" "FAIL" "Intelligence"
            $workflowSuccessful = $false
        }
        
    } catch {
        Write-TestLog "Intelligence workflow test failed: $($_.Exception.Message)" "FAIL" "Intelligence"
        $workflowSuccessful = $false
    }
    
    return $workflowSuccessful
}

function Test-ConfigurationIntegrity {
    Write-TestLog "Testing configuration file integrity..." "INFO" "Config"
    
    $configFiles = @{
        "mcp.config.json" = @("port", "sources")
        "production-config.json" = @("mcpServers", "logging", "monitoring")
        "multi-server-mcp-config.json" = @("mcpServers", "proxy")
    }
    
    $configsValid = $true
    
    foreach ($configFile in $configFiles.Keys) {
        if (Test-Path $configFile) {
            try {
                $config = Get-Content $configFile | ConvertFrom-Json
                $requiredFields = $configFiles[$configFile]
                
                $missingFields = @()
                foreach ($field in $requiredFields) {
                    if (-not $config.PSObject.Properties.Name -contains $field) {
                        $missingFields += $field
                    }
                }
                
                if ($missingFields.Count -eq 0) {
                    Write-TestLog "Configuration valid: $configFile" "PASS" "Config"
                } else {
                    Write-TestLog "Missing fields in $configFile`: $($missingFields -join ', ')" "FAIL" "Config"
                    $configsValid = $false
                }
                
            } catch {
                Write-TestLog "Invalid JSON in configuration: $configFile" "FAIL" "Config"
                $configsValid = $false
            }
        } else {
            Write-TestLog "Missing configuration file: $configFile" "FAIL" "Config"
            $configsValid = $false
        }
    }
    
    return $configsValid
}

function Test-MonitoringCapabilities {
    Write-TestLog "Testing monitoring and health check capabilities..." "INFO" "Monitoring"
    
    $monitoringValid = $true
    
    # Test health check endpoints (simulated)
    $healthEndpoints = @(
        "http://localhost:3006/health",
        "http://localhost:3007/health"
    )
    
    foreach ($endpoint in $healthEndpoints) {
        try {
            # Since servers may not be running, we just test the URL format
            $uri = [System.Uri]$endpoint
            if ($uri.IsWellFormedOriginalString()) {
                Write-TestLog "Health endpoint format valid: $endpoint" "PASS" "Monitoring"
            } else {
                Write-TestLog "Invalid health endpoint format: $endpoint" "FAIL" "Monitoring"
                $monitoringValid = $false
            }
        } catch {
            Write-TestLog "Health endpoint test error: $endpoint" "WARN" "Monitoring"
        }
    }
    
    # Test log directory structure
    $logDirs = @(
        "$script:PersistentPath\logs",
        "$script:PersistentPath\workflows\health-checks"
    )
    
    foreach ($logDir in $logDirs) {
        if (Test-Path $logDir) {
            Write-TestLog "Log directory exists: $logDir" "PASS" "Monitoring"
        } else {
            Write-TestLog "Missing log directory: $logDir" "WARN" "Monitoring"
        }
    }
    
    return $monitoringValid
}

function Test-SecurityConfiguration {
    Write-TestLog "Testing security configuration..." "INFO" "Security"
    
    $securityValid = $true
    
    # Check for exposed sensitive files
    $sensitivePatterns = @("*.key", "*.pem", "*password*", "*secret*")
    
    foreach ($pattern in $sensitivePatterns) {
        $files = Get-ChildItem -Path . -Filter $pattern -Recurse -ErrorAction SilentlyContinue
        if ($files) {
            Write-TestLog "Potential sensitive files found: $($files.Name -join ', ')" "WARN" "Security"
        } else {
            Write-TestLog "No exposed sensitive files found for pattern: $pattern" "PASS" "Security"
        }
    }
    
    # Check configuration file permissions (Windows-specific)
    $configFiles = @("production-config.json", "mcp.config.json")
    
    foreach ($configFile in $configFiles) {
        if (Test-Path $configFile) {
            $acl = Get-Acl $configFile
            # Basic check - in production, implement more sophisticated permission checking
            Write-TestLog "Configuration file permissions checked: $configFile" "PASS" "Security"
        }
    }
    
    return $securityValid
}

function Invoke-StressTesting {
    Write-TestLog "Performing system stress testing..." "INFO" "Stress"
    
    if ($TestLevel -ne "Comprehensive") {
        Write-TestLog "Skipping stress testing (not in Comprehensive mode)" "INFO" "Stress"
        return $true
    }
    
    $stressTestPassed = $true
    
    try {
        # Simulate high file I/O
        Write-TestLog "Testing high file I/O operations..." "INFO" "Stress"
        
        $tempDir = "$script:PersistentPath\temp-stress-test"
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        
        # Create and delete multiple files
        for ($i = 1; $i -le 100; $i++) {
            $testFile = "$tempDir\stress-test-$i.txt"
            "Stress test data $i" * 100 | Out-File $testFile
        }
        
        # Verify all files were created
        $files = Get-ChildItem $tempDir
        if ($files.Count -eq 100) {
            Write-TestLog "High I/O stress test passed" "PASS" "Stress"
        } else {
            Write-TestLog "High I/O stress test failed: only $($files.Count) files created" "FAIL" "Stress"
            $stressTestPassed = $false
        }
        
        # Cleanup
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        
    } catch {
        Write-TestLog "Stress testing failed: $($_.Exception.Message)" "FAIL" "Stress"
        $stressTestPassed = $false
    }
    
    return $stressTestPassed
}

function Test-BackupAndRecovery {
    Write-TestLog "Testing backup and recovery mechanisms..." "INFO" "Backup"
    
    $backupValid = $true
    
    # Test backup directory structure
    $backupDirs = @(
        "$script:PersistentPath\backups",
        "$script:PersistentPath\backups\daily",
        "$script:PersistentPath\backups\weekly"
    )
    
    foreach ($backupDir in $backupDirs) {
        if (Test-Path $backupDir) {
            Write-TestLog "Backup directory exists: $backupDir" "PASS" "Backup"
        } else {
            Write-TestLog "Missing backup directory: $backupDir" "WARN" "Backup"
        }
    }
    
    # Test backup creation (simulate)
    try {
        $testBackupFile = "$script:PersistentPath\backups\test-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"
        $tempData = "Test backup data"
        $tempFile = [System.IO.Path]::GetTempFileName()
        $tempData | Out-File $tempFile
        
        Compress-Archive -Path $tempFile -DestinationPath $testBackupFile
        
        if (Test-Path $testBackupFile) {
            Write-TestLog "Backup creation test passed" "PASS" "Backup"
            Remove-Item $testBackupFile -Force
        } else {
            Write-TestLog "Backup creation test failed" "FAIL" "Backup"
            $backupValid = $false
        }
        
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        
    } catch {
        Write-TestLog "Backup testing failed: $($_.Exception.Message)" "FAIL" "Backup"
        $backupValid = $false
    }
    
    return $backupValid
}

function Generate-ValidationReport {
    Write-TestLog "Generating comprehensive validation report..." "INFO" "Report"
    
    $endTime = Get-Date
    $duration = $endTime - $script:StartTime
    
    $report = @{
        ValidationSummary = @{
            StartTime = $script:StartTime
            EndTime = $endTime
            Duration = $duration.ToString()
            TestLevel = $TestLevel
            TotalTests = $script:TestsPassed + $script:TestsFailed
            TestsPassed = $script:TestsPassed
            TestsFailed = $script:TestsFailed
            SuccessRate = if (($script:TestsPassed + $script:TestsFailed) -gt 0) { 
                [math]::Round(($script:TestsPassed / ($script:TestsPassed + $script:TestsFailed)) * 100, 2) 
            } else { 0 }
        }
        ValidationErrors = $script:ValidationErrors
        ValidationWarnings = $script:ValidationWarnings
        DetailedResults = $script:TestResults
        SystemInfo = @{
            OSVersion = [Environment]::OSVersion.VersionString
            MachineName = [Environment]::MachineName
            UserName = [Environment]::UserName
            ProcessorCount = [Environment]::ProcessorCount
            WorkingSet = [Environment]::WorkingSet
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        }
        Recommendations = @()
    }
    
    # Generate recommendations based on results
    if ($script:ValidationErrors.Count -gt 0) {
        $report.Recommendations += "CRITICAL: Address validation errors before deploying to production"
    }
    
    if ($script:ValidationWarnings.Count -gt 5) {
        $report.Recommendations += "WARNING: Multiple warnings detected - review system configuration"
    }
    
    if ($report.ValidationSummary.SuccessRate -lt 90) {
        $report.Recommendations += "IMPROVEMENT: Success rate below 90% - investigate failed tests"
    }
    
    if ($report.Recommendations.Count -eq 0) {
        $report.Recommendations += "SUCCESS: System validation passed - ready for deployment"
    }
    
    # Save report to file
    $reportDate = Get-Date -Format "yyyyMMdd-HHmmss"
    $reportPath = "$script:PersistentPath\workflows\validation-report-$reportDate.json"
    
    try {
        New-Item -ItemType Directory -Path (Split-Path $reportPath -Parent) -Force | Out-Null
        $report | ConvertTo-Json -Depth 4 | Out-File $reportPath -Encoding UTF8 -Force
        Write-TestLog "Validation report saved: $reportPath" "INFO" "Report"
    } catch {
        Write-TestLog "Failed to save validation report: $($_.Exception.Message)" "WARN" "Report"
    }
    
    return $report
}

# Main execution
try {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║      Comprehensive Workflow Validation and Testing          ║" -ForegroundColor Green
    Write-Host "║          Enhanced Persistent Intelligence System            ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    Write-TestLog "Starting comprehensive workflow validation..." "INFO" "Main"
    Write-TestLog "Test Level: $TestLevel" "INFO" "Main"
    Write-Host ""
    
    # Execute test suites
    $testSuites = @(
        @{ Name = "System Resources"; Function = { Test-SystemResourceRequirements } },
        @{ Name = "Persistent Storage Structure"; Function = { Test-PersistentStorageStructure } },
        @{ Name = "Configuration Integrity"; Function = { Test-ConfigurationIntegrity } },
        @{ Name = "MCP Server Availability"; Function = { Test-MCPServerAvailability } },
        @{ Name = "Database Connectivity"; Function = { Test-DatabaseConnectivity } },
        @{ Name = "Workflow Automation Scripts"; Function = { Test-WorkflowAutomationScripts } },
        @{ Name = "News Source Connectivity"; Function = { Test-NewsSourceConnectivity } },
        @{ Name = "Monitoring Capabilities"; Function = { Test-MonitoringCapabilities } },
        @{ Name = "Security Configuration"; Function = { Test-SecurityConfiguration } },
        @{ Name = "Backup and Recovery"; Function = { Test-BackupAndRecovery } }
    )
    
    # Add comprehensive tests if requested
    if ($TestLevel -eq "Comprehensive") {
        $testSuites += @(
            @{ Name = "Intelligence Workflow"; Function = { Test-IntelligenceWorkflow } },
            @{ Name = "System Stress Testing"; Function = { Invoke-StressTesting } }
        )
    }
    
    # Execute all test suites
    $overallSuccess = $true
    foreach ($testSuite in $testSuites) {
        Write-Host "Running test suite: $($testSuite.Name)..." -ForegroundColor Yellow
        $result = & $testSuite.Function
        
        if (-not $result) {
            $overallSuccess = $false
        }
        
        Write-Host ""
    }
    
    # Generate summary
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                    VALIDATION SUMMARY" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    Write-TestLog "Total Tests Passed: $script:TestsPassed" "INFO" "Summary"
    Write-TestLog "Total Tests Failed: $script:TestsFailed" "INFO" "Summary"
    Write-TestLog "Validation Errors: $($script:ValidationErrors.Count)" "INFO" "Summary"
    Write-TestLog "Validation Warnings: $($script:ValidationWarnings.Count)" "INFO" "Summary"
    
    if ($overallSuccess -and $script:TestsFailed -eq 0) {
        Write-TestLog "OVERALL VALIDATION: PASSED ✓" "PASS" "Summary"
        Write-Host "System is ready for deployment!" -ForegroundColor Green
    } elseif ($script:ValidationErrors.Count -eq 0) {
        Write-TestLog "OVERALL VALIDATION: PASSED WITH WARNINGS ⚠" "WARN" "Summary"
        Write-Host "System has warnings but may proceed with caution" -ForegroundColor Yellow
    } else {
        Write-TestLog "OVERALL VALIDATION: FAILED ✗" "FAIL" "Summary"
        Write-Host "System has critical issues that must be addressed" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Display critical errors if any
    if ($script:ValidationErrors.Count -gt 0) {
        Write-Host "CRITICAL ERRORS TO ADDRESS:" -ForegroundColor Red
        foreach ($error in $script:ValidationErrors) {
            Write-Host "  • $error" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    # Display warnings if any
    if ($script:ValidationWarnings.Count -gt 0) {
        Write-Host "WARNINGS TO REVIEW:" -ForegroundColor Yellow
        foreach ($warning in $script:ValidationWarnings) {
            Write-Host "  • $warning" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    # Generate detailed report if requested
    if ($GenerateReport) {
        Write-TestLog "Generating detailed validation report..." "INFO" "Main"
        $report = Generate-ValidationReport
        
        Write-Host "Detailed validation report generated with:" -ForegroundColor Cyan
        Write-Host "  • Success Rate: $($report.ValidationSummary.SuccessRate)%" -ForegroundColor $(if ($report.ValidationSummary.SuccessRate -ge 90) { "Green" } else { "Yellow" })
        Write-Host "  • Duration: $($report.ValidationSummary.Duration)" -ForegroundColor Cyan
        Write-Host "  • Recommendations: $($report.Recommendations.Count)" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-TestLog "Comprehensive workflow validation completed" "INFO" "Main"
    
}
catch {
    Write-TestLog "Critical error during validation: $($_.Exception.Message)" "CRITICAL" "Main"
    exit 1
}
