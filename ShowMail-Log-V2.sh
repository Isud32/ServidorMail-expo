#!/usr/bin/env bash
WATCH_DIR="./maildata"

# Ensure the directory exists
mkdir -p "$WATCH_DIR"
./banner.sh
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

inotifywait -q -m -e close_write --format '%f' "$WATCH_DIR" | while read F; do
  EMFILE="$WATCH_DIR/$F"

  sleep 0.5
  msg="New mail received: $F
  File: $EMFILE"
  draw_box "$msg"

  # Parse and display email
  python3 - <<PY
import email, sys, os, mimetypes, datetime
# Rich for box decorations
from rich.console import Console
from rich.panel import Panel

console = Console()
p = "$EMFILE"
ts = os.path.getmtime(p)
date_formatted = datetime.datetime.fromtimestamp(ts).strftime("%d-%m-%Y %H:%M:%S")
try:
    with open(p,'rb') as f:
        msg = email.message_from_binary_file(f)
    sender = msg.get('From','<unknown>')
    reciber = msg.get('To','<unknown>')
    subject = msg.get('Subject','<no subject>')

    # Get message body
    body = ""
    if msg.is_multipart():
        for part in msg.walk():
            if part.get_content_type() == "text/plain":
                body = part.get_payload(decode=True).decode('utf-8', errors='ignore')
                break
    else:
        body = msg.get_payload(decode=True).decode('utf-8', errors='ignore')

    if body and len(body) > 500:
        body = body[:500] + "..."

    # Create a Rich panel for the email
    panel_content = f"De: {sender}\nPara: {reciber}\nAsunto: {subject}\nFecha: {date_formatted}\n\n"
    if body:
        panel_content += f"Contenido:\n{body}\n"

    panel = Panel(panel_content, title="[✉]Correo Nuevo", border_style="green")
    console.print(panel)

    # Extract attachments
    outdir = "tmp/"
    os.makedirs(outdir, exist_ok=True)
    
    attachment_count = 0
    for part in msg.walk():
        if part.get_content_maintype() == 'multipart' or part.get('Content-Disposition') is None:
            continue
            
        filename = part.get_filename()
        if filename:
            attachment_count += 1
            path = os.path.join(outdir, filename)
            with open(path, 'wb') as of:
                of.write(part.get_payload(decode=True))
            console.print(f"[green]Archivo Guardado:[/green] {filename} ({part.get_content_type()})")
    
    console.print(f"[yellow]Archvios Totales:[/yellow] {attachment_count}")

except Exception as e:
    console.print(f"[red]Error processing email:[/red] {e}")
PY

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
