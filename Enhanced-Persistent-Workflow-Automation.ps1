#Requires -Version 5.1
<#
.SYNOPSIS
    Enhanced Persistent Workflow Automation for Geopolitical Intelligence MCP Platform
    
.DESCRIPTION
    This script provides a resilient, self-healing workflow automation system that:
    - Orchestrates multiple MCP servers for continuous operation
    - Implements intelligent restart and recovery mechanisms
    - Provides persistent storage and data management
    - Monitors system health and performance metrics
    - Automatically generates and stores intelligence reports
    - Maintains high availability and fault tolerance
    
.PARAMETER Mode
    Operation mode: Continuous, ScheduleDaily, RunOnce, or Monitor
    
.PARAMETER ConfigFile
    Path to configuration file (default: production-config.json)
    
.EXAMPLE
    .\Enhanced-Persistent-Workflow-Automation.ps1 -Mode Continuous
    
.EXAMPLE
    .\Enhanced-Persistent-Workflow-Automation.ps1 -Mode ScheduleDaily
#>

[CmdletBinding()]
param(
    [ValidateSet("Continuous", "ScheduleDaily", "RunOnce", "Monitor")]
    [string]$Mode = "Continuous",
    
    [string]$ConfigFile = "production-config.json"
)

# Global variables for system state management
$script:MCPProcesses = @{}
$script:SystemStartTime = Get-Date
$script:HealthCheckInterval = 30  # seconds
$script:MaxRestartAttempts = 5
$script:PersistentStoragePath = "NEWS-PERSISTENT"

function Write-SystemLog {
    param(
        [string]$Message, 
        [string]$Level = "INFO", 
        [string]$Component = "SYSTEM"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "CRITICAL" { "Magenta" }
        "ERROR"    { "Red" }
        "WARNING"  { "Yellow" }
        "SUCCESS"  { "Green" }
        "TRENDING" { "Cyan" }
        default    { "White" }
    }
    
    $logMessage = "[$timestamp] [$Component] [$Level] $Message"
    Write-Host $logMessage -ForegroundColor $color
    
    # Persist logs to file
    $logFile = "$script:PersistentStoragePath\logs\workflow-automation-$(Get-Date -Format 'yyyy-MM-dd').log"
    if (Test-Path (Split-Path $logFile -Parent)) {
        $logMessage | Add-Content $logFile -Encoding UTF8
    }
}

function Initialize-SystemEnvironment {
    Write-SystemLog "Initializing Enhanced Persistent Workflow Environment..." "SUCCESS" "INIT"
    
    # Ensure persistent structure exists
    if (-not (Test-Path $script:PersistentStoragePath)) {
        Write-SystemLog "Creating persistent storage structure..." "INFO" "INIT"
        & .\Enhanced-Persistent-News-Structure.ps1
    }
    
    # Set environment variables for MCP servers
    $env:NODE_ENV = "production"
    $env:MCP_PERSISTENT_PATH = (Resolve-Path $script:PersistentStoragePath).Path
    $env:MCP_LOG_LEVEL = "info"
    $env:MCP_AUTO_RESTART = "true"
    
    # Initialize system monitoring
    Initialize-PerformanceCounters
    
    Write-SystemLog "System environment initialized successfully" "SUCCESS" "INIT"
}

function Initialize-PerformanceCounters {
    $metricsPath = "$script:PersistentStoragePath\workflows\performance-metrics"
    
    $initialMetrics = @{
        system_start_time = $script:SystemStartTime
        total_restarts = 0
        successful_collections = 0
        failed_collections = 0
        health_check_passes = 0
        health_check_failures = 0
        intelligence_reports_generated = 0
        last_update = Get-Date
    }
    
    $metricsFile = "$metricsPath\system-metrics.json"
    $initialMetrics | ConvertTo-Json | Out-File $metricsFile -Encoding UTF8 -Force
    Write-SystemLog "Performance metrics initialized" "SUCCESS" "MONITOR"
}

