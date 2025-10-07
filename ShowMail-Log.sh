#!/usr/bin/env bash
WATCH_DIR="./maildata"

# Ensure the directory exists
mkdir -p "$WATCH_DIR"

echo "Watching directory: $WATCH_DIR"
echo "Script is running..."

inotifywait -m -e close_write --format '%f' "$WATCH_DIR" | while read F; do
  EMFILE="$WATCH_DIR/$F"
  
  # Wait a moment for file to be completely written
  sleep 0.5
  
  echo "============================================"
  echo "New mail received: $F"
  echo "File: $EMFILE"
  echo "============================================"
  
  # Parse and display email
  python3 - <<PY
import email, sys, os, mimetypes
p = "$EMFILE"
try:
    with open(p,'rb') as f:
        msg = email.message_from_binary_file(f)
    sender = msg.get('From','<unknown>')
    subject = msg.get('Subject','<no subject>')
    print(f"From: {sender}")
    print(f"Subject: {subject}")
    print("---")
    
    # Get message body
    body = ""
    if msg.is_multipart():
        for part in msg.walk():
            if part.get_content_type() == "text/plain":
                body = part.get_payload(decode=True).decode('utf-8', errors='ignore')
                break
    else:
        body = msg.get_payload(decode=True).decode('utf-8', errors='ignore')
    
    if body:
        print("Message:")
        print(body[:500] + ("..." if len(body) > 500 else ""))
    
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
            print(f"Attachment saved: {filename} ({part.get_content_type()})")
    
    print(f"Total attachments: {attachment_count}")
    
except Exception as e:
    print(f"Error processing email: {e}")
PY

  # Process attachments if any exist
  if [ -d "tmp/" ]; then
    for a in tmp/*; do
      [ -f "$a" ] || continue
      mime=$(file --mime-type -b "$a")
      filename=$(basename "$a")
      
      echo "Processing attachment: $filename ($mime)"
      
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
              mpv --no-video --really-quiet "$a"
          else
            echo "Install mpg123 for audio playback"
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
    # Cleanup attachments
    rm -rf tmp/*
  fi
  
  echo ""
  echo "Waiting for next email... :)"
  echo ""
done
