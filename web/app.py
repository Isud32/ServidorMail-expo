from flask import Flask, request, render_template_string, redirect
import smtplib
from email.message import EmailMessage
import os

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 300 * 1024 * 1024  # 300MB max upload

TEMPLATE = """
<form method="post" enctype="multipart/form-data">
  From: <input name="from" value="user@local"><br>
  To: <input name="to" value="display@server.local"><br>
  Subject: <input name="subject"><br>
  Message: <textarea name="body"></textarea><br>
  Attachment: <input type="file" name="file"><br>
  <button>Send</button>
</form>
"""
@app.errorhandler(413)
def too_large(e):
    return "File is too large. Maximum size is 300MB.", 413

@app.route("/", methods=["GET","POST"])
def index():
    if request.method=="POST":
        msg = EmailMessage()
        msg['From'] = request.form['from']
        msg['To'] = request.form['to']
        msg['Subject'] = request.form['subject'] or "no-subject"
        msg.set_content(request.form['body'] or "")
        f = request.files.get('file')
        if f:
            data = f.read()
            maintype, subtype = (f.mimetype.split('/',1) if f.mimetype else ('application','octet-stream'))
            msg.add_attachment(data, maintype=maintype, subtype=subtype, filename=f.filename)
        # send to postfix container
        with smtplib.SMTP(host="postfix", port=25) as s:
            s.send_message(msg)
        return "sent"
    return render_template_string(TEMPLATE)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)