function Start-MCPServerCluster {
    Write-SystemLog "Starting Enhanced MCP Server Cluster..." "SUCCESS" "MCP"
    
    # Load configuration
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    
    # Core MCP servers to start
    $mcpServers = @(
        @{
            Name = "news-fetcher"
            Script = "mcp-server.js"
            Port = 3006
            Required = $true
            HealthEndpoint = "/health"
        },
        @{
            Name = "geopolitical-intelligence"
            Script = "geopolitical-intelligence-server.js"
            Port = 3007
            Required = $true
            HealthEndpoint = "/health"
        },
        @{
            Name = "filesystem-mcp"
            Command = "npx"
            Args = @("-y", "@modelcontextprotocol/server-filesystem", $script:PersistentStoragePath)
            Port = 3008
            Required = $true
        },
        @{
            Name = "sqlite-intelligence"
            Command = "npx" 
            Args = @("-y", "@modelcontextprotocol/server-sqlite", "$script:PersistentStoragePath\mcp-data\sqlite-databases\news-intelligence.db")
            Port = 3009
            Required = $true
        },
        @{
            Name = "web-scraping-mcp"
            Script = "enhanced-mcp-server.js"
            Port = 3010
            Required = $true
        }
    )
    
    # Start orchestrator first
    Start-MCPOrchestrator
    
    # Start individual MCP servers
    foreach ($server in $mcpServers) {
        Start-SingleMCPServer $server
        Start-Sleep -Seconds 2  # Stagger startup to prevent resource conflicts
    }
    
    Write-SystemLog "MCP Server Cluster startup complete" "SUCCESS" "MCP"
}

function Start-MCPOrchestrator {
    Write-SystemLog "Starting MCP Orchestrator..." "INFO" "ORCHESTRATOR"
    
    try {
        $orchestratorArgs = @("start-mcp-orchestrator.js")
        $process = Start-Process -FilePath "node" -ArgumentList $orchestratorArgs -NoNewWindow -PassThru -WorkingDirectory $PWD
        
        if ($process) {
            $script:MCPProcesses["orchestrator"] = $process
            Write-SystemLog "MCP Orchestrator started (PID: $($process.Id))" "SUCCESS" "ORCHESTRATOR"
            return $true
        }
    }
    catch {
        Write-SystemLog "Failed to start MCP Orchestrator: $($_.Exception.Message)" "ERROR" "ORCHESTRATOR"
        return $false
    }
}

function Start-SingleMCPServer {
    param($ServerConfig)
    
    Write-SystemLog "Starting MCP Server: $($ServerConfig.Name)..." "INFO" "MCP"
    
    try {
        $processArgs = if ($ServerConfig.Script) {
            @($ServerConfig.Script)
        } elseif ($ServerConfig.Args) {
            $ServerConfig.Args
        }
        
        $executable = if ($ServerConfig.Command) { $ServerConfig.Command } else { "node" }
        
        $process = Start-Process -FilePath $executable -ArgumentList $processArgs -NoNewWindow -PassThru -WorkingDirectory $PWD
        
        if ($process) {
            $script:MCPProcesses[$ServerConfig.Name] = @{
                Process = $process
                Config = $ServerConfig
                StartTime = Get-Date
                RestartCount = 0
            }
            Write-SystemLog "$($ServerConfig.Name) started (PID: $($process.Id))" "SUCCESS" "MCP"
            return $true
        }
    }
    catch {
        Write-SystemLog "Failed to start $($ServerConfig.Name): $($_.Exception.Message)" "ERROR" "MCP"
        return $false
    }
}

function Invoke-HealthCheckCycle {
    Write-SystemLog "Performing system-wide health checks..." "INFO" "HEALTH"
    
    $healthStatus = @{
        Timestamp = Get-Date
        OverallStatus = "HEALTHY"
        MCPServers = @{}
        SystemMetrics = Get-SystemMetrics
    }
    
    # Check each MCP server
    foreach ($serverName in $script:MCPProcesses.Keys) {
        $serverInfo = $script:MCPProcesses[$serverName]
        $isHealthy = Test-MCPServerHealth $serverName $serverInfo
        
        $healthStatus.MCPServers[$serverName] = @{
            Status = if ($isHealthy) { "HEALTHY" } else { "UNHEALTHY" }
            PID = $serverInfo.Process.Id
            StartTime = $serverInfo.StartTime
            RestartCount = $serverInfo.RestartCount
        }
        
        if (-not $isHealthy) {
            $healthStatus.OverallStatus = "DEGRADED"
            Restart-MCPServer $serverName
        }
    }
    
    # Save health status to persistent storage
    $healthFile = "$script:PersistentStoragePath\workflows\health-checks\health-status-$(Get-Date -Format 'yyyy-MM-dd-HH-mm').json"
    $healthStatus | ConvertTo-Json -Depth 4 | Out-File $healthFile -Encoding UTF8 -Force
    
    Write-SystemLog "Health check cycle completed. Status: $($healthStatus.OverallStatus)" "SUCCESS" "HEALTH"
    return $healthStatus
}

