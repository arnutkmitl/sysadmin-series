#!/usr/bin/env bash
# ก่อนเริ่ม: วิธีใช้หนังสือและเตรียมเครื่อง
# SysAdmin Pocket Series M04 Python for SysAdmin
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── สิ่งที่ต้องเตรียม ───────────────────────────────────────
# ⚠️ อย่าใช้ sudo pip install ติดตั้ง library ลงระบบ pip จะเขียนทับไฟล์ที่ dnf ติดตั้งไว้ เครื่องมือของระบบที่เขียนด้วย Python เช่น dnf และ firewalld อาจเสียจนอัปเดตเครื่องไม่ได้ ติดตั้งใน venv เสมอ
python3 --version
pip3 --version
mkdir -p ~/python-admin/{labs,scripts,configs,templates,logs}
python3 -m venv ~/python-admin/.venv
source ~/python-admin/.venv/bin/activate
pip install --upgrade pip
pip install psutil paramiko requests pyyaml tabulate
pip list | grep -iE "psutil|paramiko|requests|pyyaml|tabulate"
~/python-admin/.venv/bin/python -c "import psutil; print(psutil.__version__)"

# ── กล่อง Ubuntu ────────────────────────────────────────────
sudo apt install -y python3-venv
python3 -m venv ~/python-admin/.venv
