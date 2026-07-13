#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <original-samples-directory> <fixture-output-directory>" >&2
    exit 64
fi

input_directory=$1
output_directory=$2
catalog="$(dirname "$0")/../Tests/KSPlayerTests/Resources/kodi-samples.json"

command -v ffmpeg >/dev/null || { echo "ffmpeg is required" >&2; exit 69; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 69; }
[[ -d "$input_directory" ]] || { echo "Input directory does not exist: $input_directory" >&2; exit 66; }

mkdir -p "$output_directory"

jq -r '.[] | select(.container != "YouTube" and .container != "Collection" and .container != "Archive") | [.fileName, .id] | @tsv' "$catalog" |
while IFS=$'\t' read -r file_name id; do
    input_file="$input_directory/$file_name"
    extension="${file_name##*.}"
    output_file="$output_directory/$id-3s.$extension"

    if [[ ! -f "$input_file" ]]; then
        echo "Skipping missing source: $input_file" >&2
        continue
    fi

    # Stream-copying preserves HDR, HDR10+, Dolby Vision, and original codec metadata.
    ffmpeg -hide_banner -loglevel warning -y -ss 00:00:00 -i "$input_file" -t 3 -map 0 -c copy -avoid_negative_ts make_zero "$output_file"
done
