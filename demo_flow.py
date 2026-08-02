"""
THRESHOLD — Local demo flow.

Demonstrates the full lifecycle:
  start → messages → relationship changes → end → observer/progression → report

Run with: python demo_flow.py

Starts a real uvicorn server on localhost:18765 in a background thread so that
aiosqlite's greenlet requirements are fully satisfied inside the ASGI worker.
"""
from __future__ import annotations

import json
import sys
import socket
import threading
import time
from pathlib import Path

import requests
import uvicorn

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent))

PLAYER_ID = "demo_player_01"
NPC_ID = "sara"  # friend archetype
HOST = "127.0.0.1"
PORT = 18765
BASE_URL = f"http://{HOST}:{PORT}"

# Messages designed to produce varied scores and trigger the Observer pattern
# (avoiding emotional acknowledgment multiple times)
DEMO_MESSAGES = [
    "I've just been really busy with work, sorry.",
    "Look, I don't know what you want me to say. I was busy.",
    "I get that you're upset, but things come up sometimes.",
    "I understand you missed me. I'll try to be more present.",
    "Can we just move past this? I said I was sorry.",
    "You're right. I should have checked in. I was wrong to disappear like that.",
]


# ── Server lifecycle ───────────────────────────────────────────────────────────

def _wait_for_port(host: str, port: int, timeout: float = 15.0) -> bool:
    """Poll until the TCP port accepts connections or timeout expires."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with socket.create_connection((host, port), timeout=0.5):
                return True
        except OSError:
            time.sleep(0.1)
    return False


def _start_server() -> threading.Thread:
    """Start uvicorn in a daemon thread; returns after server is ready."""
    from src.main import app  # import here so sys.path is already patched

    config = uvicorn.Config(
        app,
        host=HOST,
        port=PORT,
        log_level="warning",   # keep demo output clean
        loop="asyncio",
    )
    server = uvicorn.Server(config)

    t = threading.Thread(target=server.run, daemon=True)
    t.start()

    if not _wait_for_port(HOST, PORT):
        print("ERROR: uvicorn did not start within 15 s", file=sys.stderr)
        sys.exit(1)

    return t


# ── Pretty print helpers ───────────────────────────────────────────────────────

def _print_header(title: str) -> None:
    print("\n" + "=" * 60)
    print(f"  {title}")
    print("=" * 60)


def _print_json(label: str, data: dict) -> None:
    print(f"\n[{label}]")
    print(json.dumps(data, indent=2, ensure_ascii=False))


# ── Demo ───────────────────────────────────────────────────────────────────────

def run_demo() -> None:
    print("Starting THRESHOLD backend server…", flush=True)
    _start_server()
    print(f"Server ready at {BASE_URL}\n", flush=True)

    sess = requests.Session()

    def post(path: str, **kwargs) -> requests.Response:
        return sess.post(f"{BASE_URL}{path}", **kwargs)

    def get(path: str, **kwargs) -> requests.Response:
        return sess.get(f"{BASE_URL}{path}", **kwargs)

    # ── 0. Reset player state ──────────────────────────────────────────────
    _print_header("0. Reset Player")
    r = post("/player/reset", json={"player_id": PLAYER_ID})
    print(f"  Status: {r.status_code}")
    _print_json("reset", r.json())
    assert r.status_code == 200, r.text

    # ── 1. Start interaction ───────────────────────────────────────────────
    _print_header("1. Start Interaction")
    r = post("/interaction/start", json={"player_id": PLAYER_ID, "npc_id": NPC_ID})
    assert r.status_code == 200, f"start failed: {r.text}"
    start_data = r.json()
    _print_json("start", start_data)
    print(f"\n  NPC: {start_data['npc_name']} [{start_data['npc_expression']}]")
    print(f"  Opening: {start_data['opening_line']}")
    print(f"  Interaction ID: {start_data['interaction_id']}")

    # ── 2. Exchange messages ───────────────────────────────────────────────
    _print_header("2. Message Exchange")
    encounter_over = False
    for i, msg in enumerate(DEMO_MESSAGES, 1):
        if encounter_over:
            break

        print(f"\n  Turn {i} — Player: \"{msg}\"")
        r = post(
            "/interaction/message",
            json={"player_id": PLAYER_ID, "npc_id": NPC_ID, "message": msg},
        )
        assert r.status_code == 200, f"message failed turn {i}: {r.text}"
        data = r.json()

        print(f"  NPC [{data['npc_expression']}]: {data['npc_reply']}")
        print(f"  Relationship tier: {data['relationship_tier']} | State: {data['npc_state']}")
        print(f"  Turn scores: clarity={data['turn_scores']['clarity']:.2f}, "
              f"empathy={data['turn_scores']['empathy']:.2f}, "
              f"politeness={data['turn_scores']['politeness']:.2f}, "
              f"expression={data['turn_scores']['expression']:.2f}")
        if data["coach_hint"]["shown"]:
            print(f"  Coach: {data['coach_hint']['line']}")
        print(f"  Feedback:")
        print(f"    + {data['feedback']['strength']}")
        print(f"    ~ {data['feedback']['improvement']}")

        encounter_over = data["encounter_over"]
        if encounter_over:
            print(f"\n  [encounter_over=true at turn {i}]")

    # ── 3. End interaction ─────────────────────────────────────────────────
    _print_header("3. End Interaction")
    r = post("/interaction/end", json={"player_id": PLAYER_ID, "npc_id": NPC_ID})
    assert r.status_code == 200, f"end failed: {r.text}"
    end_data = r.json()
    _print_json("end", end_data)

    if end_data["observer_event"]["fired"]:
        print(f"\n  [OBSERVER]: {end_data['observer_event']['message']}")
    else:
        print(f"\n  Observer did not fire this encounter (pattern not yet established).")
    print(f"  Outcome: {end_data['encounter_summary']['outcome']}")
    if "level_up" in end_data and end_data["level_up"]:
        print(f"  ** Level up! -> Level {end_data['level_up']['new_level']} **")

    # ── 4. Check player status ─────────────────────────────────────────────
    _print_header("4. Player Status After Encounter")
    r = get(f"/player/status?player_id={PLAYER_ID}")
    assert r.status_code == 200
    status = r.json()
    _print_json("player_status", status)
    print(f"\n  Level: {status['level']}  XP: {status['xp_progress']:.3f}")
    sv = status["skill_vector"]
    print(f"  Skill vector: clarity={sv['clarity']:.3f}, empathy={sv['empathy']:.3f}, "
          f"politeness={sv['politeness']:.3f}, expression={sv['expression']:.3f}")

    # ── 5. Second encounter (testing Observer pattern) ─────────────────────
    _print_header("5. Second Encounter (Observer pattern test)")
    r = post("/interaction/start", json={"player_id": PLAYER_ID, "npc_id": NPC_ID})
    assert r.status_code == 200, f"start2 failed: {r.text}"
    print(f"  NPC opening: {r.json()['opening_line']}")

    encounter_over2 = False
    for i, msg in enumerate(DEMO_MESSAGES[:3], 1):
        if encounter_over2:
            break
        r = post(
            "/interaction/message",
            json={"player_id": PLAYER_ID, "npc_id": NPC_ID, "message": msg},
        )
        if r.status_code != 200:
            print(f"  message error: {r.text}")
            break
        data = r.json()
        print(f"  Turn {i} [{data['npc_state']}]: {data['npc_reply'][:80]}...")
        encounter_over2 = data["encounter_over"]

    r = post("/interaction/end", json={"player_id": PLAYER_ID, "npc_id": NPC_ID})
    assert r.status_code == 200, f"end2 failed: {r.text}"
    end2 = r.json()
    _print_json("end (encounter 2)", end2)
    if end2["observer_event"]["fired"]:
        print(f"\n  [OBSERVER FIRED]: {end2['observer_event']['message']}")
    else:
        print(f"\n  Observer did not fire this time (need more repetitions).")

    # ── 6. Report ──────────────────────────────────────────────────────────
    _print_header("6. Session Report")
    r = post("/interaction/report", json={"player_id": PLAYER_ID})
    assert r.status_code == 200, f"report failed: {r.text}"
    report = r.json()
    _print_json("report", report)
    print(f"\n  Strongest skill: {report['strongest_skill']}")
    print(f"  Improving area:  {report['improving_area']}")
    print(f"  Pattern:         {report['recent_pattern_summary']}")
    print(f"  Practice:        {report['recommended_practice']}")

    # ── 7. Daily challenge ─────────────────────────────────────────────────
    _print_header("7. Daily Challenge")
    r = get(f"/interaction/daily?player_id={PLAYER_ID}")
    assert r.status_code == 200
    _print_json("daily", r.json())

    _print_header("Demo Complete")
    print("  Full lifecycle verified:")
    print("    start -> messages (with scores + state + tier) ->")
    print("    end (observer check + progression) -> report -> daily")
    print()
    print("  Backend is working correctly.")


if __name__ == "__main__":
    run_demo()
