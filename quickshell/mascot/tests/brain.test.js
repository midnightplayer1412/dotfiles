// Run: node --test quickshell/mascot/tests/brain.test.js
const test = require("node:test");
const assert = require("node:assert/strict");
const B = require("../brain.js");

test("clamp bounds a value", () => {
    assert.equal(B.clamp(5, 0, 10), 5);
    assert.equal(B.clamp(-3, 0, 10), 0);
    assert.equal(B.clamp(99, 0, 10), 10);
});

test("walkStep moves toward target by speed", () => {
    assert.deepEqual(B.walkStep(0, 10, 2), { x: 2, dir: 1, arrived: false });
    assert.deepEqual(B.walkStep(10, 0, 2), { x: 8, dir: -1, arrived: false });
});

test("walkStep snaps and reports arrival within one step", () => {
    assert.deepEqual(B.walkStep(9, 10, 2), { x: 10, dir: 0, arrived: true });
    assert.deepEqual(B.walkStep(10, 10, 2), { x: 10, dir: 0, arrived: true });
});

test("gravityStep accelerates then lands at floor", () => {
    assert.deepEqual(B.gravityStep(0, 0, 100, 1.2), { y: 1.2, vy: 1.2, landed: false });
    assert.deepEqual(B.gravityStep(99.9, 5, 100, 1.2), { y: 100, vy: 0, landed: true });
});

test("chooseTarget maps a 0..1 random into [min,max]", () => {
    assert.equal(B.chooseTarget(0, 100, 0), 0);
    assert.equal(B.chooseTarget(0, 100, 1), 100);
    assert.equal(B.chooseTarget(0, 100, 0.5), 50);
});

test("isLowBattery only when discharging and at/below threshold", () => {
    assert.equal(B.isLowBattery(15, false, 20), true);
    assert.equal(B.isLowBattery(20, false, 20), true);
    assert.equal(B.isLowBattery(15, true, 20), false);  // charging
    assert.equal(B.isLowBattery(25, false, 20), false); // above threshold
});

test("notificationArrived detects a count increase only", () => {
    assert.equal(B.notificationArrived(0, 1), true);
    assert.equal(B.notificationArrived(2, 2), false);
    assert.equal(B.notificationArrived(3, 1), false);
});

test("resolveState honors priority order", () => {
    const base = { dragging: false, airborne: false, reaction: "", lowBattery: false, moving: false };
    assert.equal(B.resolveState({ ...base, dragging: true }), "drag");
    assert.equal(B.resolveState({ ...base, airborne: true }), "fall");
    assert.equal(B.resolveState({ ...base, reaction: "pet" }), "pet");
    assert.equal(B.resolveState({ ...base, lowBattery: true }), "low_battery");
    assert.equal(B.resolveState({ ...base, moving: true }), "walk");
    assert.equal(B.resolveState(base), "idle");
});

test("resolveState: dragging beats everything", () => {
    assert.equal(
        B.resolveState({ dragging: true, airborne: true, reaction: "pet", lowBattery: true, moving: true }),
        "drag"
    );
});

test("resolveState: intermediate priority levels", () => {
    assert.equal(
        B.resolveState({ dragging: false, airborne: true, reaction: "pet", lowBattery: true, moving: true }),
        "fall"
    );
    assert.equal(
        B.resolveState({ dragging: false, airborne: false, reaction: "pet", lowBattery: true, moving: true }),
        "pet"
    );
    assert.equal(
        B.resolveState({ dragging: false, airborne: false, reaction: "", lowBattery: true, moving: true }),
        "low_battery"
    );
});

test("gravityStep integrates a negative (upward) velocity", () => {
    assert.deepEqual(B.gravityStep(50, -5, 100, 1.2), { y: 46.2, vy: -3.8, landed: false });
});

test("chooseTarget respects a non-zero min", () => {
    assert.equal(B.chooseTarget(10, 110, 0), 10);
    assert.equal(B.chooseTarget(10, 110, 0.5), 60);
    assert.equal(B.chooseTarget(10, 110, 1), 110);
});

// --- Sequence engine ---------------------------------------------------------

