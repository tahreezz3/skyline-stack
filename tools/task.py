#!/usr/bin/env python3
"""Update a task file's frontmatter and log without hand-editing.

  python3 tools/task.py claim  T-0203 --owner opus55-a7k2
  python3 tools/task.py status T-0203 review --owner opus55-a7k2 --note "waiting on HR-0017"
  python3 tools/task.py done   T-0203 --owner opus55-a7k2 --note "progression.gd + 6 tests"
  python3 tools/task.py log    T-0203 "found an edge case" --owner opus55-a7k2
  python3 tools/task.py tick   T-0203          # tick every acceptance checkbox

Refuses to claim a task someone else holds unless --force (stale takeover; see AGENTS.md).
"""
import argparse
import datetime as dt
import re
import sys
from pathlib import Path

TASKS = Path(__file__).resolve().parent.parent / "coordination" / "tasks"


def find(tid: str) -> Path:
    hits = list(TASKS.glob(f"{tid}-*.md"))
    if len(hits) != 1:
        sys.exit(f"task {tid}: found {len(hits)} files")
    return hits[0]


def set_field(text: str, key: str, value: str) -> str:
    return re.sub(rf"^{key}:.*$", f"{key}: {value}", text, count=1, flags=re.M)


def get_field(text: str, key: str) -> str:
    m = re.search(rf"^{key}:\s*(.*)$", text, re.M)
    return m.group(1).strip().strip('"') if m else ""


def add_log(text: str, line: str) -> str:
    return text.rstrip("\n") + f"\n- {line}\n"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("action", choices=["claim", "status", "done", "log", "tick"])
    ap.add_argument("task")
    ap.add_argument("arg", nargs="?", default="")
    ap.add_argument("--owner", default="unknown")
    ap.add_argument("--note", default="")
    ap.add_argument("--force", action="store_true")
    a = ap.parse_args()

    path = find(a.task)
    text = path.read_text(encoding="utf-8")
    now = dt.datetime.now().strftime("%Y-%m-%dT%H:%M")
    today = dt.date.today().isoformat()

    if a.action == "claim":
        holder = get_field(text, "owner")
        status = get_field(text, "status")
        if status == "in-progress" and holder and holder != a.owner and not a.force:
            sys.exit(f"{a.task} is held by {holder}; use --force only for a stale takeover")
        text = set_field(text, "status", "in-progress")
        text = set_field(text, "owner", f'"{a.owner}"')
        text = set_field(text, "claimed", f'"{now}"')
        text = add_log(text, f"{today} claimed by {a.owner}" + (f": {a.note}" if a.note else ""))
    elif a.action in ("status", "done"):
        new = "done" if a.action == "done" else a.arg
        if new not in ("todo", "in-progress", "review", "done", "blocked"):
            sys.exit("status must be todo | in-progress | review | done | blocked")
        text = set_field(text, "status", new)
        text = add_log(text, f"{today} {new} by {a.owner}" + (f": {a.note}" if a.note else ""))
    elif a.action == "log":
        text = add_log(text, f"{today} {a.owner}: {a.arg}")
    elif a.action == "tick":
        text = re.sub(r"^- \[ \]", "- [x]", text, flags=re.M)
    text = set_field(text, "updated", today)
    path.write_text(text, encoding="utf-8")
    print(f"{a.task}: {a.action} ok")


if __name__ == "__main__":
    main()