function Test-MCPServerHealth {
    param($ServerName, $ServerInfo)
    
    # Check if process is still running
    if ($ServerInfo.Process.HasExited) {
        Write-SystemLog "$ServerName process has exited" "WARNING" "HEALTH"
        return $false
    }
    
    # Check HTTP endpoint if available
    if ($ServerInfo.Config.Port -and $ServerInfo.Config.HealthEndpoint) {
        try {
            $healthUrl = "http://localhost:$($ServerInfo.Config.Port)$($ServerInfo.Config.HealthEndpoint)"
            $response = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 5 -ErrorAction Stop
            
            if ($response.status -eq "healthy" -or $response -eq "OK") {
                return $true
            }
        }
        catch {
            Write-SystemLog "$ServerName health endpoint check failed: $($_.Exception.Message)" "WARNING" "HEALTH"
            return $false
        }
    }
    
    # If no health endpoint, assume healthy if process is running
    return $true
}

function Restart-MCPServer {
    param($ServerName)
    
    Write-SystemLog "Restarting $ServerName..." "WARNING" "RESTART"
    
    $serverInfo = $script:MCPProcesses[$ServerName]
    
    # Stop existing process
    if (-not $serverInfo.Process.HasExited) {
        Stop-Process -Id $serverInfo.Process.Id -Force -ErrorAction SilentlyContinue
    }
    
    # Increment restart counter
    $serverInfo.RestartCount++
    
    # Check if we've exceeded max restarts
    if ($serverInfo.RestartCount -gt $script:MaxRestartAttempts) {
        Write-SystemLog "$ServerName exceeded maximum restart attempts ($script:MaxRestartAttempts)" "CRITICAL" "RESTART"
        return $false
    }
    
    # Wait before restart
    Start-Sleep -Seconds 5
    
    # Restart the server
    $restarted = Start-SingleMCPServer $serverInfo.Config
    
    if ($restarted) {
        $script:MCPProcesses[$ServerName].RestartCount = $serverInfo.RestartCount
        Write-SystemLog "$ServerName restarted successfully (Restart #$($serverInfo.RestartCount))" "SUCCESS" "RESTART"
    } else {
        Write-SystemLog "$ServerName restart failed" "ERROR" "RESTART"
    }
    
    return $restarted
}

function Invoke-IntelligenceCollection {
    Write-SystemLog "Starting comprehensive intelligence collection cycle..." "SUCCESS" "INTELLIGENCE"
    
    $currentDate = Get-Date -Format "yyyy-MM-dd"
    $collectionId = "INTEL-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    
    # Create collection session directory
    $sessionPath = "$script:PersistentStoragePath\current\daily\$currentDate\collection-sessions\$collectionId"
    New-Item -ItemType Directory -Path $sessionPath -Force | Out-Null
    
    $collectionResults = @{
        SessionId = $collectionId
        StartTime = Get-Date
        Results = @{}
        Status = "IN_PROGRESS"
    }
    
    # Phase 1: Raw data collection
    Write-SystemLog "Phase 1: Raw data collection from news sources..." "INFO" "INTELLIGENCE"
    $collectionResults.Results["raw_collection"] = Invoke-RawNewsCollection $sessionPath
    
    # Phase 2: Regional categorization
    Write-SystemLog "Phase 2: Regional and thematic categorization..." "INFO" "INTELLIGENCE"
    $collectionResults.Results["categorization"] = Invoke-RegionalCategorization $sessionPath
    
    # Phase 3: Intelligence analysis
    Write-SystemLog "Phase 3: Geopolitical intelligence analysis..." "INFO" "INTELLIGENCE"
    $collectionResults.Results["analysis"] = Invoke-GeopoliticalAnalysis $sessionPath
    
    # Phase 4: Report generation
    Write-SystemLog "Phase 4: Intelligence report generation..." "INFO" "INTELLIGENCE"
    $collectionResults.Results["reporting"] = Invoke-ReportGeneration $sessionPath
    
    # Phase 5: Persistent storage
    Write-SystemLog "Phase 5: Archiving to persistent storage..." "INFO" "INTELLIGENCE"
    $collectionResults.Results["archiving"] = Invoke-PersistentArchiving $sessionPath
    
    $collectionResults.EndTime = Get-Date
    $collectionResults.Status = "COMPLETED"
    
    # Save collection session metadata
    $sessionFile = "$sessionPath\collection-metadata.json"
    $collectionResults | ConvertTo-Json -Depth 4 | Out-File $sessionFile -Encoding UTF8 -Force
    
    Write-SystemLog "Intelligence collection cycle completed: $collectionId" "SUCCESS" "INTELLIGENCE"
    
    # Update performance metrics
    Update-SystemMetrics "successful_collections" 1
    
    return $collectionResults
}

