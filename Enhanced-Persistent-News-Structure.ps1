#Requires -Version 5.1
<#
.SYNOPSIS
    Creates Enhanced Persistent Folder Structure for Geopolitical News Intelligence
    
.DESCRIPTION
    This script creates a comprehensive, persistent folder structure optimized for:
    - Daily geopolitical news collection and archiving
    - Regional and thematic organization
    - Automated backup and retention management
    - MCP server integration and data persistence
    - Intelligence report generation and storage
    
.EXAMPLE
    .\Enhanced-Persistent-News-Structure.ps1
#>

[CmdletBinding()]
param()

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "Cyan" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Initialize-PersistentNewsStructure {
    $currentDate = Get-Date -Format "yyyy-MM-dd"
    $currentMonth = Get-Date -Format "yyyy-MM"
    $currentYear = Get-Date -Format "yyyy"
    
    $directories = @(
        # Core persistent data structure
        "NEWS-PERSISTENT",
        "NEWS-PERSISTENT\current",
        "NEWS-PERSISTENT\archives", 
        "NEWS-PERSISTENT\backups",
        "NEWS-PERSISTENT\intelligence",
        "NEWS-PERSISTENT\workflows",
        "NEWS-PERSISTENT\logs",
        
        # Daily news organization (last 30 days rolling)
        "NEWS-PERSISTENT\current\daily",
        "NEWS-PERSISTENT\current\daily\$currentDate",
        "NEWS-PERSISTENT\current\daily\$currentDate\raw-feeds",
        "NEWS-PERSISTENT\current\daily\$currentDate\processed",
        "NEWS-PERSISTENT\current\daily\$currentDate\categorized",
        "NEWS-PERSISTENT\current\daily\$currentDate\reports",
        
        # Regional news persistence 
        "NEWS-PERSISTENT\current\regions",
        "NEWS-PERSISTENT\current\regions\africa",
        "NEWS-PERSISTENT\current\regions\africa\$currentDate",
        "NEWS-PERSISTENT\current\regions\caribbean", 
        "NEWS-PERSISTENT\current\regions\caribbean\$currentDate",
        "NEWS-PERSISTENT\current\regions\middle-east",
        "NEWS-PERSISTENT\current\regions\middle-east\$currentDate",
        "NEWS-PERSISTENT\current\regions\afro-latino",
        "NEWS-PERSISTENT\current\regions\afro-latino\$currentDate",
        "NEWS-PERSISTENT\current\regions\east-asia",
        "NEWS-PERSISTENT\current\regions\east-asia\$currentDate",
        "NEWS-PERSISTENT\current\regions\europe",
        "NEWS-PERSISTENT\current\regions\europe\$currentDate",
        
        # Thematic intelligence categories
        "NEWS-PERSISTENT\current\themes",
        "NEWS-PERSISTENT\current\themes\political-developments",
        "NEWS-PERSISTENT\current\themes\political-developments\$currentDate",
        "NEWS-PERSISTENT\current\themes\economic-trends",
        "NEWS-PERSISTENT\current\themes\economic-trends\$currentDate",
        "NEWS-PERSISTENT\current\themes\security-issues",
        "NEWS-PERSISTENT\current\themes\security-issues\$currentDate",
        "NEWS-PERSISTENT\current\themes\diplomatic-relations",
        "NEWS-PERSISTENT\current\themes\diplomatic-relations\$currentDate",
        "NEWS-PERSISTENT\current\themes\resource-conflicts",
        "NEWS-PERSISTENT\current\themes\resource-conflicts\$currentDate",
        "NEWS-PERSISTENT\current\themes\cultural-social",
        "NEWS-PERSISTENT\current\themes\cultural-social\$currentDate",
        
        # MCP server data persistence
        "NEWS-PERSISTENT\mcp-data",
        "NEWS-PERSISTENT\mcp-data\sqlite-databases",
        "NEWS-PERSISTENT\mcp-data\filesystem-cache",
        "NEWS-PERSISTENT\mcp-data\web-scraping-cache",
        "NEWS-PERSISTENT\mcp-data\api-responses",
        "NEWS-PERSISTENT\mcp-data\search-results",
        "NEWS-PERSISTENT\mcp-data\processed-content",
        
        # Intelligence products (persistent storage)
        "NEWS-PERSISTENT\intelligence\executive-briefs",
        "NEWS-PERSISTENT\intelligence\executive-briefs\$currentMonth",
        "NEWS-PERSISTENT\intelligence\situation-reports", 
        "NEWS-PERSISTENT\intelligence\situation-reports\$currentMonth",
        "NEWS-PERSISTENT\intelligence\threat-assessments",
        "NEWS-PERSISTENT\intelligence\threat-assessments\$currentMonth",
        "NEWS-PERSISTENT\intelligence\trend-analysis",
        "NEWS-PERSISTENT\intelligence\trend-analysis\$currentMonth",
        "NEWS-PERSISTENT\intelligence\alert-bulletins",
        "NEWS-PERSISTENT\intelligence\alert-bulletins\$currentMonth",
        
        # Archive structure (long-term storage)
        "NEWS-PERSISTENT\archives\$currentYear",
        "NEWS-PERSISTENT\archives\$currentYear\$currentMonth",
        "NEWS-PERSISTENT\archives\$currentYear\$currentMonth\daily-reports",
        "NEWS-PERSISTENT\archives\$currentYear\$currentMonth\weekly-summaries",
        "NEWS-PERSISTENT\archives\$currentYear\$currentMonth\monthly-analysis",
        
        # Backup management
        "NEWS-PERSISTENT\backups\daily",
        "NEWS-PERSISTENT\backups\weekly",
        "NEWS-PERSISTENT\backups\monthly", 
        "NEWS-PERSISTENT\backups\system-snapshots",
        
        # Workflow automation persistence
        "NEWS-PERSISTENT\workflows\active-schedules",
        "NEWS-PERSISTENT\workflows\completed-tasks",
        "NEWS-PERSISTENT\workflows\error-recovery",
        "NEWS-PERSISTENT\workflows\health-checks",
        "NEWS-PERSISTENT\workflows\performance-metrics"
    )
    
    Write-Log "Creating Enhanced Persistent News Structure..." "SUCCESS"
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Log "Created: $dir" "SUCCESS"
        } else {
            Write-Log "Exists: $dir" "INFO"
        }
    }
    
    # Create persistent configuration files
    $configFiles = @{
        "NEWS-PERSISTENT\structure-config.json" = @{
            created = $currentDate
            version = "2.0.0"
            retention_policy = @{
                current_days = 30
                archive_months = 12
                backup_weeks = 8
            }
            auto_cleanup = @{
                enabled = $true
                schedule = "daily"
                preserve_intelligence = $true
            }
        }
        
        "NEWS-PERSISTENT\mcp-persistence-config.json" = @{
            sqlite_databases = @{
                news_intelligence = "NEWS-PERSISTENT\mcp-data\sqlite-databases\news-intelligence.db"
                geopolitical_trends = "NEWS-PERSISTENT\mcp-data\sqlite-databases\geopolitical-trends.db"
                regional_analysis = "NEWS-PERSISTENT\mcp-data\sqlite-databases\regional-analysis.db"
            }
            cache_settings = @{
                web_scraping_ttl = 3600
                api_response_ttl = 1800
                filesystem_cache_size = "500MB"
            }
            backup_settings = @{
                auto_backup = $true
                interval_hours = 6
                compression = $true
            }
        }
    }
    
    foreach ($configFile in $configFiles.GetEnumerator()) {
        $configJson = $configFile.Value | ConvertTo-Json -Depth 4
        $configJson | Out-File -FilePath $configFile.Key -Encoding UTF8 -Force
        Write-Log "Created config: $($configFile.Key)" "SUCCESS"
    }
    
    return $true
}

