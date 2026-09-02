#!/usr/bin/env python3
"""Escproxy dev-session layout bootstrap.

Idempotent: keeps the dev session's first two workspaces in shape and ensures
each managed slot tab (opencode / goose / crush / nvim) is actually running
its command. Agent-workspace tabs are then relabeled (opencode / goose /
crush).

Layout for the Agents workspace:
  * opencode -- own tab, with the Agent Office attached as a horizontal
    (down) split pane beneath the opencode pane.
  * goose   -- own tab, single pane.
  * crush   -- own tab, single pane.

The Agent Office lives permanently under the opencode tab. Switching focus to
goose or crush and rerunning `apply` does not move the office. The goose and
crush tabs are always plain single-pane tabs.

Per slot, per run:
  - recorded tab still exists in the right workspace
      - a foreground process matches the slot                -> leave it
      - only interactive-shell foreground processes, or none
        (native agent session resume may still be in flight, so the opencode
        slot gets a short poll first)                        -> restored shell:
                                                              close and reopen
      - a live foreign process (resumed agent or user
        command)                                             -> leave it alone
  - tab missing                                              -> open fresh

In the STARTUP context only (i.e. just after a server restart, when every
non-resumed pane is an empty restored shell), any extra tab in the managed
workspaces whose panes are only shells is closed, leaving each managed
workspace shaped exactly as declared. The manual apply action never touches
anything but the three slots and the office.

Workspaces outside the managed two are never touched.

Talks to herdr exclusively through the HERDR_BIN_PATH CLI.
"""

import json
import os
import subprocess
import sys
import time

PLUGIN = "escproxy.dev-layout"
REPO = "/home/escproxy/opencode"
SLOTS = ["opencode", "goose", "crush", "nvim"]
SLOT_CMD = {
    "opencode": "opencode",
    "goose": "goose",
    "crush": "crush",
    "nvim": "nvim",
}
# Tabs in the Agents workspace are relabeled to these after reconciliation.
# The office is not a separate tab -- it lives as a split pane inside the
# opencode tab -- so it has no entry here.
SLOT_LABEL = {"opencode": "opencode", "goose": "goose", "crush": "crush"}
# Slot that hosts the Agent Office split AND the tab the user lands on after
# a successful apply. Constant: the office always lives under opencode.
OFFICE_HOST_SLOT = "opencode"
OFFICE_PANE_LABEL = "Agent Office"
# The Agent Office pane is owned by the herdr-agent-office plugin; dev-layout
# never creates the office command itself -- it only opens a plugin pane that
# herdr-agent-office claims via its own manifest.
OFFICE_PLUGIN = "herdr-agent-office"
OFFICE_ENTRYPOINT = "office"
SHELLS = {"bash", "zsh", "sh", "dash", "fish", "ksh", "tcsh", "-bash", "-sh"}
# starship renders the prompt synchronously inside the shell, so process
# snapshots during a prompt draw catch it as a foreground process. It is
# prompt machinery, not a program -- treat it as part of the idle shell.
IDLE_EXTRA = {"starship"}
IDLE_NAMES = SHELLS | IDLE_EXTRA
RESUME_POLL_S = 3.0
STATE_BASENAME = "layout.json"

HERDR_BIN = os.environ.get("HERDR_BIN_PATH") or "herdr"


def log(msg):
    print("dev-layout: %s" % msg, flush=True)


def cli(*args, check=True):
    r = subprocess.run([HERDR_BIN, *args], capture_output=True, text=True)
    if check and r.returncode != 0:
        raise SystemExit(
            "dev-layout: `herdr %s` failed: %s"
            % (" ".join(args), (r.stderr.strip() or r.stdout.strip()))
        )
    return r.stdout


def j(*args):
    return json.loads(cli(*args))["result"]


def state_path():
    d = os.environ.get("HERDR_PLUGIN_STATE_DIR") or ""
    return os.path.join(d, STATE_BASENAME) if d else ""


def load_state():
    p = state_path()
    if p and os.path.exists(p):
        try:
            with open(p) as fh:
                data = json.load(fh)
            if isinstance(data, dict) and "panes" in data:
                return data
        except (OSError, ValueError):
            pass
    return {"panes": {}}


