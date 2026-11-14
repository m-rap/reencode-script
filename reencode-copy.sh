#!/bin/bash

trap 'echo "Interrupted by user. Exiting..."; exit 1' INT

dir="$(dirname 0)"
i=0

#for f in $(ls "in"); do
    #echo "$dir/in/$f $i"
    #if [[ $((i % 4)) -ne 3 ]]; then
    #    ffmpeg -i "$dir/in/$f" -threads 4 -map 0 -map_metadata 0 -map_metadata:s:v 0:s:v -map_metadata:s:a 0:s:a -movflags use_metadata_tags "$dir/out/$f" &
    #else
    #    ffmpeg -i "$dir/in/$f" -threads 4 -map 0 -map_metadata 0 -map_metadata:s:v 0:s:v -map_metadata:s:a 0:s:a -movflags use_metadata_tags "$dir/out/$f" 
    #fi

ISDEFAULTCODEC=0

doEncode() {
    fIn="$1"
    fOut="$2"
    echo "$fIn $fOut"
    if [ "$ISDEFAULTCODEC" = "1" ]; then
	ffmpeg -i "$fIn" -threads 4 -map 0 -map_metadata 0 -map_metadata:s:v 0:s:v -map_metadata:s:a 0:s:a -movflags use_metadata_tags "$fOut"
    else
        VCODEC=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:keyonly=1 "$fIn") && \
        ACODEC=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:keyonly=1 "$fIn") && \
        FORMAT=$(ffprobe -v error -show_entries format=format_name -of default=noprint_wrappers=1:keyonly=1 "$fIn" | cut -d',' -f1) && \
        ffmpeg -i "$fIn" -threads 4 -map 0 -c:v $VCODEC -c:a $ACODEC -f $FORMAT -map_metadata 0 -map_metadata:s:v 0:s:v -map_metadata:s:a 0:s:a -movflags use_metadata_tags "$fOut"
    fi
}

for f in in/*; do
    af=${f##*/}
    echo "$dir/$af $i"
    if [[ $((i % 4)) -ne 3 ]]; then
        doEncode "$dir/in/$af" "$dir/out/$af" &
    else
        doEncode "$dir/in/$af" "$dir/out/$af" 
    fi
    i=$((i + 1))
done

