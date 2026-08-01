#!/usr/bin/env python3
# =============================================================================
# hyprctl shim for niri.
#
# Installed on PATH as `hyprctl`, `n` and `swww` (same file; behavior selected
# by argv[0]).  It translates the hyprland IPC calls made by the quickshell
# UI into niri msg invocations, so the shell can run unmodified on niri.
#
#   hyprctl monitors -j | activewindow -j | workspaces -j | activeworkspace -j
#   hyprctl devices -j | switchxkblayout main next|prev
#   hyprctl dispatch <dispatcher> <args> | keyword monitor <monitorStr>
#   hyprctl --batch "cmd1 ; cmd2"
#
#   n <niri msg subcommand...>      -> passthrough to `niri msg`
#   swww img/kill/query/daemon      -> swaybg-based wallpaper handling
# =============================================================================
import json
import os
import re
import subprocess
import sys

PROG = os.path.basename(sys.argv[0] or "hyprctl")


def niri(*args, json_out=False):
    cmd = ["niri", "msg"]
    if json_out:
        cmd.append("-j")
    cmd.extend(args)
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return ""
    return r.stdout.strip()


def spawn(*args):
    """Detach a process (used for swaybg)."""
    try:
        subprocess.Popen(
            args,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except Exception:
        pass


# ---------------------------------------------------------------------------
# JSON schema conversions
# ---------------------------------------------------------------------------

TRANSFORM_NIRI2HYPR = {
    "Normal": 0,
    "90": 1,
    "180": 2,
    "270": 3,
    "Flipped": 4,
    "Flipped 90": 5,
    "Flipped 180": 6,
    "Flipped 270": 7,
}

TRANSFORM_HYPR2NIRI = {0: "normal", 1: "90", 2: "180", 3: "270"}


def cmd_monitors():
    data = json.loads(niri("outputs", json_out=True) or "{}")
    focused = ""
    try:
        focused = json.loads(niri("focused-output", json_out=True) or "{}").get("name", "")
    except ValueError:
        pass

    out = []
    for name, m in data.items():
        logical = m.get("logical")
        if logical is None:
            continue  # disabled output
        modes = m.get("modes") or []
        cur = modes[m.get("current_mode") or 0] if modes else {}
        available = [
            "%dx%d@%.2f" % (mo["width"], mo["height"], mo["refresh_rate"] / 1000)
            for mo in modes
        ]
        out.append({
            "id": name,
            "name": name,
            "description": name,
            "make": "",
            "model": "",
            "serial": "",
            "width": cur.get("width", 0),
            "height": cur.get("height", 0),
            "refreshRate": (cur.get("refresh_rate", 0) / 1000) if cur else 0,
            "x": logical["x"],
            "y": logical["y"],
            "activeWorkspace": {"id": None, "name": None},
            "specialWorkspace": {"id": None, "name": None},
            "reserved": [0, 0, 0, 0],
            "scale": logical["scale"],
            "transform": TRANSFORM_NIRI2HYPR.get(logical["transform"], 0),
            "focused": name == focused,
            "dpmsStatus": 1,
            "availableModes": available,
        })
    print(json.dumps(out))


def cmd_activewindow():
    d = json.loads(niri("focused-window", json_out=True) or "{}")
    if not d:
        print("{}")
        return
    ws = {}
    for w in json.loads(niri("workspaces", json_out=True) or "[]"):
        if w["id"] == d.get("workspace_id"):
            ws = {"id": w["id"], "name": w["name"], "monitor": w["output"]}
            break
    print(json.dumps({
        "address": str(d["id"]),
        "mapped": True,
        "hidden": False,
        "at": [0, 0],
        "size": [0, 0],
        "workspace": ws,
        "floating": d.get("is_floating", False),
        "pseudo": False,
        "monitor": ws.get("monitor", ""),
        "class": d.get("app_id", ""),
        "initialClass": d.get("app_id", ""),
        "title": d.get("title", ""),
        "initialTitle": d.get("title", ""),
        "pid": d.get("pid", 0),
        "xwayland": False,
        "fullscreen": False,
        "fullscreenClient": 0,
        "grouped": [],
        "tags": [],
        "swallowing": "",
        "focusHistoryID": 0,
    }))


def cmd_workspaces():
    ws = json.loads(niri("workspaces", json_out=True) or "[]")
    wins = json.loads(niri("windows", json_out=True) or "[]")
    by_ws = {}
    for w in wins:
        by_ws.setdefault(w["workspace_id"], []).append(w)

    def ts(w):
        t = w.get("focus_timestamp") or {}
        return (t.get("secs", 0), t.get("nanos", 0))

    out = []
    for w in ws:
        wl = by_ws.get(w["id"], [])
        last = max(wl, key=ts) if wl else None
        out.append({
            "id": w["id"],
            "name": w["name"] or str(w["idx"]),
            "monitor": w["output"],
            "monitorID": 0,
            "windows": len(wl),
            "hasfullscreen": False,
            "lastwindow": last["id"] if last else None,
            "lastwindowtitle": (last or {}).get("title", ""),
            "lastwindowclass": (last or {}).get("app_id", ""),
            "lastfloatingwindow": None,
            "lastfloatingwindowtitle": "",
            "mapped": True,
            "hidden": False,
            "isfullscreen": False,
        })
    print(json.dumps(out))


def cmd_activeworkspace():
    for w in json.loads(niri("workspaces", json_out=True) or "[]"):
        if w.get("is_active"):
            print(json.dumps({"id": w["id"], "name": w.get("name"), "monitor": w["output"]}))
            return
    print("{}")


def cmd_devices():
    d = json.loads(niri("keyboard-layouts", json_out=True) or "{}")
    names = d.get("names", [])
    idx = d.get("current_idx", 0)
    active = names[idx] if names else ""
    print(json.dumps({
        "keyboards": [{
            "main": True,
            "active_keymap": active,
            "active_keymap_code": active,
        }],
        "mice": [],
        "tablets": [],
        "touch": [],
        "switches": [],
    }))


def cmd_switchxkblayout(args):
    direction = "next"
    if args and args[-1] in ("next", "prev"):
        direction = args[-1]
    niri("action", "switch-layout", direction)


def cmd_keyword_monitor(monitor_str):
    """Translate `keyword monitor name,WxH@R,XxY,scale[,transform,N]`.

    The shell always emits the fields in this fixed order, so we parse by
    index instead of trying to disambiguate WxH modes from XxY positions.
    """
    parts = [p.strip() for p in monitor_str.split(",")]
    if not parts or not parts[0] or parts[0] == "monitor":
        return

    name = parts[0]
    mode = parts[1] if len(parts) > 1 and parts[1] else "auto"
    pos = parts[2] if len(parts) > 2 and parts[2] else "0x0"
    scale = parts[3] if len(parts) > 3 and parts[3] else "1"
    transform = 0
    if len(parts) > 4 and parts[4].lower() == "transform" and len(parts) > 5 and parts[5].isdigit():
        transform = int(parts[5])

    niri("output", name, "mode", mode)
    x, y = pos.split("x") if "x" in pos else ("0", "0")
    niri("output", name, "position", "set", x, y)
    niri("output", name, "scale", scale)
    if transform != 0 and transform in TRANSFORM_HYPR2NIRI:
        niri("output", name, "transform", TRANSFORM_HYPR2NIRI[transform])


DISPATCHER_MAP = {
    "movefocus": {
        "l": "focus-column-left",
        "r": "focus-column-right",
        "u": "focus-window-up",
        "d": "focus-window-down",
    },
    "movewindow": {
        "l": "move-column-left",
        "r": "move-column-right",
        "u": "move-window-up",
        "d": "move-window-down",
    },
    "killactive": None,       # -> close-window
    "togglefloating": None,   # -> toggle-window-floating
    "exit": None,             # -> quit
    "workspace": "focus-workspace",
    "movetoworkspace": "move-column-to-workspace",
}


def cmd_dispatch(args, depth=0):
    if depth > 3 or not args:
        print("Invalid dispatcher", file=sys.stderr)
        return 1
    disp = args[0]
    rest = args[1:]

    if disp in ("exec", "exec-once"):
        # hyprctl dispatch exec [--] <command...>
        # niri's spawn-sh takes a single shell command, so rebuild the argv.
        if rest and rest[0] == "--":
            rest = rest[1:]
        niri("action", "spawn-sh", "--", " ".join(rest))
        return 0

    if disp == "dispatch":
        return cmd_dispatch(rest, depth + 1)

    if disp == "submap":
        return 0  # niri has no submaps; keybind-capture UI expects a no-op

    if disp == "killactive":
        niri("action", "close-window")
        return 0

    if disp == "togglefloating":
        niri("action", "toggle-window-floating")
        return 0

    if disp == "exit":
        niri("action", "quit")
        return 0

    if disp in DISPATCHER_MAP:
        target = DISPATCHER_MAP[disp]
        if isinstance(target, dict):
            if not rest or rest[0] not in target:
                print("Invalid dispatcher argument", file=sys.stderr)
                return 1
            niri("action", target[rest[0]])
        else:
            niri("action", target, *rest)
        return 0

    if disp == "resizeactive":
        # niri has no direct equivalent; warn quietly.
        print("resizeactive: no niri equivalent, ignored", file=sys.stderr)
        return 0

    print(f"Invalid dispatcher: {disp}", file=sys.stderr)
    return 1


def cmd_batch(expr):
    """hyprctl --batch 'cmd1 ; cmd2'."""
    for chunk in expr.split(";"):
        chunk = chunk.strip()
        if not chunk:
            continue
        parts = chunk.split()
        if not parts:
            continue
        verb = parts[0]
        if verb == "dispatch":
            cmd_dispatch(parts[1:])
        elif verb == "keyword":
            if len(parts) >= 3 and parts[1] == "monitor":
                cmd_keyword_monitor(" ".join(parts[2:]))
        else:
            print(f"hyprctl: unknown batch command: {chunk}", file=sys.stderr)


# ---------------------------------------------------------------------------
# swww -> swaybg shim
# ---------------------------------------------------------------------------

def swww(args):
    if not args:
        return
    sub = args[0]
    if sub == "kill":
        subprocess.run(["pkill", "-x", "swaybg"], capture_output=True)
        return
    if sub == "daemon":
        return  # no daemon needed; swaybg is one-shot
    if sub == "query":
        return
    if sub == "img":
        path = None
        outputs = []
        rest = []
        i = 1
        while i < len(args):
            a = args[i]
            if a in ("-o", "--outputs") and i + 1 < len(args):
                outputs.extend(args[i + 1].split(","))
                i += 2
                continue
            if a.startswith("--") and a != "--outputs":
                i += 2 if i + 1 < len(args) and not args[i + 1].startswith("-") else 1
                continue
            if not a.startswith("-") and path is None:
                path = a
            else:
                rest.append(a)
            i += 1
        if not path:
            print("swww img: no image path", file=sys.stderr)
            return
        subprocess.run(["pkill", "-x", "swaybg"], capture_output=True)
        bg = ["swaybg", "-m", "fill", "-i", path]
        for o in outputs:
            bg += ["-o", o]
        spawn(*bg)
        return
    print(f"swww: unhandled subcommand '{sub}'", file=sys.stderr)


# ---------------------------------------------------------------------------
# dispatch
# ---------------------------------------------------------------------------

def main(argv):
    if PROG == "swww-daemon":
        return 0  # no wallpaper daemon needed; swaybg is one-shot

    if PROG == "swww":
        swww(argv)
        return 0

    if PROG == "n":
        # passthrough to niri msg
        r = subprocess.run(["niri", "msg", *argv])
        return r.returncode

    # hyprctl
    if not argv:
        print("usage: hyprctl <subcommand>")
        return 1

    cmd = argv[0]
    args = argv[1:]

    if cmd == "--batch":
        cmd_batch(" ".join(args))
        return 0

    if cmd == "monitors":
        cmd_monitors()
        return 0

    if cmd == "activewindow":
        cmd_activewindow()
        return 0

    if cmd == "workspaces":
        cmd_workspaces()
        return 0

    if cmd == "activeworkspace":
        cmd_activeworkspace()
        return 0

    if cmd == "devices":
        cmd_devices()
        return 0

    if cmd == "switchxkblayout":
        cmd_switchxkblayout(args)
        return 0

    if cmd == "keyword":
        if len(args) >= 2 and args[0] == "monitor":
            cmd_keyword_monitor(" ".join(args[1:]))
        return 0

    if cmd == "dispatch":
        return cmd_dispatch(args)

    print(f"hyprctl: unhandled subcommand '{cmd}'", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
