#!/usr/bin/env bash
WATCH_DIR="./maildata"

# Ensure the directory exists
mkdir -p "$WATCH_DIR"
./banner.sh
#echo "Copyright (c) 2025 7mo 7ma All rights reserved."
draw_box() {
    local msg="$1"
    # Split message into lines
    IFS=$'\n' read -rd '' -a lines <<<"$msg"

    # Find longest line for width
    local max_len=0
    for line in "${lines[@]}"; do
        (( ${#line} > max_len )) && max_len=${#line}
    done
    local width=$((max_len + 4))

    # Top border
    printf "\033[1;36m┌"
    printf '─%.0s' $(seq 1 $width)
    printf "┐\033[0m\n"

    # Print each line inside the box
    for line in "${lines[@]}"; do
        printf "\033[1;36m│  %-*s  │\033[0m\n" "$max_len" "$line"
    done

    # Bottom border
    printf "\033[1;36m└"
    printf '─%.0s' $(seq 1 $width)
    printf "┘\033[0m\n"
}
msg="Watching directory: $WATCH_DIR"
draw_box "$msg"
while true; do
  F=$(inotifywait -q -e close_write --format '%f' "$WATCH_DIR")
  EMFILE="$WATCH_DIR/$F"

  sleep 0.5
  msg="New mail received: $F
  File: $EMFILE"
  draw_box "$msg"

# Parse and display email
python3 eml_parser.py "$EMFILE"

  # Process attachments if any exist
  if [ -d "tmp/" ]; then
    for a in tmp/*; do
      [ -f "$a" ] || continue
      mime=$(file --mime-type -b "$a")
      filename=$(basename "$a")
      
      #echo "Processing attachment: $filename ($mime)"
      
      case "$mime" in
        image/*)
          echo "📷 Image attachment:"
          if command -v chafa >/dev/null 2>&1; then
            chafa --size=40 "$a"
          else
            echo "Install 'chafa' for image preview"
          fi
          ;;
        audio/*)
          echo "🔊 Audio attachment:"
          if command -v cvlc >/dev/null 2>&1; then
              timeout 5s mpv --no-video "$a"
          else
            echo "Install mpv for audio playback"
          fi
          ;;
        video/*)
          echo "🎥 Video attachment:"
          if command -v mpv >/dev/null 2>&1; then
            echo "Playing attached video for 30s"
            sleep 3
            timeout 5s mpv --vo=tct --really-quiet "$a"
            echo "Finished playing video"
          else
            echo "Install 'mpv' with --vo=tct for video preview"
          fi
          ;;
        *)
          echo "📄 Attachment: $filename (type: $mime)"
          ;;
      esac
      echo "---"
    done
    # Cleanup
    rm -rf tmp/*
  fi

  echo ""
  echo "Waiting for next email... :)"
  echo ""
done
