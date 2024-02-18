# Format and print episode titles, durations, and descriptions from spreadsheets

# INVOCATION:
#    awk -v FMT=$FMT -v WIDTH=$WIDTH -f printList.awk

BEGIN {
    FS = "\t"
}

# No processing on header and other lines unrelated to shows
/=HYPERLINK/ {
    split($1,str,"\"")
    title = str[4]
    #
    duration = ""
    if ($2 && $2 !~ /^00:00/) {
        split($2,fld,":")
        if (fld[1] != "00" ) {
            sub(/^0/,"",fld[1])
            duration = fld[1] "h "
        }
        sub(/^0/,"",fld[2])
        duration = duration fld[2] "m"
    }
    #
    description = $3

    if (FMT == "yes") {
        # If output will be piped to fmt, justify title and duration on one line, indent description
        format = "%-" WIDTH -6 "s%6s\n    %s\n\n"
    } else {
        # Otherwise print title, duration, and description each on their own line, don't indent
        format = "%s\n%s\n%s\n\n"
    }

    printf(format, title, duration, description)
}
