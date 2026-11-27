[![MIT License](https://img.shields.io/github/license/Monty/WhatsStreamingToday)](LICENSE)
[![Commits](https://badgen.net/github/commits/Monty/WhatsStreamingToday/master/)](https://github.com/Monty/WhatsStreamingToday)
[![Last Commit](https://img.shields.io/github/last-commit/Monty/WhatsStreamingToday)](https://github.com/Monty/WhatsStreamingToday)

## What's Streaming Today?

**Acorn TV** and **BritBox** are streaming services carrying hundreds of
British, Australian, New Zealand, and other television shows.
**PBS** has over 150 streaming shows, including many subtitled European
shows from **Walter Presents**.
**MHz Choice** is a streaming service for over 250 subtitled
European television detective, mystery, and crime shows. All are
available in the US on Apple TV, Amazon Prime, Xfinity, the web, and
[many others](https://support.mhznetworks.com/support/solutions/folders/44001123070).

**[Acorn](https://acorn.tv/browse)**,
**[BritBox](https://www.britbox.com/us/programmes)**,
**[PBS](https://www.pbs.org/franchise/walter-presents/)**, and
**[MHz](https://watch.mhzchoice.com/browse)** all
have visual interfaces which list all their shows. However,
you have to click on the image for each series to see its description.
I can't find any web page or document that describes all the available
series in one place.

I wrote these scripts to fetch the descriptions and other info from
their websites and APIs and create .csv spreadsheet files containing
these columns: (*Titles are hyperlinks to the series on the web*)

+ **Acorn TV:** Title | Seasons | Episodes | Duration | Description
+ **BritBox:** Title | Seasons | Episodes | Duration | Genre | Year | Rating | Description | Content_Type
+ **PBS (via OPB):** Title | Seasons | Episodes | Duration | Genre | Language | Rating | Description
+ **MHz:** Title | Seasons | Episodes | Duration | Genre | Country | Language | Rating | Description

Each service also gets a spreadsheet listing every episode. BritBox and MHz
also produce spreadsheets of cast and crew with the characters they play.

I know of no way to incorporate formatting such as column width,
horizontal centering, etc. into a .csv file. However,
[Google Apps Script](https://developers.google.com/apps-script/overview)
enables you to automate uploading and formatting spreadsheets in [Google
Sheets](https://docs.google.com/spreadsheets/u/0/).

A legacy script also builds spreadsheets of cast members, characters
portrayed, and alternate titles from downloaded **IMDb** datasets. See
[README_IMDb.md](README_IMDb.md).

The scripts run on **macOS** only. See [USAGE.md](USAGE.md) for requirements
and how to run them.
