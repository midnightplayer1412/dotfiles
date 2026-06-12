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

// --- Sequence engine ---------------------------------------------------------
// A sequence is an ordered list of steps `{ s: <state>, d: <duration> }` where
// duration is one of:
//   "anim"        advance when the current one-shot animation finishes
//   "loop"        hold indefinitely until interrupted externally (mode states)
//   <number>      dwell a fixed number of ms, then advance
//   [min, max]    dwell a random number of ms in [min,max] (mapped via r)
// A "player" is { index, state, mode, remaining } where mode is
// "anim" | "loop" | "timed"; only "timed" uses `remaining` (ms left).

// Resolve step `index` of `steps` into a player, using random r in [0,1] for
// any [min,max] dwell.
function seqEnter(steps, index, r) {
    const step = steps[index];
    if (step.d === "anim")
        return { index: index, state: step.s, mode: "anim", remaining: 0 };
    if (step.d === "loop")
        return { index: index, state: step.s, mode: "loop", remaining: 0 };
    const ms = (typeof step.d === "number")
        ? step.d
        : step.d[0] + r * (step.d[1] - step.d[0]);
    return { index: index, state: step.s, mode: "timed", remaining: ms };
}

// Advance a `player` by `dtMs`. `animFinished` is true on the tick the current
// one-shot clip reported completion. `r` seeds the next step's dwell if we
// advance into a [min,max] step. Returns { player, done }: `player` is the next
// player (or null at end of sequence), `done` is true when the sequence ended.
function seqTick(player, steps, dtMs, animFinished, r) {
    let advance = false;
    if (player.mode === "anim") {
        advance = animFinished;
    } else if (player.mode === "timed") {
        const rem = player.remaining - dtMs;
        if (rem > 0)
            return { player: { index: player.index, state: player.state, mode: "timed", remaining: rem }, done: false };
        advance = true;
    }
    // "loop": never auto-advances; falls through with advance=false.
    if (!advance)
        return { player: player, done: false };
    const next = player.index + 1;
    if (next >= steps.length)
        return { player: null, done: true };
    return { player: seqEnter(steps, next, r), done: false };
}

// Parse the aggregate "cpu " line of /proc/stat into cumulative {total, idle}
// jiffies. idle counts the idle + iowait columns; total sums all columns.
function parseProcStat(text) {
    const line = text.split("\n")[0].trim().split(/\s+/);  // ["cpu", u, n, s, idle, iowait, ...]
    let total = 0;
    for (let i = 1; i < line.length; i++)
        total += Number(line[i]) || 0;
    const idle = (Number(line[4]) || 0) + (Number(line[5]) || 0);  // idle + iowait
    return { total: total, idle: idle };
}

// Busy fraction between two /proc/stat samples, compared to a threshold. Idle
// when no jiffies elapsed (avoids divide-by-zero on a too-fast re-poll).
function cpuBusy(prev, curr, threshold) {
    const dTotal = curr.total - prev.total;
    if (dTotal <= 0)
        return false;
    const busy = (dTotal - (curr.idle - prev.idle)) / dTotal;
    return busy >= threshold;
}

// Whether the cursor's average speed over a motion burst counts as a "swat".
// `dist` is the distance travelled over `spanMs`. Requires the window to reach
// `minSpanMs` first, so tiny per-event samples (noisy, near-zero dt) can't
// trip it. Compared as dist >= speed*span to dodge a divide-by-zero.
function exceedsSwipeSpeed(dist, spanMs, minSpanMs, speed) {
    return spanMs >= minSpanMs && dist >= speed * spanMs;
}

// Flatten randomly-chosen antic groups between a fixed intro and outro step
// into one sequence. Used to build a varied box-play routine each visit.
function assembleRoutine(intro, groups, outro) {
    const steps = [intro];
    for (let i = 0; i < groups.length; i++)
        for (let j = 0; j < groups[i].length; j++)
            steps.push(groups[i][j]);
    steps.push(outro);
    return steps;
}

// The closer horizontal edge to `pos` — where the cat runs to hide. Ties to min.
function nearestEdge(pos, minX, maxX) {
    return pos <= (minX + maxX) / 2 ? minX : maxX;
}

// The wander target to flee toward when startled by the cursor: away from the
// cursor, to the far horizontal edge. The cursor is compared to the cat's
// CENTER (catLeft + catW/2) — not its left edge — so a cursor on the left half
// sends it right and vice versa. Ties flee to the max edge.
function fleeTarget(cursorX, catLeft, catW, minX, maxX) {
    return cursorX <= catLeft + catW / 2 ? maxX : minX;
}

// Weighted pick among idle behaviors. `weights` is [{name, weight}, ...] with
// positive weights (need not sum to 1); `r` in [0,1) selects a band. Returns the
// chosen name. r=1 falls through to the last behavior.
function pickIdle(weights, r) {
    let total = 0;
    for (let i = 0; i < weights.length; i++)
        total += weights[i].weight;
    let x = r * total;
    for (let i = 0; i < weights.length; i++) {
        if (x < weights[i].weight)
            return weights[i].name;
        x -= weights[i].weight;
    }
    return weights[weights.length - 1].name;
}

// True once a press has moved far enough from its origin to count as a drag
// rather than a click. Below the threshold a release is a click (e.g. pet);
// at/above it the press becomes a pick-up. Compared squared to avoid a sqrt.
function exceedsDragThreshold(dx, dy, threshold) {
    return dx * dx + dy * dy >= threshold * threshold;
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = {
        clamp, walkStep, gravityStep, chooseTarget,
        isLowBattery, notificationArrived, resolveState,
        seqEnter, seqTick, exceedsDragThreshold, pickIdle, fleeTarget,
        exceedsSwipeSpeed, parseProcStat, cpuBusy, nearestEdge, assembleRoutine
    };
}