test("seqEnter resolves an 'anim' step (advances on animation finish)", () => {
    const steps = [{ s: "jump", d: "anim" }];
    assert.deepEqual(B.seqEnter(steps, 0, 0.5),
        { index: 0, state: "jump", mode: "anim", remaining: 0 });
});

test("seqEnter resolves a 'loop' step (held until interrupted)", () => {
    const steps = [{ s: "stealth", d: "loop" }];
    assert.deepEqual(B.seqEnter(steps, 0, 0.5),
        { index: 0, state: "stealth", mode: "loop", remaining: 0 });
});

test("seqEnter resolves a fixed-ms step", () => {
    const steps = [{ s: "pet", d: 1800 }];
    assert.deepEqual(B.seqEnter(steps, 0, 0.5),
        { index: 0, state: "pet", mode: "timed", remaining: 1800 });
});

test("seqEnter maps a [min,max] dwell through the random r", () => {
    const steps = [{ s: "sit_idle", d: [1000, 5000] }];
    assert.deepEqual(B.seqEnter(steps, 0, 0),
        { index: 0, state: "sit_idle", mode: "timed", remaining: 1000 });
    assert.deepEqual(B.seqEnter(steps, 0, 0.5),
        { index: 0, state: "sit_idle", mode: "timed", remaining: 3000 });
    assert.deepEqual(B.seqEnter(steps, 0, 1),
        { index: 0, state: "sit_idle", mode: "timed", remaining: 5000 });
});

test("seqTick counts a timed step down without advancing", () => {
    const steps = [{ s: "pet", d: 1800 }, { s: "idle", d: "loop" }];
    const p = B.seqEnter(steps, 0, 0);              // remaining 1800
    const r = B.seqTick(p, steps, 16, false, 0);
    assert.equal(r.done, false);
    assert.deepEqual(r.player, { index: 0, state: "pet", mode: "timed", remaining: 1784 });
});

test("seqTick advances to the next step when a timed step elapses", () => {
    const steps = [{ s: "stand_to_sit", d: 100 }, { s: "sit_idle", d: [2000, 2000] }];
    const p = { index: 0, state: "stand_to_sit", mode: "timed", remaining: 16 };
    const r = B.seqTick(p, steps, 16, false, 0.5);
    assert.equal(r.done, false);
    assert.deepEqual(r.player, { index: 1, state: "sit_idle", mode: "timed", remaining: 2000 });
});

test("seqTick holds an 'anim' step until animFinished, then advances", () => {
    const steps = [{ s: "jump_in_box", d: "anim" }, { s: "play_box", d: "loop" }];
    const p = B.seqEnter(steps, 0, 0);
    assert.deepEqual(B.seqTick(p, steps, 16, false, 0).player, p);   // not finished: unchanged
    const r = B.seqTick(p, steps, 16, true, 0);                      // finished: advance
    assert.deepEqual(r.player, { index: 1, state: "play_box", mode: "loop", remaining: 0 });
    assert.equal(r.done, false);
});

test("seqTick never auto-advances a 'loop' step", () => {
    const steps = [{ s: "stealth", d: "loop" }];
    const p = B.seqEnter(steps, 0, 0);
    assert.deepEqual(B.seqTick(p, steps, 9999, true, 0).player, p);  // even with animFinished + huge dt
});

test("seqTick reports done and nulls the player at end of sequence", () => {
    const steps = [{ s: "jump", d: "anim" }];
    const p = B.seqEnter(steps, 0, 0);
    const r = B.seqTick(p, steps, 16, true, 0);
    assert.deepEqual(r, { player: null, done: true });
});

// --- Click vs. drag classification ------------------------------------------

test("exceedsDragThreshold is false below the threshold distance", () => {
    assert.equal(B.exceedsDragThreshold(0, 0, 6), false);   // no movement = a click
    assert.equal(B.exceedsDragThreshold(3, 4, 6), false);   // dist 5 < 6
    assert.equal(B.exceedsDragThreshold(4, 4, 6), false);   // dist ~5.66 < 6
});

test("exceedsDragThreshold is true at or beyond the threshold", () => {
    assert.equal(B.exceedsDragThreshold(3, 4, 5), true);    // dist 5 >= 5 (boundary)
    assert.equal(B.exceedsDragThreshold(6, 0, 6), true);
    assert.equal(B.exceedsDragThreshold(0, -6, 6), true);   // negative direction
});

