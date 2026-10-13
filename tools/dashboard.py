#!/usr/bin/env python3
"""Generate coordination/DASHBOARD.md and coordination/dashboard.html.

Reads (never writes) task files, checkpoints, session logs, HUMAN_NEEDED.md and
coordination/.last_check.json. Safe to run any time, from any session, in parallel:
output is fully derived from those files. Standard library only.

Usage: python3 tools/dashboard.py [--quiet]
"""
from __future__ import annotations

import datetime as dt
import html
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
COORD = ROOT / "coordination"
STALE_HOURS = 48
STATUSES = ["in-progress", "review", "todo", "blocked", "done"]
HR_DONE = {"delivered", "answered", "accepted", "wontdo"}
MILESTONES = {
    "M0": "Foundation", "M1": "Core feel", "M2": "Game loop", "M3": "Art and audio",
    "M4": "City meta", "M5": "Services", "M6": "Release",
}


# --- parsing -------------------------------------------------------------------

def parse_frontmatter(text: str) -> dict:
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return {}
    data = {}
    for line in m.group(1).splitlines():
        if ":" not in line or line.strip().startswith("#"):
            continue
        key, val = line.split(":", 1)
        val = re.sub(r"\s+#.*$", "", val).strip()
        if val.startswith("[") and val.endswith("]"):
            data[key.strip()] = [v.strip().strip('"\'') for v in val[1:-1].split(",") if v.strip()]
        else:
            data[key.strip()] = val.strip('"\'')
    return data


def load_tasks() -> list[dict]:
    tasks = []
    for p in sorted((COORD / "tasks").glob("T-*.md")):
        text = p.read_text(encoding="utf-8")
        fm = parse_frontmatter(text)
        if not fm.get("id"):
            continue
        fm.setdefault("depends", [])
        fm.setdefault("human", [])
        fm["file"] = p.relative_to(ROOT).as_posix()
        boxes = re.findall(r"^- \[([ xX])\]", text, re.M)
        fm["criteria_total"] = len(boxes)
        fm["criteria_done"] = sum(1 for b in boxes if b.lower() == "x")
        tasks.append(fm)
    return tasks


def load_human_requests() -> list[dict]:
    path = ROOT / "HUMAN_NEEDED.md"
    if not path.exists():
        return []
    text = path.read_text(encoding="utf-8")
    out = []
    for block in re.split(r"\n(?=### HR-\d+)", text):
        m = re.match(r"### (HR-\d+)\s*[·\-–—:]\s*(.+)", block)
        if not m:
            continue
        hr = {"id": m.group(1), "title": m.group(2).strip()}
        for key, val in re.findall(r"^- (\w+):\s*(.*)$", block, re.M):
            hr[key] = val.strip()
        status = hr.get("status", "open").split()[0]
        files = re.findall(r"`([^`]+)`", hr.get("files", ""))
        present = [f for f in files if (ROOT / f).exists()]
        hr["files_list"] = files
        hr["files_present"] = len(present)
        hr["auto_delivered"] = bool(files) and len(present) == len(files) and status not in HR_DONE
        hr["status_eff"] = "delivered" if hr["auto_delivered"] else status
        out.append(hr)
    return out


def load_docs(folder: str, pattern: str) -> list[dict]:
    items = []
    for p in sorted((COORD / folder).glob(pattern), reverse=True):
        if p.name.startswith("TEMPLATE"):
            continue
        text = p.read_text(encoding="utf-8")
        title = next((l.lstrip("# ").strip() for l in text.splitlines() if l.startswith("#")), p.stem)
        date = re.search(r"Date:\s*(\S+)", text)
        items.append({"title": title, "file": p.relative_to(ROOT).as_posix(), "date": date.group(1) if date else ""})
    return items


def load_last_check() -> dict | None:
    p = COORD / ".last_check.json"
    if p.exists():
        try:
            return json.loads(p.read_text())
        except json.JSONDecodeError:
            return None
    return None


# --- analysis ------------------------------------------------------------------

