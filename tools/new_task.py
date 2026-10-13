#!/usr/bin/env python3
"""Create a task file with the next free id in a milestone's range (M1 -> T-01xx).

Usage: python3 tools/new_task.py --title "Add wind gusts" --milestone M1 [--priority P2] [--depends T-0101,T-0105] [--human HR-0005]
"""
import argparse
import datetime as dt
import re
from pathlib import Path

TASKS = Path(__file__).resolve().parent.parent / "coordination" / "tasks"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--title", required=True)
    ap.add_argument("--milestone", required=True, help="M0..M6")
    ap.add_argument("--priority", default="P2")
    ap.add_argument("--depends", default="")
    ap.add_argument("--human", default="")
    ap.add_argument("--goal", default="TODO: describe the goal.")
    ap.add_argument("--author", default="unknown")
    a = ap.parse_args()

    m = int(a.milestone.lstrip("Mm"))
    used = {int(p.name[2:6]) for p in TASKS.glob("T-*.md")}
    n = next(i for i in range(m * 100 + 1, m * 100 + 100) if i not in used)
    tid = f"T-{n:04d}"
    slug = re.sub(r"[^a-z0-9]+", "-", a.title.lower()).strip("-")[:40]
    today = dt.date.today().isoformat()
    path = TASKS / f"{tid}-{slug}.md"
    deps = ", ".join(x.strip() for x in a.depends.split(",") if x.strip())
    hum = ", ".join(x.strip() for x in a.human.split(",") if x.strip())
    path.write_text(f"""---
id: {tid}
title: {a.title}
milestone: M{m}
status: todo
priority: {a.priority}
owner: ""
claimed: ""
depends: [{deps}]
human: [{hum}]
updated: {today}
---
# {tid} · {a.title}

## Goal
{a.goal}

## Context and references
-

## Acceptance criteria
- [ ] TODO
- [ ] `tools/check.sh` passes; docs updated; session log written

## Notes

## Log
- {today} created by {a.author}
""", encoding="utf-8")
    print(path.relative_to(TASKS.parent.parent))


if __name__ == "__main__":
    main()
