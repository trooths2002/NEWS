#!/usr/bin/env node

/**
 * Intelligent News Aggregation MCP Server
 * 
 * This advanced MCP server provides:
 * - Multi-source news aggregation from diverse geopolitical sources
 * - Intelligent deduplication using content fingerprinting
 * - Advanced categorization by region, theme, and strategic importance
 * - Real-time sentiment analysis and risk assessment
 * - Persistent storage with SQLite integration
 * - Automated trend detection and alerting
 * 
 * MCP Integration: Provides tools for comprehensive news intelligence collection
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const { CallToolRequestSchema, ListToolsRequestSchema } = require('@modelcontextprotocol/sdk/types.js');
const axios = require('axios');
const crypto = require('crypto');
const fs = require('fs').promises;
const path = require('path');
const sqlite3 = require('sqlite3');
const { open } = require('sqlite');

class IntelligentNewsAggregator {
    constructor() {
        this.persistentPath = process.env.MCP_PERSISTENT_PATH || 'NEWS-PERSISTENT';
        this.db = null;
        this.sources = this.getNewsSources();
        this.deduplicationCache = new Map();
        this.trendingTopics = new Map();
        this.riskIndicators = new Map();
        this.lastCollection = null;
    }

    async initialize() {
        // Initialize SQLite database for persistent news storage
        await this.initializeDatabase();
        
        // Load deduplication cache from persistent storage
        await this.loadDeduplicationCache();
        
        console.log('✅ Intelligent News Aggregator MCP Server initialized');
    }

    async initializeDatabase() {
        const dbPath = path.join(this.persistentPath, 'mcp-data', 'sqlite-databases', 'news-aggregator.db');
        
        // Ensure directory exists
        await fs.mkdir(path.dirname(dbPath), { recursive: true });
        
        this.db = await open({
            filename: dbPath,
            driver: sqlite3.Database
        });

        // Create tables for news intelligence
        await this.db.exec(`
            CREATE TABLE IF NOT EXISTS news_articles (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                content_hash TEXT UNIQUE NOT NULL,
                title TEXT NOT NULL,
                description TEXT,
                url TEXT,
                source TEXT,
                region TEXT,
                theme TEXT,
                risk_level TEXT,
                sentiment_score REAL,
                strategic_importance INTEGER,
                published_date TEXT,
                collected_date TEXT,
                raw_content TEXT
            );

            CREATE TABLE IF NOT EXISTS trending_topics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                keyword TEXT NOT NULL,
                frequency INTEGER DEFAULT 1,
                regions TEXT,
                last_seen TEXT,
                trend_score REAL
            );

            CREATE TABLE IF NOT EXISTS risk_assessments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                region TEXT NOT NULL,
                risk_level TEXT NOT NULL,
                risk_score REAL,
                indicators TEXT,
                assessment_date TEXT,
                alert_generated BOOLEAN DEFAULT FALSE
            );

            CREATE INDEX IF NOT EXISTS idx_articles_region ON news_articles(region);
            CREATE INDEX IF NOT EXISTS idx_articles_theme ON news_articles(theme);
            CREATE INDEX IF NOT EXISTS idx_articles_collected_date ON news_articles(collected_date);
            CREATE INDEX IF NOT EXISTS idx_trending_topics_keyword ON trending_topics(keyword);
            CREATE INDEX IF NOT EXISTS idx_risk_assessments_region ON risk_assessments(region);
        `);
    }

    getNewsSources() {
        return [
            // African News Sources
            { name: 'AllAfrica', url: 'https://allafrica.com/tools/headlines/rdf/latest/headlines.rdf', type: 'rss', region: 'africa' },
            { name: 'AfricaNews', url: 'https://www.africanews.com/feed', type: 'rss', region: 'africa' },
            { name: 'BBC Africa', url: 'https://feeds.bbci.co.uk/news/world/africa/rss.xml', type: 'rss', region: 'africa' },
            { name: 'Reuters Africa', url: 'https://feeds.reuters.com/reuters/AfricaWorldNews', type: 'rss', region: 'africa' },
            { name: 'Al Jazeera Africa', url: 'https://www.aljazeera.com/xml/rss/all.xml', type: 'rss', region: 'africa' },
            
            // Middle East Sources
            { name: 'Middle East Eye', url: 'https://www.middleeasteye.net/rss', type: 'rss', region: 'middle-east' },
            { name: 'Al Arabiya', url: 'https://english.alarabiya.net/rss.xml', type: 'rss', region: 'middle-east' },
            
            // Caribbean Sources  
            { name: 'Caribbean National Weekly', url: 'https://www.caribbeannationalweekly.com/feed/', type: 'rss', region: 'caribbean' },
            { name: 'Jamaica Observer', url: 'https://www.jamaicaobserver.com/feeds/news/', type: 'rss', region: 'caribbean' },
            
            // East Asian Sources
            { name: 'South China Morning Post', url: 'https://www.scmp.com/rss/91/feed', type: 'rss', region: 'east-asia' },
            { name: 'Nikkei Asia', url: 'https://asia.nikkei.com/rss/feed', type: 'rss', region: 'east-asia' },
            
            // Global Geopolitical Sources
            { name: 'Council on Foreign Relations', url: 'https://feeds.cfr.org/publication/in-brief', type: 'rss', region: 'global' },
            { name: 'Foreign Policy', url: 'https://foreignpolicy.com/feed/', type: 'rss', region: 'global' },
            { name: 'Stratfor', url: 'https://worldview.stratfor.com/feeds/all', type: 'rss', region: 'global' }
        ];
    }

    async collectNewsFromAllSources() {
        const collectionId = `COLLECTION-${Date.now()}`;
        const currentDate = new Date().toISOString().split('T')[0];
        
        console.log(`🚀 Starting comprehensive news collection: ${collectionId}`);
        
        const results = {
            collectionId,
            startTime: new Date(),
            sources: {},
            totalArticles: 0,
            duplicatesRemoved: 0,
            categorizedArticles: 0,
            trendingTopics: [],
            riskAlerts: [],
            status: 'IN_PROGRESS'
        };

        // Create session directory
        const sessionPath = path.join(this.persistentPath, 'current', 'daily', currentDate, 'collection-sessions', collectionId);
        await fs.mkdir(sessionPath, { recursive: true });

        // Collect from all sources
        for (const source of this.sources) {
            try {
                console.log(`📡 Collecting from: ${source.name} (${source.region})`);
                const articles = await this.collectFromSource(source);
                
                results.sources[source.name] = {
                    status: 'SUCCESS',
                    articleCount: articles.length,
                    region: source.region,
                    collectedAt: new Date()
                };
                
                // Process and deduplicate articles
                const processedArticles = await this.processArticles(articles, source);
                results.totalArticles += processedArticles.length;
                
                // Save raw data to persistent storage
                await this.saveRawData(sessionPath, source.name, articles);
                
            } catch (error) {
                console.error(`❌ Failed to collect from ${source.name}:`, error.message);
                results.sources[source.name] = {
                    status: 'FAILED',
                    error: error.message,
                    region: source.region
                };
            }
        }

        // Perform post-collection analysis
        results.trendingTopics = await this.analyzeTrendingTopics();
        results.riskAlerts = await this.performRiskAssessment();
        results.categorizedArticles = await this.getCategorizedCount();
        
        results.endTime = new Date();
        results.status = 'COMPLETED';
        this.lastCollection = results;

        // Save collection metadata
        const metadataPath = path.join(sessionPath, 'collection-metadata.json');
        await fs.writeFile(metadataPath, JSON.stringify(results, null, 2));

        console.log(`✅ News collection completed: ${results.totalArticles} articles processed`);
        return results;
    }

    async collectFromSource(source) {
        try {
            const response = await axios.get(source.url, {
                timeout: 30000,
                headers: {
                    'User-Agent': 'GeopoliticalIntelligence-MCP/2.0'
                }
            });

            if (source.type === 'rss') {
                return this.parseRSSFeed(response.data, source);
            } else if (source.type === 'api') {
                return this.parseAPIResponse(response.data, source);
            }
            
            return [];
        } catch (error) {
            throw new Error(`Failed to fetch from ${source.url}: ${error.message}`);
        }
    }

    parseRSSFeed(xmlData, source) {
        // Simple RSS parsing (in production, use a proper XML parser like xml2js)
        const articles = [];
        
        // Extract items from RSS feed (basic regex approach for demo)
        const itemMatches = xmlData.match(/<item[^>]*>(.*?)<\/item>/gs) || [];
        
        for (const itemMatch of itemMatches) {
            const title = this.extractXMLContent(itemMatch, 'title');
            const description = this.extractXMLContent(itemMatch, 'description');
            const link = this.extractXMLContent(itemMatch, 'link');
            const pubDate = this.extractXMLContent(itemMatch, 'pubDate');
            
            if (title && link) {
                articles.push({
                    title: this.cleanText(title),
                    description: this.cleanText(description),
                    url: link,
                    source: source.name,
                    region: source.region,
                    publishedDate: pubDate,
                    rawContent: itemMatch
                });
            }
        }
        
        return articles;
    }

    extractXMLContent(xml, tag) {
        const match = xml.match(new RegExp(`<${tag}[^>]*>(.*?)<\/${tag}>`, 's'));
        return match ? match[1].replace(/<!\[CDATA\[(.*?)\]\]>/s, '$1').trim() : '';
    }

    cleanText(text) {
        if (!text) return '';
        return text
            .replace(/<[^>]+>/g, '') // Remove HTML tags
            .replace(/&amp;/g, '&')
            .replace(/&lt;/g, '<')
            .replace(/&gt;/g, '>')
            .replace(/&quot;/g, '"')
            .replace(/&#39;/g, "'")
            .replace(/\s+/g, ' ')
            .trim();
    }

    async processArticles(articles, source) {
        const processedArticles = [];
        
        for (const article of articles) {
            // Generate content hash for deduplication
            const contentHash = this.generateContentHash(article.title, article.description);
            
            // Check for duplicates
            if (this.deduplicationCache.has(contentHash)) {
                this.deduplicationCache.get(contentHash).sourceCount++;
                continue; // Skip duplicate
            }

            // Categorize article
            const categorization = this.categorizeArticle(article);
            article.theme = categorization.theme;
            article.riskLevel = categorization.riskLevel;
            article.strategicImportance = categorization.strategicImportance;
            article.sentimentScore = categorization.sentimentScore;

            // Add to deduplication cache
            this.deduplicationCache.set(contentHash, {
                article,
                sourceCount: 1,
                firstSeen: new Date()
            });

            // Store in database
            await this.storeArticleInDatabase(article, contentHash);
            
            processedArticles.push(article);
        }

        return processedArticles;
    }

    generateContentHash(title, description) {
        const content = `${title} ${description}`.toLowerCase().replace(/[^a-z0-9\s]/g, '');
        return crypto.createHash('md5').update(content).digest('hex');
    }

    categorizeArticle(article) {
        const content = `${article.title} ${article.description}`.toLowerCase();
        
        // Theme categorization
        const themes = {
            'political-developments': ['election', 'government', 'parliament', 'politics', 'democracy', 'governance', 'president', 'minister'],
            'economic-trends': ['economy', 'trade', 'investment', 'gdp', 'inflation', 'development', 'business', 'market'],
            'security-issues': ['security', 'military', 'conflict', 'terrorism', 'peacekeeping', 'defense', 'war', 'violence'],
            'diplomatic-relations': ['diplomacy', 'treaty', 'summit', 'bilateral', 'multilateral', 'ambassador', 'embassy'],
            'resource-conflicts': ['oil', 'gas', 'mining', 'water', 'energy', 'resources', 'extraction', 'minerals'],
            'cultural-social': ['culture', 'social', 'education', 'health', 'human rights', 'civil society', 'religion']
        };

        let bestTheme = 'general';
        let maxScore = 0;

        for (const [theme, keywords] of Object.entries(themes)) {
            const score = keywords.reduce((count, keyword) => {
                return count + (content.includes(keyword) ? 1 : 0);
            }, 0);
            
            if (score > maxScore) {
                maxScore = score;
                bestTheme = theme;
            }
        }

        // Risk level assessment
        const highRiskKeywords = ['war', 'conflict', 'violence', 'crisis', 'emergency', 'coup', 'terrorism', 'attack'];
        const mediumRiskKeywords = ['tension', 'dispute', 'protest', 'instability', 'concern', 'warning', 'threat'];
        
        let riskLevel = 'LOW';
        if (highRiskKeywords.some(keyword => content.includes(keyword))) {
            riskLevel = 'HIGH';
        } else if (mediumRiskKeywords.some(keyword => content.includes(keyword))) {
            riskLevel = 'MEDIUM';
        }

        // Strategic importance (1-10 scale)
        const strategicKeywords = ['strategic', 'alliance', 'partnership', 'agreement', 'treaty', 'sanctions', 'embargo'];
        const strategicImportance = strategicKeywords.reduce((count, keyword) => {
            return count + (content.includes(keyword) ? 2 : 0);
        }, maxScore);

        // Sentiment analysis (simple keyword-based)
        const positiveKeywords = ['agreement', 'cooperation', 'success', 'growth', 'peace', 'stability'];
        const negativeKeywords = ['conflict', 'crisis', 'failure', 'decline', 'violence', 'instability'];
        
        const positiveScore = positiveKeywords.reduce((count, keyword) => count + (content.includes(keyword) ? 1 : 0), 0);
        const negativeScore = negativeKeywords.reduce((count, keyword) => count + (content.includes(keyword) ? 1 : 0), 0);
        const sentimentScore = (positiveScore - negativeScore) / Math.max(positiveScore + negativeScore, 1);

        return {
            theme: bestTheme,
            riskLevel,
            strategicImportance: Math.min(strategicImportance, 10),
            sentimentScore
        };
    }

    async storeArticleInDatabase(article, contentHash) {
        try {
            await this.db.run(`
                INSERT OR IGNORE INTO news_articles 
                (content_hash, title, description, url, source, region, theme, risk_level, 
                 sentiment_score, strategic_importance, published_date, collected_date, raw_content)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `, [
                contentHash,
                article.title,
                article.description,
                article.url,
                article.source,
                article.region,
                article.theme,
                article.riskLevel,
                article.sentimentScore,
                article.strategicImportance,
                article.publishedDate,
                new Date().toISOString(),
                article.rawContent
            ]);
        } catch (error) {
            console.error('Failed to store article in database:', error);
        }
    }

    async analyzeTrendingTopics() {
        const trends = [];
        
        // Analyze trending keywords from recent articles
        const recentArticles = await this.db.all(`
            SELECT title, description, region, theme, collected_date 
            FROM news_articles 
            WHERE collected_date > datetime('now', '-24 hours')
        `);

        const keywordCounts = {};
        
        for (const article of recentArticles) {
            const content = `${article.title} ${article.description}`.toLowerCase();
            const words = content.match(/\b\w{4,}\b/g) || [];
            
            for (const word of words) {
                if (!keywordCounts[word]) {
                    keywordCounts[word] = { count: 0, regions: new Set(), themes: new Set() };
                }
                keywordCounts[word].count++;
                keywordCounts[word].regions.add(article.region);
                keywordCounts[word].themes.add(article.theme);
            }
        }

        // Identify trending topics (appearing in multiple regions/themes)
        for (const [keyword, data] of Object.entries(keywordCounts)) {
            if (data.count >= 3 && data.regions.size >= 2) {
                trends.push({
                    keyword,
                    frequency: data.count,
                    regions: Array.from(data.regions),
                    themes: Array.from(data.themes),
                    trendScore: data.count * data.regions.size
                });
            }
        }

        // Store trending topics in database
        for (const trend of trends.slice(0, 20)) {
            await this.db.run(`
                INSERT OR REPLACE INTO trending_topics 
                (keyword, frequency, regions, last_seen, trend_score)
                VALUES (?, ?, ?, ?, ?)
            `, [
                trend.keyword,
                trend.frequency,
                trend.regions.join(','),
                new Date().toISOString(),
                trend.trendScore
            ]);
        }

        return trends.sort((a, b) => b.trendScore - a.trendScore).slice(0, 10);
    }

    async performRiskAssessment() {
        const alerts = [];
        const regions = ['africa', 'caribbean', 'middle-east', 'east-asia', 'europe', 'global'];
        
        for (const region of regions) {
            const riskData = await this.db.all(`
                SELECT risk_level, COUNT(*) as count, AVG(sentiment_score) as avg_sentiment
                FROM news_articles 
                WHERE region = ? AND collected_date > datetime('now', '-24 hours')
                GROUP BY risk_level
            `, [region]);

            let overallRiskScore = 0;
            let totalArticles = 0;
            
            for (const risk of riskData) {
                const weight = risk.risk_level === 'HIGH' ? 3 : risk.risk_level === 'MEDIUM' ? 2 : 1;
                overallRiskScore += risk.count * weight;
                totalArticles += risk.count;
            }

            if (totalArticles > 0) {
                const averageRisk = overallRiskScore / totalArticles;
                const riskLevel = averageRisk > 2.5 ? 'HIGH' : averageRisk > 1.5 ? 'MEDIUM' : 'LOW';
                
                // Store risk assessment
                await this.db.run(`
                    INSERT INTO risk_assessments 
                    (region, risk_level, risk_score, indicators, assessment_date)
                    VALUES (?, ?, ?, ?, ?)
                `, [
                    region,
                    riskLevel, 
                    averageRisk,
                    JSON.stringify(riskData),
                    new Date().toISOString()
                ]);

                if (riskLevel === 'HIGH') {
                    alerts.push({
                        region,
                        level: 'HIGH',
                        score: averageRisk,
                        articleCount: totalArticles,
                        message: `HIGH RISK ALERT: ${region} showing elevated risk indicators (${totalArticles} articles, score: ${averageRisk.toFixed(2)})`
                    });
                }
            }
        }

        return alerts;
    }

    async saveRawData(sessionPath, sourceName, articles) {
        const rawPath = path.join(sessionPath, 'raw-feeds');
        await fs.mkdir(rawPath, { recursive: true });
        
        const filename = `${sourceName.replace(/\s+/g, '-')}-${Date.now()}.json`;
        const filepath = path.join(rawPath, filename);
        
        await fs.writeFile(filepath, JSON.stringify(articles, null, 2));
    }

    async loadDeduplicationCache() {
        // Load recent content hashes to prevent reprocessing
        const recentHashes = await this.db.all(`
            SELECT content_hash FROM news_articles 
            WHERE collected_date > datetime('now', '-7 days')
        `);

        for (const row of recentHashes) {
            this.deduplicationCache.set(row.content_hash, { sourceCount: 1, firstSeen: new Date() });
        }
    }

    async getCategorizedCount() {
        const result = await this.db.get(`
            SELECT COUNT(*) as count FROM news_articles 
            WHERE collected_date > datetime('now', '-24 hours')
        `);
        return result.count;
    }

    async generateIntelligenceReport() {
        const currentDate = new Date().toISOString().split('T')[0];
        const currentTime = new Date().toISOString();
        
        // Get recent analytics
        const trendingTopics = await this.analyzeTrendingTopics();
        const riskAlerts = await this.performRiskAssessment();
        
        // Get regional summaries
        const regionalData = await this.db.all(`
            SELECT region, theme, COUNT(*) as article_count, AVG(sentiment_score) as avg_sentiment
            FROM news_articles 
            WHERE collected_date > datetime('now', '-24 hours')
            GROUP BY region, theme
            ORDER BY region, article_count DESC
        `);

        const report = {
            generated: currentTime,
            reportId: `INTEL-REPORT-${Date.now()}`,
            summary: {
                totalArticles: await this.getCategorizedCount(),
                trendingTopicsCount: trendingTopics.length,
                riskAlertsCount: riskAlerts.length,
                regionsMonitored: [...new Set(regionalData.map(r => r.region))].length
            },
            trendingTopics: trendingTopics.slice(0, 10),
            riskAlerts: riskAlerts,
            regionalAnalysis: regionalData,
            lastCollectionStatus: this.lastCollection?.status || 'UNKNOWN'
        };

        // Save intelligence report to persistent storage
        const reportPath = path.join(
            this.persistentPath, 
            'intelligence', 
            'situation-reports',
            currentDate.substring(0, 7), // YYYY-MM
            `intelligence-report-${currentDate}.json`
        );
        
        await fs.mkdir(path.dirname(reportPath), { recursive: true });
        await fs.writeFile(reportPath, JSON.stringify(report, null, 2));

        console.log(`📊 Intelligence report generated: ${report.reportId}`);
        return report;
    }

    async getSystemStatus() {
        const dbStats = await this.db.get(`
            SELECT 
                COUNT(*) as total_articles,
                COUNT(CASE WHEN collected_date > datetime('now', '-24 hours') THEN 1 END) as recent_articles,
                COUNT(CASE WHEN risk_level = 'HIGH' THEN 1 END) as high_risk_articles
            FROM news_articles
        `);

        return {
            status: 'OPERATIONAL',
            uptime: Date.now() - (this.lastCollection?.startTime || Date.now()),
            database: dbStats,
            deduplicationCache: this.deduplicationCache.size,
            lastCollection: this.lastCollection,
            sources: this.sources.length
        };
    }
}

// Initialize the MCP server
const server = new Server(
    { name: 'intelligent-news-aggregator', version: '2.0.0' },
    { capabilities: { tools: {} } }
);

const aggregator = new IntelligentNewsAggregator();

// Define MCP tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
    return {
        tools: [
            {
                name: 'collect_comprehensive_news',
                description: 'Collect news from all configured geopolitical sources with intelligent deduplication and categorization',
                inputSchema: {
                    type: 'object',
                    properties: {
                        includeAnalysis: { type: 'boolean', default: true },
                        generateReport: { type: 'boolean', default: true }
                    }
                }
            },
            {
                name: 'analyze_trending_topics',
                description: 'Analyze trending topics and keywords across all regions and themes',
                inputSchema: {
                    type: 'object',
                    properties: {
                        timeframe: { type: 'string', default: '24h', enum: ['1h', '6h', '24h', '7d'] },
                        minFrequency: { type: 'integer', default: 3 }
                    }
                }
            },
            {
                name: 'assess_regional_risk',
                description: 'Perform comprehensive risk assessment across monitored regions',
                inputSchema: {
                    type: 'object',
                    properties: {
                        region: { type: 'string', enum: ['africa', 'caribbean', 'middle-east', 'east-asia', 'europe', 'global', 'all'] },
                        alertThreshold: { type: 'string', default: 'MEDIUM', enum: ['LOW', 'MEDIUM', 'HIGH'] }
                    }
                }
            },
            {
                name: 'generate_intelligence_report',
                description: 'Generate comprehensive intelligence report with analysis and strategic implications',
                inputSchema: {
                    type: 'object',
                    properties: {
                        format: { type: 'string', default: 'json', enum: ['json', 'markdown'] },
                        includeRawData: { type: 'boolean', default: false }
                    }
                }
            },
            {
                name: 'get_system_status',
                description: 'Get current system status, health metrics, and operational statistics',
                inputSchema: {
                    type: 'object',
                    properties: {}
                }
            },
            {
                name: 'search_articles',
                description: 'Search stored articles by keyword, region, theme, or risk level',
                inputSchema: {
                    type: 'object',
                    properties: {
                        keyword: { type: 'string' },
                        region: { type: 'string' },
                        theme: { type: 'string' },
                        riskLevel: { type: 'string', enum: ['LOW', 'MEDIUM', 'HIGH'] },
                        limit: { type: 'integer', default: 50 }
                    }
                }
            },
            {
                name: 'get_regional_summary', 
                description: 'Get detailed summary for a specific region with recent developments',
                inputSchema: {
                    type: 'object',
                    properties: {
                        region: { type: 'string', required: true },
                        days: { type: 'integer', default: 7 }
                    },
                    required: ['region']
                }
            }
        ]
    };
});

// Tool handlers
server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;

    try {
        switch (name) {
            case 'collect_comprehensive_news': {
                const results = await aggregator.collectNewsFromAllSources();
                
                if (args.generateReport) {
                    const report = await aggregator.generateIntelligenceReport();
                    results.intelligenceReport = report;
                }
                
                return { content: [{ type: 'text', text: JSON.stringify(results, null, 2) }] };
            }

            case 'analyze_trending_topics': {
                const trends = await aggregator.analyzeTrendingTopics();
                return { content: [{ type: 'text', text: JSON.stringify(trends, null, 2) }] };
            }

            case 'assess_regional_risk': {
                const risks = await aggregator.performRiskAssessment();
                const filteredRisks = args.region === 'all' ? risks : risks.filter(r => r.region === args.region);
                return { content: [{ type: 'text', text: JSON.stringify(filteredRisks, null, 2) }] };
            }

            case 'generate_intelligence_report': {
                const report = await aggregator.generateIntelligenceReport();
                
                if (args.format === 'markdown') {
                    const markdown = `
# Geopolitical Intelligence Report
*Generated: ${report.generated}*

## Executive Summary
- **Total Articles Analyzed**: ${report.summary.totalArticles}
- **Trending Topics**: ${report.summary.trendingTopicsCount}
- **Risk Alerts**: ${report.summary.riskAlertsCount}
- **Regions Monitored**: ${report.summary.regionsMonitored}

## Top Trending Topics
${report.trendingTopics.map(t => `- **${t.keyword}** (${t.frequency} mentions across ${t.regions.length} regions)`).join('\n')}

## Risk Alerts
${report.riskAlerts.map(a => `- 🚨 **${a.region.toUpperCase()}**: ${a.message}`).join('\n')}

## Regional Analysis
${report.regionalAnalysis.map(r => `- **${r.region}** (${r.theme}): ${r.article_count} articles, sentiment: ${r.avg_sentiment?.toFixed(2) || 'N/A'}`).join('\n')}
`;
                    return { content: [{ type: 'text', text: markdown }] };
                }
                
                return { content: [{ type: 'text', text: JSON.stringify(report, null, 2) }] };
            }

            case 'get_system_status': {
                const status = await aggregator.getSystemStatus();
                return { content: [{ type: 'text', text: JSON.stringify(status, null, 2) }] };
            }

            case 'search_articles': {
                let query = 'SELECT * FROM news_articles WHERE 1=1';
                const params = [];
                
                if (args.keyword) {
                    query += ' AND (title LIKE ? OR description LIKE ?)';
                    params.push(`%${args.keyword}%`, `%${args.keyword}%`);
                }
                if (args.region) {
                    query += ' AND region = ?';
                    params.push(args.region);
                }
                if (args.theme) {
                    query += ' AND theme = ?';
                    params.push(args.theme);
                }
                if (args.riskLevel) {
                    query += ' AND risk_level = ?';
                    params.push(args.riskLevel);
                }
                
                query += ' ORDER BY collected_date DESC LIMIT ?';
                params.push(args.limit || 50);
                
                const articles = await aggregator.db.all(query, params);
                return { content: [{ type: 'text', text: JSON.stringify(articles, null, 2) }] };
            }

            case 'get_regional_summary': {
                const summary = await aggregator.db.all(`
                    SELECT 
                        theme,
                        COUNT(*) as article_count,
                        AVG(sentiment_score) as avg_sentiment,
                        COUNT(CASE WHEN risk_level = 'HIGH' THEN 1 END) as high_risk_count,
                        MAX(collected_date) as latest_article
                    FROM news_articles 
                    WHERE region = ? AND collected_date > datetime('now', '-${args.days || 7} days')
                    GROUP BY theme
                    ORDER BY article_count DESC
                `, [args.region]);

                return { content: [{ type: 'text', text: JSON.stringify(summary, null, 2) }] };
            }

            default:
                throw new Error(`Unknown tool: ${name}`);
        }
    } catch (error) {
        return { 
            content: [{ 
                type: 'text', 
                text: `Error executing ${name}: ${error.message}` 
            }], 
            isError: true 
        };
    }
});

// Start the server
async function main() {
    console.log('🚀 Starting Intelligent News Aggregation MCP Server...');
    
    try {
        await aggregator.initialize();
        
        const transport = new StdioServerTransport();
        await server.connect(transport);
        
        console.log('✅ Intelligent News Aggregation MCP Server running');
        
        // Perform initial news collection
        setTimeout(async () => {
            try {
                await aggregator.collectNewsFromAllSources();
            } catch (error) {
                console.error('Initial news collection failed:', error);
            }
        }, 5000);
        
    } catch (error) {
        console.error('❌ Failed to start MCP server:', error);
        process.exit(1);
    }
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = { IntelligentNewsAggregator };
