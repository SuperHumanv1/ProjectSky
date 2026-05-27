from flask import Flask, Response
import requests

app = Flask(__name__)

# เปลี่ยนตรงนี้เป็น URL ของ Gist ของคุณที่ลงท้ายด้วย /raw
GIST_BASE_URL = "https://gist.githubusercontent.com/SuperHumanv1/"

@app.route('/<script_name>')
def get_script(script_name):
    # ดึงโค้ดจาก Gist ของคุณ
    url = f"{GIST_BASE_URL}{script_name}/raw"
    try:
        response = requests.get(url)
        if response.status_code == 200:
            # ส่งค่ากลับเป็น text/plain (Roblox ต้องการแบบนี้)
            return Response(response.text, mimetype='text/plain')
        else:
            return "404 Not Found", 404
    except:
        return "Error", 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
