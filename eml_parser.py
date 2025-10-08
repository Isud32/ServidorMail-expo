import email, sys, os, mimetypes, datetime, time, termios, tty, select
# Rich for box decorations
from rich.console import Console
from rich.panel import Panel
from rich.live import Live
from rich.text import Text
# import subprocess #for bash commands in python

def kbhit():
    dr, _, _ = select.select([sys.stdin], [], [], 0)
    return dr != []

def getch():
    return sys.stdin.read(1)

console = Console()
if len(sys.argv) < 2:
    raise RuntimeError("No email file specified")

p = sys.argv[1]

if not os.path.exists(p):
    raise FileNotFoundError(f"Email file not found: {p}")
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
        panel_content += "Contenido:\n"
    
    chars = list(body)
    panel = Panel("", title=" ✉ Correo Nuevo ", border_style="green")
    
    delay = 0.04
    old_settings = termios.tcgetattr(sys.stdin)
    tty.setcbreak(sys.stdin.fileno())
    try:
      with Live(panel, refresh_per_second=30, console=console) as live:
        content = panel_content
        for char in chars:
          if kbhit():
            key = getch()
            if key == "0":
              delay = 0 #instant
            if key == "9":
              delay = 0.01 #fast
            if key == "8":
              delay = 0.04 #normal

          content += char
          panel.renderable = Text(content)      
          live.refresh()
          time.sleep(delay)
    finally:
      termios.tcsetattr(sys.stdin, termios.TCSADRAIN, old_settings)

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

