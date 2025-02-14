#!/bin/bash

#
# This script is used for "repairing" "incomplete" mkv files that are downloaded using the 'multi-output-music.conf' configuration.
# That configuration is setup to extract audio and keep partial video files along the way. What that means is that
# the thumbnail is not attached to the video file, and that metadata is not assigned in the video file. This script
# accepts an incomplete *.mkv and attaches the thumbnail and assigns metadata.
#
# Can be called via:
# ~/.yt-dlp/scripts/repair_mkv.sh "mkv_file"
# for file in *.mkv; do ~/.yt-dlp/scripts/repair_mkv.sh "${file}"; done

echo "[repair_mkv.sh] Entering script. Incoming file name: \"${1}\""


# Setup variables...

realname="${1}"
trimmed="${1%.mkv}"
tempvid="${trimmed}.old.mkv"
#audio="${trimmed}.opus"
thumb="${trimmed}.jpg"
infojson="${trimmed}.info.json"

#if [ ! -f "${audio}" ]; then
#	audio="${trimmed}.m4a"
#
#fi
#
#if [ ! -f "${audio}" ]; then
#	echo "[repair_mkv.sh] ERROR! No audio files (tried .opus, .m4a); needed for metadata. Exiting."
#	exit 1
#fi

#if [ ! -f "${thumb}" ]; then
#	echo "[repair_mkv.sh] warn - attempting to pull thumbnail from audio file."
#	ffmpeg -y -i "${audio}" -an -c:v copy "${thumb}"
#fi

if [ ! -f "${thumb}" ]; then
	echo "[repair_mkv.sh] ERROR! Thumbnail does not exist. Make sure to include --write-thumbnail or --skip-download in the yt-dlp command."
	exit 1
fi

if [ ! -f "${infojson}" ]; then
	infojson="extra/${$infojson}"

fi

if [ ! -f "${infojson}" ]; then
	echo "[repair_mkv.sh] ERROR! info.json does not exist. Make sure to include --write-info-json or --skip-download in the yt-dlp command."
	exit 1
fi

echo "[repair_mkv.sh] Real file name:      \"${realname}\""
echo "[repair_mkv.sh] Temp file name:      \"${tempvid}\""
#echo "[repair_mkv.sh] Audio file name:     \"${audio}\""
echo "[repair_mkv.sh] Thumb file name:     \"${thumb}\""
echo "[repair_mkv.sh] info.json file name: \"${infojson}\""


if [ ! -f "${tempvid}" ]; then
	echo "[repair_mkv.sh] Attempting to move \"${realname}\" to \"${tempvid}\""
	mv "${realname}" "${tempvid}";
fi

if [ ! -f "${tempvid}" ]; then
	echo "[repair_mkv.sh] ERROR! Unable to move video file!"
	exit 1
fi


# Collect metadata I want in the file...

metadata_title=$(cat "${infojson}" | jq -r '.title')
metadata_description=$(cat "${infojson}" | jq -r '.description')
metadata_comment=$(cat "${infojson}" | jq -r '.webpage_url')
metadata_artist=$(cat "${infojson}" | jq -r '.channel')
metadata_date=$(cat "${infojson}" | jq -r '.meta_date')
metadata_year=$(cat "${infojson}" | jq -r '.meta_year')
metadata_purl=$(cat "${infojson}" | jq -r '.webpage_url')

#echo "${metadata_title}"
#echo "${metadata_description}"
#echo "${metadata_comment}"
#echo "${metadata_artist}"
#echo "${metadata_date}"
#echo "${metadata_year}"
#echo "${metadata_purl}"


# Rebuild the file...

ffmpeg -y \
-i "${tempvid}" \
-ignore_unknown \
-map 0 \
-map -0:v \
-map 0:v:0 \
-c copy \
-map_metadata 0 \
-attach "${thumb}" \
-metadata:s:t "mimetype=image/jpeg" \
-metadata:s:t "filename=cover.jpg" \
-metadata:g "title=${metadata_title}" \
-metadata:g "description=${metadata_description}" \
-metadata:g "comment=${metadata_comment}" \
-metadata:g "artist=${metadata_artist}" \
-metadata:g "date=${metadata_date}" \
-metadata:g "year=${metadata_year}" \
-metadata:g "purl=${metadata_purl}" \
-metadata:s:a "filename=" \
-metadata:s:a "mimetype=" \
-metadata:s:a "title=" \
-metadata:s:a "description=" \
-metadata:s:a "comment=" \
-metadata:s:a "artist=" \
-metadata:s:a "date=" \
-metadata:s:a "year=" \
-metadata:s:a "purl=" \
-movflags +faststart \
"${realname}";





# Cleanup...
# TODO - Cleanup all intermediate files (thumbnail, info.json, etc.)

#\"${thumb}\""
echo "[repair_mkv.sh] Removing \"${tempvid}\""
#"${thumb}"
rm "${tempvid}"