def parse_time(s: str) -> dt.datetime | None:
    if not s:
        return None
    for fmt in ("%Y-%m-%dT%H:%M:%S%z", "%Y-%m-%dT%H:%M%z", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M", "%Y-%m-%d"):
        try:
            t = dt.datetime.strptime(s, fmt)
            return t if t.tzinfo else t.replace(tzinfo=dt.timezone.utc)
        except ValueError:
            continue
    return None


def analyse(tasks, hrs):
    now = dt.datetime.now(dt.timezone.utc)
    by_id = {t["id"]: t for t in tasks}
    hr_by_id = {h["id"]: h for h in hrs}
    warnings = []
    for tid, n in Counter(t["id"] for t in tasks).items():
        if n > 1:
            warnings.append(f"Duplicate task id {tid} ({n} files)")
    for hid, n in Counter(h["id"] for h in hrs).items():
        if n > 1:
            warnings.append(f"Duplicate human request id {hid}")
    blocked_by_hr = defaultdict(list)
    for t in tasks:
        if t.get("status") not in STATUSES:
            warnings.append(f"{t['id']}: unknown status '{t.get('status')}'")
        for d in t["depends"]:
            if d not in by_id:
                warnings.append(f"{t['id']}: depends on unknown task {d}")
        for h in t["human"]:
            if h not in hr_by_id:
                warnings.append(f"{t['id']}: references unknown human request {h}")
            elif hr_by_id[h]["status_eff"] not in HR_DONE:
                blocked_by_hr[h].append(t["id"])
        deps_done = all(by_id.get(d, {}).get("status") == "done" for d in t["depends"])
        human_done = all(hr_by_id.get(h, {}).get("status_eff") in HR_DONE for h in t["human"])
        t["deps_done"], t["human_done"] = deps_done, human_done
        t["ready"] = t.get("status") == "todo" and deps_done and human_done
        t["stale"] = False
        if t.get("status") == "in-progress":
            ref = parse_time(t.get("updated", "")) or parse_time(t.get("claimed", ""))
            if ref and (now - ref).total_seconds() > STALE_HOURS * 3600:
                t["stale"] = True
                warnings.append(f"{t['id']}: claimed by {t.get('owner') or '?'} but not updated for {STALE_HOURS}+ hours (may be taken over)")
            if not deps_done:
                warnings.append(f"{t['id']}: in progress although dependencies are not done")
    for h in hrs:
        h["blocks"] = blocked_by_hr.get(h["id"], [])
    ms = defaultdict(lambda: Counter())
    for t in tasks:
        ms[t.get("milestone", "?")][t.get("status", "?")] += 1
    return {"now": now, "warnings": warnings, "milestones": ms}


# --- output: markdown ----------------------------------------------------------

def bar(done, total, width=20):
    filled = round(width * done / total) if total else 0
    return "█" * filled + "░" * (width - filled)


def render_md(tasks, hrs, cps, sessions, check, a) -> str:
    L = ["# Project dashboard", "",
         f"_Generated {a['now']:%Y-%m-%d %H:%M} UTC by `tools/dashboard.py`. Do not edit by hand._", ""]
    if cps:
        L += [f"**Current checkpoint:** [{cps[0]['title']}](../{cps[0]['file']})", ""]
    if check:
        state = "PASS" if check.get("ok") else "FAIL"
        L += [f"**Last `tools/check.sh`:** {state} at {check.get('time', '?')}  "
              + " · ".join(f"{k}: {'ok' if v else 'FAIL'}" for k, v in check.get("steps", {}).items()), ""]
    L += ["## Milestones", "", "| Milestone | Progress | Done / total |", "|---|---|---|"]
    for m in sorted(a["milestones"]):
        c = a["milestones"][m]
        total = sum(c.values())
        L.append(f"| {m} {MILESTONES.get(m, '')} | `{bar(c['done'], total)}` | {c['done']} / {total} |")
    def task_line(t):
        extra = []
        if t.get("owner") and t.get("status") != "done":
            extra.append(f"owner {t['owner']}")
        if t["stale"]:
            extra.append("STALE")
        if not t["deps_done"]:
            extra.append("waits on " + ", ".join(d for d in t["depends"]))
        if not t["human_done"]:
            extra.append("needs " + ", ".join(t["human"]))
        return f"- **{t['id']}** [{t['title']}](../{t['file']}) · {t.get('milestone')} {t.get('priority')}" + (f" · _{'; '.join(extra)}_" if extra else "")
    ready = [t for t in tasks if t["ready"]]
    L += ["", f"## Ready to claim ({len(ready)})", ""] + ([task_line(t) for t in ready] or ["- none"])
    for st in ["in-progress", "review", "blocked"]:
        group = [t for t in tasks if t.get("status") == st]
        L += ["", f"## {st.title()} ({len(group)})", ""] + ([task_line(t) for t in group] or ["- none"])
    waiting = [t for t in tasks if t.get("status") == "todo" and not t["ready"]]
    L += ["", f"## Waiting ({len(waiting)})", ""] + ([task_line(t) for t in waiting] or ["- none"])
    open_hr = [h for h in hrs if h["status_eff"] not in HR_DONE]
    L += ["", f"## Needs a human ({len(open_hr)} open of {len(hrs)})", "",
          "Details and exact file names: [HUMAN_NEEDED.md](../HUMAN_NEEDED.md)", "",
          "| ID | Request | Type | Priority | Files | Blocks |", "|---|---|---|---|---|---|"]
    for h in open_hr:
        files = f"{h['files_present']}/{len(h['files_list'])}" if h["files_list"] else "-"
        L.append(f"| {h['id']} | {h['title']} | {h.get('type', '')} | {h.get('priority', '')} | {files} | {', '.join(h['blocks']) or '-'} |")
    done_hr = [h for h in hrs if h["status_eff"] in HR_DONE]
    if done_hr:
        L += ["", "Delivered / answered: " + ", ".join(f"{h['id']}{' (auto-detected, please confirm)' if h['auto_delivered'] else ''}" for h in done_hr)]
    L += ["", "## Recent sessions", ""] + ([f"- [{s['title']}](../{s['file']})" for s in sessions[:8]] or ["- none"])
    L += ["", "## Checkpoints", ""] + ([f"- [{c['title']}](../{c['file']}) {c['date']}" for c in cps] or ["- none"])
    L += ["", "## Warnings", ""] + ([f"- {w}" for w in a["warnings"]] or ["- none"])
    L += ["", f"## Done ({sum(1 for t in tasks if t.get('status') == 'done')})", ""]
    L += [f"- {t['id']} {t['title']}" for t in tasks if t.get("status") == "done"]
    return "\n".join(L) + "\n"


# --- output: html --------------------------------------------------------------

CSS = """
:root{--bg:#f6f7f9;--card:#fff;--text:#1d2330;--muted:#6b7385;--line:#e3e6ec;--accent:#3b6fd8;--ok:#2e8b57;--warn:#c27c0e;--bad:#c0392b;--chip:#eef1f6}
@media (prefers-color-scheme: dark){:root:not([data-theme="light"]){--bg:#12151b;--card:#1b2029;--text:#e6e9ef;--muted:#99a1b3;--line:#2b3240;--accent:#7aa2ff;--ok:#5cc58c;--warn:#e0a640;--bad:#ef6b5b;--chip:#252c38}}
:root[data-theme="dark"]{--bg:#12151b;--card:#1b2029;--text:#e6e9ef;--muted:#99a1b3;--line:#2b3240;--accent:#7aa2ff;--ok:#5cc58c;--warn:#e0a640;--bad:#ef6b5b;--chip:#252c38}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font:15px/1.45 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
main{max-width:1200px;margin:0 auto;padding:20px 16px 48px}
h1{font-size:24px;margin:0 0 4px}h2{font-size:17px;margin:28px 0 10px}.muted{color:var(--muted)}
.grid{display:grid;gap:12px;grid-template-columns:repeat(auto-fit,minmax(220px,1fr))}
.card{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:12px 14px}
.kpi{font-size:26px;font-weight:650}.bar{height:8px;background:var(--chip);border-radius:4px;overflow:hidden;margin-top:6px}
.bar>i{display:block;height:100%;background:var(--accent)}
.cols{display:grid;gap:12px;grid-template-columns:repeat(auto-fit,minmax(230px,1fr))}
.task{border:1px solid var(--line);border-radius:8px;padding:8px 10px;margin:8px 0;background:var(--bg)}
.task b{font-variant-numeric:tabular-nums}.chip{display:inline-block;background:var(--chip);border-radius:10px;padding:0 8px;font-size:12px;margin:2px 4px 0 0}
.ready{border-left:4px solid var(--ok)}.stale{border-left:4px solid var(--bad)}.wait{opacity:.8}
.ok{color:var(--ok)}.bad{color:var(--bad)}.warn{color:var(--warn)}
table{width:100%;border-collapse:collapse;background:var(--card);border:1px solid var(--line);border-radius:10px;overflow:hidden}
th,td{text-align:left;padding:7px 10px;border-bottom:1px solid var(--line);vertical-align:top;font-size:14px}th{color:var(--muted);font-weight:600}
.scroll{overflow-x:auto}a{color:var(--accent);text-decoration:none}a:hover{text-decoration:underline}
details summary{cursor:pointer;color:var(--muted)}
"""


def render_html(tasks, hrs, cps, sessions, check, a) -> str:
    e = html.escape
    def link(path, label):
        return f'<a href="../{e(path)}">{e(label)}</a>'
    def task_card(t):
        cls = "task" + (" ready" if t["ready"] else "") + (" stale" if t["stale"] else "") + ("" if t["ready"] or t.get("status") != "todo" else " wait")
        chips = [t.get("milestone", ""), t.get("priority", "")]
        if t.get("owner") and t.get("status") != "done":
            chips.append("👤 " + t["owner"])
        if t["stale"]:
            chips.append("stale")
        if not t["deps_done"]:
            chips.append("waits " + ", ".join(t["depends"]))
        if not t["human_done"]:
            chips.append("needs " + ", ".join(t["human"]))
        if t["criteria_total"]:
            chips.append(f"{t['criteria_done']}/{t['criteria_total']} criteria")
        return (f'<div class="{cls}"><b>{e(t["id"])}</b> {link(t["file"], t["title"])}<br>'
                + "".join(f'<span class="chip">{e(c)}</span>' for c in chips if c) + "</div>")
    total = len(tasks)
    done = sum(1 for t in tasks if t.get("status") == "done")
    open_hr = [h for h in hrs if h["status_eff"] not in HR_DONE]
    ready = [t for t in tasks if t["ready"]]
    check_html = '<span class="muted">not run yet</span>'
    if check:
        check_html = (f'<span class="{"ok" if check.get("ok") else "bad"}">{"PASS" if check.get("ok") else "FAIL"}</span>'
                      f'<div class="muted">{e(check.get("time", ""))}</div>')
    H = [f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
         f'<meta http-equiv="refresh" content="60"><title>Project Dashboard</title><style>{CSS}</style></head><body><main>',
         '<h1>Skyline Stack · project dashboard</h1>',
         f'<div class="muted">Generated {a["now"]:%Y-%m-%d %H:%M} UTC from the coordination files. Reloads every 60 s; regenerate with <code>python3 tools/dashboard.py</code>.</div>',
         '<h2>Overview</h2><div class="grid">',
         f'<div class="card"><div class="muted">Checkpoint</div><div class="kpi" style="font-size:18px">{link(cps[0]["file"], cps[0]["title"]) if cps else "none"}</div></div>',
         f'<div class="card"><div class="muted">Tasks done</div><div class="kpi">{done}/{total}</div><div class="bar"><i style="width:{100*done/max(1,total):.0f}%"></i></div></div>',
         f'<div class="card"><div class="muted">Ready to claim</div><div class="kpi">{len(ready)}</div></div>',
         f'<div class="card"><div class="muted">Open human requests</div><div class="kpi">{len(open_hr)}</div><div class="muted">{sum(1 for h in open_hr if h.get("priority","").startswith("P0"))} are P0</div></div>',
         f'<div class="card"><div class="muted">Last check</div><div class="kpi" style="font-size:18px">{check_html}</div></div>',
         '</div><h2>Milestones</h2><div class="grid">']
    for m in sorted(a["milestones"]):
        c = a["milestones"][m]
        tot = sum(c.values())
        H.append(f'<div class="card"><b>{e(m)}</b> {e(MILESTONES.get(m, ""))}<div class="muted">{c["done"]}/{tot} done'
                 f'{" · " + str(c["in-progress"]) + " in progress" if c["in-progress"] else ""}</div>'
                 f'<div class="bar"><i style="width:{100*c["done"]/max(1,tot):.0f}%"></i></div></div>')
    H.append('</div><h2>Board</h2><div class="cols">')
    columns = [("Ready", ready), ("In progress", [t for t in tasks if t.get("status") == "in-progress"]),
               ("Review", [t for t in tasks if t.get("status") == "review"]),
               ("Blocked", [t for t in tasks if t.get("status") == "blocked"])]
    for name, group in columns:
        H.append(f'<div class="card"><b>{name}</b> <span class="muted">({len(group)})</span>'
                 + ("".join(task_card(t) for t in group) or '<div class="muted">none</div>') + "</div>")
    waiting = [t for t in tasks if t.get("status") == "todo" and not t["ready"]]
    H.append('</div>')
    H.append(f'<details><summary>Waiting on dependencies or humans ({len(waiting)})</summary><div class="cols">'
             + "".join(f'<div>{task_card(t)}</div>' for t in waiting) + '</div></details>')
    H.append(f'<h2>Needs a human ({len(open_hr)} open)</h2><div class="muted">Make the file, save it at the exact path, and the dashboard marks it delivered. Full specs: {link("HUMAN_NEEDED.md", "HUMAN_NEEDED.md")}</div><div class="scroll"><table>'
             '<tr><th>ID</th><th>Request</th><th>Type</th><th>Pri</th><th>Files present</th><th>Blocks tasks</th></tr>')
    for h in hrs:
        if h["status_eff"] in HR_DONE:
            continue
        files = f'{h["files_present"]}/{len(h["files_list"])}' if h["files_list"] else "decision/account"
        pri = h.get("priority", "").split()[0] if h.get("priority") else ""
        H.append(f'<tr><td>{e(h["id"])}</td><td>{e(h["title"])}</td><td>{e(h.get("type",""))}</td>'
                 f'<td class="{"bad" if pri == "P0" else ""}">{e(pri)}</td><td>{e(files)}</td><td>{e(", ".join(h["blocks"]) or "-")}</td></tr>')
    H.append('</table></div>')
    done_hr = [h for h in hrs if h["status_eff"] in HR_DONE]
    if done_hr:
        H.append('<p class="muted">Delivered / answered: ' + ", ".join(e(h["id"]) + (" (auto-detected)" if h["auto_delivered"] else "") for h in done_hr) + "</p>")
    H.append('<h2>Recent sessions</h2><div class="card">' + ("<br>".join(link(s["file"], s["title"]) for s in sessions[:8]) or '<span class="muted">none</span>') + '</div>')
    H.append('<h2>Checkpoints</h2><div class="card">' + ("<br>".join(link(c["file"], c["title"]) + f' <span class="muted">{e(c["date"])}</span>' for c in cps) or "none") + '</div>')
    H.append('<h2>Warnings</h2><div class="card">' + ("<br>".join(f'<span class="warn">⚠</span> {e(w)}' for w in a["warnings"]) or '<span class="ok">none</span>') + '</div>')
    H.append(f'<details><summary>Done ({done})</summary><div class="card">' + "<br>".join(f'<b>{e(t["id"])}</b> {e(t["title"])}' for t in tasks if t.get("status") == "done") + '</div></details>')
    H.append('</main></body></html>')
    return "\n".join(H)


def main() -> int:
    tasks = load_tasks()
    hrs = load_human_requests()
    cps = load_docs("checkpoints", "CP-*.md")
    sessions = load_docs("sessions", "*.md")
    check = load_last_check()
    a = analyse(tasks, hrs)
    (COORD / "DASHBOARD.md").write_text(render_md(tasks, hrs, cps, sessions, check, a), encoding="utf-8")
    (COORD / "dashboard.html").write_text(render_html(tasks, hrs, cps, sessions, check, a), encoding="utf-8")
    if "--quiet" not in sys.argv:
        ready = sum(1 for t in tasks if t["ready"])
        print(f"dashboard: {len(tasks)} tasks ({ready} ready), {sum(1 for h in hrs if h['status_eff'] not in HR_DONE)} open human requests, {len(a['warnings'])} warnings")
        for w in a["warnings"]:
            print("  warning:", w)
    return 0


if __name__ == "__main__":
    sys.exit(main())
