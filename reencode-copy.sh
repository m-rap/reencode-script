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
    local fIn="$1"
    local fOut="$2"
    echo "$fIn -> $fOut"

    # Only apply movflags for mp4/mov/m4v containers
    local movflags=()
    case "${fOut,,}" in
        *.mp4|*.mov|*.m4v) movflags=(-movflags use_metadata_tags) ;;
    esac

    if [ "$ISDEFAULTCODEC" = "1" ]; then
        ffmpeg -nostdin -i "$fIn" -threads 4 \
            -map 0 -map_metadata 0 -map_metadata:s:v 0:s:v -map_metadata:s:a 0:s:a \
            "${movflags[@]}" "$fOut" || return $?
    else
        local VCODEC ACODEC
        VCODEC=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$fIn")
        ACODEC=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$fIn")

        local codec_args=()
        [ -n "$VCODEC" ] && codec_args+=(-c:v "$VCODEC")
        [ -n "$ACODEC" ] && codec_args+=(-c:a "$ACODEC")

        # Let FFmpeg auto-detect container format from $fOut extension (assuming $fOut keeps the source extension)
        ffmpeg -nostdin -i "$fIn" -threads 4 \
            -map 0 "${codec_args[@]}" \
            -map_metadata 0 -map_metadata:s:v 0:s:v -map_metadata:s:a 0:s:a \
            "${movflags[@]}" "$fOut" || return $?
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

