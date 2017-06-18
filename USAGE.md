#### To create a .csv spreadsheet of available streaming TV series:

Run **makeAcornSpreadsheet.sh [-c]** or **makeMHzSpreadsheet.sh**  
(_-c turns off deletion of_ "Not available in Canada." _in Acorn TV
descriptions._)

Each will create a number of .csv files. To see the complete list,
look at **saveLatestAcornFiles.sh** or **saveLatestMHzFiles.sh**.

The primary spreadsheet file is called **Acorn_TV_Shows-[DATE].csv**
or **MHz_TV_Shows-[DATE].csv**, where **[DATE]** is today’s date
in the format yymmdd, e.g. 170610. It can be loaded into Open Office
or Google Sheets for further formatting. Any secondary .csv files
are tucked away in the directories **Acorn-columns** or **MHz-columns**.

Running the script again will overwrite any .csv files from earlier
that day but not from any previous day.

You don't need to keep any .csv files around after loading the
spreadsheet into an application for formatting. Formatted spreadsheets
should get saved as .xls or .ods files. Spreadsheets uploaded to
Google Sheets won't depend on the local file being around.

Shows in the spreadsheet are in the order they are found on the
web. If you want to sort by Title, Language, Rating, etc. you should
either create a Named Range to sort on or delete the "Totals" row
at the end. Otherwise the "Totals" row will wind up in the middle
of your spreadsheet. You can always get back to the original order
by sorting on the first column.

#### To see what has changed since a previous run:

Examine the diff file called **Acorn_diffs-[LONGDATE].txt** or
**MHz_diffs-[LONGDATE].txt**, where **[LONGDATE]** is the date/time
the script was run in the format yymmdd.HHMMSS, e.g. 170609.161113.

If you are happy with the diffs, you can create a new baseline by
running **saveLatestAcornFiles.sh** or **saveLatestMHzFiles.sh**.

If the diff file is large or complex, it could be due to a bug in
the script, or an unforeseen change in the format of the website.

#### To remove any files created by running scripts:

Run **cleanupEverything.sh [-i | -v]**

If you add either -v or -i as an option, it will be passed along
to the rm command.

You will be given a choice whether to delete the primary spreadsheet
files, secondary spreadsheet files, diff results, and diff baselines.
Answer y to delete them, anything else to skip. Deleting them cannot
be undone! To see exacly what will be deleted, look at the script.
