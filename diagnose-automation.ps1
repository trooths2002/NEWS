# Advanced Automation Diagnostic Script
# Tests all components of the advanced-mcp-automation.ps1 script step by step

param(
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Continue"
$DiagnosticResults = @()

function Add-DiagnosticResult {
    param($Test, $Status, $Message, $Details = "")
    $Result = [PSCustomObject]@{
        Test = $Test
        Status = $Status
        Message = $Message
        Details = $Details
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    $DiagnosticResults += $Result
    
    $Color = switch($Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARN" { "Yellow" }
        default { "White" }
    }
    Write-Host "$Status - $Test`: $Message" -ForegroundColor $Color
    if ($Details -and $Verbose) {
        Write-Host "  Details: $Details" -ForegroundColor Gray
    }
    return $Result
}

Write-Host "🔍 Advanced Automation Diagnostic Test" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: PowerShell Execution Policy
Write-Host "1. Testing PowerShell Environment..." -ForegroundColor Yellow
try {
    $ExecutionPolicy = Get-ExecutionPolicy
    if ($ExecutionPolicy -eq "Restricted") {
        Add-DiagnosticResult "ExecutionPolicy" "FAIL" "Execution policy is Restricted" $ExecutionPolicy
    } else {
        Add-DiagnosticResult "ExecutionPolicy" "PASS" "Execution policy allows script execution" $ExecutionPolicy
    }
} catch {
    Add-DiagnosticResult "ExecutionPolicy" "FAIL" "Cannot check execution policy" $_.Exception.Message
}

# Test 2: Required Files Existence
Write-Host "2. Testing Required Files..." -ForegroundColor Yellow
$RequiredFiles = @(
    "advanced-mcp-automation.ps1",
    "fetchAllAfrica.js",
    "package.json"
)

foreach ($File in $RequiredFiles) {
    if (Test-Path $File) {
        Add-DiagnosticResult "File-$File" "PASS" "File exists" (Get-Item $File).FullName
    } else {
        Add-DiagnosticResult "File-$File" "FAIL" "File missing" $File
    }
}

# Test 3: Required Directories
Write-Host "3. Testing Required Directories..." -ForegroundColor Yellow
$RequiredDirs = @("images", "workflows", "archives")

foreach ($Dir in $RequiredDirs) {
    if (Test-Path $Dir -PathType Container) {
        $ItemCount = (Get-ChildItem $Dir -ErrorAction SilentlyContinue).Count
        Add-DiagnosticResult "Directory-$Dir" "PASS" "Directory exists" "$ItemCount items"
    } else {
        Add-DiagnosticResult "Directory-$Dir" "WARN" "Directory missing - will be created" $Dir
        try {
            New-Item -ItemType Directory -Path $Dir -Force | Out-Null
            Add-DiagnosticResult "Directory-$Dir-Create" "PASS" "Directory created successfully" $Dir
        } catch {
            Add-DiagnosticResult "Directory-$Dir-Create" "FAIL" "Failed to create directory" $_.Exception.Message
        }
    }
}

# Test 4: Node.js Environment
Write-Host "4. Testing Node.js Environment..." -ForegroundColor Yellow
try {
    $NodeVersion = node --version 2>$null
    if ($NodeVersion) {
        Add-DiagnosticResult "Node.js" "PASS" "Node.js is available" $NodeVersion
        
        # Test npm
        $NpmVersion = npm --version 2>$null
        if ($NpmVersion) {
            Add-DiagnosticResult "npm" "PASS" "npm is available" $NpmVersion
        } else {
            Add-DiagnosticResult "npm" "FAIL" "npm not available" ""
        }
    } else {
        Add-DiagnosticResult "Node.js" "FAIL" "Node.js not found in PATH" ""
    }
} catch {
    Add-DiagnosticResult "Node.js" "FAIL" "Error checking Node.js" $_.Exception.Message
}

# Test 5: Node Dependencies
Write-Host "5. Testing Node.js Dependencies..." -ForegroundColor Yellow
if (Test-Path "package.json") {
    try {
        $PackageJson = Get-Content "package.json" | ConvertFrom-Json
        $Dependencies = $PackageJson.dependencies
        
        foreach ($Dep in $Dependencies.PSObject.Properties) {
            $DepName = $Dep.Name
            $DepVersion = $Dep.Value
            
            # Check if node_modules exists for this dependency
            $ModulePath = "node_modules\$DepName"
            if (Test-Path $ModulePath) {
                Add-DiagnosticResult "Dependency-$DepName" "PASS" "Dependency installed" $DepVersion
            } else {
                Add-DiagnosticResult "Dependency-$DepName" "WARN" "Dependency not found in node_modules" $DepVersion
            }
        }
    } catch {
        Add-DiagnosticResult "Dependencies" "FAIL" "Error reading package.json" $_.Exception.Message
    }
} else {
    Add-DiagnosticResult "Dependencies" "FAIL" "package.json not found" ""
}

# Test 6: Core News Fetcher Test
Write-Host "6. Testing Core News Fetcher..." -ForegroundColor Yellow
if (Test-Path "fetchAllAfrica.js") {
    try {
        Write-Host "  Running fetchAllAfrica.js (timeout: 30 seconds)..." -ForegroundColor Gray
        $FetchJob = Start-Job -ScriptBlock {
            Set-Location $using:PWD
            node fetchAllAfrica.js 2>&1
        }
        
        $FetchResult = Wait-Job $FetchJob -Timeout 30
        if ($FetchResult) {
            $FetchOutput = Receive-Job $FetchJob
            Remove-Job $FetchJob
            
            if ($FetchOutput -match "error|Error|ERROR") {
                Add-DiagnosticResult "NewsFetcher" "WARN" "News fetcher completed with warnings" ($FetchOutput -join "; ")
            } else {
                Add-DiagnosticResult "NewsFetcher" "PASS" "News fetcher executed successfully" ($FetchOutput -join "; ")
            }
        } else {
            Remove-Job $FetchJob -Force
            Add-DiagnosticResult "NewsFetcher" "FAIL" "News fetcher timed out (30s)" ""
        }
    } catch {
        Add-DiagnosticResult "NewsFetcher" "FAIL" "Error running news fetcher" $_.Exception.Message
    }
} else {
    Add-DiagnosticResult "NewsFetcher" "FAIL" "fetchAllAfrica.js not found" ""
}

# Test 7: Advanced Script Syntax Check
Write-Host "7. Testing Advanced Script Syntax..." -ForegroundColor Yellow
if (Test-Path "advanced-mcp-automation.ps1") {
    try {
        $ScriptContent = Get-Content "advanced-mcp-automation.ps1" -Raw
        # Test syntax by attempting to create a script block
        [void][ScriptBlock]::Create($ScriptContent)
        Add-DiagnosticResult "ScriptSyntax" "PASS" "Advanced script syntax is valid" ""
    } catch {
        Add-DiagnosticResult "ScriptSyntax" "FAIL" "Advanced script syntax error" $_.Exception.Message
    }
} else {
    Add-DiagnosticResult "ScriptSyntax" "FAIL" "Advanced script not found" ""
}

# Test 8: Timestamp and Variables Issue Check
Write-Host "8. Testing Advanced Script Variables..." -ForegroundColor Yellow
try {
    # Check for the timestamp variable issue that causes scripts to fail
    $ScriptContent = Get-Content "advanced-mcp-automation.ps1" -Raw
    
    # Check for proper variable scoping in Write-Log function
    if ($ScriptContent -match '\$TimeStamp\s*=.*Get-Date.*-Format') {
        # Check if TimeStamp is defined globally but used in function
        if ($ScriptContent -match 'function Write-Log.*\$TimeStamp') {
            Add-DiagnosticResult "VariableScope" "WARN" "TimeStamp variable scope issue detected" "TimeStamp defined globally but used in function"
        } else {
            Add-DiagnosticResult "VariableScope" "PASS" "Variable scoping appears correct" ""
        }
    }
    
    # Check for potential path issues
    if ($ScriptContent -match '\\[a-zA-Z]') {
        Add-DiagnosticResult "PathSeparators" "WARN" "Potential backslash path separator issues" "Use forward slashes or proper escaping"
    } else {
        Add-DiagnosticResult "PathSeparators" "PASS" "Path separators look correct" ""
    }
    
} catch {
    Add-DiagnosticResult "VariableAnalysis" "FAIL" "Error analyzing script variables" $_.Exception.Message
}

# Test 9: Test Minimal Advanced Script Execution
Write-Host "9. Testing Advanced Script (Test Mode)..." -ForegroundColor Yellow
try {
    Write-Host "  Running advanced-mcp-automation.ps1 in test mode..." -ForegroundColor Gray
    $AdvancedJob = Start-Job -ScriptBlock {
        Set-Location $using:PWD
        powershell -ExecutionPolicy Bypass -File "advanced-mcp-automation.ps1" -Mode test 2>&1
    }
    
    $AdvancedResult = Wait-Job $AdvancedJob -Timeout 60
    if ($AdvancedResult) {
        $AdvancedOutput = Receive-Job $AdvancedJob
        Remove-Job $AdvancedJob
        
        if ($AdvancedOutput -match "error|Error|ERROR|exception|Exception") {
            Add-DiagnosticResult "AdvancedScript" "FAIL" "Advanced script failed in test mode" ($AdvancedOutput -join "; ")
        } else {
            Add-DiagnosticResult "AdvancedScript" "PASS" "Advanced script test mode completed" ($AdvancedOutput -join "; ")
        }
    } else {
        Remove-Job $AdvancedJob -Force
        Add-DiagnosticResult "AdvancedScript" "FAIL" "Advanced script timed out (60s)" ""
    }
} catch {
    Add-DiagnosticResult "AdvancedScript" "FAIL" "Error running advanced script" $_.Exception.Message
}

# Test 10: Check Created Files
Write-Host "10. Checking Output Files..." -ForegroundColor Yellow
$ExpectedFiles = @(
    "multi-mcp-workflow.log",
    "enhanced-config.json", 
    "workflows\test-integration.txt"
)

foreach ($File in $ExpectedFiles) {
    if (Test-Path $File) {
        $FileSize = (Get-Item $File).Length
        Add-DiagnosticResult "Output-$($File.Replace('\','-'))" "PASS" "Output file created" "$FileSize bytes"
    } else {
        Add-DiagnosticResult "Output-$($File.Replace('\','-'))" "WARN" "Expected output file not created" $File
    }
}

# Summary
Write-Host ""
Write-Host "📊 Diagnostic Summary" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan

$PassCount = ($DiagnosticResults | Where-Object { $_.Status -eq "PASS" }).Count
$FailCount = ($DiagnosticResults | Where-Object { $_.Status -eq "FAIL" }).Count
$WarnCount = ($DiagnosticResults | Where-Object { $_.Status -eq "WARN" }).Count
$TotalCount = $DiagnosticResults.Count

Write-Host "✅ PASSED: $PassCount" -ForegroundColor Green
Write-Host "❌ FAILED: $FailCount" -ForegroundColor Red
Write-Host "⚠️  WARNINGS: $WarnCount" -ForegroundColor Yellow
Write-Host "📋 TOTAL: $TotalCount" -ForegroundColor White

# Export results
$DiagnosticResults | Export-Csv -Path "diagnostic-results.csv" -NoTypeInformation
$DiagnosticResults | ConvertTo-Json -Depth 3 | Out-File -FilePath "diagnostic-results.json" -Encoding UTF8

Write-Host ""
Write-Host "📄 Results exported to:" -ForegroundColor Cyan
Write-Host "  • diagnostic-results.csv" -ForegroundColor Gray
Write-Host "  • diagnostic-results.json" -ForegroundColor Gray

# Recommendations
Write-Host ""
Write-Host "🔧 Recommendations:" -ForegroundColor Yellow

if ($FailCount -gt 0) {
    Write-Host "  • Fix FAILED tests before running automation" -ForegroundColor Red
}

if ($WarnCount -gt 0) {
    Write-Host "  • Review WARNINGS for potential issues" -ForegroundColor Yellow
}

if ($PassCount -eq $TotalCount) {
    Write-Host "  • All tests passed! Automation should work correctly" -ForegroundColor Green
}

Write-Host ""
Write-Host "🏁 Diagnostic completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan