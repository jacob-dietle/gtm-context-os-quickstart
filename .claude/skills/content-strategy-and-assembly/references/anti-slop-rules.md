# Anti-Slop Detection Rules — Consolidated Reference

Consolidated from three sources:
- Anti-slop checklist (quick pre-publish)
- Universal principles reference (comprehensive Pattern Groups A-G)
- Intelligence pipeline `ce-editorial-rules.md` (practitioner content)

---

## Hard Limits (Automated, Zero Tolerance)

### Filler Phrases — ELIMINATE ON SIGHT
- "It's worth noting that..."
- "This represents..."
- "What this means is..."
- "In today's landscape..."
- "However, it's important to recognize that..."
- "The implications extend beyond..."
- "Organizations are responding by..."

### Abstract Framing Words — NEVER USE
- "Paradox", "Collision", "Tension", "Dichotomy"
- "Validates", "Represents"
- Replace with simple cause-and-effect language

### Generic Enthusiasm — NEVER USE
- "Revolutionary", "Game-changing", "Transformative"
- "Cutting-edge", "Best-in-class", "Industry-leading"
- Replace with specific claims: "Reduces X by 71%" not "dramatically improves"

### Formal Transitions — NEVER USE
- "Furthermore", "Moreover", "Subsequently", "Additionally", "Consequently"
- Replace with: "Also", "And", "So", "Then", or just start the next sentence

### Hedge Words — REPLACE DEFINITIVELY
- "might indicate" → "indicates"
- "could suggest" → "suggests"
- "potentially" → remove or use specific qualifier
- "seems to" → remove or restate as fact from evidence

### Passive Voice — CONVERT TO ACTIVE
- "was observed across teams" → "Teams demonstrated"
- "can be seen emerging" → "3 patterns emerged"
- "CVEs are being weaponized" → "Attackers weaponize CVEs"

---

## Counted Limits

| Pattern | Max Per Article | Detection |
|---|---|---|
| Em-dashes (—) | 2 | `grep -c "—"` |
| Colon-sentences (X: Y where Y is a full sentence) | 3 | `grep -cP ": [A-Z]"` |

**Em-dash alternatives:** "including", "whether via", parentheses, "from X to Y"
**Colon-sentence fix:** Break into two sentences, use conjunctions, or just state the fact directly

---

## Pattern Groups (AI Composition Tropes)

### Group A: False Drama (Max: 0-1 per article)
- "This isn't X—it's Y"
- "But here's the critical difference:"
- "The question is no longer X? It's Y?"
- **Fix:** Direct statements without negation or rhetorical setup

### Group B: Colon/Em-Dash Overload (Max: 2-3 per article)
- "The playbook shift: from blocking everything—to responding fast"
- "The pattern is clear:" / "The logic is straightforward:"
- **Fix:** Simple sentences or integrated descriptions

### Group C: Setup Constructions (Max: 1 per article)
- "This is where X becomes critical"
- "What does this look like in practice?"
- "Here's what this looks like for most teams:"
- **Fix:** Jump directly to showing — skip the preview

### Group D: Repetitive Structures (Max: 0)
- "It means X. It means Y. It means Z."
- "Think about what this means for..."
- **Fix:** Varied sentence starters or bullet points

### Group E: False Profundity (Max: 1 per article)
- "This is fundamentally different from..."
- **Fix:** Show the difference directly

### Group G: AI Composition Tropes (Max: 0)

**G1. Invented Concept Labels** — Ad-hoc compound terms presented as established concepts: "supervision paradox", "acceleration trap". Fix: cite who coined it or earn it with 3+ paragraphs of evidence.

**G2. False Vulnerability** — "I'll be honest...", "This keeps me up at night..." Fix: show vulnerability through specifics, don't announce it.

**G3. Listicle in Trench Coat** — 3+ consecutive one-sentence paragraphs masquerading as prose. Fix: vary paragraph length.

**G4. Magic Adverbs** — "quietly", "deeply", "fundamentally", "increasingly", "remarkably", "simply", "arguably". Fix: cut the adverb, pick a better verb.

**G5. "Serves As" Dodge** — "serves as", "acts as", "functions as", "stands as", "marks a", "represents a". Fix: use the direct verb.

