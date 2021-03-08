# Generate MHz_TV_Shows_minutes.csv by processing  SHORT_SPREADSHEET to figure
# average episode length
#

BEGIN {
    FS = "\t"
}

/^Title/ {
    printf ("%s\t%s\t%s\t%s\tAvg Len\t%s\t%s\t%s\t%s\t%s\n",
            $1,$2,$3,$4,$5,$6,$7,$8,$9)
}

/=HYPERLINK/ {
    dur=$4
    sub (/h/,"",dur)
    sub (/m/,"",dur)
    split (dur,fld," ")
    eplen = (fld[1]*60+fld[2])/$3
    printf ("%s\t%s\t%s\t%s\t%d\t%s\t%s\t%s\t%s\t%s\n",
            $1,$2,$3,$4,eplen,$5,$6,$7,$8,$9)
}
