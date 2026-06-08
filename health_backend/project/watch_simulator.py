#!/usr/bin/env python3
"""
╔══════════════════════════════════════════════════════════════╗
║           SSHA SmartWatch Simulator  v1.0                    ║
║  Emulates a Bluetooth smartwatch over a local WebSocket.     ║
║                                                              ║
║  Usage:                                                      ║
║    pip install websockets                                    ║
║    python3 watch_simulator.py                                ║
║                                                              ║
║  Flutter app connects to:  ws://localhost:8765               ║
║  Physical device:  replace 'localhost' with your LAN IP.     ║
╚══════════════════════════════════════════════════════════════╝
"""

import asyncio
import json
import math
import random
import time
from datetime import datetime

try:
    import websockets
except ImportError:
    print("Missing dependency. Run:  pip install websockets")
    exit(1)

# ─── Simulation state ──────────────────────────────────────────────────────────

HOST = "localhost"
PORT = 8765

class WatchSimulator:
    def __init__(self):
        self.heart_rate = 72
        self.steps = 0
        self.calories = 0
        self.spo2 = 98
        self.stress = 30
        self.battery = 87
        self.activity = "sedentary"

        self._tick = 0
        self._activity_timer = 0
        self._activity_duration = random.randint(20, 60)

        # HR wanders around a baseline using a sine wave + noise
        self._hr_baseline = 72
        self._hr_phase = 0.0

    def tick(self):
        self._tick += 1
        self._hr_phase += 0.15

        # ── Activity changes every ~30-60 ticks ────────────────────────
        self._activity_timer += 1
        if self._activity_timer >= self._activity_duration:
            self._activity_timer = 0
            self._activity_duration = random.randint(20, 60)
            activities = ["sedentary", "walking", "walking", "running", "cycling"]
            weights  = [0.40, 0.30, 0.15, 0.10, 0.05]
            self.activity = random.choices(activities, weights=weights)[0]
            # Adjust HR baseline per activity
            baselines = {
                "sedentary": random.randint(60, 75),
                "walking":   random.randint(80, 100),
                "running":   random.randint(120, 165),
                "cycling":   random.randint(100, 140),
            }
            self._hr_baseline = baselines.get(self.activity, 72)

        # ── Heart rate: sine wave + random noise ──────────────────────
        sine = math.sin(self._hr_phase) * 4
        noise = random.gauss(0, 1.5)
        self.heart_rate = int(
            max(50, min(200, self._hr_baseline + sine + noise))
        )

        # ── Steps: increment only when active ─────────────────────────
        if self.activity in ("walking", "running", "cycling"):
            step_delta = {
                "walking": random.randint(1, 3),
                "running": random.randint(3, 6),
                "cycling": random.randint(1, 2),
            }.get(self.activity, 0)
            self.steps += step_delta
            self.calories += max(1, step_delta // 3)

        # ── SpO2: stays 95-100%, dips slightly during high activity ───
        if self.heart_rate > 150:
            self.spo2 = max(93, self.spo2 - random.choice([0, 0, 0, 1]))
        else:
            self.spo2 = min(100, self.spo2 + random.choice([0, 0, 1]))

        # ── Stress: rises with high HR, dips when resting ─────────────
        if self.heart_rate > 130:
            self.stress = min(90, self.stress + random.randint(0, 2))
        elif self.activity == "sedentary":
            self.stress = max(10, self.stress - random.randint(0, 1))

        # ── Battery: slow drain (1% every ~120 ticks ≈ 2 min) ─────────
        if self._tick % 120 == 0:
            self.battery = max(0, self.battery - 1)

    def to_json(self) -> str:
        return json.dumps({
            "type": "metrics",
            "heart_rate": self.heart_rate,
            "steps": self.steps,
            "calories": self.calories,
            "spo2": self.spo2,
            "stress": self.stress,
            "battery": self.battery,
            "activity": self.activity,
            "timestamp": datetime.now().isoformat(),
        })


# ─── WebSocket server ──────────────────────────────────────────────────────────

watch = WatchSimulator()
connected_clients: set = set()

async def handler(websocket):
    connected_clients.add(websocket)
    addr = websocket.remote_address
    print(f"  ✅  Flutter client connected  {addr[0]}:{addr[1]}")
    try:
        async for _ in websocket:
            pass   # we don't read messages — Flutter only listens
    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        connected_clients.discard(websocket)
        print(f"  ✖   Client disconnected    {addr[0]}:{addr[1]}")

async def broadcast_loop():
    """Send a metrics update to all connected clients every second."""
    while True:
        watch.tick()
        if connected_clients:
            payload = watch.to_json()
            await asyncio.gather(
                *[ws.send(payload) for ws in list(connected_clients)],
                return_exceptions=True,
            )
        await asyncio.sleep(1.0)

async def main():
    print("╔══════════════════════════════════════════════════╗")
    print("║   SSHA SmartWatch Simulator — RUNNING            ║")
    print(f"║   Listening on  ws://{HOST}:{PORT}                ║")
    print("║   Open the Flutter app → SmartWatch tab → Connect ║")
    print("╚══════════════════════════════════════════════════╝\n")
    print("  Waiting for Flutter client...")

    async with websockets.serve(handler, HOST, PORT):
        await broadcast_loop()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n  Simulator stopped.")
