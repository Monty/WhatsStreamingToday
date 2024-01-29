#!/usr/bin/env bash

cd $WS

OPB=$(ls -1t Walter-Presents/OPB_TV_ShowsEpisodes-*csv | head -1)
OPB+=" "
OPB+=$(ls -1t Walter-Presents/OPB_TV_Shows-*csv | head -1)
OPB+=" "
OPB+=$(ls -1t Walter-Presents/OPB_anomalies-*txt | head -1)
OPB+=" "
OPB+=$(ls -1t Walter-Presents/OPB_anomalies-*txt | head -2 | tail -1)
OPB+=" "
OPB+=$(ls -1t Walter-Presents/OPB_uniqTitles-*txt | head -1)
# Grab diffs too
OPB+=" "
OPB+=$(ls -1t Walter-Presents/OPB_diffs-*txt | head -1)
OPB+=" "
OPB+=$(ls -1t Walter-Presents/OPB_diffs-*txt | head -2 | tail -1)

# Grab logfiles too
LOGS=$(ls -1t Walter-Presents/OPB-columns/logfile-*txt | head -1)
LOGS+=" "
LOGS+=$(ls -1t Walter-Presents/OPB-columns/logfile_episodes-*txt | head -1)

scp -p $OPB monty@Irene.local:~/Projects/WhatsStreamingToday
scp -p $LOGS \
    monty@Irene.local:~/Projects/WhatsStreamingToday/Walter-Presents/OPB-columns