function Create-DailyWorkflowTemplate {
    $templateContent = @"
# Daily Geopolitical Intelligence Workflow Template
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Morning Intelligence Collection (06:00 - 09:00)
1. Initialize MCP servers and health checks
2. Scrape overnight news from primary sources
3. Process and categorize regional developments
4. Generate morning executive brief

## Midday Analysis (12:00 - 14:00)  
5. Deep dive analysis of trending stories
6. Cross-reference with historical patterns
7. Update situation reports for active regions
8. Publish midday intelligence update

## Evening Synthesis (18:00 - 20:00)
9. Synthesize full day intelligence picture  
10. Generate end-of-day executive summary
11. Archive processed content to persistent storage
12. Prepare next-day collection priorities

## Continuous Monitoring (24/7)
- Health checks every 5 minutes
- News feed monitoring every 15 minutes  
- Alert generation for breaking developments
- Automated backup every 6 hours
"@

    $templatePath = "NEWS-PERSISTENT\workflows\daily-workflow-template.md"
    $templateContent | Out-File -FilePath $templatePath -Encoding UTF8 -Force
    Write-Log "Created daily workflow template" "SUCCESS"
}

function Initialize-RetentionPolicy {
    $retentionScript = @"
# Automated Retention and Cleanup Policy
# Runs daily to manage storage and maintain system performance

function Invoke-DailyCleanup {
    # Remove old temporary files
    Get-ChildItem "NEWS-PERSISTENT\current\daily" | Where-Object { 
        `$_.Name -match '\d{4}-\d{2}-\d{2}' -and 
        [datetime]::ParseExact(`$_.Name, 'yyyy-MM-dd', `$null) -lt (Get-Date).AddDays(-30) 
    } | Remove-Item -Recurse -Force
    
    # Archive old intelligence reports
    Get-ChildItem "NEWS-PERSISTENT\intelligence" -Recurse | Where-Object {
        `$_.LastWriteTime -lt (Get-Date).AddDays(-7)
    } | ForEach-Object {
        # Move to monthly archives
        `$archivePath = "NEWS-PERSISTENT\archives\$((Get-Date).Year)\$((Get-Date).ToString('yyyy-MM'))"
        Move-Item `$_.FullName `$archivePath -Force
    }
    
    # Compress old backups
    Get-ChildItem "NEWS-PERSISTENT\backups\weekly" | Where-Object {
        `$_.LastWriteTime -lt (Get-Date).AddDays(-14)
    } | ForEach-Object {
        Compress-Archive `$_.FullName "`$(`$_.FullName).zip" -Force
        Remove-Item `$_.FullName -Recurse -Force
    }
}
"@

    $retentionPath = "NEWS-PERSISTENT\workflows\automated-retention.ps1"
    $retentionScript | Out-File -FilePath $retentionPath -Encoding UTF8 -Force
    Write-Log "Created automated retention policy" "SUCCESS"
}

# Main execution
try {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║          Enhanced Persistent News Structure Creator          ║" -ForegroundColor Green  
    Write-Host "║             Geopolitical Intelligence Platform              ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    # Initialize persistent structure
    if (Initialize-PersistentNewsStructure) {
        Write-Log "Persistent news structure created successfully" "SUCCESS"
    }
    
    # Create workflow templates
    Create-DailyWorkflowTemplate
    
    # Initialize retention policies
    Initialize-RetentionPolicy
    
    # Display summary
    Write-Host ""
    Write-Log "Enhanced Persistent News Structure Complete!" "SUCCESS"
    Write-Log "Key directories created:" "INFO"
    Write-Log "  • NEWS-PERSISTENT - Main persistent storage" "INFO"
    Write-Log "  • Daily news organization with date structure" "INFO"
    Write-Log "  • Regional and thematic categorization" "INFO"
    Write-Log "  • MCP server data persistence" "INFO"
    Write-Log "  • Intelligence product storage" "INFO"
    Write-Log "  • Automated backup and archiving" "INFO"
    Write-Host ""
    Write-Log "Next steps:" "INFO"
    Write-Log "1. Run Enhanced-Persistent-Workflow-Automation.ps1" "INFO"
    Write-Log "2. Configure MCP servers for persistent storage" "INFO"
    Write-Log "3. Set up automated scheduling" "INFO"
    Write-Host ""
    
}
catch {
    Write-Log "Error creating persistent structure: $($_.Exception.Message)" "ERROR"
    exit 1
}
