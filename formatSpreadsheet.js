/**
 * Format TV Spreadsheets and accept automated local CSV/TSV uploads via Zsh
 * @author Monty Williams
 *
 * For information on how to use this code, see:
 * https://developers.google.com/apps-script/guides/sheets
 */

/* Keep eslint from complaining about classes provided by Google App Script */
/* global SpreadsheetApp Logger ContentService */
/* eslint-disable no-magic-numbers */

// Mapping your short identifiers to the target Spreadsheet URLs
const SHEET_MAP = {
  acorn_shows: "https://docs.google.com/spreadsheets/d/abc1234567/edit",
  acorn_episodes: "https://docs.google.com/spreadsheets/d/abc1234567/edit",
  bbox_shows: "https://docs.google.com/spreadsheets/d/abc1234567/edit",
  bbox_episodes: "https://docs.google.com/spreadsheets/d/abc1234567/edit",
  mhz_shows: "https://docs.google.com/spreadsheets/d/abc1234567/edit",
  mhz_episodes: "https://docs.google.com/spreadsheets/d/abc1234567/edit",
  opb_shows: "https://docs.google.com/spreadsheets/d/abc1234567/edit",
  opb_episodes: "https://docs.google.com/spreadsheets/d/abc1234567/edit",
};

// eslint-disable-next-line no-unused-vars
function format_All_TV_Spreadsheets() {
  // Using Object.keys avoids the guard-for-in prototype check completely
  Object.keys(SHEET_MAP).forEach((target) => {
    const ss = SpreadsheetApp.openByUrl(SHEET_MAP[target]);
    format_a_TV_Spreadsheet(ss);
  });
}

/**
 * Handles incoming POST requests from your MacBook terminal
 */
// eslint-disable-next-line no-unused-vars
function doPost(e) {
  try {
    const target = e.parameter.target;
    if (!target || !SHEET_MAP[target]) {
      return ContentService.createTextOutput(
        JSON.stringify({
          status: "error",
          message: "Invalid target sheet specified.",
        }),
      ).setMimeType(ContentService.MimeType.JSON);
    }

    // 1. Grab raw contents
    const csvText = e.postData.contents;
    if (!csvText) {
      return ContentService.createTextOutput(
        JSON.stringify({ status: "error", message: "Empty payload received." }),
      ).setMimeType(ContentService.MimeType.JSON);
    }

    // 2. Strip UTF-8 Byte Order Mark (BOM) if present
    let sanitizedText = csvText;
    if (sanitizedText.startsWith("\ufeff")) {
      sanitizedText = sanitizedText.slice(1);
    }

    // 3. MANUAL TAB PARSING: Split into rows, then split columns by literal tabs (\t)
    const lines = sanitizedText.split(/\r?\n/);
    const rawData = [];
    let maxColumns = 0;

    // First pass: Parse columns and track the longest row length (the header size)
    for (let i = 0; i < lines.length; i++) {
      if (lines[i].trim() === "") {
        continue;
      } // Skip trailing blank lines

      const columns = lines[i].split("\t");
      if (columns.length > maxColumns) {
        maxColumns = columns.length;
      }
      rawData.push(columns);
    }

    // Second pass: Pad shorter records with blank fields to make the 2D array rectangular
    for (let i = 0; i < rawData.length; i++) {
      while (rawData[i].length < maxColumns) {
        rawData[i].push(""); // Fill empty trailing columns
      }
    }

    const ss = SpreadsheetApp.openByUrl(SHEET_MAP[target]);
    const sheet = ss.getSheets()[0];

    // Clear old contents and formats completely (mimicking "replace spreadsheet")
    sheet.clearContents();
    sheet.clearFormats();

    // Inject new raw data array stream
    if (rawData.length > 0) {
      sheet
        .getRange(1, 1, rawData.length, rawData[0].length)
        .setValues(rawData);
    }

    // Run your robust layout formatting engine
    format_a_TV_Spreadsheet(ss);

    return ContentService.createTextOutput(
      JSON.stringify({
        status: "success",
        message: `Successfully updated and formatted ${target}`,
      }),
    ).setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService.createTextOutput(
      JSON.stringify({ status: "error", message: `Exception: ${err.message}` }),
    ).setMimeType(ContentService.MimeType.JSON);
  }
}

/**
 * Structure of a TV Spreadsheet
 * 1 Title  2 Seasons  3 Episodes  4 Duration   5 Description  6... Others
 */
