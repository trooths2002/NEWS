#!/usr/bin/env node

/**
 * Enhanced Geopolitical News Intelligence Scraper
 * 
 * Focuses on African, Caribbean, and Afro-Latino geopolitics
 * Generates 130-character summaries and trending analysis
 */

// Load environment variables
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const RSSParser = require('rss-parser');
const fs = require('fs').promises;
const path = require('path');
const https = require('https');
const http = require('http');
const cheerio = require('cheerio');
const fetch = require('node-fetch');
const crypto = require('crypto');

class GeopoliticalNewsIntelligence {
    constructor() {
        this.app = express();
        this.parser = new RSSParser();
        this.port = 3007; // Different port for enhanced server
        this.trendingData = [];
        this.geopoliticalKeywords = {
            // Core Regional Classifications
            african: [
                'african union', 'ecowas', 'sadc', 'east african community',
                'continental free trade', 'african development bank',
                'nigeria', 'south africa', 'kenya', 'ghana', 'ethiopia',
                'morocco', 'egypt', 'tunisia', 'algeria', 'senegal',
                'democratic republic congo', 'rwanda', 'uganda', 'tanzania',
                'african politics', 'pan-african', 'sahel region'
            ],
            caribbean: [
                'caricom', 'caribbean community', 'caribbean development bank',
                'jamaica', 'barbados', 'trinidad tobago', 'guyana', 'haiti',
                'dominican republic', 'puerto rico', 'cuba', 'bahamas',
                'caribbean politics', 'west indies', 'caribbean basin',
                'organization eastern caribbean states', 'oecs',
                'caribbean', 'antilles', 'caribbean sea', 'windward islands',
                'leeward islands', 'greater antilles', 'lesser antilles',
                'martinique', 'guadeloupe', 'suriname', 'belize',
                'aruba', 'curacao', 'sint maarten', 'antigua', 'barbuda',
                'dominica', 'grenada', 'st lucia', 'st vincent', 'grenadines',
                'st kitts', 'nevis', 'montserrat', 'anguilla',
                'caribbean climate', 'hurricane', 'climate vulnerability',
                'caribbean tourism', 'rum', 'sugar', 'banana',
                'caribbean diaspora', 'remittances', 'migration'
            ],
            afroLatino: [
                'afro-latino', 'afro-descendant', 'afro-brazilian', 'afro-colombian',
                'afro-venezuelan', 'afro-peruvian', 'afro-ecuadorian',
                'brazil black movement', 'colombia pacific coast', 'venezuela afro',
                'latin america racism', 'afro-caribbean diaspora',
                'black latin america', 'quilombo', 'palenque', 'maroon communities',
                'afrodescendiente', 'negro', 'moreno', 'pardo',
                'afro-argentinian', 'afro-uruguayan', 'afro-mexican',
                'afro-honduran', 'afro-costa rican', 'afro-panamanian',
                'garifuna', 'creole', 'cimarron', 'cumbe',
                'black consciousness', 'movimento negro', 'negritude',
                'racial democracy', 'mestizaje', 'blanqueamiento',
                'favela', 'barrio', 'comunidad negra',
                'afro-latin music', 'reggaeton', 'samba', 'salsa',
                'capoeira', 'santeria', 'candomble', 'umbanda',
                'black liberation', 'civil rights latin america',
                'afro-latin feminism', 'intersectionality latin america'
            ],
            // Extended Regional Coverage
            middleEast: [
                'israel', 'palestine', 'iran', 'saudi arabia', 'turkey', 'syria', 'iraq',
                'lebanon', 'jordan', 'uae', 'gulf cooperation council', 'opec',
                'middle east', 'persian gulf', 'arab league', 'levant'
            ],
            eastAsia: [
                'china', 'japan', 'south korea', 'north korea', 'taiwan', 'asean',
                'south china sea', 'asia pacific', 'belt and road', 'east asia',
                'indo-pacific', 'quad alliance', 'rcep'
            ],
            europe: [
                'european union', 'nato', 'russia', 'ukraine', 'germany', 'france',
                'united kingdom', 'brexit', 'eurozone', 'schengen', 'council of europe',
                'osce', 'g7', 'g20'
            ],
            // Core Disciplines - Political Science
            politicalScience: [
                'sovereignty', 'diplomacy', 'foreign policy', 'international law',
                'bilateral', 'multilateral', 'treaty', 'alliance', 'coalition',
                'democracy', 'autocracy', 'regime change', 'election', 'parliament',
                'government', 'politics', 'minister', 'president', 'prime minister',
                'international relations', 'realism', 'liberalism', 'constructivism'
            ],
            // Geography
            geography: [
                'border', 'territory', 'maritime', 'landlocked', 'strait', 'peninsula',
                'natural resources', 'climate change', 'water rights', 'migration',
                'demographics', 'urbanization', 'trade route', 'geopolitics',
                'territorial dispute', 'boundary', 'exclusive economic zone'
            ],
            // History
            history: [
                'colonial', 'independence', 'partition', 'empire', 'legacy',
                'historical grievance', 'precedent', 'territorial dispute',
                'ethnic conflict', 'civil war', 'revolution', 'decolonization',
                'historical', 'anniversary', 'commemoration'
            ],
            // Economics
            economics: [
                'trade war', 'sanctions', 'tariff', 'embargo', 'investment',
                'supply chain', 'commodity', 'currency', 'inflation', 'debt',
                'world bank', 'imf', 'wto', 'free trade agreement', 'economic',
                'finance', 'market', 'gdp', 'development', 'aid'
            ],
            // Strategic Studies & Security
            strategicStudies: [
                'military', 'defense', 'security', 'intelligence', 'terrorism',
                'cyber warfare', 'hybrid warfare', 'nuclear', 'missile', 'arms control',
                'peacekeeping', 'humanitarian intervention', 'insurgency', 'conflict',
                'war', 'armed forces', 'nato', 'defense spending', 'weapons'
            ],
            // Political Economy
            politicalEconomy: [
                'state capitalism', 'privatization', 'nationalization', 'subsidy',
                'development aid', 'structural adjustment', 'debt relief',
                'economic diplomacy', 'trade bloc', 'economic partnership',
                'fiscal policy', 'monetary policy', 'economic governance'
            ],
            // Cultural & Social Studies
            culturalSocial: [
                'ethnic', 'religious', 'sectarian', 'tribal', 'linguistic',
                'minority rights', 'human rights', 'refugee', 'diaspora',
                'cultural heritage', 'identity politics', 'social movement',
                'civil society', 'indigenous', 'cultural', 'social'
            ],
            // Energy & Resource Geopolitics
            energyResources: [
                'oil', 'gas', 'petroleum', 'pipeline', 'energy security',
                'renewable energy', 'mineral', 'rare earth', 'lithium',
                'water scarcity', 'food security', 'resource curse',
                'energy', 'mining', 'natural gas', 'coal', 'uranium'
            ],
            // Risk Assessment Indicators
            riskIndicators: [
                'instability', 'volatility', 'uncertainty', 'crisis', 'tension',
                'escalation', 'de-escalation', 'breakthrough', 'deadlock',
                'fragile state', 'failed state', 'governance', 'emergency',
                'alert', 'warning', 'threat', 'risk'
            ]
        };
        
        this.setupMiddleware();
        this.setupRoutes();
        this.initializeDirectories();
    }

    async initializeDirectories() {
        const dirs = [
            // Core system directories
            'trending-intelligence',
            'trending-intelligence/summaries',
            'trending-intelligence/archives',
            
            // Regional classification directories
            'trending-intelligence/geopolitics',
            'trending-intelligence/geopolitics/african',
            'trending-intelligence/geopolitics/caribbean',
            'trending-intelligence/geopolitics/afro-latino',
            'trending-intelligence/geopolitics/middleEast',
            'trending-intelligence/geopolitics/eastAsia',
            'trending-intelligence/geopolitics/europe',
            
            // Analytical discipline directories
            'trending-intelligence/analysis',
            'trending-intelligence/analysis/security',
            'trending-intelligence/analysis/risk_alert', 
            'trending-intelligence/analysis/economic_intelligence',
            'trending-intelligence/analysis/resource_geopolitics',
            'trending-intelligence/analysis/political_economy',
            'trending-intelligence/analysis/cultural_social',
            'trending-intelligence/analysis/comprehensive',
            
            // Intelligence assessment directories
            'trending-intelligence/risk-assessment',
            'trending-intelligence/strategic-foresight',
            'trending-intelligence/scenario-planning',
            
            // Output and reporting
            'trending-intelligence/reports',
            'trending-intelligence/alerts',
            'trending-intelligence/copyable-content',
            
            // OSINT and data sources
            'trending-intelligence/osint-analysis',
            'trending-intelligence/source-verification',
            
            // Image storage directories
            'images',
            'images/headlines',
            'images/thumbnails',
            'images/articles',
            'images/regional',
            'images/regional/african',
            'images/regional/caribbean',
            'images/regional/afro-latino'
        ];

        for (const dir of dirs) {
            try {
                await fs.mkdir(dir, { recursive: true });
            } catch (error) {
                // Directory might already exist
            }
        }
    }

    setupMiddleware() {
        this.app.use(cors({
            origin: '*',
            methods: ['GET', 'POST', 'OPTIONS'],
            headers: ['Content-Type', 'Accept', 'Authorization']
        }));
        this.app.use(express.json());
    }

