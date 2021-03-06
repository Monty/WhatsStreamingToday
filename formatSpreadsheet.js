/**
 * Format Acorn TV, MHz TV, or BritBox Spreadsheets after uploading them to Google Sheets
 * @author Monty Williams
 *
 * For information on how to use this code, see:
 *   https://developers.google.com/apps-script/guides/sheets
 *
 * Change the 6 URL's below to those in your Google Sheets
 *
 */

/* Keep eslint from complaining about classes provided by Google App Script */
/* global SpreadsheetApp Logger */

// eslint-disable-next-line no-unused-vars
function format_All_TV_Spreadsheets() {
  format_Acorn_TV_Shows();
  format_Acorn_TV_ShowsEpisodes();
  format_BBox_TV_Shows();
  format_BBox_TV_ShowsEpisodes();
  format_MHz_TV_Shows();
  format_MHz_TV_ShowsEpisodes();
}

function format_Acorn_TV_Shows() {
  var ss = SpreadsheetApp.openByUrl(
    'https://docs.google.com/spreadsheets/d/abc1234567/edit'
  );
  format_a_TV_Spreadsheet(ss);
}

function format_Acorn_TV_ShowsEpisodes() {
  var ss = SpreadsheetApp.openByUrl(
    'https://docs.google.com/spreadsheets/d/abc1234567/edit'
  );
  format_a_TV_Spreadsheet(ss);
}

function format_BBox_TV_Shows() {
  var ss = SpreadsheetApp.openByUrl(
    'https://docs.google.com/spreadsheets/d/abc1234567/edit'
  );
  format_a_TV_Spreadsheet(ss);
}

function format_BBox_TV_ShowsEpisodes() {
  var ss = SpreadsheetApp.openByUrl(
    'https://docs.google.com/spreadsheets/d/abc1234567/edit'
  );
  format_a_TV_Spreadsheet(ss);
}

function format_MHz_TV_Shows() {
  var ss = SpreadsheetApp.openByUrl(
    'https://docs.google.com/spreadsheets/d/abc1234567/edit'
  );
  format_a_TV_Spreadsheet(ss);
}

function format_MHz_TV_ShowsEpisodes() {
  var ss = SpreadsheetApp.openByUrl(
    'https://docs.google.com/spreadsheets/d/abc1234567/edit'
  );
  format_a_TV_Spreadsheet(ss);
}

/**
 * Structure of an Acorn TV Spreadsheet
 *   1 #            2 Title          3 Seasons         4 Episodes     5 Duration    6 Description
 *
 * Structure of a BBox Spreadsheet
 *   1 Sortkey      2 Title          3 Seasons         4 Episodes     5 Duration    6 Year
 *   7 Rating       8 Description    9 Content_Type   10 Content_ID  11 Entity_ID  12 Genre
 *  13 Show_Type   14 Date_Type     15 Original_Date  16 Show_ID     17 Season_ID  18 Sn_#
 *  19 Ep_#        20 1st_#         21 Last_#
 *
 * Structure of an MHz TV Spreadsheet
 *   1 #            2 Title          3 Seasons         4 Episodes     5 Duration    6 Genre
 *   7 Country      8 Language       9 Rating         10 Description
 */

