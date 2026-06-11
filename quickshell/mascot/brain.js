// Pure, dependency-free behavior helpers for the desktop mascot.
// Imported by QML (`import "brain.js" as Brain`) and by Node tests.
// IMPORTANT: no `.pragma` line here — it is QML-only and breaks Node parsing.

function clamp(v, lo, hi) {
    return v < lo ? lo : (v > hi ? hi : v);
}

// Move x toward target by at most `speed`. Returns new x, direction (-1/0/1),
// and whether we reached the target this step.
function walkStep(x, target, speed) {
    const d = target - x;
    if (Math.abs(d) <= speed) return { x: target, dir: 0, arrived: true };
    const dir = d > 0 ? 1 : -1;
    return { x: x + dir * speed, dir: dir, arrived: false };
}

// Integrate one gravity step. Lands (clamps to floorY, zeroes velocity) on contact.
function gravityStep(y, vy, floorY, gravity) {
    const nvy = vy + gravity;
    const ny = y + nvy;
    if (ny >= floorY) return { y: floorY, vy: 0, landed: true };
    return { y: ny, vy: nvy, landed: false };
}

// Map a random r in [0,1] to an integer x in [min,max].
function chooseTarget(min, max, r) {
    return Math.round(min + r * (max - min));
}

function isLowBattery(pct, charging, threshold) {
    return !charging && pct <= threshold;
}

function notificationArrived(prevCount, count) {
    return count > prevCount;
}

// Highest priority wins. `reaction` is "" or a reaction state name.
function resolveState(s) {
    if (s.dragging) return "drag";
    if (s.airborne) return "fall";
    if (s.reaction) return s.reaction;
    if (s.lowBattery) return "low_battery";
    return s.moving ? "walk" : "idle";
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = {
        clamp, walkStep, gravityStep, chooseTarget,
        isLowBattery, notificationArrived, resolveState
    };
}
