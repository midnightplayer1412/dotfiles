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