def save_state(state):
    p = state_path()
    if not p:
        return
    try:
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p + ".tmp", "w") as fh:
            json.dump(state, fh, indent=2, sort_keys=True)
        os.replace(p + ".tmp", p)
    except OSError as exc:
        log("could not write state: %s" % exc)


def get_label(ws_id):
    for w in j("workspace", "list")["workspaces"]:
        if w["workspace_id"] == ws_id:
            return w.get("label") or ""
    return ""


def rename_if_needed(ws_id, label):
    if get_label(ws_id) != label:
        cli("workspace", "rename", ws_id, label)


def resolve_workspaces():
    wss = j("workspace", "list")["workspaces"]
    by_label = {w.get("label"): w for w in wss}
    agents = by_label.get("Agents")
    editor = by_label.get("Editor")

    if agents is None:
        if wss:
            agents = sorted(wss, key=lambda w: w.get("number") or 0)[0]
        if agents is None:
            agents = j("workspace", "create", "--label", "Agents",
                       "--cwd", REPO)["workspace"]
    rename_if_needed(agents["workspace_id"], "Agents")

    if editor is None:
        others = [w for w in j("workspace", "list")["workspaces"]
                  if w["workspace_id"] != agents["workspace_id"]]
        if others:
            editor = sorted(others, key=lambda w: w.get("number") or 0)[0]
        if editor is None:
            editor = j("workspace", "create", "--label", "Editor",
                       "--cwd", REPO)["workspace"]
    rename_if_needed(editor["workspace_id"], "Editor")

    return agents["workspace_id"], editor["workspace_id"]


def tabs():
    return j("tab", "list")["tabs"]


def panes():
    return j("pane", "list")["panes"]


def tab_exists(tab_id, ws_id):
    return any(t["tab_id"] == tab_id and t["workspace_id"] == ws_id
               for t in tabs())


def foreground_procs(pane_id):
    try:
        pi = j("pane", "process-info", "--pane", pane_id)["process_info"]
    except SystemExit:
        return []
    out = []
    for p in pi.get("foreground_processes") or []:
        argv = p.get("argv") or []
        name = (argv[0] if argv else p.get("name", "")).split("/")[-1]
        if name.startswith("--name="):
            pass
        out.append({"name": name, "cmdline": p.get("cmdline", "")})
    return out


def is_idle_shell(procs):
    return bool(procs) and all(p["name"] in IDLE_NAMES for p in procs)


def is_bare_shell(pane_id):
    """True when `pane_id` holds only the shell herdr restored it with.

    Mirrors the agent-office plugin's reclaimable_frame(): a single foreground
    process that *is* the pane's own shell and is not an exec'd office. The
    office pane runs `bash -lc 'cd <plugin> && exec python3 -m office run'`, so
    once running its foreground pid equals the shell pid -- that is NOT a bare
    shell (reclaiming it would kill a live office), so any non-shell foreground
    (or a possessed office command) is excluded.
    """
    try:
        pi = j("pane", "process-info", "--pane", pane_id)["process_info"]
    except SystemExit:
        return False
    procs = pi.get("foreground_processes") or []
    if len(procs) != 1:
        return False
    shell_pid = pi.get("shell_pid")
    if shell_pid is None or procs[0].get("pid") != shell_pid:
        return False
    argv = procs[0].get("argv") or [procs[0].get("name", "")]
    argv0 = (argv[0] or "").split("/")[-1]
    # A live office `exec`s python as the shell pid; don't treat it as bare.
    return argv0 in SHELLS


def open_slot(entrypoint, ws_id):
    out = j(
        "plugin", "pane", "open",
        "--plugin", PLUGIN,
        "--entrypoint", entrypoint,
        "--placement", "tab",
        "--workspace", ws_id,
        "--cwd", REPO,
        "--no-focus",
    )
    pane = out["plugin_pane"]["pane"]
    return {
        "pane": pane["pane_id"],
        "tab": pane["tab_id"],
        "ws": pane["workspace_id"],
    }


def find_running_slot(expected, ws_id):
    """Return the slot-shaped pane running `expected` in ws_id, if any."""
    for p in panes():
        if p["workspace_id"] != ws_id:
            continue
        if any(expected in x["cmdline"] for x in
               foreground_procs(p["pane_id"])):
            return {"pane": p["pane_id"], "tab": p["tab_id"], "ws": ws_id}
    return None


