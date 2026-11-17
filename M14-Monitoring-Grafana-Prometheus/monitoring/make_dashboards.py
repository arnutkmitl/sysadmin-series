"""Generate the M14 Grafana dashboards (provisioned from grafana/dashboards/).

Run: python make_dashboards.py
Each dashboard uses the provisioned data source uid "prometheus" and a $instance variable.
"""
import json
import pathlib

OUT = pathlib.Path(__file__).resolve().parent / "grafana" / "dashboards"
DS = {"type": "prometheus", "uid": "prometheus"}


def target(expr, legend="{{instance}}", ref="A"):
    return {"datasource": DS, "expr": expr, "legendFormat": legend, "refId": ref}


def panel(pid, title, ptype, x, y, w, h, targets, unit=None, thresholds=None, minv=None, maxv=None, desc=""):
    p = {"id": pid, "type": ptype, "title": title, "description": desc, "datasource": DS,
         "gridPos": {"x": x, "y": y, "w": w, "h": h}, "targets": targets,
         "fieldConfig": {"defaults": {}, "overrides": []}, "options": {}}
    d = p["fieldConfig"]["defaults"]
    if unit:
        d["unit"] = unit
    if minv is not None:
        d["min"] = minv
    if maxv is not None:
        d["max"] = maxv
    if thresholds is not None:
        d["thresholds"] = {"mode": "absolute", "steps": [{"color": "green" if thresholds else "blue", "value": None}] +
                           [{"color": c, "value": v} for v, c in thresholds]}
        d["color"] = {"mode": "thresholds"}
    if ptype == "timeseries":
        d["custom"] = {"lineWidth": 2, "fillOpacity": 10, "showPoints": "never",
                       "thresholdsStyle": {"mode": "line+area" if thresholds else "off"}}
        d["color"] = {"mode": "palette-classic"}
        p["options"] = {"legend": {"displayMode": "list", "placement": "bottom", "showLegend": True},
                        "tooltip": {"mode": "multi", "sort": "desc"}}
    if ptype in ("stat", "gauge", "bargauge"):
        p["options"] = {"reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False}}
    return p


def var_instance(query='label_values(up{job="node"}, instance)'):
    return {"name": "instance", "label": "เครื่อง", "type": "query", "datasource": DS,
            "query": {"query": query, "refId": "instance"}, "definition": query,
            "includeAll": True, "multi": True, "refresh": 1, "sort": 1,
            "current": {"selected": True, "text": ["All"], "value": ["$__all"]}}


def dashboard(uid, title, panels, variables, tags):
    return {"uid": uid, "title": title, "tags": tags, "timezone": "browser", "schemaVersion": 41,
            "time": {"from": "now-1h", "to": "now"}, "refresh": "30s", "editable": True,
            "templating": {"list": variables}, "panels": panels, "annotations": {"list": []}}


I = '{instance=~"$instance"}'
server = dashboard("m14-server", "M14 Server Overview", [
    panel(1, "CPU ที่ใช้ (%)", "timeseries", 0, 0, 12, 8,
          [target(f'100 - (avg by (instance) (rate(node_cpu_seconds_total{{mode="idle",instance=~"$instance"}}[$__rate_interval])) * 100)')],
          unit="percent", minv=0, maxv=100, thresholds=[(80, "red")]),
    panel(2, "RAM ที่ใช้ (%)", "gauge", 12, 0, 6, 8,
          [target(f'(1 - node_memory_MemAvailable_bytes{I} / node_memory_MemTotal_bytes{I}) * 100')],
          unit="percent", minv=0, maxv=100, thresholds=[(75, "orange"), (90, "red")]),
    panel(3, "Uptime", "stat", 18, 0, 6, 8,
          [target(f'time() - node_boot_time_seconds{I}')], unit="s", thresholds=[]),
    panel(4, "Disk / ที่ใช้ (%)", "bargauge", 0, 8, 8, 8,
          [target(f'100 - (node_filesystem_avail_bytes{{mountpoint="/",instance=~"$instance"}} / node_filesystem_size_bytes{{mountpoint="/",instance=~"$instance"}} * 100)')],
          unit="percent", minv=0, maxv=100, thresholds=[(80, "orange"), (90, "red")]),
    panel(5, "Network enp0s8 (bit/s)", "timeseries", 8, 8, 10, 8,
          [target(f'rate(node_network_receive_bytes_total{{device="enp0s8",instance=~"$instance"}}[$__rate_interval]) * 8', "{{instance}} รับ", "A"),
           target(f'-rate(node_network_transmit_bytes_total{{device="enp0s8",instance=~"$instance"}}[$__rate_interval]) * 8', "{{instance}} ส่ง", "B")],
          unit="bps"),
    panel(6, "Load Average 1 นาที", "stat", 18, 8, 6, 8,
          [target(f'node_load1{I}')], unit="short", thresholds=[(1, "orange"), (2, "red")]),
], [var_instance()], ["m14", "node"])

docker = dashboard("m14-docker", "M14 Docker Containers", [
    panel(1, "CPU ของแต่ละ container (%)", "timeseries", 0, 0, 12, 9,
          [target('sum by (name) (rate(container_cpu_usage_seconds_total{name!=""}[$__rate_interval])) * 100', "{{name}}")],
          unit="percent", minv=0),
    panel(2, "หน่วยความจำของแต่ละ container", "timeseries", 12, 0, 12, 9,
          [target('container_memory_working_set_bytes{name!=""}', "{{name}}")], unit="bytes", minv=0),
    panel(3, "Top 5 ใช้ RAM", "bargauge", 0, 9, 12, 8,
          [target('topk(5, container_memory_working_set_bytes{name!=""})', "{{name}}")], unit="bytes", thresholds=[]),
    panel(4, "Network รับ (bit/s)", "timeseries", 12, 9, 12, 8,
          [target('sum by (name) (rate(container_network_receive_bytes_total{name!=""}[$__rate_interval])) * 8', "{{name}}")], unit="bps"),
], [], ["m14", "docker"])

nginx = dashboard("m14-nginx", "M14 Nginx", [
    panel(1, "Request ต่อวินาที", "timeseries", 0, 0, 12, 8,
          [target('rate(nginx_http_requests_total[$__rate_interval])', "{{instance}}")], unit="reqps", minv=0),
    panel(2, "Connection ที่เปิดอยู่", "stat", 12, 0, 6, 8,
          [target('nginx_connections_active', "{{instance}}")], unit="short", thresholds=[]),
    panel(3, "Nginx ทำงาน", "stat", 18, 0, 6, 8,
          [target('nginx_up', "{{instance}}")], unit="short", thresholds=[(1, "green")]),
    panel(4, "สถานะ Connection", "timeseries", 0, 8, 12, 8,
          [target('nginx_connections_reading', "reading", "A"), target('nginx_connections_writing', "writing", "B"),
           target('nginx_connections_waiting', "waiting", "C")], unit="short", minv=0),
    panel(5, "เวลาตอบของหน้าเว็บจาก blackbox (วินาที)", "timeseries", 12, 8, 12, 8,
          [target('probe_duration_seconds{job="blackbox-http"}', "{{instance}}")], unit="s", minv=0),
], [], ["m14", "nginx"])

mariadb = dashboard("m14-mariadb", "M14 MariaDB", [
    panel(1, "MariaDB ทำงาน", "stat", 0, 0, 6, 7,
          [target('mysql_up', "{{instance}}")], unit="short", thresholds=[(1, "green")]),
    panel(2, "Connection ที่เชื่อมอยู่", "stat", 6, 0, 6, 7,
          [target('mysql_global_status_threads_connected', "{{instance}}")], unit="short", thresholds=[]),
    panel(3, "Uptime", "stat", 12, 0, 6, 7,
          [target('mysql_global_status_uptime', "{{instance}}")], unit="s", thresholds=[]),
    panel(4, "Slow query สะสม", "stat", 18, 0, 6, 7,
          [target('mysql_global_status_slow_queries', "{{instance}}")], unit="short", thresholds=[(1, "orange")]),
    panel(5, "Query ต่อวินาที", "timeseries", 0, 7, 12, 8,
          [target('rate(mysql_global_status_queries[$__rate_interval])', "{{instance}}")], unit="qps", minv=0),
    panel(6, "คำสั่งแยกชนิด (ต่อวินาที)", "timeseries", 12, 7, 12, 8,
          [target('topk(5, rate(mysql_global_status_commands_total[$__rate_interval]))', "{{command}}")], unit="ops", minv=0),
], [], ["m14", "mariadb"])

multi = dashboard("m14-multi", "M14 Multi-Server", [
    panel(1, "สรุปทุกเครื่อง", "table", 0, 0, 24, 9,
          [dict(target('100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[$__rate_interval])) * 100)', "", "A"), format="table", instant=True),
           dict(target('(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100', "", "B"), format="table", instant=True),
           dict(target('100 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} * 100)', "", "C"), format="table", instant=True),
           dict(target('up{job="node"}', "", "D"), format="table", instant=True)],
          unit="percent"),
    panel(2, "CPU ทุกเครื่อง (%)", "timeseries", 0, 9, 12, 8,
          [target('100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[$__rate_interval])) * 100)')],
          unit="percent", minv=0, maxv=100, thresholds=[(80, "red")]),
    panel(3, "RAM ทุกเครื่อง (%)", "timeseries", 12, 9, 12, 8,
          [target('(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100')],
          unit="percent", minv=0, maxv=100, thresholds=[(90, "red")]),
], [], ["m14", "node"])
multi["panels"][0]["transformations"] = [
    {"id": "merge", "options": {}},
    {"id": "organize", "options": {"excludeByName": {"Time": True, "job": True, "role": True, "device": True,
                                                       "fstype": True, "mountpoint": True, "__name__": True},
                                    "renameByName": {"Value #A": "CPU %", "Value #B": "RAM %",
                                                     "Value #C": "Disk / %", "Value #D": "UP"}}}]
multi["panels"][0]["gridPos"]["h"] = 5
multi["panels"][0]["fieldConfig"]["overrides"] = [
    {"matcher": {"id": "byName", "options": "UP"},
     "properties": [{"id": "unit", "value": "none"},
                    {"id": "mappings", "value": [{"type": "value", "options": {
                        "0": {"text": "DOWN", "color": "red"}, "1": {"text": "UP", "color": "green"}}}]},
                    {"id": "custom.cellOptions", "value": {"type": "color-text"}}]}]
for p in multi["panels"][1:]:
    p["gridPos"]["y"] = 5

OUT.mkdir(parents=True, exist_ok=True)
for name, d in (("server-overview", server), ("docker", docker), ("nginx", nginx),
                ("mariadb", mariadb), ("multi-server", multi)):
    (OUT / f"{name}.json").write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("wrote", sorted(p.name for p in OUT.glob("*.json")))
