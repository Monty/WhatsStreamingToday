[![MIT License](https://img.shields.io/github/license/Monty/WhatsStreamingToday)](LICENSE)
[![Commits](https://badgen.net/github/commits/Monty/WhatsStreamingToday/master/)](https://github.com/Monty/WhatsStreamingToday)
[![Last Commit](https://img.shields.io/github/last-commit/Monty/WhatsStreamingToday)](https://github.com/Monty/WhatsStreamingToday)

## What's Streaming Today?

**Acorn TV** and **BritBox** are streaming services that offer hundreds of
British, Australian, New Zealand, and other television shows.
**PBS** offers over 150 streaming shows, including many subtitled European
series from **Walter Presents**.
**MHz Choice** offers over 250 subtitled European detective, mystery,
and crime series. All are available in the US on a variety of streaming platforms
and through their websites.

**[Acorn TV](https://acorn.tv/)**,
**[BritBox](https://www.britbox.com/us)**,
**[PBS](https://www.pbs.org/franchise/walter-presents)**, and
**[MHz Choice](https://watch.mhzchoice.com/)**
provide visual interfaces that list all their shows. However,
you have to click on each series to see its description.
I haven't found any web page or document that describes
all the available series in one place.

I wrote these scripts to fetch the descriptions and other info
from their websites and generate tab-separated CSV files containing the
following columns (_titles become hyperlinks to the series when opened in a spreadsheet_)

| Service           | CSV columns                                                                                        |
| ----------------- | -------------------------------------------------------------------------------------------------- |
| **Acorn TV**      | Title \| Seasons \| Episodes \| Duration \| Description                                            |
| **BritBox**       | Title \| Seasons \| Episodes \| Duration \| Genre \| Year \| Rating \| Description \| Content_Type |
| **PBS (via OPB)** | Title \| Seasons \| Episodes \| Duration \| Genre \| Language \| Rating \| Description             |
| **MHz Choice**    | Title \| Seasons \| Episodes \| Duration \| Genre \| Country \| Language \| Rating \| Description  |

The scripts also generate a separate CSV file for each service that lists
every episode. The BritBox and MHz Choice scripts additionally generate
files listing cast members, the characters they portray, and crew members.

CSV files do not support formatting such as column widths or cell
alignment. However,
[Google Apps Script](https://developers.google.com/apps-script/overview)
enables you to automate importing and formatting the data in
[Google Sheets](https://docs.google.com/spreadsheets/u/0/).

A legacy script generates cast and character CSV files for shows you specify,
using datasets downloaded from IMDb.
See [README_IMDb.md](README_IMDb.md).

The scripts run on **macOS** only.
See [USAGE.md](USAGE.md) for requirements and instructions.