function Invoke-RawNewsCollection {
    param($SessionPath)
    
    Write-SystemLog "Collecting raw news from all configured sources..." "INFO" "COLLECTION"
    
    $sources = @(
        @{ Name = "AllAfrica"; URL = "https://allafrica.com/tools/headlines/rdf/latest/headlines.rdf"; Type = "RSS" },
        @{ Name = "AfricaNews"; URL = "https://www.africanews.com/api/"; Type = "API" },
        @{ Name = "BBC Africa"; URL = "https://feeds.bbci.co.uk/news/world/africa/rss.xml"; Type = "RSS" },
        @{ Name = "Reuters Africa"; URL = "https://feeds.reuters.com/reuters/AfricaWorldNews"; Type = "RSS" }
    )
    
    $collectionResults = @{}
    
    foreach ($source in $sources) {
        try {
            Write-SystemLog "Collecting from: $($source.Name)..." "INFO" "COLLECTION"
            
            if ($source.Type -eq "RSS") {
                $content = Invoke-RestMethod -Uri $source.URL -TimeoutSec 30
                $outputFile = "$SessionPath\raw-$($source.Name.Replace(' ', '-'))-$(Get-Date -Format 'HHmmss').xml"
                $content | Out-File $outputFile -Encoding UTF8 -Force
                
                $collectionResults[$source.Name] = @{
                    Status = "SUCCESS"
                    ItemCount = if ($content.rss.channel.item) { $content.rss.channel.item.Count } else { 0 }
                    OutputFile = $outputFile
                }
            }
        }
        catch {
            Write-SystemLog "Failed to collect from $($source.Name): $($_.Exception.Message)" "ERROR" "COLLECTION"
            $collectionResults[$source.Name] = @{
                Status = "FAILED"
                Error = $_.Exception.Message
            }
        }
    }
    
    return $collectionResults
}

