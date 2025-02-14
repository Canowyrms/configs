#!/bin/bash

#
# This script produces an mp3 file from a downloaded video and thumbnail.
# The thumbnail and metadata from the video is preserved in the mp3.
#
# Can be called via:
# yt-dlp --exec "bash -c '~/.yt-dlp/scripts/make_mp3.sh %(_filename)q'" <id>
#

echo "[make_mp3.sh] Entering script. Incoming file name: \"${1}\""

trimmed="${1%.mkv}"
#thumb="${trimmed}.jpg"
mp3_out="${trimmed}.mp3"

echo "[make_mp3.sh] Trimmed file name:    \"${trimmed}\""
#echo "[make_mp3.sh] Thumbnail file name:  \"${thumb}\""
echo "[make_mp3.sh] MP3 output file name: \"${mp3_out}\""


#if [ ! -f "${thumb}" ]; then
#	echo "[make_mp3.sh] ERROR! Thumbnail does not exist. Make sure to include --write-thumbnail in the yt-dlp command."
#	exit 1
#fi



# Example: Rename the file
#mv "$file" "${file%.mp4}_processed.mp4"


# yt-dlp logs for reference

#[ExtractAudio] Destination: Half the price. All the Games. - MiSTER Pi [Am-cx8yzk0A].mp3
#[debug] ffmpeg command line: C:\Users\BK/.yt-dlp/ffmpeg/latest/bin\ffmpeg -y -loglevel repeat+info -i "file:Half the price. All the Games. - MiSTER Pi [Am-cx8yzk0A].mkv" -vn -acodec libmp3lame -q:a 5.0 -movflags +faststart "file:Half the price. All the Games. - MiSTER Pi [Am-cx8yzk0A].mp3"

# WORKS
#ffmpeg -y -loglevel repeat+info -i "file:${1}" -vn -acodec libmp3lame -q:a 5.0 -map_metadata 0 -metadata "synopsis=" -write_id3v1 1 -movflags +faststart "file:${trimmed}.temp1.mp3"


#[EmbedThumbnail] ffmpeg: Adding thumbnail to "Half the price. All the Games. - MiSTER Pi [Am-cx8yzk0A].mp3"
#[debug] ffmpeg command line: C:\Users\BK/.yt-dlp/ffmpeg/latest/bin\ffmpeg -y -loglevel repeat+info -i "file:Half the price. All the Games. - MiSTER Pi [Am-cx8yzk0A].mp3" -i "file:Half the price. All the Games. - MiSTER Pi [Am-cx8yzk0A].jpg" -c copy -map 0:0 -map 1:0 -write_id3v1 1 -id3v2_version 3 -metadata:s:v "title=\"Album cover\"" -metadata:s:v "comment=Cover (front)" -movflags +faststart "file:Half the price. All the Games. - MiSTER Pi [Am-cx8yzk0A].temp.mp3"

# WORKS
#ffmpeg -y -loglevel repeat+info -i "file:${trimmed}.temp1.mp3" -i "file:${thumb}" -c copy -map 0:0 -map 1:0 -write_id3v1 1 -id3v2_version 3 -metadata:s:v "title=\"Album cover\"" -metadata:s:v "comment=Cover (front)" -movflags +faststart "file:${trimmed}.mp3"


# Combining the above into a single command:

# WORKS
#ffmpeg -y -loglevel repeat+info -i "file:${1}" -i "file:${thumb}" -map 0:a:0 -c:a libmp3lame -q:a 5.0 -map 1:0 -c:v copy -map_metadata 0 -metadata "synopsis=" -write_id3v1 1 -id3v2_version 3 -metadata:s:v "title=\"Album cover\"" -metadata:s:v "comment=Cover (front)" -movflags +faststart "file:${mp3_out}"


# WORKS
# Does not require a discrete thumbnail file, can copy thumbnail stream from input video to output mp3.

ffmpeg -y -loglevel repeat+info -i "file:${1}" -map 0:a:0 -c:a libmp3lame -q:a 0 -map 0:v:1 -c:v copy -map_metadata 0 -metadata "synopsis=" -write_id3v1 1 -id3v2_version 3 -metadata:s:v "title=\"Album cover\"" -metadata:s:v "comment=Cover (front)" -movflags +faststart "file:${mp3_out}" > /dev/null 2>&1 &
