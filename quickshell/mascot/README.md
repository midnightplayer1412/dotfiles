# Desktop Mascot — "Oreo Cat"

A sprite-based desktop pet for Hyprland / Quickshell. A cat roams the
configured screen, can be picked up and dropped (with gravity), and reacts to
your cursor and to system state. It lives on a full-screen transparent
layer-shell overlay whose input region is masked to just the sprite, so it
floats over apps without stealing clicks.

## Credits & attribution

The cat sprite art is the **"Aichan" cat sprite sheet**, created by **Aichan**.

The art is **not redistributed** in this repository — the sprite sheet is
git-ignored (only the license text is tracked, to preserve attribution). To run
the mascot you must obtain the sprite sheet yourself and place it at:

```
quickshell/mascot/sprites/Sprite Sheet Cat - Aichan_owo.png
```

Key license terms (full text in [`sprites/Aichan's Asset License.txt`](sprites/Aichan's%20Asset%20License.txt)):
personal & commercial use permitted; **no** reselling or redistribution; **no**
editing/altering the original files; **no** blockchain / crypto / NFT use; and
**no** use for training LLMs or generative AI. The runtime only reads regions of
the unmodified sheet — it never alters or re-exports the art.

## Behaviors

| Trigger | Behavior |
|---------|----------|
| (idle) | Wanders; most stops are a plain stand-still, sometimes a **sit**, occasionally a long **nap**, rarely a randomized **box-play** routine |
| Single click | **Pet** |
| Double-click | Startled **hop** |
| Fast cursor swipe over it | **Runs away** to the far edge |
| Drag | Pick up; release drops it and it falls back to the floor |
| Low battery | Curls up and **sleeps** in place |
| High CPU load | **Runs** instead of walking |
| Focused window fullscreen | Runs to the nearest corner and **crouches** (stealth) |
| New notification | **Attack** swat |

## Architecture

All scripted behavior is **data** consumed by a small sequence engine, so new
behaviors are usually just config, not code.

| File | Role |
|------|------|
| `brain.js` | Pure, dependency-free logic — sequence engine, gravity/walk physics, idle/flee/CPU helpers. Imported by QML *and* by the Node tests. |
| `MascotConfig.qml` | Singleton: the animation region map + behavior sequences (`actions`, `modes`, box pool) + tunables (speeds, thresholds, weights). |
| `MascotSprite.qml` | A "dumb" clip player — shows the named animation region and emits `finished()` when a one-shot clip ends. |
| `MascotBrain.qml` | Owns live state, runs the ~60 fps tick, steps sequences, and consumes signals. |
| `MascotSignals.qml` | Singleton: system signals — CPU busy (from `/proc/stat` deltas) and fullscreen (Hyprland IPC). |
| `Mascot.qml` | The layer-shell overlay window, sprite rendering, and mouse interaction. |

A **sequence** is a list of steps `{ s: <animation>, d: <duration> }` where
duration is `"anim"` (advance when the one-shot clip finishes), `"loop"` (hold
until interrupted), a number (fixed ms), or `[min, max]` (random dwell).
`actions` are transient (preempt, then fall back); `modes` are condition-held
(entered on a rising edge, cleared on the falling edge).

## Tests

The pure logic is covered by `node:test` (no Qt needed):

```sh
node --test quickshell/mascot/tests/brain.test.js
```

## Tuning

Most knobs live in `MascotConfig.qml`:

- `idleWeights` — how often each idle behavior (idle / sit / nap / box) is chosen
- `speed` / `runSpeed` / `gravity` / `jumpVelocity` — movement & physics
- `startleSpeed` — how fast a cursor swipe must be to scare it
- `cpuBusyThreshold` — CPU fraction that makes it run
- `lowBatteryThreshold` — battery % that makes it sleep
- the `actions` / `modes` / `boxAntics` sequence definitions themselves