function Invoke-RegionalCategorization {
    param($SessionPath)
    
    Write-SystemLog "Performing regional and thematic categorization..." "INFO" "CATEGORIZATION"
    
    # Process raw files and categorize by region and theme
    $categorizedResults = @{}
    
    # Regional keywords for automatic categorization
    $regionKeywords = @{
        "africa" = @("africa", "african", "nigeria", "kenya", "south africa", "ghana", "ethiopia", "egypt", "morocco")
        "caribbean" = @("caribbean", "jamaica", "barbados", "trinidad", "haiti", "cuba", "dominican republic")
        "middle-east" = @("middle east", "israel", "palestine", "lebanon", "syria", "iraq", "iran", "saudi")
        "east-asia" = @("china", "japan", "korea", "taiwan", "asean", "southeast asia")
    }
    
    # Theme keywords for categorization
    $themeKeywords = @{
        "political-developments" = @("election", "government", "parliament", "politics", "democracy", "governance")
        "economic-trends" = @("economy", "trade", "investment", "gdp", "inflation", "development")
        "security-issues" = @("security", "military", "conflict", "terrorism", "peacekeeping", "defense")
        "diplomatic-relations" = @("diplomacy", "treaty", "summit", "bilateral", "multilateral", "ambassador")
        "resource-conflicts" = @("oil", "gas", "mining", "water", "energy", "resources", "extraction")
        "cultural-social" = @("culture", "social", "education", "health", "human rights", "civil society")
    }
    
    # Get raw news files
    $rawFiles = Get-ChildItem "$SessionPath\..\raw-feeds" -Filter "*.xml" -ErrorAction SilentlyContinue
    
    foreach ($file in $rawFiles) {
        $content = Get-Content $file.FullName -Encoding UTF8 -Raw
        
        # Categorize by region
        foreach ($region in $regionKeywords.Keys) {
            $matches = 0
            foreach ($keyword in $regionKeywords[$region]) {
                if ($content -match $keyword) {
                    $matches++
                }
            }
            if ($matches -gt 0) {
                $regionPath = "$script:PersistentStoragePath\current\regions\$region\$(Get-Date -Format 'yyyy-MM-dd')"
                if (-not (Test-Path $regionPath)) { 
                    New-Item -ItemType Directory -Path $regionPath -Force | Out-Null 
                }
                Copy-Item $file.FullName "$regionPath\$($file.Name)" -Force
                Write-SystemLog "Categorized $($file.Name) under region: $region" "SUCCESS" "CATEGORIZATION"
            }
        }
        
        # Categorize by theme
        foreach ($theme in $themeKeywords.Keys) {
            $matches = 0
            foreach ($keyword in $themeKeywords[$theme]) {
                if ($content -match $keyword) {
                    $matches++
                }
            }
            if ($matches -gt 0) {
                $themePath = "$script:PersistentStoragePath\current\themes\$theme\$(Get-Date -Format 'yyyy-MM-dd')"
                if (-not (Test-Path $themePath)) { 
                    New-Item -ItemType Directory -Path $themePath -Force | Out-Null 
                }
                Copy-Item $file.FullName "$themePath\$($file.Name)" -Force
                Write-SystemLog "Categorized $($file.Name) under theme: $theme" "SUCCESS" "CATEGORIZATION"
            }
        }
    }
    
    return $categorizedResults
}

function Invoke-GeopoliticalAnalysis {
    param($SessionPath)
    
    Write-SystemLog "Performing geopolitical intelligence analysis..." "INFO" "ANALYSIS"
    
    $analysisResults = @{}
    
    # Trending topics analysis
    $trendingTopics = Get-TrendingTopics $SessionPath
    $analysisResults["trending"] = $trendingTopics
    
    # Risk assessment analysis
    $riskAssessment = Perform-RiskAssessment $SessionPath
    $analysisResults["risk"] = $riskAssessment
    
    # Strategic implications analysis
    $strategicImplications = Analyze-StrategicImplications $SessionPath
    $analysisResults["strategic"] = $strategicImplications
    
    # Save analysis results
    $analysisFile = "$SessionPath\analysis-results.json"
    $analysisResults | ConvertTo-Json -Depth 4 | Out-File $analysisFile -Encoding UTF8 -Force
    
    return $analysisResults
}

function Get-TrendingTopics {
    param($SessionPath)
    
    # Simple trending analysis based on keyword frequency
    $keywordCounts = @{}
    $trendingThreshold = 3
    
    # Process all categorized files
    $categorizedFiles = Get-ChildItem "$script:PersistentStoragePath\current\regions" -Filter "*.xml" -Recurse
    
    foreach ($file in $categorizedFiles) {
        $content = Get-Content $file.FullName -Encoding UTF8 -Raw
        
        # Extract and count significant keywords
        $words = $content -split '\W+' | Where-Object { $_.Length -gt 4 }
        foreach ($word in $words) {
            $word = $word.ToLower()
            if ($keywordCounts.ContainsKey($word)) {
                $keywordCounts[$word]++
            } else {
                $keywordCounts[$word] = 1
            }
        }
    }
    
    # Identify trending topics
    $trendingTopics = $keywordCounts.GetEnumerator() | Where-Object { $_.Value -ge $trendingThreshold } | Sort-Object Value -Descending | Select-Object -First 20
    
    Write-SystemLog "Identified $($trendingTopics.Count) trending topics" "SUCCESS" "ANALYSIS"
    
    return $trendingTopics
}