def reconcile_slot(slot, ws_id, state):
    expected = SLOT_CMD[slot]
    rec = state["panes"].get(slot)

    # Adopt a live slot before trusting (or distrusting) the rec tab -- the
    # recorded tab can be stale (server restart, manual close), and blindly
    # reopening would spawn a duplicate alongside the surviving process.
    running = find_running_slot(expected, ws_id)
    if running:
        if rec and rec.get("tab") == running["tab"]:
            log("%s: already running (%s)" % (slot, running["pane"]))
            return rec
        log("%s: adopted existing %s (%s)"
            % (slot, running["pane"], running["tab"]))
        return running

    if rec and tab_exists(rec.get("tab", ""), ws_id):
        procs = foreground_procs(rec["pane"])
        if not procs and slot == "opencode" and rec.get("tab"):
            deadline = time.monotonic() + RESUME_POLL_S
            while time.monotonic() < deadline and not procs:
                time.sleep(0.4)
                procs = foreground_procs(rec["pane"])
        if is_idle_shell(procs) or not procs:
            log("%s: restored shell in %s, reopening" % (slot, rec["tab"]))
            cli("tab", "close", rec["tab"])
        else:
            log("%s: foreign process present (%s); leaving it"
                % (slot, json.dumps(procs)))
            ps = [p for p in panes() if p["tab_id"] == rec["tab"]]
            cur = ps[0] if ps else None
            if cur:
                return {"pane": cur["pane_id"], "tab": cur["tab_id"],
                        "ws": ws_id}
    log("%s: opening into %s" % (slot, ws_id))
    new = open_slot(slot, ws_id)
    log("%s: opened %s (%s)" % (slot, new["pane"], new["tab"]))
    return new


def cleanup_stale_tabs(managed_ws, kept_tabs):
    """Startup context only: close restored-shell tabs in managed workspaces.

    The Agent Office frame (label `Agent Office`) is exempt: the
    `herdr-agent-office` startup hook runs concurrently and needs the frame
    to reclaim. `place_office` runs after this and either adopts the
    reclaimed office (if it landed under the opencode tab) or moves it
    there.
    """
    ps = panes()
    for t in tabs():
        if t["workspace_id"] not in managed_ws:
            continue
        if t["tab_id"] in kept_tabs:
            continue
        if any((p.get("label") or "") == OFFICE_PANE_LABEL
               for p in ps if p["tab_id"] == t["tab_id"]):
            continue
        procs = [p for pane in ps if pane["tab_id"] == t["tab_id"]
                 for p in foreground_procs(pane["pane_id"])]
        if not procs or is_idle_shell(procs):
            log("closing stale tab %s (%s)" % (t["tab_id"], t.get("label")))
            cli("tab", "close", t["tab_id"])


def office_panes(agents_ws):
    """All panes in `agents_ws` whose label is the Agent Office frame.

    Includes both stand-alone office tabs and office split panes (which sit
    inside the opencode tab but still carry the `Agent Office` label).
    """
    out = []
    for p in panes():
        if p["workspace_id"] != agents_ws:
            continue
        if (p.get("label") or "") == OFFICE_PANE_LABEL:
            out.append(p)
    return out


def office_in_tab(agent_rec):
    """Return the office pane sitting inside `agent_rec`'s tab, if any."""
    for p in panes():
        if p["tab_id"] == agent_rec.get("tab"):
            if (p.get("label") or "") == OFFICE_PANE_LABEL:
                return p
    return None


