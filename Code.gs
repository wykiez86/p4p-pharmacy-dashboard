const CONFIG = {
  spreadsheetId: "1_GYidBhP5QAZ06cs7KvBoHIjLRNzrrZRMpFDM2OhE_M",
  sheetNames: {
    staff: "P4P Staff",
    activities: "P4P Activities",
    entries: "P4P Entries"
  }
};
const TARGETS = {
  "เภสัชกร": 1440,
  "เจ้าพนักงานเภสัชกรรม": 960,
  "พนักงานประจำห้องยา": 600
};

function doGet() {
  return HtmlService.createHtmlOutputFromFile("Index")
    .setTitle("ระบบบันทึกภาระงาน P4P | กลุ่มงานเภสัชกรรม")
    .addMetaTag("viewport", "width=device-width, initial-scale=1");
}

function getDashboardData(month) {
  validateMonth_(month);
  const sheets = getDatabaseSheets_();
  const staff = rows_(sheets.staff)
    .filter(row => row[0] === month)
    .map(row => ({ id: String(row[1]), name: String(row[2]), role: String(row[3]) }));
  const activities = rows_(sheets.activities)
    .filter(row => row[0] === month)
    .map(row => ({ id: String(row[1]), name: String(row[2]), points: Number(row[3]) || 0 }));
  const entries = {};
  rows_(sheets.entries).filter(row => row[0] === month).forEach(row => {
    const [, staffId, activityId, day, count] = row;
    entries[String(staffId)] ??= {};
    entries[String(staffId)][String(activityId)] ??= {};
    entries[String(staffId)][String(Number(day))] = Number(count) || 0;
  });
  return { staff, activities, entries };
}

function addStaff(month, name, role) {
  validateMonth_(month);
  const cleanName = safeText_(name, "ชื่อบุคลากร");
  if (!Object.prototype.hasOwnProperty.call(TARGETS, role)) throw new Error("ตำแหน่งไม่อยู่ในรายการเกณฑ์");
  getDatabaseSheets_().staff.appendRow([month, Utilities.getUuid(), cleanName, role]);
  return true;
}

function removeStaff(month, staffId) {
  validateMonth_(month);
  const sheets = getDatabaseSheets_();
  deleteRows_(sheets.entries, row => row[0] === month && String(row[1]) === String(staffId));
  deleteRows_(sheets.staff, row => row[0] === month && String(row[1]) === String(staffId));
  return true;
}

function addActivity(month, name, points) {
  validateMonth_(month);
  const cleanName = safeText_(name, "ชื่อประเภทงาน");
  const value = Number(points);
  if (!Number.isFinite(value) || value < 0) throw new Error("คะแนนต่องานต้องเป็นตัวเลขตั้งแต่ 0 ขึ้นไป");
  getDatabaseSheets_().activities.appendRow([month, Utilities.getUuid(), cleanName, value]);
  return true;
}

function setEntry(month, staffId, activityId, day, count) {
  validateMonth_(month);
  const dayNumber = Number(day);
  const countNumber = Number(count);
  const [year, monthNumber] = month.split("-").map(Number);
  const daysInMonth = new Date(year, monthNumber, 0).getDate();
  if (!Number.isInteger(dayNumber) || dayNumber < 1 || dayNumber > daysInMonth) throw new Error("วันที่ไม่ถูกต้องสำหรับงวดนี้");
  if (!Number.isFinite(countNumber) || countNumber < 0) throw new Error("จำนวนงานต้องเป็นตัวเลขตั้งแต่ 0 ขึ้นไป");

  const lock = LockService.getScriptLock();
  lock.waitLock(10000);
  try {
    const sheets = getDatabaseSheets_();
    const staffExists = rows_(sheets.staff).some(row => row[0] === month && String(row[1]) === String(staffId));
    const activityExists = rows_(sheets.activities).some(row => row[0] === month && String(row[1]) === String(activityId));
    if (!staffExists || !activityExists) throw new Error("ไม่พบบุคลากรหรือประเภทงานของงวดนี้");
    const match = row => row[0] === month && String(row[1]) === String(staffId) &&
      String(row[2]) === String(activityId) && Number(row[3]) === dayNumber;
    const existing = rows_(sheets.entries).findIndex(match);
    if (countNumber === 0) {
      if (existing >= 0) sheets.entries.deleteRow(existing + 2);
    } else if (existing >= 0) {
      sheets.entries.getRange(existing + 2, 5).setValue(countNumber);
    } else {
      sheets.entries.appendRow([month, String(staffId), String(activityId), dayNumber, countNumber]);
    }
  } finally {
    lock.releaseLock();
  }
  return true;
}

function clearMonth(month) {
  validateMonth_(month);
  const sheets = getDatabaseSheets_();
  Object.keys(sheets).forEach(key => deleteRows_(sheets[key], row => row[0] === month));
  return true;
}

function validateMonth_(month) {
  if (!/^\d{4}-(0[1-9]|1[0-2])$/.test(String(month))) throw new Error("งวดเดือนมีรูปแบบไม่ถูกต้อง");
}

function safeText_(value, label) {
  const text = String(value || "").trim();
  if (!text) throw new Error(label + "ห้ามเว้นว่าง");
  if (/^[=+@]/.test(text) || /^-[^\d]/.test(text)) throw new Error(label + "ขึ้นต้นด้วยอักขระที่ไม่รองรับ");
  return text;
}

function getDatabaseSheets_() {
  const book = SpreadsheetApp.openById(CONFIG.spreadsheetId);
  const definitions = {
    staff: [CONFIG.sheetNames.staff, ["Month", "ID", "Name", "Role"]],
    activities: [CONFIG.sheetNames.activities, ["Month", "ID", "Activity", "PointsPerTask"]],
    entries: [CONFIG.sheetNames.entries, ["Month", "StaffID", "ActivityID", "Day", "Count"]]
  };
  const result = {};
  Object.keys(definitions).forEach(key => {
    const [name, headers] = definitions[key];
    let sheet = book.getSheetByName(name);
    if (!sheet) sheet = book.insertSheet(name);
    if (sheet.getLastRow() === 0) sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
    result[key] = sheet;
  });
  return result;
}

function rows_(sheet) {
  const lastRow = sheet.getLastRow();
  return lastRow < 2 ? [] : sheet.getRange(2, 1, lastRow - 1, sheet.getLastColumn()).getValues();
}

function deleteRows_(sheet, predicate) {
  const values = rows_(sheet);
  for (let index = values.length - 1; index >= 0; index--) {
    if (predicate(values[index])) sheet.deleteRow(index + 2);
  }
}