// --- Weighted idle-behavior picker ------------------------------------------

test("pickIdle returns the band containing r across cumulative weights", () => {
    const w = [{ name: "idle", weight: 3 }, { name: "sit", weight: 1 }];  // total 4
    assert.equal(B.pickIdle(w, 0),    "idle");   // x=0   in [0,3)
    assert.equal(B.pickIdle(w, 0.7),  "idle");   // x=2.8 in [0,3)
    assert.equal(B.pickIdle(w, 0.75), "sit");    // x=3.0 in [3,4)
    assert.equal(B.pickIdle(w, 0.99), "sit");    // x=3.96 in [3,4)
});

test("pickIdle maps r=1 to the last behavior (no overflow)", () => {
    const w = [{ name: "idle", weight: 3 }, { name: "sit", weight: 1 }, { name: "nap", weight: 1 }];
    assert.equal(B.pickIdle(w, 1), "nap");
});

test("pickIdle with a single behavior always returns it", () => {
    assert.equal(B.pickIdle([{ name: "idle", weight: 1 }], 0),   "idle");
    assert.equal(B.pickIdle([{ name: "idle", weight: 1 }], 0.5), "idle");
});

// --- Flee direction (run from cursor) ---------------------------------------

test("fleeTarget flees away from the cursor relative to the cat's center", () => {
    // cat spans [100, 200) -> center 150
    // cursor left of center -> flee to the right edge (maxX)
    assert.equal(B.fleeTarget(120, 100, 100, 0, 1820), 1820);
    // cursor right of center -> flee to the left edge (minX)
    assert.equal(B.fleeTarget(180, 100, 100, 0, 1820), 0);
});

test("fleeTarget at the cat's center flees to the far (max) edge", () => {
    assert.equal(B.fleeTarget(150, 100, 100, 0, 1820), 1820);
});

test("exceedsSwipeSpeed needs a minimum window before it trusts the speed", () => {
    // span below the floor: too little data, never a swat (avoids per-event noise)
    assert.equal(B.exceedsSwipeSpeed(100, 20, 25, 2.0), false);
    assert.equal(B.exceedsSwipeSpeed(0, 0, 25, 2.0), false);   // no divide-by-zero
});

test("exceedsSwipeSpeed compares average speed once the window is long enough", () => {
    assert.equal(B.exceedsSwipeSpeed(100, 40, 25, 2.0), true);   // 2.5 px/ms
    assert.equal(B.exceedsSwipeSpeed(20, 40, 25, 2.0), false);   // 0.5 px/ms (slow approach)
    assert.equal(B.exceedsSwipeSpeed(50, 25, 25, 2.0), true);    // 2.0 px/ms at the boundary
});

// --- CPU load (run when busy) -----------------------------------------------

test("parseProcStat sums totals and counts idle+iowait as idle", () => {
    // cpu  user nice system idle iowait irq softirq ...
    const text = "cpu  100 0 50 800 50 0 0 0 0 0\ncpu0 ...\nintr ...";
    assert.deepEqual(B.parseProcStat(text), { total: 1000, idle: 850 });
});

test("cpuBusy compares the busy fraction across two samples to the threshold", () => {
    const prev = { total: 1000, idle: 850 };
    assert.equal(B.cpuBusy(prev, { total: 2000, idle: 1700 }, 0.7), false); // 15% busy
    assert.equal(B.cpuBusy(prev, { total: 2000, idle: 1000 }, 0.7), true);  // 85% busy
});

test("cpuBusy is false when no time elapsed between samples", () => {
    assert.equal(B.cpuBusy({ total: 1000, idle: 850 }, { total: 1000, idle: 850 }, 0.7), false);
});

// --- Nearest edge (run to a corner to hide) ---------------------------------

test("nearestEdge returns whichever horizontal edge is closer", () => {
    assert.equal(B.nearestEdge(100, 0, 1820), 0);      // near the left
    assert.equal(B.nearestEdge(1700, 0, 1820), 1820);  // near the right
});

test("nearestEdge at the midpoint picks the left edge", () => {
    assert.equal(B.nearestEdge(910, 0, 1820), 0);      // exactly halfway -> min
});