def open_office_split(agents_ws, target_pane, target_tab):
    """Open the Agent Office under `target_pane` in `target_tab` as a down split.

    Workaround for a herdr 0.8.2 bug: `plugin.pane.open` with
    `placement=split --target-pane` rejects every variant of the target field
    with `use target_pane_id`, but the server also rejects requests that name
    `target_pane_id`. So the placement=split route is broken at the API.

    Instead, open the office as its own tab (the only placement that works
    end-to-end) and immediately move it into the host tab as a down split
    via `pane.move`. The intermediate tab is auto-closed by the move when its
    only pane is the one being moved; if not, the leftover tab is closed in
    `place_office` before the next attempt.
    """
    open_out = j(
        "plugin", "pane", "open",
        "--plugin", OFFICE_PLUGIN,
        "--entrypoint", OFFICE_ENTRYPOINT,
        "--placement", "tab",
        "--workspace", agents_ws,
        "--no-focus",
    )
    pane = open_out["plugin_pane"]["pane"]
    office_pane = pane["pane_id"]
    office_tab = pane["tab_id"]
    log("office: opened as tab %s (%s); moving into %s as down split"
        % (office_pane, office_tab, target_pane))

    try:
        move_out = j(
            "pane", "move", office_pane,
            "--tab", target_tab,
            "--split", "down",
            "--target-pane", target_pane,
            "--no-focus",
        )
    except SystemExit as exc:
        # The move failed -- close the now-orphaned office tab and re-raise.
        try:
            cli("pane", "close", office_pane)
        except SystemExit:
            pass
        raise SystemExit("office: pane.move into %s failed: %s"
                         % (target_pane, exc))

    moved = move_out.get("pane") or move_out.get("move_result", {}).get("pane", {})
    return {"pane": moved.get("pane_id", office_pane),
            "tab": moved.get("tab_id", target_tab),
            "parent_pane": target_pane}


def close_office_pane(pane):
    """Close a single office pane. The office command exits when the shell
    holding it is closed (issue #39's measurement)."""
    try:
        cli("pane", "close", pane["pane_id"])
        log("office: closed stale split %s" % pane["pane_id"])
    except SystemExit:
        # A pane the agent-office plugin also tried to close races here --
        # `pane.close` on a missing pane raises. Treat as already gone.
        pass


def place_office(agents_ws, host_rec, state, poll_s=2.0):
    """Make sure exactly one Agent Office split exists, under `host_rec`'s tab.

    The office is a single global plugin pane owned by herdr-agent-office.
    herdr 0.8.2 cannot open a plugin pane with `placement=split --target-pane`
    (server rejects every variant of the target field), so the office is
    opened as its own tab and immediately moved into the host tab with
    `pane.move --split down --target-pane`. The move closes the source tab
    when its only pane is the one being moved.

    The host is fixed: it is always the opencode tab. If the office already
    lives as a split under the opencode tab, the call is a no-op. If the
    office is a stand-alone tab in the Agents workspace (legacy layout) or
    lives as a split under a different agent tab, the existing office is
    moved into the opencode tab instead of being closed and reopened --
    this preserves the running office process and avoids the
    `herdr-agent-office` startup hook race on a closed shell frame.
    """
    host_pane = host_rec.get("pane")
    host_tab = host_rec.get("tab")

    def move_existing_to_host(pane, from_tab):
        try:
            move_out = j(
                "pane", "move", pane,
                "--tab", host_tab,
                "--split", "down",
                "--target-pane", host_pane,
                "--no-focus",
            )
        except SystemExit as exc:
            log("office: move of %s into %s failed: %s"
                % (pane, host_pane, exc))
            return None
        moved = move_out.get("pane") or move_out.get("move_result", {}).get(
            "pane", {})
        new_pane = moved.get("pane_id", pane)
        new_tab = moved.get("tab_id", host_tab)
        log("office: moved %s (was in %s) into %s as down split -> %s (%s)"
            % (pane, from_tab, host_pane, new_pane, new_tab))
        return {"pane": new_pane, "tab": new_tab, "parent_pane": host_pane}

    # 1. If the office is already a live split under the opencode tab, do
    #    nothing.
    existing = office_in_tab(host_rec)
    if existing and not is_bare_shell(existing["pane_id"]):
        log("office: already split under %s (%s); leaving it"
            % (OFFICE_HOST_SLOT, existing["pane_id"]))
        return {"pane": existing["pane_id"], "tab": existing["tab_id"],
                "parent_pane": host_pane}

    # 2. If the office exists anywhere else in the Agents workspace (stand-
    #    alone tab or split under a different agent), move it under the
    #    opencode tab.
    others = [p for p in office_panes(agents_ws)
              if not existing or p["pane_id"] != existing["pane_id"]]
    if others:
        target = others[0]
        if is_bare_shell(target["pane_id"]):
            # Bare-shell frame: the herdr-agent-office startup hook may be
            # about to reclaim it. Poll briefly to give it a chance; if it
            # does not, take over by closing it and opening fresh.
            deadline = time.monotonic() + poll_s
            claimed = False
            while time.monotonic() < deadline:
                cur = next((p for p in office_panes(agents_ws)
                            if p["pane_id"] == target["pane_id"]), None)
                if cur is None:
                    claimed = True
                    break
                if not is_bare_shell(cur["pane_id"]):
                    claimed = True
                    break
                time.sleep(0.25)
            if not claimed:
                close_office_pane(target)
            else:
                return move_existing_to_host(target["pane_id"], target["tab_id"])
        else:
            return move_existing_to_host(target["pane_id"], target["tab_id"])

    # 3. If `existing` is a bare shell under the opencode tab, the office
    #    command never came up -- wait briefly for the agent-office hook to
    #    reclaim it, otherwise close and reopen under the host.
    if existing and is_bare_shell(existing["pane_id"]):
        deadline = time.monotonic() + poll_s
        claimed = False
        while time.monotonic() < deadline:
            cur = next((p for p in office_panes(agents_ws)
                        if p["pane_id"] == existing["pane_id"]), None)
            if cur is None:
                claimed = True
                break
            if not is_bare_shell(cur["pane_id"]):
                claimed = True
                break
            time.sleep(0.25)
        if claimed:
            log("office: agent-office hook reclaimed %s; leaving it"
                % existing["pane_id"])
            return {"pane": existing["pane_id"], "tab": existing["tab_id"],
                    "parent_pane": host_pane}
        close_office_pane(existing)

    # 4. No live office anywhere in the Agents workspace -- open fresh.
    return open_office_split(agents_ws, host_pane, host_tab)


