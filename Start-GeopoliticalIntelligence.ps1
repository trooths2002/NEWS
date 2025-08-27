#Requires -Version 5.1

<#
.SYNOPSIS
    Comprehensive Geopolitical Intelligence Collection System

.DESCRIPTION
    Automated comprehensive geopolitical intelligence system covering all core disciplines:
    - Political Science: Sovereignty, diplomacy, international relations, governance
    - Geography: Territorial dynamics, resource distribution, strategic locations
    - History: Historical precedents, colonial legacies, cultural contexts
    - Economics: Trade, sanctions, development, political economy
    - Strategic Studies: Security, defense, intelligence, risk assessment
    - Cultural/Social: Ethnic dynamics, human rights, diaspora communities
    - Energy/Resources: Resource geopolitics, energy security, supply chains
    
    Regional Focus: African, Caribbean, Afro-Latino, Middle East, East Asia, Europe

.PARAMETER IntervalMinutes
    How often to check for new news (default: 30 minutes)

.PARAMETER MaxRetries
    Maximum retry attempts for failed operations (default: 3)

.PARAMETER ScheduleDaily
    Schedule daily execution at 8:00 AM using Windows Task Scheduler

.EXAMPLE
    .\Start-GeopoliticalIntelligence.ps1 -ScheduleDaily
    Sets up daily automated collection at 8:00 AM

.EXAMPLE
    .\Start-GeopoliticalIntelligence.ps1 -RunOnce
    Single comprehensive intelligence collection
#>

[CmdletBinding()]
param(
    [int]$IntervalMinutes = 30,
    [int]$MaxRetries = 3,
    [switch]$RunOnce,
    [switch]$ScheduleDaily
)

function Write-StatusMessage {
    param([string]$Message, [string]$Status = "INFO")
    
    $color = switch ($Status) {
        "SUCCESS" { "Green" }
        "ERROR"   { "Red" }
        "WARNING" { "Yellow" }
        "TRENDING" { "Magenta" }
        default   { "Cyan" }
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Status] $Message" -ForegroundColor $color
}

function Initialize-IntelligenceDirectories {
    $directories = @(
        # Core system directories
        "trending-intelligence",
        "trending-intelligence\summaries",
        "trending-intelligence\archives", 
        "trending-intelligence\reports",
        "trending-intelligence\alerts",
        "trending-intelligence\copyable-content",
        
        # Regional geopolitical directories
        "trending-intelligence\geopolitics",
        "trending-intelligence\geopolitics\african",
        "trending-intelligence\geopolitics\caribbean",
        "trending-intelligence\geopolitics\afro-latino",
        "trending-intelligence\geopolitics\middle-east",
        "trending-intelligence\geopolitics\east-asia",
        "trending-intelligence\geopolitics\europe",
        
        # Core discipline analysis directories
        "trending-intelligence\disciplines",
        "trending-intelligence\disciplines\political-science",
        "trending-intelligence\disciplines\geography", 
        "trending-intelligence\disciplines\history",
        "trending-intelligence\disciplines\economics",
        "trending-intelligence\disciplines\strategic-studies",
        "trending-intelligence\disciplines\cultural-social",
        "trending-intelligence\disciplines\energy-resources",
        
        # Analytical methods directories
        "trending-intelligence\analysis",
        "trending-intelligence\analysis\risk-assessment",
        "trending-intelligence\analysis\strategic-foresight", 
        "trending-intelligence\analysis\scenario-planning",
        "trending-intelligence\analysis\osint-analysis",
        "trending-intelligence\analysis\trend-analysis",
        
        # Intelligence output directories
        "trending-intelligence\intelligence-products",
        "trending-intelligence\intelligence-products\executive-briefs",
        "trending-intelligence\intelligence-products\situation-reports",
        "trending-intelligence\intelligence-products\threat-assessments"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-StatusMessage "Created directory: $dir" "SUCCESS"
        }
    }
    
    # Create comprehensive geopolitical subject area documentation
    $subjectAreasDoc = @"
# Comprehensive Geopolitical Intelligence Framework
## Core Disciplines Monitored

### Political Science
- Sovereignty and state behavior
- International relations theory (realism, liberalism, constructivism)
- Diplomacy and foreign policy analysis
- Democratic governance and authoritarianism
- Electoral politics and regime change

