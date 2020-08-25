# Format and print episode information from spreadsheets

BEGIN {
    FS = "\t"
}

# No processing on header and other lines unrelated to shows
/=HYPERLINK/ {
    split ($1,str,"\"")
    description = str[4] "\n"
    #
    if ($2 && $2 !~ /^00:00/) {
        split ($2,fld,":")
        if (fld[1] != "00" ) {
            sub (/^0/,"",fld[1])
            description = description fld[1] "h "
        }
        sub (/^0/,"",fld[2])
        description = description fld[2] "m\n"
    }
    description = description $3 "\n"
    print description
}