def relabel_tabs(updated, agents_ws):
    """Agents-workspace agent tabs get their declared labels after the office
    has been placed (the opencode tab keeps its label; the office is a pane
    inside it, not its own tab)."""
    for slot, label in SLOT_LABEL.items():
        rec = updated.get(slot)
        if rec and tab_exists(rec.get("tab", ""), agents_ws):
            cli("tab", "rename", rec["tab"], label)
            log("%s: tab relabeled to %s" % (slot, label))


def main():
    log("event=%s action=%s"
        % (os.environ.get("HERDR_PLUGIN_EVENT"), os.environ.get("HERDR_PLUGIN_ACTION_ID")))
    state = load_state()
    agents_ws, editor_ws = resolve_workspaces()
    log("managed workspaces: agents=%s editor=%s" % (agents_ws, editor_ws))

    updated = {}
    updated["opencode"] = reconcile_slot("opencode", agents_ws, state)
    updated["goose"] = reconcile_slot("goose", agents_ws, state)
    updated["crush"] = reconcile_slot("crush", agents_ws, state)
    updated["nvim"] = reconcile_slot("nvim", editor_ws, state)
    state["panes"].update(updated)

    kept = {r["tab"] for r in updated.values()}
    if os.environ.get("HERDR_PLUGIN_EVENT") == "startup":
        cleanup_stale_tabs({agents_ws, editor_ws}, kept)

    host_rec = updated.get(OFFICE_HOST_SLOT)
    log("office host: slot=%s tab=%s pane=%s"
        % (OFFICE_HOST_SLOT, host_rec.get("tab"), host_rec.get("pane")))
    office = place_office(agents_ws, host_rec, state)
    if office:
        state["office"] = {
            "pane": office["pane"],
            "tab": office["tab"],
            "parent_pane": office.get("parent_pane") or host_rec["pane"],
            "parent_slot": OFFICE_HOST_SLOT,
        }
    save_state(state)

    relabel_tabs(updated, agents_ws)

    # Land the user on the opencode tab so the Agent Office split is
    # visible after the layout operation completes.
    if host_rec and tab_exists(host_rec["tab"], agents_ws):
        try:
            cli("workspace", "focus", agents_ws)
            cli("tab", "focus", host_rec["tab"])
        except SystemExit:
            pass

    log("done")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        log("ERROR: %s" % exc)
        sys.exit(1)