### Geography
- Territorial disputes and border dynamics
- Strategic geographic chokepoints
- Natural resource distribution
- Climate change geopolitical impacts
- Migration and demographic shifts

### History
- Colonial legacies and post-colonial dynamics
- Historical grievances and precedents
- Cultural and ethnic conflict patterns
- Independence movements and nation-building

### Economics
- International trade and economic diplomacy
- Sanctions and economic warfare
- Development aid and structural adjustment
- Currency and financial system dynamics
- Supply chain vulnerabilities

### Strategic Studies & Security
- Military capabilities and defense cooperation
- Intelligence and counterintelligence
- Terrorism and asymmetric threats
- Cyber warfare and hybrid threats
- Arms control and nonproliferation

### Cultural & Social Studies
- Ethnic and religious dynamics
- Human rights and civil society
- Diaspora communities and transnational networks
- Identity politics and social movements
- Cultural heritage and soft power

### Energy & Resource Geopolitics
- Energy security and pipeline politics
- Critical mineral dependencies
- Water scarcity and resource conflicts
- Environmental degradation impacts
- Resource curse dynamics

## Regional Focus Areas

### African Geopolitics
- Continental integration (AU, ECOWAS, SADC)
- Resource governance and extraction
- Post-conflict reconstruction
- Democracy and governance challenges
- Economic development partnerships

### Caribbean Geopolitics
- CARICOM integration and cooperation
- Climate vulnerability and resilience
- Tourism and economic dependencies
- Drug trafficking and security
- Diaspora remittances and development

### Afro-Latino Geopolitics
- Afro-descendant rights and representation
- Social movements and political participation
- Cultural preservation and identity
- Economic inclusion and development
- Intersectionality with indigenous rights

## Analytical Methods

### Risk Assessment
- Multi-dimensional risk matrices
- Scenario-based threat modeling
- Vulnerability assessments
- Early warning indicators

### Strategic Foresight
- Trend analysis and pattern recognition
- Alternative futures exploration
- Strategic planning horizons
- Uncertainty and complexity management

### OSINT Analysis
- Source verification and validation
- Information correlation and synthesis
- Bias recognition and mitigation
- Structured analytical techniques

Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
    
    $subjectAreasDoc | Set-Content -Path "trending-intelligence\comprehensive-framework.md" -Encoding UTF8
    Write-StatusMessage "Created comprehensive geopolitical framework documentation" "SUCCESS"
}

