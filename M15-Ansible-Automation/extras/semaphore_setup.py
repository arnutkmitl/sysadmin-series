"""ตั้งค่า Semaphore UI ผ่าน API สำหรับ Lab บทที่ 6 (รันบน ctl ในโฟลเดอร์ ~/ansible-lab)

สร้าง project, key (SSH ของผู้ใช้ ansible และรหัสผ่าน Vault), repository /repo, inventory.yml,
environment และ template ที่รัน playbooks/common.yml แล้วสั่งรันหนึ่งครั้งและรอผล
ไม่พิมพ์รหัสผ่านใด ๆ ออกหน้าจอ
"""
import http.cookiejar
import json
import pathlib
import subprocess
import sys
import time
import urllib.request

BASE = "http://192.168.56.67:3000/api"
cj = http.cookiejar.CookieJar()
op = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))


def call(method, path, data=None):
    req = urllib.request.Request(BASE + path, method=method,
                                 data=json.dumps(data).encode() if data is not None else None,
                                 headers={"Content-Type": "application/json"})
    with op.open(req) as r:
        body = r.read().decode()
        return json.loads(body) if body.strip().startswith(("{", "[")) else body


vault = subprocess.run(["ansible-vault", "view", "group_vars/dockerhosts/vault.yml"],
                       capture_output=True, text=True, check=True).stdout
admin_pw = next(l.split(":", 1)[1].strip() for l in vault.splitlines() if l.startswith("vault_semaphore_password"))
call("POST", "/auth/login", {"auth": "admin", "password": admin_pw})

projects = call("GET", "/projects")
p = next((x for x in projects if x["name"] == "M15 Server farm"), None) or call("POST", "/projects", {"name": "M15 Server farm"})
pid = p["id"]


def ensure(kind, name, payload):
    items = call("GET", f"/project/{pid}/{kind}")
    found = next((x for x in items if x["name"] == name), None)
    if found:
        return found
    payload.update({"name": name, "project_id": pid})
    return call("POST", f"/project/{pid}/{kind}", payload)


key_none = ensure("keys", "ไม่ใช้ key", {"type": "none"})
key_ssh = ensure("keys", "ansible@ctl", {"type": "ssh", "ssh": {
    "login": "ansible", "private_key": pathlib.Path("~/.ssh/id_ed25519").expanduser().read_text()}})
key_vault = ensure("keys", "Vault ของ M15", {"type": "login_password", "login_password": {
    "password": pathlib.Path("~/.ansible/vault-pass-m15").expanduser().read_text().strip()}})
repo = ensure("repositories", "ansible-lab", {"git_url": "/repo", "git_branch": "", "ssh_key_id": key_none["id"]})
inv = ensure("inventory", "inventory.yml", {"type": "file", "inventory": "inventory.yml",
                                            "ssh_key_id": key_ssh["id"], "repository_id": repo["id"]})
env = ensure("environment", "ค่าว่าง", {"json": "{}", "env": "{}"})
tpl = ensure("templates", "ค่าพื้นฐานทุกเครื่อง (common.yml)", {
    "playbook": "playbooks/common.yml", "inventory_id": inv["id"], "repository_id": repo["id"],
    "environment_id": env["id"], "app": "ansible",
    "vaults": [{"vault_key_id": key_vault["id"], "type": "password"}]})

if "--run" in sys.argv:
    t = call("POST", f"/project/{pid}/tasks", {"template_id": tpl["id"]})
    for _ in range(90):
        time.sleep(5)
        st = call("GET", f"/project/{pid}/tasks/{t['id']}")
        if st["status"] in ("success", "error", "stopped"):
            break
    out = call("GET", f"/project/{pid}/tasks/{t['id']}/output")
    print("task", t["id"], "status", st["status"])
    for line in [o["output"] for o in out][-25:]:
        print(line)
print("project", pid, "template", tpl["id"])
