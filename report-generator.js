// report-generator.js
// Generates a geopolitics-focused report, breaking out news by category and including all relevant fields
// No paid APIs or keys required

const fs = require('fs');
const path = require('path');
const PDFDocument = require('pdfkit');

const INPUT_DIR = path.join(__dirname, 'news-daily');
const OUTPUT_DIR = path.join(__dirname, 'reports');
const today = new Date().toISOString().slice(0, 10);
const newsFile = path.join(INPUT_DIR, `news-${today}.json`);
const reportFile = path.join(OUTPUT_DIR, `report-${today}.pdf`);

const categoryLabels = {
  politics: 'Politics',
  military: 'Military',
  diplomacy: 'Diplomacy',
  agriculture: 'Agriculture',
  economy: 'Economy',
  society: 'Society',
  science: 'Science/Tech',
  diaspora: 'Diaspora',
  other: 'Other',
};

function groupByCategory(items) {
  const grouped = {};
  for (const item of items) {
    const cat = item.category || 'other';
    if (!grouped[cat]) grouped[cat] = [];
    grouped[cat].push(item);
  }
  return grouped;
}

function generateReport() {
  if (!fs.existsSync(newsFile)) {
    console.error('No news file for today.');
    process.exit(1);
  }
  if (!fs.existsSync(OUTPUT_DIR)) fs.mkdirSync(OUTPUT_DIR);
  const news = JSON.parse(fs.readFileSync(newsFile));
  const grouped = groupByCategory(news);
  const doc = new PDFDocument();
  doc.pipe(fs.createWriteStream(reportFile));
  doc.fontSize(20).text('Panafrican Geopolitical Intelligence Report', {align: 'center'});
  doc.fontSize(12).text(`Date: ${today}`, {align: 'center'});
  doc.moveDown();
  for (const [cat, items] of Object.entries(grouped)) {
    doc.fontSize(16).text(categoryLabels[cat] || cat, {underline: true});
    doc.moveDown(0.5);
    items.forEach((item, i) => {
      doc.fontSize(12).text(`${i + 1}. ${item.title || 'No Title'}`);
      doc.fontSize(10).text(`Summary: ${item.contentSnippet || item.content || ''}`);
      doc.fontSize(10).text(`Source: ${item.source || ''}`);
      doc.fontSize(10).text(`Date: ${item.pubDate || item.isoDate || ''}`);
      doc.fontSize(10).text(`Link: ${item.link || ''}`);
      doc.moveDown();
    });
    doc.addPage();
  }
  doc.end();
  console.log(`Report generated: ${reportFile}`);
}

generateReport();
