// news-fetcher.js
// Scrapes free news sources (RSS/public) for Africa, Caribbean, Afro-Latino, African American geopolitics
// Saves to /news-daily/news-YYYY-MM-DD.json

const fs = require('fs');
const path = require('path');
const Parser = require('rss-parser');
const parser = new Parser();

const OUTPUT_DIR = path.join(__dirname, 'news-daily');
const today = new Date().toISOString().slice(0, 10);
const outputFile = path.join(OUTPUT_DIR, `news-${today}.json`);

const feeds = [
  // Africa
  'https://allafrica.com/tools/headlines/rdf/latest/headlines.rdf',
  // Caribbean
  'https://www.caribbeannewsnow.com/feed/',
  // Afro-Latino
  'https://www.latimes.com/world-nation/rss2.0.xml',
  // African American
  'https://www.thegrio.com/feed/'
];

async function fetchNews() {
  try {
    if (!fs.existsSync(OUTPUT_DIR)) fs.mkdirSync(OUTPUT_DIR);
    let allItems = [];
    for (const url of feeds) {
      const feed = await parser.parseURL(url);
      allItems = allItems.concat(feed.items.map(item => ({
        title: item.title,
        link: item.link,
        pubDate: item.pubDate,
        content: item.contentSnippet || item.content,
        source: feed.title
      })));
    }
    fs.writeFileSync(outputFile, JSON.stringify(allItems, null, 2));
    console.log(`News saved to ${outputFile}`);
  } catch (err) {
    console.error('Failed to fetch news:', err.message);
    process.exit(1);
  }
}

fetchNews();