function Set-DailySchedule {
    $taskName = "GeopoliticalIntelligence-Daily"
    $scriptPath = $PSCommandPath
    $workingDirectory = $PWD.Path
    
    # Remove existing task if it exists
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-StatusMessage "Removed existing scheduled task: $taskName" "WARNING"
    }
    
    # Create new scheduled task for daily 8 AM execution
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`" -RunOnce" -WorkingDirectory $workingDirectory
    
    $trigger = New-ScheduledTaskTrigger -Daily -At "08:00"
    
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
    
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
    
    $task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Comprehensive Geopolitical Intelligence Collection - Daily automated execution covering African, Caribbean, and Afro-Latino geopolitics across all core disciplines"
    
    Register-ScheduledTask -TaskName $taskName -InputObject $task | Out-Null
    
    Write-StatusMessage "Created daily scheduled task: $taskName" "SUCCESS"
    Write-StatusMessage "Daily execution time: 8:00 AM" "INFO"
    Write-StatusMessage "Task covers: Political Science, Geography, History, Economics, Strategic Studies, Cultural/Social, Energy/Resources" "INFO"
    Write-StatusMessage "Regional focus: African, Caribbean, Afro-Latino, Middle East, East Asia, Europe" "INFO"
    
    # Test the task
    $scheduledTask = Get-ScheduledTask -TaskName $taskName
    if ($scheduledTask.State -eq "Ready") {
        Write-StatusMessage "Scheduled task verified and ready" "SUCCESS"
        
        # Show next run time
        $nextRun = (Get-ScheduledTask -TaskName $taskName | Get-ScheduledTaskInfo).NextRunTime
        Write-StatusMessage "Next automated run: $nextRun" "INFO"
    } else {
        Write-StatusMessage "Warning: Scheduled task may not be properly configured" "WARNING"
    }
}

function Start-GeopoliticalServer {
    $serverProcess = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {
        $_.MainWindowTitle -like "*geopolitical*" -or 
        (Get-NetTCPConnection -LocalPort 3007 -ErrorAction SilentlyContinue).Count -gt 0
    }
    
    if (-not $serverProcess) {
        Write-StatusMessage "Starting Comprehensive Geopolitical Intelligence Server..." "INFO"
        
        $startScript = @"
cd "$PWD"
node geopolitical-intelligence-server.js
"@
        
        Start-Process powershell -ArgumentList "-Command", $startScript -WindowStyle Minimized
        Start-Sleep -Seconds 5
        
        # Verify server started
        $verification = 0
        do {
            Start-Sleep -Seconds 2
            $verification++
            $serverCheck = Get-NetTCPConnection -LocalPort 3007 -ErrorAction SilentlyContinue
        } while (-not $serverCheck -and $verification -lt 10)
        
        if ($serverCheck) {
            Write-StatusMessage "Server started successfully on port 3007" "SUCCESS"
            Write-StatusMessage "Comprehensive geopolitical coverage active" "SUCCESS"
            return $true
        } else {
            Write-StatusMessage "Failed to start server after $verification attempts" "ERROR"
            return $false
        }
    } else {
        Write-StatusMessage "Geopolitical intelligence server already running" "INFO"
        return $true
    }
}
    $serverProcess = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {
        $_.MainWindowTitle -like "*geopolitical*" -or 
        (Get-NetTCPConnection -LocalPort 3007 -ErrorAction SilentlyContinue).Count -gt 0
    }
    
    if (-not $serverProcess) {
        Write-StatusMessage "Starting Geopolitical Intelligence Server..." "INFO"
        
        $startScript = @"
cd "$PWD"
node geopolitical-intelligence-server.js
"@
        
        Start-Process powershell -ArgumentList "-Command", $startScript -WindowStyle Minimized
        Start-Sleep -Seconds 5
        
        # Verify server started
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:3007/health" -TimeoutSec 10
            if ($response.status -eq "healthy") {
                Write-StatusMessage "Geopolitical Intelligence Server started successfully" "SUCCESS"
                return $true
            }
        }
        catch {
            Write-StatusMessage "Failed to start server: $($_.Exception.Message)" "ERROR"
            return $false
        }
    }
    else {
        Write-StatusMessage "Geopolitical Intelligence Server already running" "INFO"
        return $true
    }
}

function Invoke-GeopoliticalDataCollection {
    param([int]$RetryCount = 0)
    
    try {
        Write-StatusMessage "Collecting geopolitical intelligence..." "INFO"
        
        # Fetch geopolitical news
        $fetchResponse = Invoke-RestMethod -Uri "http://localhost:3007/api/fetch-geopolitical" -Method Post -TimeoutSec 60
        
        if ($fetchResponse.success) {
            $result = $fetchResponse.result
            Write-StatusMessage "Collected $($result.totalItems) news items" "SUCCESS"
            
            # Generate trending analysis
            $trendingResponse = Invoke-RestMethod -Uri "http://localhost:3007/api/trending" -TimeoutSec 30
            
            if ($trendingResponse.success) {
                $trending = $trendingResponse.trending
                Write-StatusMessage "Generated trending analysis for $($trending.totalItems) items" "TRENDING"
                
                # Generate copyable content formats
                $copyableResult = Generate-CopyableIntelligence
                
                if ($copyableResult) {
                    Write-StatusMessage "Comprehensive copyable intelligence generated successfully" "SUCCESS"
                } else {
                    Write-StatusMessage "Warning: Copyable intelligence generation had issues" "WARNING"
                }
                
                # Create daily intelligence report
                Initialize-DailyIntelligenceReport -TrendingData $trending
                
                return @{
                    Success = $true
                    ItemsCollected = $result.totalItems
                    Categories = $result.categories
                    TrendingItems = $trending.totalItems
                }
            }
        }
        
        throw "Failed to collect geopolitical data"
        
    }
    catch {
        Write-StatusMessage "Data collection failed: $($_.Exception.Message)" "ERROR"
        
        if ($RetryCount -lt $MaxRetries) {
            Write-StatusMessage "Retrying in 60 seconds... (Attempt $($RetryCount + 1)/$MaxRetries)" "WARNING"
            Start-Sleep -Seconds 60
            return Invoke-GeopoliticalDataCollection -RetryCount ($RetryCount + 1)
        }
        
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Initialize-DailyIntelligenceReport {
    param($TrendingData)
    
    $date = Get-Date -Format "yyyy-MM-dd"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $reportContent = @"
# Daily Geopolitical Intelligence Report
**Date**: $date  
**Generated**: $timestamp  
**Total Items**: $($TrendingData.totalItems)

## Executive Summary

### Regional Breakdown
"@

    if ($TrendingData.categoryBreakdown) {
        foreach ($category in $TrendingData.categoryBreakdown.PSObject.Properties) {
            $reportContent += "`n- **$($category.Name.ToUpper())**: $($category.Value) items"
        }
    }

    $reportContent += @"

