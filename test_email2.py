import requests

url = "http://192.168.1.32/"
data = {
    "from": "benjatecnologia@local",
    "to": "display@server.local",
    "subject": "soad",
    "body": "Liar, liar. Banana, banana, banana, terracotta. Banana terracotta, terracotta pie. Banana, banana, banana, terracotta. Banana terracotta, terracotta pie. Is there a perfect way of holding you, baby? (Liar) Vicinity of obscenity in your eyes. Terracotta, terracotta, terracotta pie. Is there a perfect way of holding you, baby? (Liar) Vicinity of obscenity in your eyes. Terracotta pie, hey. Terracotta pie, hey. Terracotta pie, hey. Terracotta pie. Banana, banana, banana, banana, terracotta. Banana terracotta, terracotta pie. Banana, banana, banana, banana, terracotta. Banana terracotta, terracotta pie."
}

response = requests.post(url, data=data)
print(response.text)
