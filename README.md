## What's Streaming Today?

**Acorn TV** is a streaming service for over 250 British television
shows.  **MHz Choice** is a streaming service for over 100 subtitled
European television detective, mystery, and crime shows.  Both are
available in the US on Apple TV, Amazon Prime, or the web.

Both https://acorn.tv/browse and https://mhzchoice.vhx.tv/series
have a visual interface which lists all their TV series. However,
you have to click on the image for each series to see its description.
I can't find any web page or document that describes all the available
series in one place.

I wrote these scripts to fetch the descriptions and other info from
their websites and create .csv spreadsheet files containing these
columns: (*Titles are hyperlinks to the series on the web*)

+ **Acorn TV:** # | Title | Seasons | Episodes | Description  
+ **MHz Choice:** # | Title | Seasons | Episodes | Duration | Genre
| Country | Language | Rating | Description

I know of no way to incorporate formatting such as column width,
horizontal centering, etc. into a .csv file. However, 
[Google Apps Script](https://developers.google.com/apps-script/overview)
enables you to automate formatting spreadsheets uploaded to [Google
Sheets](https://docs.google.com/spreadsheets/u/0/).