**G6. False Ranges** — "It's both X and Y" / "at once X and Y" / "simultaneously X and Y". Fix: pick the more important one.

**G7. Historical Analogy Stacking** — 3+ historical comparisons in one piece. Fix: max 1, make it earn its place.

**G8. One-Point Dilution** — Single insight padded to article length. Fix: if one point, make a short piece.

**G9. Signposted Conclusions** — "Despite its challenges, X remains...", "In conclusion...", "To sum up..." Fix: end with strongest claim or most interesting open question.

**G10. Vague Attributions** — "experts say", "research shows", "studies suggest". Fix: name the expert, cite the study, or cut the claim.

**G11. Superficial -ing Analyses** — "reshaping", "reimagining", "redefining", "revolutionizing". Fix: describe what actually changed.

**G12. "Not X. Not Y. Just Z." Escalation** — Three-part negation building to dramatic reveal. Fix: state Z directly.

---

## Detection Regexes

Run these against the draft. Any match is a flag to fix.

```bash
# Filler phrases
grep -iP "(worth noting|this represents|in today's landscape|however.*important to recognize|implications extend|organizations are responding)" draft.md

# Abstract framing
grep -iP "\b(paradox|collision|tension|dichotomy|validates|represents)\b" draft.md

# Generic enthusiasm
grep -iP "\b(revolutionary|game-changing|transformative|cutting-edge|best-in-class|industry-leading)\b" draft.md

# Formal transitions (line start)
grep -iP "^(Furthermore|Moreover|Subsequently|Additionally|Consequently)" draft.md

# Hedge words
grep -iP "(might indicate|could suggest|potentially|seems to)" draft.md

# AI composition tropes (Group G)
grep -iP "(serves as|acts as a|functions as|stands as|quietly \w+|deeply \w+|fundamentally \w+|increasingly \w+)" draft.md

# False drama (Group A)
grep -P "(This isn't \w+.it's|But here's the (critical|key|fundamental)|The question is no longer)" draft.md

# Setup constructions (Group C)
grep -iP "(This is where \w+ (thinking|becomes|applies)|What does (this|that|it) (look like|mean) (in practice|operationally))" draft.md

# Signposted conclusions (Group G9)
grep -iP "(Despite (its|the|these) (challenges|limitations)|In conclusion|To sum up|While not without)" draft.md

# Magic adverbs (Group G4)
grep -iP "\b(quietly|deeply|fundamentally|increasingly|remarkably|simply|arguably)\b" draft.md

# False vulnerability (Group G2)
grep -iP "(I'll be honest|This keeps me up|And yes, I'm openly)" draft.md

# Vague attributions (Group G10)
grep -iP "(experts (say|argue|suggest)|research (shows|suggests|indicates)|studies suggest|many believe)" draft.md
```

---

## The Swap Test (Batch Content)

If producing multiple pieces from similar inputs:

**If you can swap the entity name and the sentence still works unchanged, it's template slop.**

- SLOP: "The company is well-positioned to invest in justified proposals" — works for ANY company
- GOOD: "Their 39.4% budget increase funds a $63M capital plan including a formal ERP RFP" — specific to ONE

Detection: grep for exact phrases across all outputs. Any phrase appearing in >30% of outputs is template slop.

---

## The Pitch-Slap Test

Copy any paragraph into a sales deck. Does it fit seamlessly? Then it's pitch-slapping.

**Detection rules:**
- Paragraph focuses on what a product does (not what the problem is)
- Language includes "market category failure", "paradigm shift", "fundamental limitation"
- Ends with implicit "you need [our solution category]" conclusion

Fix: rewrite to provide independent value — would the reader share this paragraph even if no product existed?

---

## Quick Pre-Publish Checklist

- [ ] Em-dashes: ≤2 per article
- [ ] Colon-sentences: ≤3 per article
- [ ] Filler phrases: Zero
- [ ] Abstract framing: Zero
- [ ] Buzzwords: Zero
- [ ] Formal transitions: Zero
- [ ] Hedge words: Zero
- [ ] Passive voice: Converted to active
- [ ] AI composition tropes (Groups A-G): Zero
- [ ] Pitch-slap test: No paragraphs that fit in a sales deck
- [ ] Swap test (if batch): No phrases in >30% of outputs