    setupRoutes() {
        // Health check
        this.app.get('/health', (req, res) => {
            res.json({
                status: 'healthy',
                timestamp: new Date().toISOString(),
                uptime: process.uptime(),
                server: 'Geopolitical News Intelligence',
                version: '2.1.0',
                capabilities: [
                    'enhanced_news_scraping',
                    'geopolitical_analysis',
                    'trending_summaries',
                    'regional_categorization',
                    'image_scraping',
                    'visual_intelligence'
                ]
            });
        });

        // Enhanced news fetching with geopolitical focus
        this.app.post('/api/fetch-geopolitical', async (req, res) => {
            try {
                const result = await this.fetchGeopoliticalNews();
                res.json({ success: true, result });
            } catch (error) {
                res.status(500).json({ success: false, error: error.message });
            }
        });

        // Trending analysis endpoint
        this.app.get('/api/trending', async (req, res) => {
            try {
                const trending = await this.generateTrendingAnalysis();
                res.json({ success: true, trending });
            } catch (error) {
                res.status(500).json({ success: false, error: error.message });
            }
        });

        // Regional geopolitical summaries
        this.app.get('/api/geopolitics/:region', async (req, res) => {
            try {
                const region = req.params.region;
                const summaries = await this.getRegionalSummaries(region);
                res.json({ success: true, region, summaries });
            } catch (error) {
                res.status(500).json({ success: false, error: error.message });
            }
        });
        
        // Image scraping endpoint
        this.app.post('/api/scrape-images', async (req, res) => {
            try {
                const { limit } = req.body; // Optional limit for articles to process
                
                // Get recent trending news
                const trending = await this.generateTrendingAnalysis();
                
                if (!trending.topTrending || trending.topTrending.length === 0) {
                    return res.json({ success: false, message: 'No trending data available for image scraping' });
                }
                
                const newsItems = limit ? trending.topTrending.slice(0, limit) : trending.topTrending;
                const imageResults = await this.scrapeImagesFromHeadlines(newsItems);
                
                res.json({ 
                    success: true, 
                    message: `Image scraping completed for ${newsItems.length} articles`,
                    ...imageResults
                });
            } catch (error) {
                res.status(500).json({ success: false, error: error.message });
            }
        });

        // Enhanced image scraping endpoint
        this.app.post('/api/enhanced-scrape-images', async (req, res) => {
            try {
                const { strategy, limit, includeRelated, region } = req.body;
                
                // Get recent trending news
                const trending = await this.generateTrendingAnalysis();
                
                if (!trending.topTrending || trending.topTrending.length === 0) {
                    return res.json({ success: false, message: 'No trending data available for enhanced image scraping' });
                }
                
                let newsItems = trending.topTrending;
                
                // Filter by region if specified
                if (region && region !== 'all') {
                    newsItems = newsItems.filter(item => 
                        item.categories && item.categories.includes(region)
                    );
                }
                
                const limitedItems = newsItems.slice(0, limit || 20);
                const enhancedResults = await this.enhancedImageScraping(
                    limitedItems,
                    strategy || 'all',
                    includeRelated !== false
                );
                
                res.json({ 
                    success: true, 
                    message: `Enhanced image scraping completed using ${strategy || 'all'} strategy`,
                    region: region || 'all',
                    ...enhancedResults
                });
            } catch (error) {
                res.status(500).json({ success: false, error: error.message });
            }
        });

        // Generate copyable content formats
        this.app.post('/api/generate-copyable', async (req, res) => {
            try {
                const { format } = req.body; // 'txt', 'csv', 'template', or 'all'
                const trending = await this.generateTrendingAnalysis();
                
                if (!trending.topTrending || trending.topTrending.length === 0) {
                    return res.json({ success: false, message: 'No trending data available' });
                }
                
                const timestamp = new Date().toISOString().split('T')[0];
                const results = {};
                
                if (format === 'txt' || format === 'all') {
                    const txtContent = this.generatePlainTextSummaries(trending.topTrending);
                    await fs.writeFile(
                        `trending-intelligence/copyable-content/summaries-${timestamp}.txt`,
                        txtContent
                    );
                    results.txt = `summaries-${timestamp}.txt`;
                }
                
                if (format === 'csv' || format === 'all') {
                    const csvContent = this.generateCSVFormat(trending.topTrending);
                    await fs.writeFile(
                        `trending-intelligence/copyable-content/summaries-${timestamp}.csv`,
                        csvContent
                    );
                    results.csv = `summaries-${timestamp}.csv`;
                }
                
                if (format === 'template' || format === 'all') {
                    const templateContent = this.generateContentTemplate(trending.topTrending);
                    await fs.writeFile(
                        `trending-intelligence/copyable-content/content-template-${timestamp}.txt`,
                        templateContent
                    );
                    results.template = `content-template-${timestamp}.txt`;
                }
                
                res.json({ 
                    success: true, 
                    message: 'Copyable content generated successfully',
                    files: results,
                    itemsProcessed: trending.topTrending.length
                });
            } catch (error) {
                res.status(500).json({ success: false, error: error.message });
            }
        });

        // MCP protocol support
        this.app.post('/mcp', async (req, res) => {
            try {
                const { method, params } = req.body;
                
                switch (method) {
                    case 'tools/list':
                        res.json({
                            tools: [
                                {
                                    name: 'fetch_geopolitical_news',
                                    description: 'Comprehensive geopolitical news collection covering African, Caribbean, Afro-Latino, Middle East, East Asia, and European regions with multi-disciplinary analysis',
                                    inputSchema: { 
                                        type: 'object', 
                                        properties: { 
                                            region: { type: 'string', enum: ['african', 'caribbean', 'afroLatino', 'middleEast', 'eastAsia', 'europe', 'all'] },
                                            discipline: { type: 'string', enum: ['politicalScience', 'economics', 'strategicStudies', 'energyResources', 'all'] }
                                        } 
                                    }
                                },
                                {
                                    name: 'generate_trending_summaries',
                                    description: 'Create 130-character executive summaries with risk assessment and strategic implications',
                                    inputSchema: { 
                                        type: 'object', 
                                        properties: { 
                                            priorityLevel: { type: 'string', enum: ['all', 'high', 'critical'] }
                                        } 
                                    }
                                },
                                {
                                    name: 'analyze_geopolitical_trends',
                                    description: 'Comprehensive trend analysis using structured analytical techniques, scenario planning, and strategic foresight',
                                    inputSchema: { 
                                        type: 'object', 
                                        properties: { 
                                            timeframe: { type: 'string', enum: ['daily', 'weekly', 'monthly'] },
                                            methodology: { type: 'string', enum: ['risk_assessment', 'scenario_planning', 'strategic_foresight', 'comprehensive'] }
                                        } 
                                    }
                                },
                                {
                                    name: 'generate_copyable_content',
                                    description: 'Generate content in copyable formats (.txt, .csv, templates) optimized for comprehensive geopolitical intelligence consumption',
                                    inputSchema: { 
                                        type: 'object', 
                                        properties: { 
                                            format: { type: 'string', enum: ['txt', 'csv', 'template', 'all'] },
                                            discipline: { type: 'string', enum: ['security', 'economics', 'political', 'comprehensive'] }
                                        } 
                                    }
                                },
                                {
                                    name: 'perform_risk_assessment',
                                    description: 'Multi-disciplinary risk assessment covering geopolitical, economic, security, and social risk factors',
                                    inputSchema: { 
                                        type: 'object', 
                                        properties: { 
                                            region: { type: 'string' },
                                            timeframe: { type: 'string', enum: ['current', 'short_term', 'medium_term'] }
                                        } 
                                    }
                                },
                                {
                                    name: 'generate_scenario_analysis',
                                    description: 'Strategic foresight and scenario planning for geopolitical developments',
                                    inputSchema: { 
                                        type: 'object', 
                                        properties: { 
                                            focus: { type: 'string', enum: ['regional', 'global', 'thematic'] },
                                            scenarios: { type: 'number', minimum: 2, maximum: 6 }
                                        } 
                                    }
                                },
                                {
                                    name: 'osint_guidance',
                                    description: 'Open Source Intelligence collection guidance and verification methods for geopolitical analysis',
                                    inputSchema: { 
                                        type: 'object', 
                                        properties: { 
                                            topic: { type: 'string' },
                                            urgency: { type: 'string', enum: ['routine', 'priority', 'urgent'] }
                                        } 
                                    }
                                },
                                {
                                    name: 'scrape_article_images',
                                    description: 'Scrape images from captured headlines and related articles for comprehensive visual intelligence collection',
                                    inputSchema: { 
                                        type: 'object', 
                                        properties: { 
                                            limit: { type: 'number', minimum: 1, maximum: 20, description: 'Number of articles to process for image scraping' },
                                            region: { type: 'string', enum: ['african', 'caribbean', 'afroLatino', 'all'], description: 'Focus on specific regional content' }
                                        } 
                                    }
                                },
                                {
                                    name: 'get_image_metadata',
                                    description: 'Retrieve metadata and statistics about scraped images from headlines',
                                    inputSchema: { 
                                        type: 'object', 
                                        properties: { 
                                            date: { type: 'string', description: 'Date to retrieve image metadata (YYYY-MM-DD format)' },
                                            region: { type: 'string', enum: ['african', 'caribbean', 'afroLatino', 'all'] }
                                        } 
                                    }
                                },
                                {
                                    name: 'enhanced_image_scraping',
                                    description: 'Advanced image collection with multiple fallback strategies, social media integration, and AI-powered image discovery',
                                    inputSchema: { 
                                        type: 'object', 
                                        properties: { 
                                            strategy: { type: 'string', enum: ['aggressive', 'social_media', 'related_articles', 'ai_discovery', 'all'], description: 'Image collection strategy' },
                                            limit: { type: 'number', minimum: 1, maximum: 50, description: 'Number of articles to process' },
                                            includeRelated: { type: 'boolean', description: 'Search for related articles with images' }
                                        } 
                                    }
                                },
                                {
                                    name: 'search_related_images',
                                    description: 'Search for related images using article keywords and topics across multiple sources',
                                    inputSchema: { 
                                        type: 'object', 
                                        properties: { 
                                            keywords: { type: 'string', description: 'Keywords to search for related images' },
                                            sources: { type: 'array', items: { type: 'string' }, description: 'Image sources to search' },
                                            region: { type: 'string', enum: ['african', 'caribbean', 'afroLatino', 'all'] }
                                        } 
                                    }
                                }
                            ]
                        });
                        break;
                        
                    case 'tools/call':
                        const toolName = params.name;
                        let result;
                        
                        switch (toolName) {
                            case 'fetch_geopolitical_news':
                                result = await this.fetchGeopoliticalNews();
                                break;
                            case 'generate_trending_summaries':
                                result = await this.generateTrendingAnalysis();
                                break;
                            case 'analyze_geopolitical_trends':
                                result = await this.analyzeGeopoliticalTrends(params.timeframe || 'daily');
                                break;
                            case 'perform_risk_assessment':
                                const riskData = await this.loadHistoricalData('weekly');
                                result = this.performRiskAssessment(riskData);
                                break;
                            case 'generate_scenario_analysis':
                                const trends = await this.analyzeGeopoliticalTrends('daily');
                                result = {
                                    scenarios: this.generateScenarios(trends.trends || []),
                                    methodology: 'Strategic Foresight Analysis',
                                    confidence: 'Medium',
                                    timeHorizon: '6-12 months'
                                };
                                break;
                            case 'osint_guidance':
                                const currentTrends = await this.analyzeGeopoliticalTrends('daily');
                                result = this.generateOSINTGuidance(currentTrends.trends || []);
                                break;
                            case 'generate_copyable_content':
                                const format = params.format || 'all';
                                const trending = await this.generateTrendingAnalysis();
                                if (trending.topTrending && trending.topTrending.length > 0) {
                                    await this.generateCopyableFormats(trending.topTrending, new Date().toISOString().split('T')[0]);
                                    result = {
                                        success: true,
                                        message: `Generated ${format} format(s) for comprehensive geopolitical intelligence`,
                                        itemsProcessed: trending.topTrending.length,
                                        formats: format === 'all' ? ['txt', 'csv', 'template'] : [format],
                                        disciplines: this.extractDisciplines(trending.topTrending)
                                    };
                                } else {
                                    result = { success: false, message: 'No trending data available' };
                                }
                                break;
                            case 'scrape_article_images':
                                const imageLimit = params.limit || 10;
                                const regionFilter = params.region || 'all';
                                
                                const currentTrending = await this.generateTrendingAnalysis();
                                if (currentTrending.topTrending && currentTrending.topTrending.length > 0) {
                                    let newsItemsForImages = currentTrending.topTrending;
                                    
                                    // Filter by region if specified
                                    if (regionFilter !== 'all') {
                                        newsItemsForImages = newsItemsForImages.filter(item => 
                                            item.categories && item.categories.includes(regionFilter)
                                        );
                                    }
                                    
                                    const limitedItems = newsItemsForImages.slice(0, imageLimit);
                                    const imageResults = await this.scrapeImagesFromHeadlines(limitedItems);
                                    
                                    result = {
                                        success: true,
                                        message: `Image scraping completed for ${limitedItems.length} articles`,
                                        region: regionFilter,
                                        ...imageResults
                                    };
                                } else {
                                    result = { success: false, message: 'No trending data available for image scraping' };
                                }
                                break;
                            case 'get_image_metadata':
                                const metadataDate = params.date || new Date().toISOString().split('T')[0];
                                const metadataRegion = params.region || 'all';
                                
                                try {
                                    const metadataFile = `trending-intelligence/images/image-metadata-${metadataDate}.json`;
                                    const metadataContent = await fs.readFile(metadataFile, 'utf8');
                                    const metadata = JSON.parse(metadataContent);
                                    
                                    let filteredMetadata = metadata;
                                    if (metadataRegion !== 'all') {
                                        filteredMetadata.articles = metadata.articles.filter(article =>
                                            article.categories && article.categories.includes(metadataRegion)
                                        );
                                        filteredMetadata.totalArticles = filteredMetadata.articles.length;
                                        filteredMetadata.totalImages = filteredMetadata.articles.reduce((sum, article) => 
                                            sum + article.images.length, 0
                                        );
                                    }
                                    
                                    result = {
                                        success: true,
                                        date: metadataDate,
                                        region: metadataRegion,
                                        ...filteredMetadata
                                    };
                                } catch (error) {
                                    result = { 
                                        success: false, 
                                        message: `No image metadata found for date: ${metadataDate}`,
                                        error: error.message 
                                    };
                                }
                                break;
                            case 'enhanced_image_scraping':
                                const strategy = params.strategy || 'all';
                                const enhancedLimit = params.limit || 20;
                                const includeRelated = params.includeRelated || true;
                                
                                const enhancedTrending = await this.generateTrendingAnalysis();
                                if (enhancedTrending.topTrending && enhancedTrending.topTrending.length > 0) {
                                    const enhancedResults = await this.enhancedImageScraping(
                                        enhancedTrending.topTrending.slice(0, enhancedLimit),
                                        strategy,
                                        includeRelated
                                    );
                                    
                                    result = {
                                        success: true,
                                        message: `Enhanced image scraping completed using ${strategy} strategy`,
                                        strategy: strategy,
                                        includeRelated: includeRelated,
                                        ...enhancedResults
                                    };
                                } else {
                                    result = { success: false, message: 'No trending data available for enhanced image scraping' };
                                }
                                break;
                            case 'search_related_images':
                                const searchKeywords = params.keywords || '';
                                const searchSources = params.sources || ['google_images', 'bing_images', 'news_sites'];
                                const searchRegion = params.region || 'all';
                                
                                if (!searchKeywords) {
                                    result = { success: false, message: 'Keywords are required for related image search' };
                                } else {
                                    const relatedResults = await this.searchRelatedImages(
                                        searchKeywords,
                                        searchSources,
                                        searchRegion
                                    );
                                    
                                    result = {
                                        success: true,
                                        message: `Found related images for keywords: ${searchKeywords}`,
                                        keywords: searchKeywords,
                                        sources: searchSources,
                                        region: searchRegion,
                                        ...relatedResults
                                    };
                                }
                                break;
                            default:
                                result = { error: 'Unknown tool', availableTools: ['fetch_geopolitical_news', 'generate_trending_summaries', 'analyze_geopolitical_trends', 'perform_risk_assessment', 'generate_scenario_analysis', 'osint_guidance', 'generate_copyable_content', 'scrape_article_images', 'get_image_metadata', 'enhanced_image_scraping', 'search_related_images'] };
                        }
                        
                        res.json({ content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] });
                        break;
                        
                    default:
                        res.status(400).json({ error: 'Unknown method' });
                }
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });
    }

