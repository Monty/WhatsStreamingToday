### IMDb Spreadsheets

Simplify finding information from IMDb about shows, actors, and the characters
they portray.

**makeIMDbFromFiles.sh** is a self-contained script that builds these
spreadsheets from downloaded IMDb datasets. It's a legacy extra -- it still
works, but it only knows about the shows listed in the **\*.tconst** files,
which are maintained by hand. A more comprehensive IMDb cross-referencing
toolkit is maintained as a separate project.

**IMDb_Credits-Person-[DATE].csv** lists primary cast members, show titles, and
characters portrayed for all shows for which we have IMDb information — sorted
by cast member name.

Useful to see all shows a person is in, and what characters they portrayed in
each, *e.g.* Alexandra Rapaport has top billing in both "The Sandhamn Murders"
and "Gåsmamman".

“Person” and “Primary Title” are both clickable links to IMDb pages.

**IMDb_Credits-Show-[DATE].csv** also lists primary cast members, show titles, and
characters portrayed, but sorted by primary title.

Useful to see who stars in a show, and what character they portrayed.

“Person” and “Primary Title” are both clickable links to IMDb pages. There may
be up to 10 primary cast members for each show title, sorted by IMDb’s billing
rank.

**IMDb_Shows-[DATE].csv** lists all the shows for which we have IMDb information.

Useful as a short list of what shows are (*and aren't*) included.

The "Primary Title" is what the show is called by the provider. It's also a
clickable link to that show's page on IMDb, since that title may not work as a
search term on IMDb.

"Show Types" that aren't a series complicate matters as each episode has a
separate IMDb page with no parent series - *e.g.* “Bukow and König” and “Murder
In…”.

**IMDb_Persons-Titles-[DATE].csv** lists the top titles a person is known for.

Useful to find other shows by persons credited in other spreadsheets.

**IMDb_suggestedEpisodes-[DATE].csv** lists the episodes IMDb has for each
series, *except* those in series listed in **skipEpisodes.TCONST** (series with
hundreds of episodes, or with episode titles like "Episode 1").

**IMDb_associatedTitles-[DATE].csv** lists every title that appears in the
"Known For" columns of **IMDb_Persons-Titles**, with links to IMDb.

**Note:** **\*-noHype-\*** spreadsheets, made by **makeIMDbFromFiles-noHype.sh**,
have the same data, but without hyperlinks, which is more readable in text
searches.

### Choosing which shows to include

Each **\*.tconst** file lists IMDb title identifiers, one per line. Only the
first column is used; the rest are comments. By default every **\*.tconst**
file is processed, or you can name files on the command line, *e.g.*
`./makeIMDbFromFiles.sh MyShows.tconst`. See the comments at the top of any
**.tconst** file for details.

Each **\*.xlate** file contains tab separated pairs of non-English titles and
their English equivalents. By default every **\*.xlate** file is used, or pick
one with `-t file`.

After checking the results, run **saveTodaysIMDbFiles.sh** (or
**saveTodaysIMDbFiles-noHype.sh**) to make them the baseline for future diffs.

**Note:** Spreadsheets are generated from these downloaded IMDb datasets:

		* name.basics.tsv.gz
		* title.basics.tsv.gz
		* title.episode.tsv.gz
		* title.principals.tsv.gz

If they aren't present, the script downloads them. Run **downloadFromIMDb.sh**
to refresh them. See
[https://www.imdb.com/interfaces/](https://www.imdb.com/interfaces/)
for a description of these IMDb Datasets.
