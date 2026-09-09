const fs = require('fs');
const path = require('path');
const PDFDocument = require('pdfkit');
const { rephraseWeek } = require('./rephrase');

const BLACK = '#161616';
const ORANGE = '#E8690C';
const ORANGE_LIGHT = '#FCE9D9';
const TEXT_DARK = '#1F2937';
const TEXT_MUTED = '#6B7280';
const RULE = '#E5E7EB';

function loadConfig() {
  const configPath = path.join(__dirname, 'config.json');
  if (!fs.existsSync(configPath)) {
    console.error('config.json not found. Run setup.ps1 first to enter your name and title.');
    process.exit(1);
  }
  const config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
  if (!config.authorName || !config.authorTitle) {
    console.error('config.json is missing authorName/authorTitle. Run setup.ps1 to fix it.');
    process.exit(1);
  }
  return config;
}

const { authorName: AUTHOR_NAME, authorTitle: AUTHOR_TITLE } = loadConfig();

function formatDateRange(startStr, endStr) {
  const opts = { month: 'long', day: 'numeric' };
  const start = new Date(startStr + 'T00:00:00');
  const end = new Date(endStr + 'T00:00:00');
  const year = end.getFullYear();
  return `${start.toLocaleDateString('en-US', opts)} – ${end.toLocaleDateString('en-US', opts)}, ${year}`;
}

function drawHeader(doc, weekStart, weekEnd) {
  const pageWidth = doc.page.width;
  const marginX = 50;

  doc.rect(0, 0, pageWidth, 118).fill(BLACK);
  doc.rect(0, 118, pageWidth, 6).fill(ORANGE);

  doc.fillColor(ORANGE).font('Helvetica-Bold').fontSize(30)
    .text('DBM', marginX, 30);
  doc.font('Helvetica').fontSize(17).fillColor('#FFFFFF')
    .text('Weekly Report', marginX, 66);
  doc.font('Helvetica').fontSize(9.5).fillColor('#9CA3AF')
    .text('Discount Building Material', marginX, 90);

  doc.font('Helvetica-Bold').fontSize(13).fillColor('#FFFFFF')
    .text(formatDateRange(weekStart, weekEnd), 0, 40, { align: 'right', width: pageWidth - marginX });

  // Author bar
  const barY = 124;
  const barHeight = 34;
  doc.rect(0, barY, pageWidth, barHeight).fill('#F4F4F5');
  doc.rect(marginX, barY, 3, barHeight).fill(ORANGE);
  doc.font('Helvetica-Bold').fontSize(11).fillColor(BLACK)
    .text(AUTHOR_NAME, marginX + 14, barY + 10, { continued: true });
  doc.font('Helvetica').fontSize(10.5).fillColor(TEXT_MUTED)
    .text(`   |   ${AUTHOR_TITLE}`, { continued: false });

  return barY + barHeight + 26;
}

function drawFooter(doc, pageNum) {
  const pageWidth = doc.page.width;
  const pageHeight = doc.page.height;
  const marginX = 50;
  doc.moveTo(marginX, pageHeight - 55).lineTo(pageWidth - marginX, pageHeight - 55)
    .lineWidth(0.5).strokeColor(RULE).stroke();
  doc.fontSize(8).fillColor(TEXT_MUTED)
    .text(`Generated ${new Date().toLocaleString('en-US')}`, marginX, pageHeight - 42);
  doc.fontSize(8).fillColor(TEXT_MUTED)
    .text(`Page ${pageNum}`, 0, pageHeight - 42, { align: 'right', width: pageWidth - marginX });
}

async function generateReport(dataPath) {
  const data = JSON.parse(fs.readFileSync(dataPath, 'utf-8'));
  const { weekStart, weekEnd } = data;
  const days = await rephraseWeek(data.days, AUTHOR_NAME);

  const outDir = path.join(__dirname, 'Weekly Reports', `Week of ${weekStart}`);
  fs.mkdirSync(outDir, { recursive: true });
  const outPath = path.join(outDir, `Weekly Report - ${weekStart} to ${weekEnd}.pdf`);

  const doc = new PDFDocument({ size: 'A4', margin: 0, bufferPages: true });
  doc.pipe(fs.createWriteStream(outPath));

  const pageWidth = doc.page.width;
  const pageHeight = doc.page.height;
  const marginX = 50;
  const contentWidth = pageWidth - marginX * 2 - 28;

  let y = drawHeader(doc, weekStart, weekEnd);
  let pageNum = 1;

  const ensureSpace = (needed) => {
    if (y + needed > pageHeight - 70) {
      drawFooter(doc, pageNum);
      doc.addPage();
      pageNum += 1;
      y = 50;
    }
  };

  const entries = Object.entries(days).filter(([, items]) => items && items.length);

  for (const [label, items] of entries) {
    ensureSpace(40);

    const labelWidth = doc.font('Helvetica-Bold').fontSize(12).widthOfString(label) + 24;
    doc.roundedRect(marginX, y, labelWidth, 26, 5).fill(ORANGE_LIGHT);
    doc.fillColor(BLACK).font('Helvetica-Bold').fontSize(12)
      .text(label, marginX, y + 7, { width: labelWidth, align: 'center' });
    y += 36;

    for (const item of items) {
      const itemHeight = doc.font('Helvetica').fontSize(10.5).heightOfString(item, { width: contentWidth });
      ensureSpace(itemHeight + 10);
      doc.circle(marginX + 15, y + 6, 3).fill(ORANGE);
      doc.fillColor(TEXT_DARK).font('Helvetica').fontSize(10.5)
        .text(item, marginX + 28, y, { width: contentWidth });
      y += itemHeight + 10;
    }

    y += 12;
    ensureSpace(1);
    doc.moveTo(marginX, y).lineTo(pageWidth - marginX, y).lineWidth(0.5).strokeColor(RULE).stroke();
    y += 20;
  }

  drawFooter(doc, pageNum);
  doc.end();
  console.log('Saved report to', outPath);
}

const dataPath = process.argv[2];
if (!dataPath) {
  console.error('Usage: node generateReport.js <path-to-week-json>');
  process.exit(1);
}
generateReport(dataPath).catch((err) => {
  console.error('Failed to generate report:', err);
  process.exit(1);
});