    async fetchGeopoliticalNews() {
        console.log('🌍 Fetching comprehensive geopolitical news...');
        
        const sources = [
            // African Sources - Political Science & Regional Politics
            'https://allafrica.com/tools/headlines/rdf/latest/headlines.rdf',
            
            // Caribbean Sources - Comprehensive Regional Coverage
            'https://www.caribbeannewsnow.com/feed/',
            'https://www.jamaicaobserver.com/feed/',
            'https://barbadostoday.bb/feed/',
            'https://guyanachronicle.com/feed/',
            'https://www.caribbeanlifenews.com/feed/',
            'https://www.stabroeknews.com/feed/',
            'https://www.thebahamas.com/feed/',
            'https://dominicantoday.com/dr/feeds/news.xml',
            'https://www.caricomtoday.com/feed/',
            'https://www.caribbean360.com/feed/',
            'https://newsroom.caricom.org/feed/',
            
            // Afro-Latino Sources - Enhanced Coverage
            'https://www.afrolatindiasporic.com/feed/',
            'https://rss.cnn.com/rss/edition_americas.rss',
            'https://feeds.reuters.com/reuters/worldNews',
            'https://www.americasquarterly.org/feed/',
            'https://www.coha.org/feed/',
            'https://www.dialogo-americas.com/feed/',
            'https://afrolatinproject.org/feed/',
            'https://remezcla.com/feed/',
            
            // Latin America Political & Social
            'https://www.as-coa.org/feed',
            'https://www.cepr.net/category/regions/latin-america-caribbean/feed/',
            'https://www.wola.org/feed/',
            'https://nacla.org/feed',
            
            // Regional Economic & Development
            'https://www.iadb.org/en/news/rss',
            'https://www.eclac.org/en/rss',
            'https://oilnow.gy/feed/',
            
            // Strategic Studies & Security (Multi-regional)
            'https://www.insightcrime.org/feed/',
            'https://www.securityassistance.org/feed',
            
            // International Organizations & Diplomacy
            'https://www.un.org/en/caribbean/feed.xml',
            'https://www.oas.org/en/media_center/rss.xml',
            
            // Cultural & Social Studies
            'https://www.americas.org/feed/',
            'https://www.blacklatinamerica.com/feed/'
        ];

        const allNews = [];
        let successfulSources = 0;
        let failedSources = [];
        
        for (const source of sources) {
            try {
                console.log(`📡 Fetching from: ${source}`);
                const feed = await this.parser.parseURL(source);
                
                if (feed.items && feed.items.length > 0) {
                    const categorizedNews = this.categorizeNews(feed.items);
                    const relevantNews = categorizedNews.filter(item => 
                        item.categories.some(cat => ['african', 'caribbean', 'afroLatino'].includes(cat)) ||
                        item.relevanceScore >= 2
                    );
                    
                    allNews.push(...relevantNews);
                    successfulSources++;
                    console.log(`✅ ${source}: ${relevantNews.length} relevant items`);
                } else {
                    console.log(`⚠️ ${source}: No items found`);
                }
            } catch (error) {
                console.error(`❌ Error fetching from ${source}:`, error.message);
                failedSources.push(source);
            }
        }
        
        console.log(`📊 Collection Summary: ${successfulSources}/${sources.length} sources successful`);
        
        // Enhanced content analysis for better categorization
        const enhancedNews = allNews.map(item => {
            return {
                ...item,
                enhancedCategories: this.performDeepCategorization(item),
                confidenceScore: this.calculateContentConfidence(item)
            };
        });

        // Generate summaries and save
        const processedNews = await this.processTrendingNews(enhancedNews);
        await this.saveGeopoliticalData(processedNews);
        
        // Log regional distribution for monitoring
        const regionalDistribution = this.getRegionalDistribution(processedNews);
        console.log('🌍 Regional Distribution:', regionalDistribution);
        
        if (regionalDistribution.caribbean === 0) {
            console.log('⚠️ WARNING: No Caribbean content detected - RSS sources may need verification');
        }
        
        if (regionalDistribution.afroLatino === 0) {
            console.log('⚠️ WARNING: No Afro-Latino content detected - RSS sources may need verification');
        }
        
        return {
            totalItems: processedNews.length,
            categories: this.getCategoryCounts(processedNews),
            timestamp: new Date().toISOString(),
            processed: processedNews,
            sourcesSuccessful: successfulSources,
            sourcesFailed: failedSources.length,
            regionalDistribution: regionalDistribution
        };
    }
    
    performDeepCategorization(item) {
        const content = `${item.title} ${item.description || ''} ${item.content || ''}`.toLowerCase();
        const enhancedCategories = [];
        
        // More sophisticated Caribbean detection
        const caribbeanIndicators = [
            'caribbean', 'caricom', 'west indies', 'antilles',
            'jamaica', 'haiti', 'barbados', 'trinidad', 'guyana',
            'bahamas', 'cuba', 'dominican', 'puerto rico'
        ];
        
        // More sophisticated Afro-Latino detection
        const afroLatinoIndicators = [
            'afro', 'negro', 'black latin', 'afrodescendant',
            'quilombo', 'palenque', 'maroon', 'garifuna',
            'brazil', 'colombia', 'venezuela', 'peru', 'ecuador'
        ];
        
        const caribbeanScore = caribbeanIndicators.reduce((score, indicator) => {
            return score + (content.includes(indicator) ? 1 : 0);
        }, 0);
        
        const afroLatinoScore = afroLatinoIndicators.reduce((score, indicator) => {
            return score + (content.includes(indicator) ? 1 : 0);
        }, 0);
        
        if (caribbeanScore >= 1) enhancedCategories.push('caribbean');
        if (afroLatinoScore >= 1) enhancedCategories.push('afroLatino');
        
        return enhancedCategories;
    }
    
    calculateContentConfidence(item) {
        let confidence = 0.5; // Base confidence
        
        // Boost confidence for regional content
        if (item.categories.includes('caribbean')) confidence += 0.2;
        if (item.categories.includes('afroLatino')) confidence += 0.2;
        if (item.categories.includes('african')) confidence += 0.1;
        
        // Boost for multi-disciplinary content
        if (item.disciplines && item.disciplines.length > 2) confidence += 0.1;
        
        // Boost for high relevance score
        if (item.relevanceScore >= 3) confidence += 0.1;
        
        return Math.min(confidence, 1.0);
    }
    
    getRegionalDistribution(newsItems) {
        const distribution = {
            african: 0,
            caribbean: 0,
            afroLatino: 0,
            middleEast: 0,
            eastAsia: 0,
            europe: 0,
            general: 0
        };
        
        newsItems.forEach(item => {
            item.categories.forEach(category => {
                if (distribution.hasOwnProperty(category)) {
                    distribution[category]++;
                }
            });
        });
        
        return distribution;
    }

