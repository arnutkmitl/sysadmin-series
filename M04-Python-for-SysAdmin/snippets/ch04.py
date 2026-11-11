# Network และ API: requests และ paramiko
# SysAdmin Pocket Series M04 Python for SysAdmin
# ตัวอย่างที่พิมพ์ใน Python interactive (>>>) ตามลำดับในเล่ม ตัด prompt และผลลัพธ์ออกแล้ว
# ให้คัดลอกทีละส่วนไปลองใน python3 หรือ .venv/bin/python ไม่ใช่สคริปต์ที่รันทั้งไฟล์

# ── 4.1 requests เรียก API
import requests
r = requests.get("https://api.github.com/repos/giampaolo/psutil", timeout=10)
r.status_code
data = r.json()
print(f"{data['full_name']} stars {data['stargazers_count']}, open issues {data['open_issues_count']}")

# ── 4.1 requests เรียก API
r = requests.post("https://httpbin.org/post", json={"host": "web01", "disk": 91}, timeout=10)
r.json()["json"]

# ── 4.1 requests เรียก API
try:
    r = requests.get("http://192.168.56.20:8080/health", timeout=3)
    r.raise_for_status()
except requests.exceptions.ConnectionError:
    print("ติดต่อไม่ได้")
except requests.exceptions.HTTPError as e:
    print(f"ได้ status {e.response.status_code}")

# ── 4.3 ส่งแจ้งเตือน: LINE, Slack และอีเมล
from notify import notify
notify("ทดสอบ", "disk / ใช้ 91%")

# ── 4.4 paramiko SSH ไปหลายเครื่อง
import paramiko
ssh = paramiko.SSHClient()
ssh.load_system_host_keys()
ssh.connect("192.168.56.20", port=2222, username="admin", timeout=10)
stdin, stdout, stderr = ssh.exec_command("uptime -p")
stdout.read().decode().strip(), stdout.channel.recv_exit_status()
ssh.close()

# ── 4.4 paramiko SSH ไปหลายเครื่อง
sftp = ssh.open_sftp()
attrs = sftp.put("/home/admin/python-admin/configs/watchdog.yaml", "/home/admin/watchdog.yaml")
attrs.st_size
sftp.get("/etc/os-release", "/tmp/client-os-release")
sftp.close()