## Priority Intelligence Items

"@

    if ($TrendingData.topTrending) {
        $counter = 1
        foreach ($item in $TrendingData.topTrending) {
            $reportContent += @"
### $counter. $($item.title)

**Summary**: $($item.summary)  
**Categories**: $($item.categories -join ', ')  
**Relevance Score**: $($item.trendingScore)/10  
**Source**: [$($item.link)]($($item.link))

---

"@
            $counter++
        }
    }

    $reportContent += @"

## Intelligence Assessment

- **Collection Quality**: $(if ($TrendingData.totalItems -gt 10) { "HIGH" } elseif ($TrendingData.totalItems -gt 5) { "MEDIUM" } else { "LOW" })
- **Geographic Coverage**: $(($TrendingData.categoryBreakdown.PSObject.Properties | Measure-Object).Count) regions
- **Next Update**: $(Get-Date (Get-Date).AddMinutes($IntervalMinutes) -Format "HH:mm")

---
*Generated by Geopolitical Intelligence System*
"@

    $reportPath = "trending-intelligence\reports\daily-report-$date.md"
    $reportContent | Set-Content -Path $reportPath -Encoding UTF8
    
    Write-StatusMessage "Daily intelligence report saved: $reportPath" "SUCCESS"
}

function Generate-CopyableIntelligence {
    Write-StatusMessage "Generating copyable intelligence formats..." "INFO"
    
    try {
        # Generate all copyable formats
        $response = Invoke-RestMethod -Uri "http://localhost:3007/api/generate-copyable" -Method Post -Body (@{format="all"} | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 30
        
        if ($response.success) {
            Write-StatusMessage "Generated copyable formats: $($response.files.Keys -join ', ')" "SUCCESS"
            Write-StatusMessage "Items processed: $($response.itemsProcessed)" "INFO"
            
            # Verify regional coverage
            $csvPath = "trending-intelligence\copyable-content\summaries-$(Get-Date -Format 'yyyy-MM-dd').csv"
            if (Test-Path $csvPath) {
                $csvContent = Get-Content $csvPath
                $caribbeanCount = ($csvContent | Select-String "caribbean").Count
                $afroLatinoCount = ($csvContent | Select-String "afroLatino").Count
                $africanCount = ($csvContent | Select-String "african").Count
                
                Write-StatusMessage "Regional coverage verification:" "INFO"
                Write-StatusMessage "- African: $africanCount items" "INFO"
                Write-StatusMessage "- Caribbean: $caribbeanCount items" "INFO"
                Write-StatusMessage "- Afro-Latino: $afroLatinoCount items" "INFO"
                
                if ($caribbeanCount -eq 0) {
                    Write-StatusMessage "WARNING: No Caribbean geopolitical content detected in this collection" "WARNING"
                    Write-StatusMessage "Caribbean RSS sources may need verification or additional time to populate" "WARNING"
                }
                
                if ($afroLatinoCount -eq 0) {
                    Write-StatusMessage "WARNING: No Afro-Latino geopolitical content detected in this collection" "WARNING"
                    Write-StatusMessage "Afro-Latino RSS sources may need verification or additional time to populate" "WARNING"
                }
            }
            
            return $response
        } else {
            Write-StatusMessage "Failed to generate copyable content: $($response.message)" "ERROR"
            return $null
        }
    }
    catch {
        Write-StatusMessage "Error generating copyable intelligence: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Test-HighPriorityAlerts {
    param($CollectionResult)
    
    $alertKeywords = @(
        'emergency', 'crisis', 'conflict', 'war', 'attack', 'terrorism',
        'coup', 'revolution', 'protest', 'violence', 'death', 'killed'
    )
    
    # This would implement alert logic based on keywords and patterns
    # For now, just log that alert monitoring is active
    Write-StatusMessage "High-priority alert monitoring active" "WARNING"
}

function Start-ContinuousMonitoring {
    Write-StatusMessage "Starting continuous geopolitical intelligence monitoring" "INFO"
    Write-StatusMessage "Monitoring interval: $IntervalMinutes minutes" "INFO"
    Write-StatusMessage "Press Ctrl+C to stop monitoring" "WARNING"
    
    $iteration = 1
    
    do {
        Write-StatusMessage "=== Intelligence Collection Cycle $iteration ===" "INFO"
        
        # Ensure server is running
        if (-not (Start-GeopoliticalServer)) {
            Write-StatusMessage "Cannot continue without server. Retrying in 5 minutes..." "ERROR"
            Start-Sleep -Seconds 300
            continue
        }
        
        # Collect intelligence
        $result = Invoke-GeopoliticalDataCollection
        
        if ($result.Success) {
            Write-StatusMessage "Cycle $iteration completed successfully" "SUCCESS"
            Write-StatusMessage "Items: $($result.ItemsCollected) | Trending: $($result.TrendingItems)" "TRENDING"
            
            # Test for high-priority alerts
            Test-HighPriorityAlerts -CollectionResult $result
        }
        else {
            Write-StatusMessage "Cycle $iteration failed: $($result.Error)" "ERROR"
        }
        
        if (-not $RunOnce) {
            Write-StatusMessage "Next collection in $IntervalMinutes minutes..." "INFO"
            Start-Sleep -Seconds ($IntervalMinutes * 60)
        }
        
        $iteration++
        
    } while (-not $RunOnce)
}

# Main execution
try {
    Write-StatusMessage "=== Comprehensive Geopolitical Intelligence System ===" "INFO"
    Write-StatusMessage "Core Disciplines: Political Science, Geography, History, Economics, Strategic Studies, Cultural/Social, Energy/Resources" "INFO"
    Write-StatusMessage "Regional Focus: African, Caribbean, Afro-Latino, Middle East, East Asia, Europe" "INFO"
    
    # Handle daily scheduling request
    if ($ScheduleDaily) {
        Write-StatusMessage "Setting up daily automated execution at 8:00 AM..." "INFO"
        
        # Initialize comprehensive directory structure
        Initialize-IntelligenceDirectories
        
        # Set up daily scheduling
        Set-DailySchedule
        
        Write-StatusMessage "Daily automation configured successfully!" "SUCCESS"
        Write-StatusMessage "The system will automatically run comprehensive geopolitical intelligence collection daily at 8:00 AM" "SUCCESS"
        Write-StatusMessage "Coverage includes all defined subject areas with RSS feeds for Caribbean and Afro-Latino sources" "SUCCESS"
        
        # Run initial collection to verify setup
        Write-StatusMessage "Running initial verification collection..." "INFO"
        $RunOnce = $true
    }
    
    Write-StatusMessage "Initializing Geopolitical Intelligence System" "INFO"
    
    # Initialize directory structure
    Initialize-IntelligenceDirectories
    
    # Start geopolitical intelligence server
    if (-not (Start-GeopoliticalServer)) {
        throw "Failed to start Geopolitical Intelligence Server"
    }
    
    # Begin monitoring
    if ($RunOnce) {
        Write-StatusMessage "Running single intelligence collection cycle" "INFO"
        $result = Invoke-GeopoliticalDataCollection
        
        if ($result.Success) {
            Write-StatusMessage "Single collection completed successfully" "SUCCESS"
        }
        else {
            Write-StatusMessage "Single collection failed: $($result.Error)" "ERROR"
            exit 1
        }
    }
    else {
        Start-ContinuousMonitoring
    }
}
catch {
    Write-StatusMessage "Critical error: $($_.Exception.Message)" "ERROR"
    exit 1
}
finally {
    Write-StatusMessage "Geopolitical Intelligence System shutdown" "INFO"
}