function Perform-RiskAssessment {
    param($SessionPath)
    
    # Risk indicators based on content analysis
    $riskKeywords = @{
        "HIGH" = @("war", "conflict", "violence", "crisis", "emergency", "coup", "terrorism")
        "MEDIUM" = @("tension", "dispute", "protest", "instability", "concern", "warning")
        "LOW" = @("cooperation", "agreement", "stability", "development", "partnership")
    }
    
    $riskAssessment = @{
        OverallRisk = "LOW"
        RegionalRisks = @{}
        Alerts = @()
    }
    
    # Analyze regional risk levels
    $regions = @("africa", "caribbean", "middle-east", "afro-latino", "east-asia", "europe")
    
    foreach ($region in $regions) {
        $regionPath = "$script:PersistentStoragePath\current\regions\$region"
        if (Test-Path $regionPath) {
            $regionFiles = Get-ChildItem $regionPath -Filter "*.xml" -Recurse
            $riskScore = 0
            $totalItems = 0
            
            foreach ($file in $regionFiles) {
                $content = Get-Content $file.FullName -Encoding UTF8 -Raw
                $totalItems++
                
                foreach ($riskLevel in $riskKeywords.Keys) {
                    foreach ($keyword in $riskKeywords[$riskLevel]) {
                        if ($content -match $keyword) {
                            $riskScore += switch ($riskLevel) {
                                "HIGH" { 3 }
                                "MEDIUM" { 2 }
                                "LOW" { -1 }
                            }
                        }
                    }
                }
            }
            
            $averageRisk = if ($totalItems -gt 0) { $riskScore / $totalItems } else { 0 }
            $riskLevel = if ($averageRisk -gt 2) { "HIGH" } elseif ($averageRisk -gt 0.5) { "MEDIUM" } else { "LOW" }
            
            $riskAssessment.RegionalRisks[$region] = @{
                Level = $riskLevel
                Score = $averageRisk
                ItemCount = $totalItems
            }
            
            if ($riskLevel -eq "HIGH") {
                $riskAssessment.Alerts += "HIGH RISK: $region showing elevated risk indicators"
                $riskAssessment.OverallRisk = "HIGH"
            }
        }
    }
    
    Write-SystemLog "Risk assessment completed. Overall risk: $($riskAssessment.OverallRisk)" "INFO" "ANALYSIS"
    
    return $riskAssessment
}

function Analyze-StrategicImplications {
    param($SessionPath)
    
    Write-SystemLog "Analyzing strategic implications..." "INFO" "ANALYSIS"
    
    $strategicAnalysis = @{
        KeyDevelopments = @()
        CrossRegionalTrends = @()
        StrategicRecommendations = @()
        MonitoringPriorities = @()
    }
    
    # Identify key developments requiring strategic attention
    $regions = Get-ChildItem "$script:PersistentStoragePath\current\regions" -Directory
    
    foreach ($region in $regions) {
        $recentFiles = Get-ChildItem $region.FullName -Filter "*.xml" -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 5
        
        foreach ($file in $recentFiles) {
            $content = Get-Content $file.FullName -Encoding UTF8 -Raw
            
            # Look for strategic indicators
            $strategicKeywords = @("strategic", "alliance", "partnership", "agreement", "treaty", "sanctions", "embargo")
            foreach ($keyword in $strategicKeywords) {
                if ($content -match $keyword) {
                    $strategicAnalysis.KeyDevelopments += @{
                        Region = $region.Name
                        Indicator = $keyword
                        File = $file.Name
                        Timestamp = $file.LastWriteTime
                    }
                }
            }
        }
    }
    
    Write-SystemLog "Strategic analysis identified $($strategicAnalysis.KeyDevelopments.Count) key developments" "SUCCESS" "ANALYSIS"
    
    return $strategicAnalysis
}

