

const Parser = require('rss-parser');
const fs = require('fs');
const path = require('path');
const fetch = require('node-fetch');
const cheerio = require('cheerio');
const parser = new Parser();

const FEED_URL = 'https://allafrica.com/tools/headlines/rdf/latest/headlines.rdf';
const OUTPUT_FILE = 'allafrica-headlines.txt';
const IMAGES_DIR = 'images';

// Create images directory if it doesn't exist
if (!fs.existsSync(IMAGES_DIR)) {
  fs.mkdirSync(IMAGES_DIR);
}

async function getMainImage(url) {
  try {
    const res = await fetch(url);
    const html = await res.text();
    const $ = cheerio.load(html);
    // Try to find the main image (common selectors)
    let img = $('meta[property="og:image"]').attr('content');
    if (!img) img = $('img').first().attr('src');
    return img || 'No image found';
  } catch (e) {
    return 'Error fetching image';
  }
}

async function downloadImage(imageUrl, filename) {
  try {
    if (imageUrl === 'No image found' || imageUrl === 'Error fetching image') {
      return imageUrl;
    }
    
    const response = await fetch(imageUrl);
    if (!response.ok) {
      return 'Error downloading image';
    }
    
    const buffer = await response.buffer();
    const filePath = path.join(IMAGES_DIR, filename);
    fs.writeFileSync(filePath, buffer);
    
    return filePath;
  } catch (e) {
    console.error(`Error downloading image ${imageUrl}:`, e.message);
    return 'Error downloading image';
  }
}

function generateImageFilename(title, index, imageUrl) {
  // Create a safe filename from the title
  const safeTitle = title.replace(/[^a-zA-Z0-9]/g, '_').substring(0, 50);
  
  // Extract file extension from URL or default to .jpg
  let ext = '.jpg';
  try {
    const urlPath = new URL(imageUrl).pathname;
    const urlExt = path.extname(urlPath);
    if (urlExt && ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(urlExt.toLowerCase())) {
      ext = urlExt;
    }
  } catch (e) {
    // Use default extension if URL parsing fails
  }
  
  return `${index + 1}_${safeTitle}${ext}`;
}

(async () => {
  const feed = await parser.parseURL(FEED_URL);
  const results = [];
  
  for (let i = 0; i < feed.items.length; i++) {
    const item = feed.items[i];
    console.log(`Processing ${i + 1}/${feed.items.length}: ${item.title}`);
    
    const imgUrl = await getMainImage(item.link);
    let localImagePath = imgUrl;
    
    // Download image if URL is valid
    if (imgUrl && imgUrl !== 'No image found' && imgUrl !== 'Error fetching image') {
      const filename = generateImageFilename(item.title, i, imgUrl);
      localImagePath = await downloadImage(imgUrl, filename);
    }
    
    results.push(`[${item.title}](${item.link})\nImage: ${localImagePath}`);
    console.log(`[${item.title}](${item.link})\nImage: ${localImagePath}`);
  }
  
  fs.writeFileSync(OUTPUT_FILE, results.join('\n\n'), 'utf8');
  console.log(`Saved ${results.length} headlines with images to ${OUTPUT_FILE}`);
  console.log(`Images saved to: ${path.resolve(IMAGES_DIR)}`);
})();