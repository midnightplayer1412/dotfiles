pragma Singleton

import QtQuick

// Stateless fuzzy matcher. match(query, text) returns { hit, score }:
//   hit   — true when every query char appears in text in order (subsequence).
//   score — higher is better; rewards prefix, word-boundary, and contiguous hits.
// Empty query is a universal hit with score 0 (caller handles ordering).
QtObject {
    id: matcher

    function match(query, text) {
        if (!query) return { hit: true, score: 0 };
        const q = query.toLowerCase();
        const t = (text || "").toLowerCase();

        let qi = 0;
        let score = 0;
        let lastHit = -2;
        let streak = 0;

        for (let ti = 0; ti < t.length && qi < q.length; ti++) {
            if (t[ti] !== q[qi]) continue;

            let s = 1;
            if (ti === lastHit + 1) { streak++; s += streak * 2; }   // contiguous run
            else { streak = 0; }
            if (ti === 0) s += 10;                                   // start of string
            else if (/[\s\-_./]/.test(t[ti - 1])) s += 8;            // start of a word
            score += s;
            lastHit = ti;
            qi++;
        }

        if (qi < q.length) return { hit: false, score: 0 };

        // Prefer tighter and prefix matches.
        score += Math.max(0, 10 - (t.length - q.length) / 4);
        if (t.startsWith(q)) score += 15;
        return { hit: true, score: score };
    }
}