function format_a_TV_Spreadsheet(ss) {
  var sheet = ss.getSheets()[0];
  var lastRowNum = sheet.getLastRow();
  var lastColumnNum = sheet.getLastColumn();
  // Find significant column numbers by title
  var columnNum;
  for (columnNum = 1; columnNum <= lastColumnNum; columnNum++) {
    columnName = sheet.getRange(1, columnNum).getValue().toString();
    if (columnName == "Title") var titleColumnNum = columnNum;
    if (columnName == "Duration") var durationColumnNum = columnNum;
    if (columnName == "Description") var descriptionColumnNum = columnNum;
  }
  var totalsRow = sheet.getRange(lastRowNum, 1, 1, lastColumnNum);
  var countsRow = sheet.getRange(lastRowNum - 1, 1, 1, lastColumnNum);
  // Make column length adjustments for 'Totals' rows if they exist
  // i.e the bottom Title Row cell contains 'Total ' rather than a link
  var footerRowsCount = sheet.getRange(lastRowNum, titleColumnNum).getValue()
    .toString().match('Total ') == 'Total ' ? 2 : 0;
  var sortkeyInColumnOne = sheet.getRange(1, 1).getValue()
    .toString().match('Sortkey') == 'Sortkey' ? 1 : 0;
  var dataColumnLength = lastRowNum - footerRowsCount - 1;
  
  Logger.log('Formatting spreadsheet: ' + sheet.getName());
  Logger.log('Last row number: ' + lastRowNum);
  Logger.log('Last column number: ' + lastColumnNum);
  Logger.log('Title column number: ' + titleColumnNum);
  Logger.log('Duration column number: ' + durationColumnNum);
  Logger.log('Description column number: ' + descriptionColumnNum);
  Logger.log('Totals row count: ' + footerRowsCount);
  Logger.log('Data column length: ' + dataColumnLength);
  Logger.log('---');

  // All columns: default to Vertical align top, Horizontal align center
  sheet.getDataRange().clearFormat()
    .setVerticalAlignment('top').setHorizontalAlignment('center');

  // Header Row: Bold
  sheet.getRange(1, 1, 1, lastColumnNum).setFontWeight('bold');

  // All columns except title column and description column: Resize, Fit to data
  for (columnNum = 1; columnNum < lastColumnNum; columnNum++) {
    if (columnNum != titleColumnNum && columnNum != descriptionColumnNum) {
      sheet.autoResizeColumn(columnNum);
    }
  }

  // Title Column: Resize to 300 pixels, Horizontal align left, wrap text
  sheet.setColumnWidth(titleColumnNum, 300);
  // Note: The Title column may appear unwrapped, even though every cell has its
  // wrap attribute set to true. Clicking on wrap in the GUI shows it correctly.
  // Create a Named Range to make that easier
  ss.setNamedRange('Titles', sheet.getRange(2, titleColumnNum, dataColumnLength)
    .setHorizontalAlignment('left').setWrap(true));

  // Description Column: Resize to 500 pixels, Horizontal align left, wrap text
  sheet.setColumnWidth(descriptionColumnNum, 500);
  sheet.getRange(2, descriptionColumnNum, dataColumnLength)
    .setHorizontalAlignment('left').setWrap(true);

  // Duration Column: Format Elapsed hours (01):Minute (01):Second (01)
  sheet.getRange(2, durationColumnNum, dataColumnLength)
    .setNumberFormat('[hh]:mm:ss');

  // Hide Sortkey column
  if (sortkeyInColumnOne != 0) {
    sheet.hideColumns(1);
  }

  // Formatting for Totals & Counts rows
  if (footerRowsCount != 0) {
    totalsRow.setFontWeight('bold');
    totalsRow.getCell(1, titleColumnNum).setHorizontalAlignment('right');
    totalsRow.getCell(1, durationColumnNum).setNumberFormat('[hh]:mm:ss');
    totalsRow.getCell(1, descriptionColumnNum).setHorizontalAlignment('left');
    //
    countsRow.setFontWeight('bold');
    countsRow.setBorder(true, null, null, null, null, null);
    countsRow.getCell(1, titleColumnNum).setHorizontalAlignment('right');
    countsRow.getCell(1, durationColumnNum).setNumberFormat('#####');
    countsRow.getCell(1, descriptionColumnNum).setHorizontalAlignment('left');
  }

  // Create Named Range ‘Shows’ from all data except last two rows
  ss.setNamedRange('Shows', sheet.getRange(1, 1, dataColumnLength + 1,
    lastColumnNum));

  // View freeze: 1 row, up to title column
  sheet.setFrozenRows(1);
  sheet.setFrozenColumns(titleColumnNum);
}