    categorizeNews(items) {
        return items.map(item => {
            const content = `${item.title} ${item.description || ''}`.toLowerCase();
            const categories = [];
            const disciplines = [];
            
            // Check for regional categories
            const regions = ['african', 'caribbean', 'afroLatino', 'middleEast', 'eastAsia', 'europe'];
            regions.forEach(region => {
                if (this.geopoliticalKeywords[region].some(keyword => content.includes(keyword))) {
                    categories.push(region);
                }
            });
            
            // Check for disciplinary categories
            const disciplineKeys = ['politicalScience', 'geography', 'history', 'economics', 
                                  'strategicStudies', 'politicalEconomy', 'culturalSocial', 
                                  'energyResources', 'riskIndicators'];
            disciplineKeys.forEach(discipline => {
                if (this.geopoliticalKeywords[discipline].some(keyword => content.includes(keyword))) {
                    disciplines.push(discipline);
                }
            });
            
            const relevanceAnalysis = this.calculateRelevanceScore(content);
            
            return {
                ...item,
                categories: categories.length > 0 ? categories : ['general'],
                disciplines: disciplines,
                relevanceScore: relevanceAnalysis.totalScore,
                disciplineBreakdown: relevanceAnalysis.disciplineBreakdown,
                disciplinesCount: relevanceAnalysis.disciplinesCount,
                geopoliticalType: this.classifyGeopoliticalType(disciplines)
            };
        });
    }
    
    classifyGeopoliticalType(disciplines) {
        if (disciplines.includes('strategicStudies')) return 'SECURITY';
        if (disciplines.includes('riskIndicators')) return 'RISK_ALERT';
        if (disciplines.includes('economics') && disciplines.includes('politicalEconomy')) return 'ECONOMIC_INTELLIGENCE';
        if (disciplines.includes('energyResources')) return 'RESOURCE_GEOPOLITICS';
        if (disciplines.includes('culturalSocial')) return 'SOCIAL_DYNAMICS';
        if (disciplines.length >= 3) return 'COMPREHENSIVE';
        return 'GENERAL';
    }

    calculateRelevanceScore(content) {
        let score = 0;
        let disciplineScores = {
            politicalScience: 0,
            geography: 0,
            history: 0,
            economics: 0,
            strategicStudies: 0,
            politicalEconomy: 0,
            culturalSocial: 0,
            energyResources: 0,
            riskIndicators: 0
        };
        
        // Score by discipline
        Object.keys(this.geopoliticalKeywords).forEach(discipline => {
            if (disciplineScores.hasOwnProperty(discipline)) {
                this.geopoliticalKeywords[discipline].forEach(term => {
                    if (content.includes(term)) {
                        disciplineScores[discipline] += 1;
                        score += this.getDisciplineWeight(discipline);
                    }
                });
            }
        });
        
        // Bonus for multi-disciplinary coverage
        const disciplinesHit = Object.values(disciplineScores).filter(s => s > 0).length;
        if (disciplinesHit >= 3) score += 2; // Multi-disciplinary bonus
        if (disciplinesHit >= 5) score += 3; // Comprehensive coverage bonus
        
        return {
            totalScore: Math.min(score, 10),
            disciplineBreakdown: disciplineScores,
            disciplinesCount: disciplinesHit
        };
    }
    
    getDisciplineWeight(discipline) {
        const weights = {
            strategicStudies: 2.0,    // High priority for security intelligence
            riskIndicators: 1.8,      // Critical for risk assessment
            politicalScience: 1.5,    // Core geopolitical content
            economics: 1.4,           // Economic intelligence
            geography: 1.3,           // Geographic factors
            energyResources: 1.2,     // Resource geopolitics
            politicalEconomy: 1.1,    // Political-economic dynamics
            history: 1.0,             // Historical context
            culturalSocial: 0.9       // Social dynamics
        };
        return weights[discipline] || 1.0;
    }

    async processTrendingNews(newsItems) {
        const trending = newsItems
            .filter(item => item.relevanceScore >= 2)
            .sort((a, b) => {
                // Priority sort: Security > Risk > Multi-disciplinary > Score
                if (a.geopoliticalType === 'SECURITY' && b.geopoliticalType !== 'SECURITY') return -1;
                if (b.geopoliticalType === 'SECURITY' && a.geopoliticalType !== 'SECURITY') return 1;
                if (a.geopoliticalType === 'RISK_ALERT' && b.geopoliticalType !== 'RISK_ALERT') return -1;
                if (b.geopoliticalType === 'RISK_ALERT' && a.geopoliticalType !== 'RISK_ALERT') return 1;
                if (a.disciplinesCount !== b.disciplinesCount) return b.disciplinesCount - a.disciplinesCount;
                return b.relevanceScore - a.relevanceScore;
            })
            .slice(0, 25); // Increased for comprehensive coverage

        return trending.map(item => ({
            ...item,
            summary: this.generateSummary(item.title, item.description),
            trendingScore: item.relevanceScore,
            riskAssessment: this.assessRisk(item),
            strategicImplications: this.generateStrategicImplications(item),
            processedAt: new Date().toISOString()
        }));
    }
    
    assessRisk(item) {
        let riskLevel = 'LOW';
        let riskFactors = [];
        
        if (item.disciplines.includes('strategicStudies')) {
            riskLevel = 'HIGH';
            riskFactors.push('Security implications');
        }
        if (item.disciplines.includes('riskIndicators')) {
            if (riskLevel === 'LOW') riskLevel = 'MEDIUM';
            riskFactors.push('Instability indicators');
        }
        if (item.geopoliticalType === 'ECONOMIC_INTELLIGENCE') {
            riskFactors.push('Economic impact');
        }
        if (item.disciplinesCount >= 4) {
            riskLevel = riskLevel === 'LOW' ? 'MEDIUM' : 'HIGH';
            riskFactors.push('Multi-dimensional impact');
        }
        
        return {
            level: riskLevel,
            factors: riskFactors,
            score: this.calculateRiskScore(item)
        };
    }
    
    calculateRiskScore(item) {
        let score = 0;
        if (item.disciplines.includes('strategicStudies')) score += 3;
        if (item.disciplines.includes('riskIndicators')) score += 2;
        if (item.disciplinesCount >= 3) score += 1;
        return Math.min(score, 5);
    }
    
    generateStrategicImplications(item) {
        const implications = [];
        
        if (item.disciplines.includes('strategicStudies')) {
            implications.push('Monitor for security developments');
        }
        if (item.disciplines.includes('economics')) {
            implications.push('Track economic ramifications');
        }
        if (item.disciplines.includes('energyResources')) {
            implications.push('Assess resource security impact');
        }
        if (item.disciplinesCount >= 4) {
            implications.push('Comprehensive multi-sector analysis required');
        }
        
        return implications;
    }

    generateSummary(title, description) {
        const fullText = `${title}. ${description || ''}`;
        
        // Simple summarization - truncate to 130 characters
        if (fullText.length <= 130) return fullText;
        
        // Find the best truncation point (end of sentence or word)
        let summary = fullText.substring(0, 127);
        const lastPeriod = summary.lastIndexOf('.');
        const lastSpace = summary.lastIndexOf(' ');
        
        if (lastPeriod > 80) {
            summary = fullText.substring(0, lastPeriod + 1);
        } else if (lastSpace > 100) {
            summary = fullText.substring(0, lastSpace) + '...';
        } else {
            summary = fullText.substring(0, 127) + '...';
        }
        
        return summary;
    }

    async saveGeopoliticalData(processedNews) {
        const timestamp = new Date().toISOString().split('T')[0];
        
        // Save overall trending summary
        const trendingSummary = {
            date: timestamp,
            totalItems: processedNews.length,
            topTrending: processedNews.slice(0, 10),
            categoryBreakdown: this.getCategoryCounts(processedNews)
        };
        
        await fs.writeFile(
            `trending-intelligence/summaries/trending-${timestamp}.json`,
            JSON.stringify(trendingSummary, null, 2)
        );

        // Save by regional category
        const regions = ['african', 'caribbean', 'afroLatino', 'middleEast', 'eastAsia', 'europe'];
        for (const region of regions) {
            const regionNews = processedNews.filter(item => 
                item.categories.includes(region)
            );
            
            if (regionNews.length > 0) {
                await fs.writeFile(
                    `trending-intelligence/geopolitics/${region}/latest-${timestamp}.json`,
                    JSON.stringify(regionNews, null, 2)
                );
            }
        }
        
        // Save by geopolitical type
        const types = ['SECURITY', 'RISK_ALERT', 'ECONOMIC_INTELLIGENCE', 'RESOURCE_GEOPOLITICS', 'COMPREHENSIVE'];
        for (const type of types) {
            const typeNews = processedNews.filter(item => item.geopoliticalType === type);
            
            if (typeNews.length > 0) {
                await fs.writeFile(
                    `trending-intelligence/analysis/${type.toLowerCase()}/latest-${timestamp}.json`,
                    JSON.stringify(typeNews, null, 2)
                );
            }
        }
        
        // Generate risk assessment report
        const highRiskItems = processedNews.filter(item => item.riskAssessment?.level === 'HIGH');
        if (highRiskItems.length > 0) {
            await fs.writeFile(
                `trending-intelligence/risk-assessment/high-risk-${timestamp}.json`,
                JSON.stringify({
                    date: timestamp,
                    totalHighRiskItems: highRiskItems.length,
                    items: highRiskItems,
                    generatedAt: new Date().toISOString()
                }, null, 2)
            );
        }

        // Save human-readable summaries
        const readableSummary = this.generateReadableSummary(processedNews);
        await fs.writeFile(
            `trending-intelligence/summaries/briefing-${timestamp}.md`,
            readableSummary
        );
        
        // Generate copyable content formats
        await this.generateCopyableFormats(processedNews, timestamp);
    }

    generateReadableSummary(newsItems) {
        const timestamp = new Date().toISOString();
        const categoryBreakdown = this.getCategoryCounts(newsItems);
        
        let summary = `# Geopolitical Intelligence Briefing\n\n`;
        summary += `**Generated**: ${timestamp}\n`;
        summary += `**Total Items**: ${newsItems.length}\n\n`;
        
        summary += `## Category Breakdown\n\n`;
        Object.entries(categoryBreakdown).forEach(([category, count]) => {
            summary += `- **${category.charAt(0).toUpperCase() + category.slice(1)}**: ${count} items\n`;
        });
        
        summary += `\n## Top Trending Stories\n\n`;
        newsItems.slice(0, 10).forEach((item, index) => {
            summary += `### ${index + 1}. ${item.title}\n\n`;
            summary += `**Summary**: ${item.summary}\n\n`;
            summary += `**Categories**: ${item.categories.join(', ')}\n`;
            summary += `**Relevance Score**: ${item.trendingScore}/10\n`;
            summary += `**Source**: [Link](${item.link})\n\n`;
            summary += `---\n\n`;
        });
        
        return summary;
    }