function Invoke-ReportGeneration {
    param($SessionPath)
    
    Write-SystemLog "Generating intelligence reports..." "SUCCESS" "REPORTING"
    
    $currentDate = Get-Date -Format "yyyy-MM-dd"
    $reportTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Executive Brief
    $executiveBrief = @"
# GEOPOLITICAL INTELLIGENCE EXECUTIVE BRIEF
## Date: $reportTimestamp

### EXECUTIVE SUMMARY
This automated intelligence brief provides a comprehensive overview of geopolitical developments
across monitored regions with strategic implications analysis.

### KEY DEVELOPMENTS
[Automated analysis of trending topics and risk indicators]

### REGIONAL SITUATION REPORTS
[Automated regional analysis from collected news sources]

### STRATEGIC RECOMMENDATIONS
[AI-generated strategic implications and monitoring priorities]

### RISK ASSESSMENT
[Automated risk level analysis with alert notifications]

---
*Generated by Enhanced Persistent Workflow Automation System*
*Collection Session: $(Get-Date -Format 'yyyyMMdd-HHmmss')*
"@

    # Save executive brief
    $briefPath = "$script:PersistentStoragePath\intelligence\executive-briefs\$(Get-Date -Format 'yyyy-MM')\executive-brief-$currentDate.md"
    $executiveBrief | Out-File $briefPath -Encoding UTF8 -Force
    
    # Situation Report
    $situationReport = @"
# GEOPOLITICAL SITUATION REPORT
## Date: $reportTimestamp

### AFRICA
[Automated analysis of African regional developments]

### CARIBBEAN  
[Automated analysis of Caribbean regional developments]

### MIDDLE EAST
[Automated analysis of Middle Eastern developments]

### TRENDING ANALYSIS
[Cross-regional trend identification and analysis]

---
*Generated by MCP Intelligence Platform*
"@

    $situationPath = "$script:PersistentStoragePath\intelligence\situation-reports\$(Get-Date -Format 'yyyy-MM')\situation-report-$currentDate.md"
    $situationReport | Out-File $situationPath -Encoding UTF8 -Force
    
    Write-SystemLog "Intelligence reports generated and stored persistently" "SUCCESS" "REPORTING"
    
    # Update metrics
    Update-SystemMetrics "intelligence_reports_generated" 1
    
    return @{
        ExecutiveBrief = $briefPath
        SituationReport = $situationPath
        GeneratedAt = $reportTimestamp
    }
}

function Invoke-PersistentArchiving {
    param($SessionPath)
    
    Write-SystemLog "Archiving session to persistent storage..." "INFO" "ARCHIVING"
    
    $currentDate = Get-Date -Format "yyyy-MM-dd"
    $currentMonth = Get-Date -Format "yyyy-MM"
    $currentYear = Get-Date -Format "yyyy"
    
    # Archive to long-term storage
    $archivePath = "$script:PersistentStoragePath\archives\$currentYear\$currentMonth\daily-reports"
    if (-not (Test-Path $archivePath)) {
        New-Item -ItemType Directory -Path $archivePath -Force | Out-Null
    }
    
    # Compress and archive session data
    $archiveFile = "$archivePath\intelligence-session-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"
    Compress-Archive -Path $SessionPath -DestinationPath $archiveFile -Force
    
    Write-SystemLog "Session archived to: $archiveFile" "SUCCESS" "ARCHIVING"
    
    return @{
        ArchiveFile = $archiveFile
        ArchiveSize = (Get-Item $archiveFile).Length
    }
}

function Get-SystemMetrics {
    $metricsFile = "$script:PersistentStoragePath\workflows\performance-metrics\system-metrics.json"
    
    if (Test-Path $metricsFile) {
        return Get-Content $metricsFile | ConvertFrom-Json
    } else {
        return @{
            total_restarts = 0
            successful_collections = 0
            failed_collections = 0
            health_check_passes = 0
            health_check_failures = 0
            intelligence_reports_generated = 0
        }
    }
}

function Update-SystemMetrics {
    param($MetricName, $Increment)
    
    $metricsFile = "$script:PersistentStoragePath\workflows\performance-metrics\system-metrics.json"
    $metrics = Get-SystemMetrics
    
    if ($metrics.$MetricName) {
        $metrics.$MetricName += $Increment
    } else {
        $metrics.$MetricName = $Increment
    }
    
    $metrics.last_update = Get-Date
    $metrics | ConvertTo-Json | Out-File $metricsFile -Encoding UTF8 -Force
}

