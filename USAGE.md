#### Requirements

The scripts run on **macOS** only. They need **curl**, **perl**, **awk**,
**python3** (standard library only), **node**, and
[ripgrep](https://crates.io/crates/ripgrep) (**rg**).
**timeAllScripts.sh** also needs [sd](https://crates.io/crates/sd) and
[zet](https://crates.io/crates/zet).

**required_files.txt** lists the files each top-level script needs. Source it
to get `$ACORN_FILES`, `$BBOX_FILES`, `$MHZ_FILES`, and `$OPB_FILES`.

#### To create CSV files of available streaming TV series:

| Service       | Script                         | Save baseline               |
| ------------- | ------------------------------ | --------------------------- |
| Acorn TV      | **makeAcornFromBrowsePage.sh** | **saveTodaysAcornFiles.sh** |
| BritBox       | **makeBBoxFromSitemap.sh**     | **saveTodaysBBoxFiles.sh**  |
| MHz Choice    | **makeMHzFromSitemap.sh**      | **saveTodaysMHzFiles.sh**   |
| PBS (via OPB) | **makeOPB.sh**                 | **saveTodaysOPBFiles.sh**   |

All four scripts accept these options:

| Option | Meaning                                                                  |
| ------ | ------------------------------------------------------------------------ |
| **-d** | _Debug_ - Create a diffs file that details what changed in each column.  |
| **-s** | _Summary_ - Delete all new files except for anomalies reports and diffs. |
| **-t** | _Totals_ - Add column totals and row counts at the end of the CSV file.  |

Some scripts have extra options:

| Script                     | Option   | Meaning                                                                      |
| -------------------------- | -------- | ---------------------------------------------------------------------------- |
| **makeBBoxFromSitemap.sh** | **-H**   | Scrape the HTML pages instead of using the BritBox API.                      |
| **makeMHzFromSitemap.sh**  | **-q**   | _Quick_ - Stop after the show and episode CSV files; skip credits and diffs. |
| **makeOPB.sh**             | **-m N** | Retry failed fetches up to N times (default 5).                              |
| **makeOPB.sh**             | **-r N** | Multiply the wait between retries by N (default 3).                          |

With **-d**, the BritBox CSV files also include the internal columns
(Content_ID, Item_Type, Show_ID, Season_ID, etc.) that are normally hidden.

To run all four, fastest first so early results are available quickly, run
**timeAllScripts.sh**. It runs each script with **-td** and times it.

#### Output files

[DATE] is today's date in the format yymmdd, e.g. 261126. [LONGDATE] adds the
time, e.g. 261126.161113.

The .csv files are tab-separated. Titles are `=HYPERLINK()` formulas, so they
become links when the file is opened in a spreadsheet app.

| File                                                                                           | Contents                                        |
| ---------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| **[SVC]\_TV\_Shows-[DATE].csv**                                                                | The primary CSV file, one row per show          |
| **[SVC]\_TV\_ShowsEpisodes-[DATE].csv**                                                        | Every show followed by its episodes             |
| **[SVC]\_uniqTitles-[DATE].txt**                                                               | Plain list of show titles                       |
| **[SVC]\_anomalies-[LONGDATE].txt**                                                            | Missing or odd data worth checking              |
| **[SVC]\_diffs-[LONGDATE].txt**                                                                | Changes since the baseline                      |
| **BBox\_TV\_Credits-[DATE].csv**, **MHz\_TV\_Credits-[DATE].csv**                              | Cast and crew with characters portrayed         |
| **BBox\_uniqPersons**, **BBox\_uniqCharacters**, **MHz\_uniqPersons**, **MHz\_uniqCharacters** | Plain lists of people and characters            |
| **MHz\_TV\_Shows\_Avg-[DATE].csv**                                                             | Shows CSV file with average episode durations   |
| **OPB\_TV\_ExtraEpisodes-[DATE].csv**                                                          | Episodes plus clips, previews, and other extras |

[SVC] is **Acorn**, **BBox**, **MHz**, or **OPB**. Working files are tucked
away in **Acorn-columns**, **BBox-columns**, **MHz-columns**, and
**OPB-columns**. To see the complete list of files a script keeps, look at its
**saveTodays\*Files.sh** script.

Running a script again will overwrite any .csv files from earlier that day but
not from any previous day.

#### To see what has changed since a previous run:

Run **checkDiffs.sh** after a run. It diffs the two most recent anomalies files,
shows the latest diffs from each service, and offers to save today's files as
the new baseline.

Run **newTitles.sh** to see shows added or removed, **newEpisodes.sh** to see new
episodes, and **removedEpisodes.sh** to see episodes that are gone. **-b N**
compares against the Nth most recent run instead of the previous one (the
default is 2). **newTitles.sh** and **newEpisodes.sh** also include Apple TV+
if you create **Apple\_\*** files manually -- they can't be generated
automatically.

Run **listEpisodes.sh [-f] [-w width] search-string** to print episode titles,
durations, and descriptions from the latest CSV files, _e.g._
`./listEpisodes.sh Wallander, S03`. **-f** formats descriptions with **fmt**,
**-w** changes the wrap column from the default 80.

To compare any two CSV files from the same service, run
**whatChanged [-bs] oldFile.csv newFile.csv**

| Option | Meaning                                                    |
| ------ | ---------------------------------------------------------- |
| **-b** | _Brief_ - Don't output the diffs, just list what was done. |
| **-s** | _Summary_ - Only output the diffstat summary line.         |

```
    ==> 2 insertions, 1 deletion, 1 modification
        deleted 1 show at line 35
        added 2 shows after line 98
        changed 1 show at line 101
```

The descriptions in the CSV files are quite long, so you may want to
redirect the full output into a .csv file and open it as a spreadsheet for
easier viewing.

If you are happy with the diffs, make today's results the new baseline by
running the matching **saveTodays\*Files.sh [-v]**, where **-v** is passed
through to **cp**. To save results from a different date use **-d DATE** with
a date in the format yymmdd.

If the diff file is large or complex, it could be due to a bug in the script,
or an unforeseen change in the format of the website.

#### To help debug any problems:

Run one of the primary scripts with the **-d** option. This provides diffs of
each column individually, which is more useful for debugging than diffs of the
whole file. Then examine **[SVC]\_diffs-[LONGDATE].txt**.

Occasionally a service's website has missing or incomplete data such as missing
descriptions, missing durations, etc. Some are intentional, but if there are a
large number, something is probably broken. Usually it's the service's problem.
Cross check **[SVC]\_anomalies-[LONGDATE].txt** against what you see in your
browser.

#### To upload and format the CSV files in Google Sheets:

Manual formatting is tedious, but you can automate it with
**formatSpreadsheet.js** and **upload\_latest\_tv\_sheets.zsh**.

1. Upload each .csv file to [Google Sheets](https://docs.google.com/spreadsheets/u/0/) once.
2. Paste **formatSpreadsheet.js** into a [Google Apps Script](https://script.google.com)
   project and change the URLs in `SHEET_MAP` to those of your sheets.
   _You'll have to authorize it the first time it's run_.
3. Deploy the script as a web app.
4. Put the web app URL in **~/.tokens** as `export TV_SHEETS_API_URL="..."`.
   Keep it private -- anyone with that URL may be able to overwrite your sheets.
5. From then on, run **upload\_latest\_tv\_sheets.zsh**. It uploads the latest
   shows and episodes CSV files for every service, replaces the contents of
   the matching sheets, and reformats them. The sheet URLs don't change.

To reformat without uploading, run `format_All_TV_Spreadsheets` from the Apps
Script editor.

#### To get cast information from IMDb:

See [README_IMDb.md](README_IMDb.md).

#### To remove any files created by running scripts:

Run **cleanupEverything.sh [-i | -v]**

If you add either **-v** or **-i** as an option, it will be passed
through to the **rm** command.

You will be given a choice whether to delete the primary CSV
files, secondary CSV files, anomalies reports, diff
results, and diff baselines. Answer y to delete them, anything
else to skip. Deleting them cannot be undone! To see exactly what
will be deleted, look at the script.

#### To run the scripts on a schedule using macOS launchd:

**com.example.makeTVspreadsheets.plist** runs **timeAllScripts.sh** weekly.
Copy it to **~/Library/LaunchAgents/**, optionally replacing "example" with
your name, then edit the copy as detailed in its comments, so your paths
stay out of the repository. Log out and back in (or use `launchctl bootstrap`)
to load it. Be sure to set its PATH -- launchd starts jobs with
only `/usr/bin:/bin:/usr/sbin:/sbin`, so a script that works from Terminal can
fail on schedule. To test the job without waiting, run
`launchctl kickstart -k gui/$(id -u)/com.example.makeTVspreadsheets`,
replacing "example" if you renamed it.
See **man launchd.plist** for further information.
