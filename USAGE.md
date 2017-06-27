#### To create a .csv spreadsheet of available streaming TV series:

Run **makeAcornSpreadsheet.sh [-cdtu]** or **makeMHzSpreadsheet.sh [-dtu]**  
&nbsp;&nbsp;&nbsp;&nbsp; 
**-c**
&nbsp;&nbsp;&nbsp;&nbsp;
_Canadian_ - Don't delete the text "Not available in Canada." in Acorn TV  
&nbsp;&nbsp;&nbsp;&nbsp;
**-d**
&nbsp;&nbsp;&nbsp;&nbsp;
_Debug_ - Create a diffs file that details what changed in each column.  
&nbsp;&nbsp;&nbsp;&nbsp;
**-t**
&nbsp;&nbsp;&nbsp;&nbsp;
_Totals_ - Add column totals and row counts at the end of the spreadsheet.  
&nbsp;&nbsp;&nbsp;&nbsp;
**-u**
&nbsp;&nbsp;&nbsp;&nbsp;
_Unsorted_ - Leave shows in the order they are found on the web.

Each script creates a number of .csv files. To see the complete list,
look at **saveTodaysAcornFiles.sh** or **saveTodaysMHzFiles.sh**.

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

Shows in the spreadsheet are sorted by title. You can sort them in
the order they are found on the web by using the **-u** switch or
sorting on the first column.  If you want to sort by a different
column **_and_** you used the **-t** switch to add column totals
and row counts you should either create a Named Range to sort on
or delete the added rows.  Otherwise those rows will wind up in the
middle of your spreadsheet.

#### To see what has changed since a previous run:

Run **whatChanged.sh [-bs] oldSpreadsheet.csv newSpreadsheet.csv**  
&nbsp;&nbsp;&nbsp;&nbsp;
**-b**
&nbsp;&nbsp;&nbsp;&nbsp;
_Brief_ - Don't output the diffs, just list what was done, e.g.
```
    ### 2 insertions, 1 deletion, 1 modification
    deleted 1 show at line 35
    added 2 shows after line 98
    changed 1 show at line 101
```
&nbsp;&nbsp;&nbsp;&nbsp;
**-s**
&nbsp;&nbsp;&nbsp;&nbsp;
_Summary_ - Only output the diffstat summary line, e.g
```
    ### 10 insertions, 10 deletions, 6 modifications
```

This script creates a human readable diff of any two "TV spreadsheets"
from the same streaming service.  The descriptions in the spreadsheet
are quite long, so you may want to redirect the full output into a
.csv file and open it as a spreadsheet for easier viewing.

If you are happy with the diffs, you can create a new baseline from
today's results by running **saveTodaysAcornFiles.sh** or
**saveTodaysMHzFiles.sh**. To save results from a different date
use **-d DATE**.

If the diff file is large or complex, it could be due to a bug in
the script, or an unforeseen change in the format of the website.

#### To help debug any problems:

Run one of the primary scripts with the **-d** [_debug]_ option. This
provides diffs of each column individually, which is more useful
for debugging than diffs of the whole spreadsheet.

Then examine the diff file called **Acorn_diffs-[LONGDATE].txt** or
**MHz_diffs-[LONGDATE].txt**, where **[LONGDATE]** is the date/time
the script was run in the format yymmdd.HHMMSS, e.g. 170609.161113.

#### To remove any files created by running scripts:

Run **cleanupEverything.sh [-i | -v]**

If you add either **-v** or **-i** as an option, it will be passed along
to the rm command.

You will be given a choice whether to delete the primary spreadsheet
files, secondary spreadsheet files, diff results, and diff baselines.
Answer y to delete them, anything else to skip. Deleting them cannot
be undone! To see exacly what will be deleted, look at the script.