function format_a_TV_Spreadsheet(ss) {
  const sheet = ss.getSheets()[0];
  const lastRowNum = sheet.getLastRow();
  const lastColumnNum = sheet.getLastColumn();

  // Track targeted columns safely
  let titleColumnNum = 1;
  let durationColumnNum = 4;
  let descriptionColumnNum = 5;

  // Find significant column numbers by title dynamically
  for (let columnNum = 1; columnNum <= lastColumnNum; columnNum++) {
    const columnName = sheet.getRange(1, columnNum).getValue().toString();
    if (columnName === "Title") {
      titleColumnNum = columnNum;
    }
    if (columnName === "Duration") {
      durationColumnNum = columnNum;
    }
    if (columnName === "Description") {
      descriptionColumnNum = columnNum;
    }
  }

  const totalsRow = sheet.getRange(lastRowNum, 1, 1, lastColumnNum);
  const countsRow = sheet.getRange(lastRowNum - 1, 1, 1, lastColumnNum);

  // Check for 'Totals' rows safely
  let footerRowsCount = 0;
  if (titleColumnNum && lastRowNum > 0) {
    const titleFooterValue = sheet
      .getRange(lastRowNum, titleColumnNum)
      .getValue()
      .toString();
    footerRowsCount = titleFooterValue.indexOf("Total ") !== -1 ? 2 : 0;
  }

  const dataColumnLength = lastRowNum - footerRowsCount - 1;

  Logger.log("Formatting spreadsheet: " + sheet.getName());
  Logger.log("Last row number: " + lastRowNum);
  Logger.log("Last column number: " + lastColumnNum);
  Logger.log("Title column number: " + titleColumnNum);
  Logger.log("Duration column number: " + durationColumnNum);
  Logger.log("Description column number: " + descriptionColumnNum);
  Logger.log("Totals row count: " + footerRowsCount);
  Logger.log("Data column length: " + dataColumnLength);
  Logger.log("---");

  // All columns: default to Vertical align top, Horizontal align center
  sheet
    .getDataRange()
    .clearFormat()
    .setVerticalAlignment("top")
    .setHorizontalAlignment("center");

  // Header Row: Bold
  sheet.getRange(1, 1, 1, lastColumnNum).setFontWeight("bold");

  // All columns except title column and description column: Resize, Fit to data
  for (let columnNum = 1; columnNum <= lastColumnNum; columnNum++) {
    if (columnNum !== titleColumnNum && columnNum !== descriptionColumnNum) {
      sheet.autoResizeColumn(columnNum);
    }
  }

  // Title Column: Resize to 300 pixels, Horizontal align left, wrap text
  sheet.setColumnWidth(titleColumnNum, 300);

  if (dataColumnLength > 0) {
    ss.setNamedRange(
      "Titles",
      sheet
        .getRange(2, titleColumnNum, dataColumnLength)
        .setHorizontalAlignment("left")
        .setWrap(true),
    );

    // Description Column: Resize to 500 pixels, Horizontal align left, wrap text
    sheet.setColumnWidth(descriptionColumnNum, 500);
    sheet
      .getRange(2, descriptionColumnNum, dataColumnLength)
      .setHorizontalAlignment("left")
      .setWrap(true);

    // Duration Column: Format Elapsed hours (01):Minute (01):Second (01)
    sheet
      .getRange(2, durationColumnNum, dataColumnLength)
      .setNumberFormat("[hh]:mm:ss");
  }

  // Formatting for Totals & Counts rows
  if (footerRowsCount !== 0) {
    totalsRow.setFontWeight("bold");
    totalsRow.getCell(1, titleColumnNum).setHorizontalAlignment("right");
    totalsRow.getCell(1, durationColumnNum).setNumberFormat("[hh]:mm:ss");
    totalsRow.getCell(1, descriptionColumnNum).setHorizontalAlignment("left");

    countsRow.setFontWeight("bold");
    countsRow.setBorder(true, null, null, null, null, null);
    countsRow.getCell(1, titleColumnNum).setHorizontalAlignment("right");
    countsRow.getCell(1, durationColumnNum).setNumberFormat("#####");
    countsRow.getCell(1, descriptionColumnNum).setHorizontalAlignment("left");
  }

  // Create Named Range ‘Shows’ from all data except last two rows
  if (dataColumnLength >= 0) {
    ss.setNamedRange(
      "Shows",
      sheet.getRange(1, 1, dataColumnLength + 1, lastColumnNum),
    );
  }

  // View freeze: 1 row, up to title column
  sheet.setFrozenRows(1);
  sheet.setFrozenColumns(titleColumnNum);
}
