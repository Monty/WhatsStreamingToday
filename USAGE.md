#### To create a .csv spreadsheet of available streaming TV series:

Run **makeAcornSpreadsheet.sh [-dst]**, **makeBBoxFromSitemap.sh [-dst]**, or **makeMHzSpreadsheet.sh [-dst]**  
&nbsp;&nbsp;&nbsp;&nbsp; 
**-d**
&nbsp;&nbsp;&nbsp;&nbsp;
_Debug_ - Create a diffs file that details what changed in each column.  
&nbsp;&nbsp;&nbsp;&nbsp;
**-s**
&nbsp;&nbsp;&nbsp;&nbsp;
_Summary_ - Delete all new files except for error reports and diffs.  
&nbsp;&nbsp;&nbsp;&nbsp;
**-t**
&nbsp;&nbsp;&nbsp;&nbsp;
_Totals_ - Add column totals and row counts at the end of the spreadsheet.  

Each script creates a number of other files. To see the complete list,
look at **saveTodaysAcornFiles.sh**, **saveTodaysBBoxFiles.sh** or
**saveTodaysMHzFiles.sh**.

The primary spreadsheet file is called **Acorn\_TV\_Shows-[DATE].csv**,
**BBox\_TV\_Shows-[DATE].csv**, or **MHz\_TV\_Shows-[DATE].csv** -- the
spreadsheet with all episodes is called
**Acorn\_TV\_ShowsEpisodes-[DATE].csv**,
**BBOX\_TV\_ShowsEpisodes-[DATE].csv**, or
**MHz\_TV\_ShowsEpisodes-[DATE].csv**. **[DATE]** is today’s date in the
format yymmdd, e.g. 170810.  These spreadsheets can be loaded into Open Office
or Google Sheets for further formatting. Any secondary .csv files are tucked
away in the directories **Acorn-columns**, **BBox-columns**, or
**MHz-columns**.

Running the script again will overwrite any .csv files from earlier
that day but not from any previous day.

You don't need to keep any .csv files around after loading the
spreadsheet into an application for formatting. Formatted spreadsheets
should get saved as .xls or .ods files. Spreadsheets uploaded to
Google Sheets won't depend on the local file being around.

#### To format the spreadsheets:

Manual formatting is tedious, but you can automate it. Upload your
spreadheets to [Google Sheets](https://docs.google.com/spreadsheets/u/0/),
modify **formatSpreadsheet.js** to include URLs for your spreadsheets,
paste it into a [Google Apps Script](https://script.google.com) and
run it.  *You'll have to authorize it the first time it's run*. If
you ever create new spreadsheets, you can copy and paste the .csv
files into your existing [Google
Sheets](https://docs.google.com/spreadsheets/u/0/) so the URLs don't
change. Then rerun the formatting script.

#### To see what has changed since a previous run:

Run **whatChanged.sh [-bs] oldSpreadsheet.csv newSpreadsheet.csv**  
&nbsp;&nbsp;&nbsp;&nbsp;
**-b**
&nbsp;&nbsp;&nbsp;&nbsp;
_Brief_ - Don't output the diffs, just list what was done, e.g.
```
    ==> 2 insertions, 1 deletion, 1 modification
        deleted 1 show at line 35
        added 2 shows after line 98
        changed 1 show at line 101
```
&nbsp;&nbsp;&nbsp;&nbsp;
**-s**
&nbsp;&nbsp;&nbsp;&nbsp;
_Summary_ - Only output the diffstat summary line, e.g
```
    ==> 10 insertions, 10 deletions, 6 modifications
```

This script creates a human readable diff of any two "TV spreadsheets"
from the same streaming service. The descriptions in the spreadsheet
are quite long, so you may want to redirect the full output into a
.csv file and open it as a spreadsheet for easier viewing.

If you are happy with the diffs, you can create a new baseline from
today's results by running **saveTodaysAcornFiles.sh [-v]**,
**saveTodaysBBoxFiles.sh [-v]**,  or
**saveTodaysMHzFiles.sh [-v]** where **-v** is the "verbose" option
to be passed through to the **cp** command. To save results from a
different date use **-d DATE** with a date in the format yymmdd.

If the diff file is large or complex, it could be due to a bug in
the script, or an unforeseen change in the format of the website.

#### To help debug any problems:

Run one of the primary scripts with the **-d** [_debug]_ option. This
provides diffs of each column individually, which is more useful
for debugging than diffs of the whole spreadsheet.

Then examine the diff file called **Acorn_diffs-[LONGDATE].txt**,
**BBox_diffs-[LONGDATE].txt**,  or
**MHz_diffs-[LONGDATE].txt**, where **[LONGDATE]** is the date/time
the script was run in the format yymmdd.HHMMSS, e.g. 170609.161113.

Occasionally the Acorn TV website has missing or incomplete data
such as missing descriptions, missing durations, etc. Some are
intentional, but if there are a large number, something is probably
broken. Usually it's Acorn TV's problem. Cross check the file called 
**Acorn_anomalies-[LONGDATE].txt** against what you see in your browser.

#### To remove any files created by running scripts:

Run **cleanupEverything.sh [-i | -v]**

If you add either **-v** or **-i** as an option, it will be passed
through to the **rm** command.

You will be given a choice whether to delete the primary spreadsheet
files, secondary spreadsheet files, Acorn anomalies reports, diff
results, and diff baselines. Answer y to delete them, anything
else to skip. Deleting them cannot be undone! To see exacly what
will be deleted, look at the script.

#### To run the scripts on a schedule using MacOS launchd:

Modify **com.example.makeTVspreadsheets.plist** as detailed in it's
comments. Copy it to **~/Library/LaunchAgents/**. Log out then log
back in. See **man launchd.plist** for further information. 