    async generateCopyableFormats(newsItems, timestamp) {
        // Create copyable content directory
        try {
            await fs.mkdir('trending-intelligence/copyable-content', { recursive: true });
        } catch (error) {
            // Directory might already exist
        }
        
        // Generate plain text format for easy copying
        const txtContent = this.generatePlainTextSummaries(newsItems);
        await fs.writeFile(
            `trending-intelligence/copyable-content/summaries-${timestamp}.txt`,
            txtContent
        );
        
        // Generate CSV format for Google Sheets
        const csvContent = this.generateCSVFormat(newsItems);
        await fs.writeFile(
            `trending-intelligence/copyable-content/summaries-${timestamp}.csv`,
            csvContent
        );
        
        // Generate content creation template
        const templateContent = this.generateContentTemplate(newsItems);
        await fs.writeFile(
            `trending-intelligence/copyable-content/content-template-${timestamp}.txt`,
            templateContent
        );
        
        console.log(`📄 Generated copyable formats: .txt, .csv, and content template`);
    }
    
    generatePlainTextSummaries(newsItems) {
        const date = new Date().toLocaleDateString();
        let content = `GEOPOLITICAL INTELLIGENCE SUMMARIES - ${date}\n`;
        content += `${'='.repeat(60)}\n\n`;
        
        // Top trending items in plain text
        content += `TOP TRENDING STORIES:\n\n`;
        newsItems.slice(0, 15).forEach((item, index) => {
            content += `${index + 1}. ${item.summary}\n`;
            content += `   Region: ${item.categories.join(', ').toUpperCase()}\n`;
            content += `   Score: ${item.trendingScore}/10\n`;
            content += `   Link: ${item.link}\n\n`;
        });
        
        // By category for easy copying
        const categories = ['african', 'caribbean', 'afro-latino'];
        categories.forEach(category => {
            const categoryItems = newsItems.filter(item => item.categories.includes(category));
            if (categoryItems.length > 0) {
                content += `\n${category.toUpperCase()} FOCUS:\n`;
                content += `${'-'.repeat(40)}\n`;
                categoryItems.slice(0, 10).forEach((item, index) => {
                    content += `${index + 1}. ${item.summary}\n`;
                });
                content += `\n`;
            }
        });
        
        return content;
    }
    
    generateCSVFormat(newsItems) {
        // CSV header
        let csv = 'Date,Title,Summary,Region,Score,Link,Category\n';
        
        // Add each news item as CSV row
        newsItems.slice(0, 50).forEach(item => {
            const date = new Date(item.processedAt).toLocaleDateString();
            const title = `"${item.title.replace(/"/g, '""')}"`; // Escape quotes
            const summary = `"${item.summary.replace(/"/g, '""')}"`;
            const region = item.categories.join('; ');
            const score = item.trendingScore;
            const link = item.link;
            const category = item.categories[0] || 'general';
            
            csv += `${date},${title},${summary},${region},${score},${link},${category}\n`;
        });
        
        return csv;
    }
    
    generateContentTemplate(newsItems) {
        const date = new Date().toLocaleDateString();
        let template = `CONTENT CREATION TEMPLATE - ${date}\n`;
        template += `${'='.repeat(50)}\n\n`;
        
        template += `HEADLINES FOR SOCIAL MEDIA:\n`;
        template += `${'-'.repeat(30)}\n`;
        newsItems.slice(0, 10).forEach((item, index) => {
            // Create social media friendly headlines
            const headline = item.summary.length > 100 ? 
                item.summary.substring(0, 97) + '...' : item.summary;
            template += `${index + 1}. ${headline}\n`;
        });
        
        template += `\n\nBLOG POST TOPICS:\n`;
        template += `${'-'.repeat(20)}\n`;
        newsItems.slice(0, 8).forEach((item, index) => {
            template += `${index + 1}. "${item.title}" - Analysis and Implications\n`;
        });
        
        template += `\n\nNEWSLETTER BULLETS:\n`;
        template += `${'-'.repeat(20)}\n`;
        newsItems.slice(0, 12).forEach((item, index) => {
            template += `• ${item.summary}\n`;
        });
        
        // Add regional focus sections
        const categories = ['african', 'caribbean', 'afro-latino'];
        categories.forEach(category => {
            const categoryItems = newsItems.filter(item => item.categories.includes(category));
            if (categoryItems.length > 0) {
                template += `\n\n${category.toUpperCase()} CONTENT IDEAS:\n`;
                template += `${'-'.repeat(25)}\n`;
                categoryItems.slice(0, 5).forEach((item, index) => {
                    template += `${index + 1}. ${item.summary}\n`;
                });
            }
        });
        
        template += `\n\nSOCIAL MEDIA HASHTAGS:\n`;
        template += `${'-'.repeat(25)}\n`;
        template += `#AfricanPolitics #GeopoliticsDaily #NewsIntelligence\n`;
        template += `#CaribbeanNews #AfroLatino #GlobalSouth #AfricanDiaspora\n`;
        
        return template;
    }

    async loadHistoricalData(timeframe) {
        const today = new Date();
        const data = [];
        
        // Load last 7 days of data for trend analysis
        for (let i = 0; i < 7; i++) {
            const date = new Date(today);
            date.setDate(date.getDate() - i);
            const dateString = date.toISOString().split('T')[0];
            
            try {
                const filePath = `trending-intelligence/summaries/trending-${dateString}.json`;
                const fileData = await fs.readFile(filePath, 'utf8');
                const jsonData = JSON.parse(fileData);
                if (jsonData.topTrending) {
                    data.push(...jsonData.topTrending);
                }
            } catch (error) {
                // File might not exist for this date
                continue;
            }
        }
        
        return data;
    }
    
    analyzeDisciplinePattern(disciplineData) {
        // Analyze patterns within a specific discipline
        const regions = {};
        const intensity = disciplineData.length;
        
        disciplineData.forEach(item => {
            if (item.categories) {
                item.categories.forEach(category => {
                    regions[category] = (regions[category] || 0) + 1;
                });
            }
        });
        
        return {
            intensity,
            regionalDistribution: regions,
            trend: intensity > 5 ? 'INCREASING' : intensity > 2 ? 'STABLE' : 'DECREASING'
        };
    }
    
    calculateConfidenceLevel(data) {
        // Calculate confidence based on data quality and quantity
        let confidence = 0.5; // Base confidence
        
        if (data.length > 10) confidence += 0.2; // More data points
        if (data.length > 20) confidence += 0.1; // Even more data
        
        // Check for multi-source verification
        const sources = new Set(data.map(item => item.link ? new URL(item.link).hostname : 'unknown'));
        if (sources.size > 3) confidence += 0.1; // Multiple sources
        
        // Check for multi-disciplinary coverage
        const disciplines = new Set();
        data.forEach(item => {
            if (item.disciplines) {
                item.disciplines.forEach(d => disciplines.add(d));
            }
        });
        if (disciplines.size > 2) confidence += 0.1; // Multi-disciplinary
        
        return Math.min(confidence, 1.0); // Cap at 1.0
    }
    
    generateDisciplineImplications(discipline, data) {
        const implications = [];
        
        switch(discipline) {
            case 'strategicStudies':
                implications.push('Monitor defense cooperation agreements');
                implications.push('Track military modernization programs');
                implications.push('Assess regional security balance');
                break;
            case 'economics':
                implications.push('Evaluate trade partnership opportunities');
                implications.push('Monitor currency stability indicators');
                implications.push('Track investment climate changes');
                break;
            case 'politicalScience':
                implications.push('Assess diplomatic relationship stability');
                implications.push('Monitor electoral developments');
                implications.push('Track international organization engagement');
                break;
            case 'energyResources':
                implications.push('Monitor energy infrastructure developments');
                implications.push('Track resource discovery announcements');
                implications.push('Assess energy security implications');
                break;
            default:
                implications.push('Continue comprehensive monitoring');
        }
        
        return implications;
    }
    
    generateRiskRecommendations(riskFactors) {
        const recommendations = [];
        
        if (riskFactors.securityRisk === 'HIGH') {
            recommendations.push('Enhance security monitoring protocols');
            recommendations.push('Increase diplomatic engagement frequency');
        }
        
        if (riskFactors.economicRisk === 'HIGH') {
            recommendations.push('Monitor trade flow disruptions');
            recommendations.push('Assess supply chain vulnerabilities');
        }
        
        if (riskFactors.overallRisk === 'HIGH') {
            recommendations.push('Activate crisis monitoring protocols');
            recommendations.push('Prepare scenario-based response plans');
        }
        
        return recommendations;
    }
    
    async saveStrategicAnalysis(analysis) {
        const timestamp = new Date().toISOString().split('T')[0];
        
        // Save comprehensive analysis
        await fs.writeFile(
            `trending-intelligence/strategic-foresight/analysis-${timestamp}.json`,
            JSON.stringify(analysis, null, 2)
        );
        
        // Save scenario planning separately
        await fs.writeFile(
            `trending-intelligence/scenario-planning/scenarios-${timestamp}.json`,
            JSON.stringify({
                date: timestamp,
                scenarios: analysis.scenarios,
                methodology: 'Strategic Foresight Analysis',
                generatedAt: new Date().toISOString()
            }, null, 2)
        );
        
        // Save OSINT guidance
        await fs.writeFile(
            `trending-intelligence/osint-analysis/guidance-${timestamp}.json`,
            JSON.stringify({
                date: timestamp,
                guidance: analysis.osintRecommendations,
                trends: analysis.trends,
                generatedAt: new Date().toISOString()
            }, null, 2)
        );
    }
    
    getCategoryCounts(newsItems) {
        const counts = {};
        newsItems.forEach(item => {
            item.categories.forEach(category => {
                counts[category] = (counts[category] || 0) + 1;
            });
        });
        return counts;
    }
    
    async scrapeImagesFromHeadlines(newsItems) {
        console.log('🖼️ Starting image scraping workflow for headlines...');
        
        const imageResults = [];
        let successCount = 0;
        let skipCount = 0;
        
        for (const item of newsItems.slice(0, 10)) { // Limit to top 10 for efficiency
            try {
                console.log(`📸 Processing images for: ${item.title.substring(0, 50)}...`);
                
                const articleImages = await this.extractImagesFromArticle(item);
                
                if (articleImages.length > 0) {
                    const downloadedImages = await this.downloadImages(articleImages, item);
                    
                    if (downloadedImages.length > 0) {
                        const imageMetadata = {
                            articleId: this.generateArticleId(item),
                            title: item.title,
                            link: item.link,
                            categories: item.categories || ['general'],
                            images: downloadedImages,
                            scrapedAt: new Date().toISOString(),
                            relevanceScore: item.relevanceScore || 0
                        };
                        
                        imageResults.push(imageMetadata);
                        successCount++;
                        
                        console.log(`✅ Downloaded ${downloadedImages.length} images for article`);
                    } else {
                        console.log(`⚠️ No images could be downloaded for article`);
                        skipCount++;
                    }
                } else {
                    console.log(`📷 No images found in article`);
                    skipCount++;
                }
                
                // Rate limiting to be respectful
                await new Promise(resolve => setTimeout(resolve, 1000));
                
            } catch (error) {
                console.error(`❌ Error processing images for article:`, error.message);
                skipCount++;
            }
        }
        
        // Save image metadata
        await this.saveImageMetadata(imageResults);
        
        console.log(`🖼️ Image scraping complete: ${successCount} successful, ${skipCount} skipped`);
        
        return {
            totalProcessed: newsItems.slice(0, 10).length,
            successful: successCount,
            skipped: skipCount,
            images: imageResults
        };
    }
    
