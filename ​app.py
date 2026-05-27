from flask import Flask, Response
import requests

app = Flask(__name__)

# เปลี่ยนตัวนี้ให้เป็น URL หลักของ Gist (ไม่ต้องมี /raw ต่อท้าย)
GIST_BASE_URL = "https://gist.githubusercontent.com/SuperHumanv1/"

@app.route('/<gist_id>')
def get_script(gist_id):
    # ปรับ URL ให้ดึงจาก ID ของ Gist ที่คุณสร้าง
    url = f"{GIST_BASE_URL}{gist_id}/raw"
    try:
        response = requests.get(url)
        if response.status_code == 200:
            return Response(response.text, mimetype='text/plain')
        else:
            return "404 Not Found", 404
    except:
        return "Error", 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
