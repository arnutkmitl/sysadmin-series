#!/usr/bin/env bash
# ก่อนเริ่ม: วิธีใช้หนังสือและเตรียมเครื่อง
# SysAdmin Pocket Series M03 Shell Script Automation
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── สิ่งที่ต้องเตรียม ───────────────────────────────────────
sudo dnf install -y epel-release
sudo dnf install -y ShellCheck jq bc s-nail tar openssl git
shellcheck --version | grep version:
bash --version | head -1
mkdir -p ~/scripts/{labs,production,templates,logs}
ls ~/scripts

# ── กล่อง Ubuntu ────────────────────────────────────────────
sudo apt update
sudo apt install -y shellcheck jq bc s-nail tar openssl git