    async extractImagesFromArticle(item) {
        try {
            // Check if item already has images from RSS
            let images = [];
            
            // Extract images from RSS enclosures
            if (item.enclosure && item.enclosure.url) {
                images.push({
                    url: item.enclosure.url,
                    type: 'rss_enclosure',
                    description: 'RSS feed image'
                });
            }
            
            // Extract images from content or description
            const content = item.content || item.description || '';
            if (content) {
                const imgRegex = /<img[^>]+src="([^"]+)"/gi;
                let match;
                while ((match = imgRegex.exec(content)) !== null) {
                    images.push({
                        url: match[1],
                        type: 'content_image',
                        description: 'Image from article content'
                    });
                }
            }
            
            // If no images found in RSS, scrape the article page
            if (images.length === 0 && item.link) {
                const scrapedImages = await this.scrapeArticlePage(item.link);
                images.push(...scrapedImages);
            }
            
            // Filter and validate image URLs
            return images.filter(img => 
                img.url && 
                (img.url.startsWith('http://') || img.url.startsWith('https://')) &&
                (img.url.includes('.jpg') || img.url.includes('.jpeg') || 
                 img.url.includes('.png') || img.url.includes('.webp') || 
                 img.url.includes('.gif'))
            );
            
        } catch (error) {
            console.error('Error extracting images from article:', error.message);
            return [];
        }
    }
    
    async scrapeArticlePage(articleUrl) {
        try {
            console.log(`🌐 Scraping article page: ${articleUrl}`);
            
            const response = await fetch(articleUrl, {
                timeout: 10000,
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
                }
            });
            
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }
            
            const html = await response.text();
            const $ = cheerio.load(html);
            
            const images = [];
            
            // Look for common article image selectors
            const imageSelectors = [
                'article img',
                '.article-image img',
                '.featured-image img',
                '.post-thumbnail img',
                '.entry-content img',
                '.story-body img',
                '.content img',
                'main img',
                '[class*="image"] img',
                '[class*="photo"] img'
            ];
            
            imageSelectors.forEach(selector => {
                $(selector).each((i, elem) => {
                    const src = $(elem).attr('src') || $(elem).attr('data-src');
                    const alt = $(elem).attr('alt') || '';
                    
                    if (src) {
                        // Convert relative URLs to absolute
                        const url = src.startsWith('http') ? src : new URL(src, articleUrl).href;
                        
                        images.push({
                            url: url,
                            type: 'scraped_image',
                            description: alt || 'Article image'
                        });
                    }
                });
            });
            
            // Deduplicate images
            const uniqueImages = images.filter((img, index, self) => 
                index === self.findIndex(i => i.url === img.url)
            );
            
            return uniqueImages.slice(0, 3); // Limit to 3 images per article
            
        } catch (error) {
            console.error(`Error scraping article page ${articleUrl}:`, error.message);
            return [];
        }
    }
    
    async downloadImages(imageList, article) {
        const downloadedImages = [];
        
        for (const image of imageList.slice(0, 2)) { // Limit to 2 images per article
            try {
                const downloadResult = await this.downloadSingleImage(image.url, article, image.type);
                if (downloadResult) {
                    downloadedImages.push({
                        ...image,
                        localPath: downloadResult.localPath,
                        fileName: downloadResult.fileName,
                        fileSize: downloadResult.fileSize,
                        downloadedAt: new Date().toISOString()
                    });
                }
            } catch (error) {
                console.error(`Error downloading image ${image.url}:`, error.message);
            }
        }
        
        return downloadedImages;
    }
    
    async downloadSingleImage(imageUrl, article, imageType) {
        try {
            const response = await fetch(imageUrl, {
                timeout: 15000,
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                }
            });
            
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }
            
            const buffer = await response.buffer();
            
            // Generate unique filename
            const articleId = this.generateArticleId(article);
            const urlHash = crypto.createHash('md5').update(imageUrl).digest('hex').substring(0, 8);
            const extension = this.getImageExtension(imageUrl) || 'jpg';
            const fileName = `${articleId}_${urlHash}_${imageType}.${extension}`;
            
            // Determine storage path based on article categories
            let storagePath = 'images/headlines';
            if (article.categories) {
                if (article.categories.includes('african')) {
                    storagePath = 'images/regional/african';
                } else if (article.categories.includes('caribbean')) {
                    storagePath = 'images/regional/caribbean';
                } else if (article.categories.includes('afroLatino')) {
                    storagePath = 'images/regional/afro-latino';
                }
            }
            
            const localPath = path.join(storagePath, fileName);
            
            // Save image to local storage
            await fs.writeFile(localPath, buffer);
            
            console.log(`💾 Saved image: ${fileName} (${buffer.length} bytes)`);
            
            return {
                localPath: localPath,
                fileName: fileName,
                fileSize: buffer.length
            };
            
        } catch (error) {
            console.error(`Failed to download image ${imageUrl}:`, error.message);
            return null;
        }
    }
    
    generateArticleId(article) {
        const title = article.title || 'unknown';
        const url = article.link || '';
        const content = title + url;
        return crypto.createHash('md5').update(content).digest('hex').substring(0, 12);
    }
    
    getImageExtension(url) {
        const match = url.match(/\.(jpg|jpeg|png|gif|webp)(\?.*)?$/i);
        return match ? match[1].toLowerCase() : null;
    }
    
    async saveImageMetadata(imageResults) {
        try {
            const timestamp = new Date().toISOString().split('T')[0];
            const metadataFile = `trending-intelligence/images/image-metadata-${timestamp}.json`;
            
            // Ensure directory exists
            await fs.mkdir('trending-intelligence/images', { recursive: true });
            
            const metadata = {
                date: timestamp,
                totalArticles: imageResults.length,
                totalImages: imageResults.reduce((sum, result) => sum + result.images.length, 0),
                articles: imageResults,
                generatedAt: new Date().toISOString()
            };
            
            await fs.writeFile(metadataFile, JSON.stringify(metadata, null, 2));
            console.log(`📋 Saved image metadata: ${metadataFile}`);
            
        } catch (error) {
            console.error('Error saving image metadata:', error.message);
        }
    }
    
    extractDisciplines(newsItems) {
        const disciplines = new Set();
        newsItems.forEach(item => {
            if (item.disciplines) {
                item.disciplines.forEach(d => disciplines.add(d));
            }
        });
        return Array.from(disciplines);
    }

    // Enhanced Image Scraping Methods
    async enhancedImageScraping(newsItems, strategy, includeRelated) {
        console.log(`🔍 Starting enhanced image scraping with ${strategy} strategy...`);
        
        const results = {
            totalProcessed: newsItems.length,
            successful: 0,
            skipped: 0,
            images: [],
            strategy: strategy,
            methods: []
        };
        
        for (const item of newsItems) {
            try {
                console.log(`🔍 Enhanced processing: ${item.title.substring(0, 50)}...`);
                
                let articleImages = [];
                
                // Strategy 1: Aggressive scraping with multiple attempts
                if (strategy === 'aggressive' || strategy === 'all') {
                    articleImages = await this.aggressiveImageScraping(item);
                    results.methods.push('aggressive');
                }
                
                // Strategy 2: API-Based Image Search (Google/Bing/News)
                if ((strategy === 'api_search' || strategy === 'all') && articleImages.length === 0) {
                    const apiImages = await this.apiImageSearch(item);
                    articleImages.push(...apiImages.images);
                    if (apiImages.images.length > 0) results.methods.push('api_search');
                }
                
                // Strategy 3: Social media and news aggregator search
                if ((strategy === 'social_media' || strategy === 'all') && articleImages.length === 0) {
                    const socialImages = await this.searchSocialMediaImages(item);
                    articleImages.push(...socialImages);
                    if (socialImages.length > 0) results.methods.push('social_media');
                }
                
                // Strategy 4: Related articles search
                if ((strategy === 'related_articles' || strategy === 'all') && articleImages.length === 0 && includeRelated) {
                    const relatedImages = await this.searchRelatedArticleImages(item);
                    articleImages.push(...relatedImages);
                    if (relatedImages.length > 0) results.methods.push('related_articles');
                }
                
                // Strategy 5: AI-powered image discovery
                if ((strategy === 'ai_discovery' || strategy === 'all') && articleImages.length === 0) {
                    const aiImages = await this.aiImageDiscovery(item);
                    articleImages.push(...aiImages);
                    if (aiImages.length > 0) results.methods.push('ai_discovery');
                }
                
                if (articleImages.length > 0) {
                    const downloadedImages = await this.downloadImages(articleImages, item);
                    
                    if (downloadedImages.length > 0) {
                        const imageMetadata = {
                            articleId: this.generateArticleId(item),
                            title: item.title,
                            link: item.link,
                            categories: item.categories || ['general'],
                            images: downloadedImages,
                            scrapedAt: new Date().toISOString(),
                            relevanceScore: item.relevanceScore || 0,
                            strategy: strategy
                        };
                        
                        results.images.push(imageMetadata);
                        results.successful++;
                        
                        console.log(`✅ Enhanced scraping found ${downloadedImages.length} images`);
                    } else {
                        console.log(`⚠️ Images found but download failed`);
                        results.skipped++;
                    }
                } else {
                    console.log(`📷 No images found with enhanced methods`);
                    results.skipped++;
                }
                
                // Enhanced rate limiting
                await new Promise(resolve => setTimeout(resolve, 2000));
                
            } catch (error) {
                console.error(`❌ Enhanced scraping error:`, error.message);
                results.skipped++;
            }
        }
        
        // Save enhanced metadata
        await this.saveEnhancedImageMetadata(results);
        
        console.log(`🔍 Enhanced scraping complete: ${results.successful} successful, ${results.skipped} skipped`);
        console.log(`📊 Methods used: ${[...new Set(results.methods)].join(', ')}`);
        
        return results;
    }
    
    async aggressiveImageScraping(item) {
        const images = [];
        
        try {
            // Multiple attempts with different techniques
            
            // 1. Deep content parsing
            const contentImages = await this.deepContentParsing(item);
            images.push(...contentImages);
            
            // 2. Multiple CSS selectors
            const scrapedImages = await this.multiSelectorScraping(item.link);
            images.push(...scrapedImages);
            
            // 3. Check for mobile/AMP versions
            const alternateImages = await this.checkAlternateVersions(item.link);
            images.push(...alternateImages);
            
            console.log(`🔍 Aggressive scraping found ${images.length} images`);
            
        } catch (error) {
            console.error('Aggressive scraping error:', error.message);
        }
        
        return this.deduplicateImages(images);
    }
    
    async deepContentParsing(item) {
        const images = [];
        
        // Parse all content fields more thoroughly
        const content = [item.content, item.description, item.summary, item.contentSnippet].join(' ');
        
        // Enhanced regex patterns
        const patterns = [
            /<img[^>]+src=["']([^"']+)["'][^>]*>/gi,
            /background-image:\s*url\(["']?([^"')]+)["']?\)/gi,
            /data-src=["']([^"']+)["']/gi,
            /data-lazy-src=["']([^"']+)["']/gi
        ];
        
        patterns.forEach(pattern => {
            let match;
            while ((match = pattern.exec(content)) !== null) {
                images.push({
                    url: match[1],
                    type: 'deep_content_image',
                    description: 'Deep content parsed image'
                });
            }
        });
        
        return images;
    }
    
    async multiSelectorScraping(articleUrl) {
        const images = [];
        
        try {
            const response = await fetch(articleUrl, {
                timeout: 15000,
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
                }
            });
            
            if (!response.ok) return images;
            
            const html = await response.text();
            const $ = cheerio.load(html);
            
            // Extensive selector list
            const selectors = [
                'img[src]',
                'img[data-src]',
                'img[data-lazy-src]',
                '[style*="background-image"]',
                'picture source[srcset]',
                'figure img',
                '.wp-post-image',
                '.featured-image img',
                '.hero-image img',
                '.banner img',
                '.thumbnail img',
                '[class*="image"] img',
                '[class*="photo"] img',
                '[class*="picture"] img'
            ];
            
            selectors.forEach(selector => {
                $(selector).each((i, elem) => {
                    const src = $(elem).attr('src') || $(elem).attr('data-src') || $(elem).attr('data-lazy-src');
                    const style = $(elem).attr('style');
                    
                    if (src) {
                        const url = src.startsWith('http') ? src : new URL(src, articleUrl).href;
                        images.push({
                            url: url,
                            type: 'multi_selector_image',
                            description: $(elem).attr('alt') || 'Multi-selector scraped image'
                        });
                    } else if (style && style.includes('background-image')) {
                        const urlMatch = style.match(/background-image:\s*url\(["']?([^"')]+)["']?\)/);
                        if (urlMatch) {
                            const url = urlMatch[1].startsWith('http') ? urlMatch[1] : new URL(urlMatch[1], articleUrl).href;
                            images.push({
                                url: url,
                                type: 'background_image',
                                description: 'Background image'
                            });
                        }
                    }
                });
            });
            
        } catch (error) {
            console.error('Multi-selector scraping error:', error.message);
        }
        
        return images;
    }
    
    async checkAlternateVersions(articleUrl) {
        const images = [];
        
        try {
            const domain = new URL(articleUrl).origin;
            
            // Try mobile version
            const mobileUrl = articleUrl.replace('www.', 'm.').replace('://', '://m.');
            if (mobileUrl !== articleUrl) {
                const mobileImages = await this.scrapeArticlePage(mobileUrl);
                images.push(...mobileImages.map(img => ({ ...img, type: 'mobile_version' })));
            }
            
            // Try AMP version
            const ampUrl = articleUrl + '/amp';
            const ampImages = await this.scrapeArticlePage(ampUrl);
            images.push(...ampImages.map(img => ({ ...img, type: 'amp_version' })));
            
        } catch (error) {
            console.error('Alternate versions check error:', error.message);
        }
        
        return images;
    }
    
    async searchSocialMediaImages(item) {
        const images = [];
        
        try {
            // Simulate social media search (would integrate with APIs in production)
            const keywords = this.extractKeywords(item.title);
            console.log(`🔍 Searching social media for: ${keywords}`);
            
            // This would integrate with actual social media APIs
            // For now, return placeholder structure
            
        } catch (error) {
            console.error('Social media search error:', error.message);
        }
        
        return images;
    }
    
    async searchRelatedArticleImages(item) {
        const images = [];
        
        try {
            const keywords = this.extractKeywords(item.title);
            console.log(`🔍 Searching related articles for: ${keywords}`);
            
            // Search for related articles with the same keywords
            // This would integrate with news aggregation APIs
            
        } catch (error) {
            console.error('Related articles search error:', error.message);
        }
        
        return images;
    }
    
    async aiImageDiscovery(item) {
        const images = [];
        
        try {
            // AI-powered image discovery using content analysis
            const keywords = this.extractKeywords(item.title);
            const entities = this.extractEntities(item);
            
            console.log(`🤖 AI discovery for keywords: ${keywords}, entities: ${entities.join(', ')}`);
            
            // This would integrate with AI services for image discovery
            
        } catch (error) {
            console.error('AI image discovery error:', error.message);
        }
        
        return images;
    }
    
    extractKeywords(title) {
        // Extract meaningful keywords from title
        const words = title.toLowerCase().split(/\s+/);
        const stopWords = ['the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by'];
        return words.filter(word => word.length > 3 && !stopWords.includes(word)).slice(0, 5).join(' ');
    }
    
    extractEntities(item) {
        // Extract entities (countries, organizations, people) from content
        const content = `${item.title} ${item.description || ''}`.toLowerCase();
        const entities = [];
        
        // Simple entity extraction (would use NLP in production)
        const regionKeywords = Object.keys(this.geopoliticalKeywords);
        regionKeywords.forEach(region => {
            this.geopoliticalKeywords[region].forEach(keyword => {
                if (content.includes(keyword) && !entities.includes(keyword)) {
                    entities.push(keyword);
                }
            });
        });
        
        return entities.slice(0, 10);
    }
    
    deduplicateImages(images) {
        const seen = new Set();
        return images.filter(img => {
            if (seen.has(img.url)) {
                return false;
            }
            seen.add(img.url);
            return true;
        });
    }
    
    async searchRelatedImages(keywords, sources, region) {
        console.log(`🔍 Searching for related images: ${keywords}`);
        
        const results = {
            totalFound: 0,
            downloaded: 0,
            images: [],
            sources: sources
        };
        
        try {
            // This would integrate with image search APIs
            // For now, return structure showing the capability
            
            console.log(`🔍 Would search ${sources.join(', ')} for: ${keywords}`);
            console.log(`🌍 Filtered by region: ${region}`);
            
            results.message = `Related image search functionality ready for API integration`;
            
        } catch (error) {
            console.error('Related image search error:', error.message);
            results.error = error.message;
        }
        
        return results;
    }
    
    async saveEnhancedImageMetadata(results) {
        try {
            const timestamp = new Date().toISOString().split('T')[0];
            const enhancedMetadataFile = `trending-intelligence/images/enhanced-metadata-${timestamp}.json`;
            
            const metadata = {
                date: timestamp,
                strategy: results.strategy,
                methods: [...new Set(results.methods)],
                totalArticles: results.totalProcessed,
                totalImages: results.images.reduce((sum, article) => sum + article.images.length, 0),
                articles: results.images,
                performance: {
                    successful: results.successful,
                    skipped: results.skipped,
                    successRate: (results.successful / results.totalProcessed * 100).toFixed(1) + '%'
                },
                generatedAt: new Date().toISOString()
            };
            
            await fs.writeFile(enhancedMetadataFile, JSON.stringify(metadata, null, 2));
            console.log(`📋 Saved enhanced image metadata: ${enhancedMetadataFile}`);
            
        } catch (error) {
            console.error('Error saving enhanced image metadata:', error.message);
        }
    }

    // API Integration Methods
    
    // Google Images API Integration
    async integrateGoogleImages(keywords, region = 'all') {
        const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY;
        const GOOGLE_CSE_ID = process.env.GOOGLE_CSE_ID;
        
        if (!GOOGLE_API_KEY || !GOOGLE_CSE_ID) {
            console.log('🔑 Google API credentials not configured');
            return { images: [], source: 'google_fallback' };
        }
        
        try {
            const searchQuery = keywords.join(' ') + (region !== 'all' ? ` ${region}` : '');
            const url = `https://www.googleapis.com/customsearch/v1?key=${GOOGLE_API_KEY}&cx=${GOOGLE_CSE_ID}&q=${encodeURIComponent(searchQuery)}&searchType=image&num=10&safe=active`;
            
            const response = await fetch(url);
            const data = await response.json();
            
            const images = (data.items || []).map(item => ({
                url: item.link,
                title: item.title,
                source: 'google_images',
                thumbnail: item.image?.thumbnailLink,
                contextLink: item.image?.contextLink,
                size: item.image?.width && item.image?.height ? `${item.image.width}x${item.image.height}` : 'unknown'
            }));
            
            console.log(`🔍 Google Images: Found ${images.length} images for "${searchQuery}"`);
            return { images, source: 'google_images', count: images.length };
        } catch (error) {
            console.error('❌ Google Images API error:', error.message);
            return { images: [], source: 'google_error' };
        }
    }

    // Bing Images API Integration
    async integrateBingImages(keywords, region = 'all') {
        const BING_API_KEY = process.env.BING_SEARCH_API_KEY;
        
        if (!BING_API_KEY) {
            console.log('🔑 Bing API key not configured');
            return { images: [], source: 'bing_fallback' };
        }
        
        try {
            const searchQuery = keywords.join(' ') + (region !== 'all' ? ` ${region}` : '');
            const url = `https://api.bing.microsoft.com/v7.0/images/search?q=${encodeURIComponent(searchQuery)}&count=10&safeSearch=Moderate`;
            
            const response = await fetch(url, {
                headers: {
                    'Ocp-Apim-Subscription-Key': BING_API_KEY
                }
            });
            
            const data = await response.json();
            
            const images = (data.value || []).map(item => ({
                url: item.contentUrl,
                title: item.name,
                source: 'bing_images',
                thumbnail: item.thumbnailUrl,
                contextLink: item.hostPageUrl,
                size: item.width && item.height ? `${item.width}x${item.height}` : 'unknown'
            }));
            
            console.log(`🔍 Bing Images: Found ${images.length} images for "${searchQuery}"`);
            return { images, source: 'bing_images', count: images.length };
        } catch (error) {
            console.error('❌ Bing Images API error:', error.message);
            return { images: [], source: 'bing_error' };
        }
    }

    // News API Integration for Related Articles
    async integrateNewsAPI(keywords, region = 'all') {
        const NEWS_API_KEY = process.env.NEWS_API_KEY;
        
        if (!NEWS_API_KEY) {
            console.log('🔑 News API key not configured');
            return { articles: [], source: 'news_fallback' };
        }
        
        try {
            const searchQuery = keywords.join(' OR ');
            const url = `https://newsapi.org/v2/everything?q=${encodeURIComponent(searchQuery)}&pageSize=20&sortBy=relevancy`;
            
            const response = await fetch(url, {
                headers: {
                    'X-API-Key': NEWS_API_KEY
                }
            });
            
            const data = await response.json();
            
            const articlesWithImages = (data.articles || [])
                .filter(article => article.urlToImage)
                .map(article => ({
                    url: article.urlToImage,
                    title: article.title,
                    source: 'news_api',
                    contextLink: article.url,
                    description: article.description,
                    publishedAt: article.publishedAt
                }));
            
            console.log(`📰 News API: Found ${articlesWithImages.length} articles with images`);
            return { articles: articlesWithImages, source: 'news_api', count: articlesWithImages.length };
        } catch (error) {
            console.error('❌ News API error:', error.message);
            return { articles: [], source: 'news_error' };
        }
    }

    // Unified API Image Search
    async apiImageSearch(item) {
        const keywords = this.extractKeywordsFromItem(item);
        const region = this.determineRegion(item);
        
        console.log(`🔍 API Search for: ${keywords.join(', ')}`);
        
        const results = {
            images: [],
            sources: [],
            totalFound: 0
        };
        
        try {
            // Try Google Images first
            const googleResults = await this.integrateGoogleImages(keywords, region);
            if (googleResults.images.length > 0) {
                results.images.push(...googleResults.images.slice(0, 3)); // Limit to 3 per source
                results.sources.push('google_images');
            }
            
            // Try Bing Images as fallback
            if (results.images.length < 2) {
                const bingResults = await this.integrateBingImages(keywords, region);
                if (bingResults.images.length > 0) {
                    results.images.push(...bingResults.images.slice(0, 3));
                    results.sources.push('bing_images');
                }
            }
            
            // Try News API for related articles
            const newsResults = await this.integrateNewsAPI(keywords, region);
            if (newsResults.articles.length > 0) {
                results.images.push(...newsResults.articles.slice(0, 2));
                results.sources.push('news_api');
            }
            
            results.totalFound = results.images.length;
            
            if (results.totalFound > 0) {
                console.log(`✅ API Search found ${results.totalFound} images from: ${results.sources.join(', ')}`);
            } else {
                console.log(`⚠️ API Search found no images for: ${keywords.join(', ')}`);
            }
            
        } catch (error) {
            console.error('❌ API Image Search error:', error.message);
        }
        
        return results;
    }

    // Extract relevant keywords from news item
    extractKeywordsFromItem(item) {
        const text = `${item.title} ${item.description || ''}`.toLowerCase();
        const keywords = [];
        
        // Extract country names
        const countries = ['nigeria', 'ghana', 'kenya', 'south africa', 'jamaica', 'haiti', 'brazil', 'colombia', 'venezuela'];
        countries.forEach(country => {
            if (text.includes(country)) keywords.push(country);
        });
        
        // Extract political terms
        const politicalTerms = ['election', 'president', 'government', 'politics', 'democracy', 'vote'];
        politicalTerms.forEach(term => {
            if (text.includes(term)) keywords.push(term);
        });
        
        // Extract key nouns (simple approach)
        const words = text.split(' ');
        const importantWords = words.filter(word => 
            word.length > 4 && 
            !['news', 'said', 'report', 'according', 'would', 'could', 'should'].includes(word)
        );
        
        keywords.push(...importantWords.slice(0, 3));
        
        return [...new Set(keywords)].slice(0, 5); // Unique keywords, max 5
    }

    // Determine region from item
    determineRegion(item) {
        const categories = item.categories || [];
        if (categories.includes('african')) return 'african';
        if (categories.includes('caribbean')) return 'caribbean';
        if (categories.includes('afroLatino')) return 'afro-latino';
        return 'all';
    }

    async generateTrendingAnalysis() {
        const today = new Date().toISOString().split('T')[0];
        
        try {
            const summaryFile = `trending-intelligence/summaries/trending-${today}.json`;
            const data = await fs.readFile(summaryFile, 'utf8');
            return JSON.parse(data);
        } catch (error) {
            // If no data for today, generate fresh
            return await this.fetchGeopoliticalNews();
        }
    }

    async getRegionalSummaries(region) {
        const today = new Date().toISOString().split('T')[0];
        
        try {
            const regionFile = `trending-intelligence/geopolitics/${region}/latest-${today}.json`;
            const data = await fs.readFile(regionFile, 'utf8');
            return JSON.parse(data);
        } catch (error) {
            return { error: `No data available for region: ${region}` };
        }
    }

    async analyzeGeopoliticalTrends(timeframe) {
        const today = new Date();
        const analysis = {
            timeframe,
            analysisDate: today.toISOString(),
            methodology: 'Structured Analytical Techniques',
            trends: [],
            riskAssessment: {},
            strategicImplications: [],
            scenarios: []
        };
        
        try {
            // Load historical data for trend analysis
            const historicalData = await this.loadHistoricalData(timeframe);
            
            // Perform multi-disciplinary trend analysis
            analysis.trends = this.identifyGeopoliticalTrends(historicalData);
            
            // Generate risk assessment using structured techniques
            analysis.riskAssessment = this.performRiskAssessment(historicalData);
            
            // Strategic foresight and scenario planning
            analysis.scenarios = this.generateScenarios(analysis.trends);
            
            // OSINT validation recommendations
            analysis.osintRecommendations = this.generateOSINTGuidance(analysis.trends);
            
            // Save analysis for future reference
            await this.saveStrategicAnalysis(analysis);
            
            return analysis;
        } catch (error) {
            return {
                error: `Analysis failed: ${error.message}`,
                fallback: 'Basic trend monitoring active'
            };
        }
    }
    
    identifyGeopoliticalTrends(data) {
        const trends = [];
        
        // Analyze by discipline
        const disciplines = ['strategicStudies', 'economics', 'politicalScience', 'energyResources'];
        
        disciplines.forEach(discipline => {
            const disciplineData = data.filter(item => 
                item.disciplines && item.disciplines.includes(discipline)
            );
            
            if (disciplineData.length > 0) {
                trends.push({
                    discipline,
                    pattern: this.analyzeDisciplinePattern(disciplineData),
                    confidence: this.calculateConfidenceLevel(disciplineData),
                    implications: this.generateDisciplineImplications(discipline, disciplineData)
                });
            }
        });
        
        return trends;
    }
    
    performRiskAssessment(data) {
        const riskFactors = {
            geopoliticalRisk: 'MEDIUM',
            economicRisk: 'MEDIUM', 
            securityRisk: 'MEDIUM',
            socialRisk: 'MEDIUM',
            overallRisk: 'MEDIUM'
        };
        
        // Security risk assessment
        const securityItems = data.filter(item => 
            item.disciplines && item.disciplines.includes('strategicStudies')
        );
        if (securityItems.length > 5) riskFactors.securityRisk = 'HIGH';
        
        // Economic risk assessment
        const economicItems = data.filter(item => 
            item.disciplines && (item.disciplines.includes('economics') || 
                               item.disciplines.includes('politicalEconomy'))
        );
        if (economicItems.length > 3) riskFactors.economicRisk = 'HIGH';
        
        // Risk indicators assessment
        const riskIndicators = data.filter(item => 
            item.disciplines && item.disciplines.includes('riskIndicators')
        );
        if (riskIndicators.length > 2) {
            riskFactors.overallRisk = 'HIGH';
            riskFactors.geopoliticalRisk = 'HIGH';
        }
        
        return {
            ...riskFactors,
            assessmentDate: new Date().toISOString(),
            methodology: 'Multi-disciplinary risk matrix',
            recommendations: this.generateRiskRecommendations(riskFactors)
        };
    }
    
    generateScenarios(trends) {
        const scenarios = [
            {
                name: 'Status Quo Continuation',
                probability: 0.4,
                description: 'Current geopolitical patterns continue with gradual evolution',
                indicators: ['Stable bilateral relations', 'Moderate economic growth']
            },
            {
                name: 'Regional Escalation',
                probability: 0.3,
                description: 'Increased regional tensions leading to economic or security challenges',
                indicators: ['Military buildups', 'Trade disputes', 'Diplomatic tensions']
            },
            {
                name: 'Breakthrough Cooperation',
                probability: 0.2,
                description: 'Significant diplomatic breakthroughs leading to enhanced regional cooperation',
                indicators: ['New trade agreements', 'Peace accords', 'Joint initiatives']
            },
            {
                name: 'Systemic Disruption',
                probability: 0.1,
                description: 'Major geopolitical realignment affecting global systems',
                indicators: ['Alliance shifts', 'Economic decoupling', 'Regime changes']
            }
        ];
        
        // Adjust probabilities based on current trends
        if (trends.some(t => t.discipline === 'strategicStudies' && t.confidence > 0.7)) {
            scenarios[1].probability += 0.1; // Regional Escalation more likely
            scenarios[0].probability -= 0.1;
        }
        
        return scenarios;
    }
    
    generateOSINTGuidance(trends) {
        const guidance = {
            priority_sources: [],
            monitoring_keywords: [],
            verification_methods: [],
            analysis_techniques: []
        };
        
        trends.forEach(trend => {
            switch(trend.discipline) {
                case 'strategicStudies':
                    guidance.priority_sources.push('Military press releases', 'Defense contractor announcements');
                    guidance.monitoring_keywords.push('military exercise', 'defense cooperation', 'arms deal');
                    break;
                case 'economics':
                    guidance.priority_sources.push('Central bank statements', 'Trade ministry announcements');
                    guidance.monitoring_keywords.push('trade agreement', 'economic sanctions', 'investment');
                    break;
                case 'energyResources':
                    guidance.priority_sources.push('Energy ministry statements', 'Pipeline announcements');
                    guidance.monitoring_keywords.push('energy security', 'pipeline', 'resource discovery');
                    break;
            }
        });
        
        guidance.verification_methods = [
            'Cross-reference multiple sources',
            'Verify official government statements',
            'Check international organization reports',
            'Monitor social media sentiment'
        ];
        
        return guidance;
    }

    async start() {
        try {
            // Initial data fetch
            await this.fetchGeopoliticalNews();
            
            // Start server
            await new Promise((resolve, reject) => {
                this.server = this.app.listen(this.port, (error) => {
                    if (error) reject(error);
                    else resolve();
                });
            });

            console.log(`
╔══════════════════════════════════════════════════════════════╗
║           Geopolitical News Intelligence Server             ║
╠══════════════════════════════════════════════════════════════╣
║  🚀 Server: http://localhost:${this.port}                       ║
║  🌍 Focus: African, Caribbean, Afro-Latino Geopolitics     ║
║  📊 Features: Trending Analysis, 130-char Summaries        ║
║  🖼️ Image Scraping: Visual Intelligence Collection         ║
║  🔍 Enhanced: Multi-strategy Image Discovery              ║
║  📁 Output: trending-intelligence/ & images/ directories   ║
╚══════════════════════════════════════════════════════════════╝

✅ Enhanced News Intelligence Server Ready!
🔗 MCP Protocol: http://localhost:${this.port}/mcp
📈 Trending API: http://localhost:${this.port}/api/trending
🌍 Geopolitics: http://localhost:${this.port}/api/geopolitics/{region}
🖼️ Image Scraping: http://localhost:${this.port}/api/scrape-images
🔍 Enhanced Images: http://localhost:${this.port}/api/enhanced-scrape-images
            `);

        } catch (error) {
            console.error('❌ Failed to start server:', error.message);
            throw error;
        }
    }
}

// Start the server
if (require.main === module) {
    const server = new GeopoliticalNewsIntelligence();
    server.start().catch(console.error);
}

module.exports = GeopoliticalNewsIntelligence;