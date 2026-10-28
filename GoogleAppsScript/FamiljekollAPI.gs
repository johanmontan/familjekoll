const SHEET_NAME = '2022-25';
const DATE_COLUMN = 3; // C
const FIRST_DATA_ROW = 2;

const EVENT_COLUMNS = [
  { valueIndex: 2, category: 'johan', sourceColumn: 'Johans liv' },   // E
  { valueIndex: 3, category: 'emma', sourceColumn: 'Emmas liv' },   // F
  { valueIndex: 4, category: 'ia', sourceColumn: 'B2s lilla liv' }, // G
  { valueIndex: 5, category: 'allie', sourceColumn: 'B3s lilla liv' }, // H
  { valueIndex: 6, category: 'annat', sourceColumn: 'Annat' }       // I
];

/**
 * GET /exec?from=2026-10-28&to=2026-10-29&key=...
 *
 * API_KEY is optional. Add it in Apps Script under Project settings →
 * Script properties to keep the web app behind a shared secret.
 */
function doGet(e) {
  try {
    const parameters = (e && e.parameter) || {};
    const expectedKey = PropertiesService.getScriptProperties().getProperty('API_KEY');
    if (expectedKey && parameters.key !== expectedKey) {
      return jsonResponse_({
        generatedAt: new Date().toISOString(),
        timeZone: Session.getScriptTimeZone(),
        events: [],
        error: 'Fel API-nyckel. Kontrollera webbadressen i Familjekoll.'
      });
    }

    const spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = spreadsheet.getSheetByName(SHEET_NAME);
    if (!sheet) {
      throw new Error('Fliken "' + SHEET_NAME + '" saknas.');
    }

    const timeZone = spreadsheet.getSpreadsheetTimeZone() || Session.getScriptTimeZone();
    const now = new Date();
    const tomorrow = new Date(now.getTime());
    tomorrow.setDate(tomorrow.getDate() + 1);

    const from = parameters.from || formatDay_(now, timeZone);
    const to = parameters.to || formatDay_(tomorrow, timeZone);
    if (!/^\d{4}-\d{2}-\d{2}$/.test(from) || !/^\d{4}-\d{2}-\d{2}$/.test(to) || from > to) {
      throw new Error('Datum måste anges som YYYY-MM-DD och from får inte ligga efter to.');
    }

    const lastRow = sheet.getLastRow();
    if (lastRow < FIRST_DATA_ROW) {
      return jsonResponse_({ generatedAt: now.toISOString(), timeZone: timeZone, events: [], error: null });
    }

    // C:I: datum, tom avdelare och de fem person-/kategorikolumnerna.
    const range = sheet.getRange(FIRST_DATA_ROW, DATE_COLUMN, lastRow - FIRST_DATA_ROW + 1, 7);
    const rawValues = range.getValues();
    const displayValues = range.getDisplayValues();
    const today = formatDay_(now, timeZone);
    const events = [];

    rawValues.forEach(function(row, rowIndex) {
      const rawDate = row[0];
      if (!(rawDate instanceof Date) || isNaN(rawDate.getTime())) return;

      const day = formatDay_(rawDate, timeZone);
      if (day < from || day > to) return;

      EVENT_COLUMNS.forEach(function(column, columnIndex) {
        const cellText = displayValues[rowIndex][column.valueIndex];
        splitEvents_(cellText).forEach(function(title, lineIndex) {
          events.push({
            id: [day, rowIndex + FIRST_DATA_ROW, columnIndex, lineIndex].join('-'),
            date: day,
            title: title,
            category: column.category,
            sourceColumn: column.sourceColumn,
            priority: scoreEvent_(title, column.category, day, today)
          });
        });
      });
    });

    events.sort(function(a, b) {
      if (a.date !== b.date) return a.date < b.date ? -1 : 1;
      if (a.priority !== b.priority) return b.priority - a.priority;
      return a.title.localeCompare(b.title, 'sv');
    });

    const requestedLimit = Number(parameters.limit || 100);
    const limit = Math.min(100, Math.max(1, isFinite(requestedLimit) ? requestedLimit : 100));
    return jsonResponse_({
      generatedAt: now.toISOString(),
      timeZone: timeZone,
      events: events.slice(0, limit),
      error: null
    });
  } catch (error) {
    return jsonResponse_({
      generatedAt: new Date().toISOString(),
      timeZone: Session.getScriptTimeZone(),
      events: [],
      error: error && error.message ? error.message : String(error)
    });
  }
}

function splitEvents_(value) {
  if (value === null || value === undefined) return [];

  return String(value)
    .split(/\r?\n/)
    .map(function(item) { return item.trim(); })
    .filter(function(item) {
      if (!item || item === '.' || item === ',') return false;
      return !/^#(REF|NAME|VALUE|DIV\/0|N\/A|NUM|NULL)/i.test(item);
    });
}

function scoreEvent_(title, category, day, today) {
  const normalized = title.toLocaleLowerCase('sv');
  const importantWords = [
    'läkare', 'tandläk', 'bvc', 'mvc', 'vaccin', 'sjuk', 'förskol', 'skola',
    'möte', 'resa', 'flyg', 'tåg', 'kalas', 'födelsedag', 'hämt', 'lämn',
    'deadline', 'stängt', 'avslutas', 'leverans'
  ];
  let score = 10;
  if (day === today) score += 25;
  if (category === 'annat') score -= 3;
  if (/\b([01]?\d|2[0-3])[:.]\d{2}\b/.test(normalized)) score += 8;
  importantWords.forEach(function(word) {
    if (normalized.indexOf(word) !== -1) score += 12;
  });
  return score;
}

function formatDay_(date, timeZone) {
  return Utilities.formatDate(date, timeZone, 'yyyy-MM-dd');
}

function jsonResponse_(payload) {
  return ContentService
    .createTextOutput(JSON.stringify(payload))
    .setMimeType(ContentService.MimeType.JSON);
}