function Start-ContinuousWorkflow {
    Write-SystemLog "Starting continuous geopolitical intelligence workflow..." "SUCCESS" "WORKFLOW"
    
    $runCount = 0
    $errorCount = 0
    $maxErrors = 10
    
    while ($errorCount -lt $maxErrors) {
        try {
            $runCount++
            Write-SystemLog "=== Workflow Cycle #$runCount ===" "TRENDING" "WORKFLOW"
            
            # Perform health checks
            $healthStatus = Invoke-HealthCheckCycle
            if ($healthStatus.OverallStatus -eq "HEALTHY") {
                Update-SystemMetrics "health_check_passes" 1
            } else {
                Update-SystemMetrics "health_check_failures" 1
            }
            
            # Run intelligence collection every 30 minutes
            if ($runCount % 6 -eq 1) {  # Every 6th cycle (30 minutes with 5-minute intervals)
                try {
                    $collectionResults = Invoke-IntelligenceCollection
                    $errorCount = 0  # Reset error count on successful collection
                }
                catch {
                    Write-SystemLog "Intelligence collection failed: $($_.Exception.Message)" "ERROR" "WORKFLOW"
                    $errorCount++
                    Update-SystemMetrics "failed_collections" 1
                }
            }
            
            # Wait for next cycle
            Write-SystemLog "Next health check in $script:HealthCheckInterval seconds..." "INFO" "WORKFLOW"
            Start-Sleep -Seconds $script:HealthCheckInterval
            
        }
        catch {
            $errorCount++
            Write-SystemLog "Workflow cycle error: $($_.Exception.Message)" "ERROR" "WORKFLOW"
            
            if ($errorCount -ge $maxErrors) {
                Write-SystemLog "Maximum error threshold reached. Stopping workflow." "CRITICAL" "WORKFLOW"
                break
            }
            
            # Exponential backoff on errors
            $backoffSeconds = [Math]::Min(300, 10 * [Math]::Pow(2, $errorCount))
            Write-SystemLog "Backing off for $backoffSeconds seconds..." "WARNING" "WORKFLOW"
            Start-Sleep -Seconds $backoffSeconds
        }
    }
}

function Set-DailySchedule {
    Write-SystemLog "Setting up daily automated schedule..." "INFO" "SCHEDULER"
    
    # Create scheduled task for daily execution at 8:00 AM
    $taskName = "GeopoliticalIntelligence-Daily"
    $scriptPath = $MyInvocation.MyCommand.Path
    
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`" -Mode RunOnce"
    $trigger = New-ScheduledTaskTrigger -Daily -At "08:00AM"
    $settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -WakeToRun
    
    try {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force
        Write-SystemLog "Daily schedule registered: $taskName at 8:00 AM" "SUCCESS" "SCHEDULER"
        
        # Also schedule health monitoring every hour
        $healthTaskName = "GeopoliticalIntelligence-HealthCheck"
        $healthAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`" -Mode Monitor"
        $healthTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Hours 1)
        
        Register-ScheduledTask -TaskName $healthTaskName -Action $healthAction -Trigger $healthTrigger -Settings $settings -Force
        Write-SystemLog "Health monitoring scheduled hourly: $healthTaskName" "SUCCESS" "SCHEDULER"
        
        return $true
    }
    catch {
        Write-SystemLog "Failed to register scheduled tasks: $($_.Exception.Message)" "ERROR" "SCHEDULER"
        return $false
    }
}

# Main execution logic
try {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║        Enhanced Persistent Workflow Automation System       ║" -ForegroundColor Green
    Write-Host "║             Geopolitical Intelligence Platform              ║" -ForegroundColor Green  
    Write-Host "║                   MCP Server Orchestration                  ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    Initialize-SystemEnvironment
    
    switch ($Mode) {
        "Continuous" {
            Start-MCPServerCluster
            Start-Sleep -Seconds 10  # Allow servers to initialize
            Start-ContinuousWorkflow
        }
        "ScheduleDaily" {
            Set-DailySchedule
            Write-SystemLog "Daily automation schedule configured" "SUCCESS" "MAIN"
        }
        "RunOnce" {
            Start-MCPServerCluster
            Start-Sleep -Seconds 10
            Invoke-IntelligenceCollection
            Write-SystemLog "One-time intelligence collection completed" "SUCCESS" "MAIN"
        }
        "Monitor" {
            $healthStatus = Invoke-HealthCheckCycle
            Write-SystemLog "Monitor mode: Health check completed" "SUCCESS" "MAIN"
        }
    }
    
    Write-SystemLog "Enhanced Persistent Workflow Automation completed successfully" "SUCCESS" "MAIN"
}
catch {
    Write-SystemLog "Critical system error: $($_.Exception.Message)" "CRITICAL" "MAIN"
    exit 1
}
