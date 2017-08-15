// Format an Acorn TV or MHz TV Spreadsheet that has been uploaded to Google Sheets
//
// Structure of an Acorn TV Spreadsheet
// #  Title      Seasons     Episodes    Duration    Description
// A  B          C           D           E           F
// 1  2          3           4           5           6

// Structure of an MHz TV Spreadsheet
// #    Title    Seasons     Episodes    Duration    Genre   Country   Language    Rating   Description
// A    B        C           D           E           F       G         H           I        J
// 1    2        3           4           5           6       7         8           9        10

function formatTVsheet() {
  // For imformation on how to use this code, see:
  //   https://developers.google.com/apps-script/guides/sheets
  //
  // Use this var ss instead of the next to use a single copy to format any spreadsheet
  // Upside: You only have to authorize the code once
  // Downside: Before running, you'll have to modify the URL below to reflect the spreadsheet
  // you want to format
  var ss = SpreadsheetApp.openByUrl(
    'https://docs.google.com/spreadsheets/d/abc1234567/edit');
  // Use this var ss instead of the previous if you prefer to bind the code to each spreadsheet
  // Upside: you don't have to modify the code for each spreadsheet
  // Downside: you have to go through the tedious authorization process for each spreadsheet
  // var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheets()[0];
  var lastRowNum = sheet.getLastRow();
  var lastColumnNum = sheet.getLastColumn();
  var titleColumnNum = 2;
  var durationColumnNum = 5;
  var descriptionColumnNum = lastColumnNum;
  Logger.log('Formatting spreadsheet: ' +sheet.getName());
  Logger.log('Last row number: ' + lastRowNum);

  // Make column length adjustments for 'Totals' rows if they exist
  var totalsTitle = sheet.getRange(lastRowNum, titleColumnNum);
  var totalsTitleValue = totalsTitle.getValue()
  Logger.log('Total title value: ' + totalsTitleValue);
  var totalsRowCount = 0;
  if (totalsTitleValue.toString().match('Total ') == 'Total ') {
    totalsRowCount = 2;
  }
  Logger.log('Totals row count: ' + totalsRowCount);
  var dataColumnLength = lastRowNum - totalsRowCount - 1;
  Logger.log('Data column length: ' + dataColumnLength);

  // All columns: Vertical align top, Horizontal align center as default to save code
  sheet.getDataRange().setVerticalAlignment("top").setHorizontalAlignment("center");

  // Title column and description column: Horizontal align left, wrap text
  sheet.getRange(2, titleColumnNum, dataColumnLength).setHorizontalAlignment("left").setWrap(true);
  sheet.getRange(2, descriptionColumnNum, dataColumnLength).setHorizontalAlignment("left").setWrap(true);

  // Duration Column: Format Elapsed hours (01):Minute (01):Second (01)
  sheet.getRange(2, durationColumnNum, dataColumnLength).setNumberFormat("[hh]:mm:ss");

  // Create Named Range ‘Shows’ from all data except last two rows
  ss.setNamedRange("Shows", sheet.getRange(1, 1, dataColumnLength + 1, lastColumnNum));

  // Row 1: Bold
  sheet.getRange(1, 1, 1, lastColumnNum).setFontWeight("bold");

  // Define Ranges
  if (totalsTitleValue.toString().match('Total ') == 'Total ') {
    var totalsRow = sheet.getRange(lastRowNum, 1, 1, lastColumnNum);
    var totalsDuration = totalsRow.getCell(1, durationColumnNum);
    var totalsDescription = totalsRow.getCell(1, descriptionColumnNum);
    var countsRow = sheet.getRange(lastRowNum - 1, 1, 1, lastColumnNum);
    var countsTitle = countsRow.getCell(1, titleColumnNum);
    var countsDuration = countsRow.getCell(1, durationColumnNum);
    var countsDescription = countsRow.getCell(1, descriptionColumnNum);
  }

  // All columns except title column and description column: Resize, Fit to data
  for (var i = 1; i < lastColumnNum; i++) {
    if ((i != titleColumnNum) && (i != descriptionColumnNum)) {
        sheet.autoResizeColumn(i);
    }
  }

  // Title Column: Resize to 300 pixels
  sheet.setColumnWidth(titleColumnNum, 300);

  // Description Column: Resize to 500 pixels
  sheet.setColumnWidth(descriptionColumnNum, 500);

  // View freeze: 1 row, up to title column
  sheet.setFrozenRows(1);
  sheet.setFrozenColumns(titleColumnNum);

  if (totalsTitleValue.toString().match('Total ') == 'Total ') {
    // Borders on counts row: Top
    countsRow.setBorder(true, null, null, null, null, null);
    // Counts and totals rows: bold
    countsRow.setFontWeight("bold");
    totalsRow.setFontWeight("bold");
    // Alignments for specific cells
    countsRow.setHorizontalAlignment("center");
    countsTitle.setHorizontalAlignment("right");
    countsDescription.setHorizontalAlignment("left");
    totalsRow.setHorizontalAlignment("center");
    totalsTitle.setHorizontalAlignment("right");
    totalsDescription.setHorizontalAlignment("left");
    // Format duration cell in counts row: Automatic
    countsDuration.setNumberFormat("#####")
    // Format duration cell in totals row: Elapsed hours (01):Minute (01):Second (01)
    totalsDuration.setNumberFormat("[hh]:mm:ss")
  }
}
