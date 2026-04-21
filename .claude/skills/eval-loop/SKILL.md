---
name: eval-loop
description: This skill should be used when a specific quality problem (UX, data, architecture, feature) needs systematic diagnosis and iterative fixing toward a defined target. Traces symptoms to root causes, sets measurable targets with automated backpressure (unit tests, Playwright, LLM-as-judge, or rubric scoring), and iterates until targets pass. Use when user reports a quality gap ("this is a 3/10"), when shipping a feature that needs a quality bar ("what would 10/10 look like?"), or when a class of problems keeps recurring. Core pattern — symptom → generalize → root causes → targets → fix → verify → loop. Step 0 routes predictive/scoring problems OUT to eval-driven-scoring.
---

# Eval Loop

Generalized quality iteration loop for any dimension — UX, data architecture, code quality, feature completeness, content tone. Traces specific symptoms to structural root causes, defines measurable targets, and iterates with automated backpressure until targets pass.

**Meta-Principle:** "Don't fix the symptom, fix the class — but verify by measuring the symptom."

**Scope-Principle (added):** "This loop verifies presence, shape, and content quality. It does NOT verify predictive validity. Scoring/classification problems require statistical gates this skill does not provide — route them to eval-driven-scoring."

---

## When to Use This Skill

**Apply this skill when:**
- A specific quality complaint surfaces ("I can't click the contact", "this email sounds robotic")
- A feature needs a quality bar before shipping ("what would 10/10 look like?")
- A class of problems keeps recurring (data gaps, UX friction, architectural debt)
- Quality needs to improve but the path from current → target is unclear
- Multiple dimensions (UX + data + code) need coordinated improvement

**Do NOT use for:**
- Initial architecture design (use `/specification-driven-development`)
- **LLM scoring / classification / predictive ranking — use `/eval-driven-scoring`. This is a HARD route, not a suggestion.**
- Simple bugs with obvious fixes (just fix them)
- Performance optimization (different discipline — profile first)

**Relationship to eval-driven-scoring:** This skill is the generalized eval loop for *deterministic quality* (presence, shape, tone, content). `eval-driven-scoring` is the specialized sibling for *predictive quality* (classification, ranking). They are NOT interchangeable — predictive problems need holdouts, base rates, and discriminative ratios that this skill does not enforce.

---

## Step 0: Classify the Problem Type (MANDATORY — DO FIRST)

Before Step 1, classify the quality problem. Routing wrong here wastes work and can produce confidently wrong scoring models.

| Type | Example prompts | Route |
|---|---|---|
| **Presence / shape** | "field X doesn't appear", "link is missing", "button 404s", "schema missing column" | Continue with this skill |
| **Content quality** | "email tone is off", "copy is unclear", "card title is generic" | Continue with this skill |
| **Predictive / scoring** | "rule identifies good leads", "model predicts churn", "score ranks ICP accurately", "lead scoring misclassifies" | **STOP. Route to `/eval-driven-scoring` and read `references/statistical-validity-checks.md`. Do not proceed with this skill.** |
| **Mixed** | Data-shape targets + scoring targets together | Split targets: presence/shape continue here; scoring/predictive targets route to eval-driven-scoring separately |

### Why routing matters

Backpressure in this skill is *assertion-based* — "does this link exist", "does this card render", "is the post_url field populated". Those verifications pass when the fix is applied correctly.

Backpressure for predictive problems requires:
- **Ground truth provenance audit** — is the "correct label" independent of what you're predicting?
- **Base rate denominator** — what % of the universe fires this rule?
- **Discriminative ratio ≥ 2.0** — is the signal real or a base-rate artifact?
- **Holdout set** — does the rule generalize beyond tuning data?

None of these are in this skill. If you use this skill's backpressure on a scoring problem, you will produce a model that perfectly "passes" on known positives and fails on reality. **This is not hypothetical — it has happened and produced client-visible damage.**

### Routing examples

| User says | Type | Action |
|---|---|---|
| "Signal cards don't link to HubSpot" | Presence | Continue Step 1 |
| "Cold emails sound robotic" | Content quality | Continue Step 1 |
| "Our lead scoring is wrong on these deals" | Predictive | STOP. Route out. |
| "Build a model to identify good-fit contacts" | Predictive | STOP. Route out. |
| "Scoring model labels are right but UI doesn't show why" | Mixed | Split: UI target continues here; scoring target routes out |

---

## Core Pattern

```
SYMPTOM (specific, observed)
    "Lisa can't click the contact to see who they are"
         │
         ▼
GENERALIZE (what class of problem is this?)
    "Signal cards lack provenance — user can't trace to source"
         │
         ▼
ROOT CAUSES (first-principle gaps that create this class)
    1. Agent doesn't include post URLs in evidence
    2. contact_linkedin not mapped to UI component
    3. reasoning_trace field exists but UI doesn't render it
    4. No signal dedup across runs
         │
         ▼
TARGETS (measurable, with verification method)
    T1: "Every signal card has a clickable LinkedIn link" → Playwright assertion
    T2: "Reasoning trace visible on expand"              → Playwright assertion
    T3: "95% of signals include source post URL"         → Unit test on pipeline output
    T4: "No duplicate accounts across consecutive runs"  → Unit test on D1 query
         │
         ▼
FIX (one root cause at a time)
         │
         ▼
VERIFY (run the target's backpressure test)
    Pass → mark target complete, move to next
    Fail → diagnose, adjust fix, re-verify
         │
         ▼
LOOP until all targets pass
```

---

## The Five Steps

### Step 1: Surface and Confirm Symptoms

**Collect the specific complaints.** Not interpretations — the actual observable problems.

```markdown
## Symptoms (observed)
1. "I can't click on the contact and see who they are"
2. "There's no way to know if this was previously rejected"
3. "I can't see the LinkedIn post that triggered this signal"
4. "The evidence section just says 'LinkedIn' — that's paper thin"
```

**Ask:** "Is this the complete list, or are there more?" Surface ALL symptoms before proceeding. Fixing one while ignoring others wastes iterations.

### Step 2: Generalize to Problem Classes

**Group symptoms by the structural gap they share.**

One symptom can point to multiple classes. Multiple symptoms often share a root.

```markdown
## Problem Classes
A. PROVENANCE — User cannot trace a signal to its source data
   Symptoms: 1, 3, 4

B. CONTACT INTELLIGENCE — User cannot evaluate who the contact is
   Symptoms: 1, 2

C. SIGNAL DEDUP — System doesn't track cross-run history
   Symptoms: 2
```

**Why generalize?** Fixing the class fixes current AND future symptoms in that class. Fixing symptoms one-by-one is whack-a-mole.

### Step 3: Identify Root Causes per Class

**For each problem class, trace to concrete technical/architectural gaps.**

Root causes are things that can be fixed in code, data, prompts, or architecture. They are NOT symptoms restated.

```markdown
## Root Causes

### Class A: PROVENANCE
A1. Agent prompt doesn't instruct to include LinkedIn post URL in evidence_json
A2. evidence_json schema has no `post_url` field
A3. SignalCard component doesn't render source links
A4. Supabase intelligence_posts VIEW has post_url but pipeline doesn't query it

### Class B: CONTACT INTELLIGENCE
B1. contact_linkedin field exists in D1 but not mapped to UI
B2. No contact card component — just name + email as text
B3. No mailto: link on email
B4. No HubSpot link for the contact (only company)
```

**Test each root cause:** "If I fixed ONLY this, would it improve the symptom?" If yes, it's a real root cause. If not, dig deeper.

### Step 4: Define Targets with Backpressure

**Every root cause fix gets a measurable target. Every target gets a verification method.**

The verification method is the **backpressure** — the thing that tells you the fix actually worked, and catches regressions.

#### Backpressure Spectrum

Choose the lightest verification that catches the problem:

| Verification Type | When to Use | Example |
|-------------------|-------------|---------|
| **Unit test** | Logic, data shape, contracts | `expect(signal.evidence.post_url).toBeTruthy()` |
| **Integration test** | API responses, data flow | `fetch('/signals/1').then(r => expect(r.contact_linkedin).toMatch(...))` |
| **Playwright assertion** | UI presence, clickability, layout | `expect(page.locator('.contact-linkedin-link')).toBeVisible()` |
| **Playwright + screenshot** | Visual quality, design intent | Screenshot → human review or LLM-as-judge |
| **LLM-as-judge** | Tone, quality, rubric compliance | "Rate this email 1-10 on the Shakespeare rubric" |
| **Rubric scoring** | Content quality, brand voice | Structured rubric with weighted dimensions |
| **Manual checklist** | Last resort for subjective quality | "Does this feel right?" (avoid if possible) |

**Rule:** If you can write an automated test, write one. If the quality is inherently subjective, use LLM-as-judge with a rubric. Manual checklists are a smell — they don't enable iteration.

**Rule (added):** Backpressure here verifies *this specific instance* matches criteria. It does NOT verify the rule generalizes to unseen data. If the target is "rule correctly classifies", Step 0 routing should have sent you elsewhere.

#### Target Format

```markdown
## Targets

### T1: Signal cards link to contact LinkedIn profile
- Root cause: B1
- Backpressure: Playwright
- Test: `expect(page.locator('a[href*="linkedin.com/in/"]').first()).toBeVisible()`
- Pass criteria: Link visible, href matches contact_linkedin from API

### T2: 95% of signals include source post URL
- Root cause: A1, A2
- Backpressure: Unit test
- Test: Run pipeline on 20 accounts → `signals.filter(s => s.evidence.post_url).length / signals.length >= 0.95`
- Pass criteria: ≥95% of generated signals have non-null post_url

### T3: Cold emails sound like Shakespeare
- Root cause: Prompt doesn't reference style guide
- Backpressure: LLM-as-judge
- Rubric: references/shakespeare-rubric.md
- Test: Score 10 emails → average ≥ 8/10
- Pass criteria: Mean score ≥ 8, no individual score < 6
```

### Step 5: Iterate

**Fix one root cause at a time. Run its backpressure test. Keep or revert.**

```
Fix A1 (add post_url to agent prompt)
  → Run T2 (unit test: 95% have post_url)
  → Result: 60% have post_url (FAIL)
  → Diagnose: agent finds post but doesn't always extract URL
  → Adjust: add explicit instruction "always include post_url field"
  → Re-run T2: 98% (PASS) → KEEP

Fix B1 (map contact_linkedin to SignalCard)
  → Run T1 (Playwright: LinkedIn link visible)
  → Result: PASS
  → KEEP
```

**Iteration Rules:**
1. ONE fix per iteration (can't attribute improvement to bundled changes)
2. Run the SPECIFIC target test for that fix (not all tests every time)
3. After ALL fixes applied, run ALL target tests as regression suite
4. Log every iteration — even failures are data
5. After 3 failed iterations on the same root cause, question whether it's the real root cause

---

## State Files

Following the autoresearch pattern, state lives in two files so a fresh agent can continue:

| File | Purpose |
|------|---------|
| `eval-session.md` | Living document: symptoms, problem classes, root causes, targets, iteration log |
| `eval-results.jsonl` | Append-only log: one line per target verification run |

```jsonl
{"timestamp":"2026-03-31T17:00:00Z","target":"T1","method":"playwright","result":"pass","details":"LinkedIn link visible for all 3 signals"}
{"timestamp":"2026-03-31T17:05:00Z","target":"T2","method":"unit_test","result":"fail","details":"12/20 signals have post_url (60%)","iteration":1}
{"timestamp":"2026-03-31T17:30:00Z","target":"T2","method":"unit_test","result":"pass","details":"19/20 signals have post_url (95%)","iteration":2}
```

---

## Workflow Integration

### Reactive (quality complaint)

```
User: "This is a 3/10, the signal cards are paper thin"
  → Step 0: Classify (presence/content — continue)
  → Step 1: Surface all symptoms (interview user)
  → Step 2-4: Generalize → root causes → targets
  → Step 5: Iterate until targets pass
  → Outcome: "Here's what changed + verification results"
```

### Proactive (shipping a feature)

```
User: "We're about to ship the signal dashboard, what would 10/10 look like?"
  → Step 0: Classify (presence/content — continue)
  → Step 1: Define ideal experience (user stories or persona walkthrough)
  → Step 2: Identify gaps between current and ideal
  → Step 3-4: Root causes → targets
  → Step 5: Iterate until targets pass
  → Outcome: "Ship confidence: all N targets passing"
```

### Scoring problem (ROUTED OUT)

```
User: "Our lead scoring model is wrong on these deals"
  → Step 0: Classify (predictive — STOP)
  → Response: "This is a predictive problem. Routing to eval-driven-scoring.
     That skill requires: ground truth provenance audit, holdout split,
     discriminative ratio check. Do not attempt here — backpressure in this
     skill would produce a model that passes on known positives and fails
     on reality."
```

### Mixed (data + UX)

When symptoms span layers (data architecture + frontend + agent prompts), group targets by layer and fix bottom-up:

```
1. Data layer first (agent prompt, schema, pipeline)
   → Unit test backpressure
2. API layer next (routes, response shapes)
   → Integration test backpressure
3. UI layer last (components, pages)
   → Playwright backpressure
```

**Why bottom-up?** UI fixes on broken data are wasted work. Fix the data, then the UI will have something real to show.

---

## Applying to Multi-Dimensional Problems

Some quality gaps span UX + data + architecture simultaneously. The signal card problem is a good example:

| Dimension | Root Cause | Target | Backpressure |
|-----------|-----------|--------|-------------|
| **Data** | Agent doesn't include post URL | 95% of signals have post_url | Unit test |
| **Data** | No signal dedup across runs | 0 duplicate accounts in consecutive runs | Unit test |
| **API** | contact_linkedin not in API response | /signals/:id returns contact_linkedin | Integration test |
| **UX** | No LinkedIn link on contact name | Link visible and clickable | Playwright |
| **UX** | No reasoning trace display | "Why this signal?" expandable visible | Playwright |
| **UX** | No mailto: on email | Email is mailto: link | Playwright |
| **Content** | Email body too long (88 words vs 50-75 target) | Mean word count ≤ 75 | Unit test on pipeline output |

Fix order: Data → API → UX → Content (bottom-up).

**Note:** None of the above are predictive targets. They verify shape, presence, and bounded content quality. If the list included "scoring rule correctly identifies ICP," Step 0 would have routed that target to eval-driven-scoring.

---

## Quality Gates

### Before Starting

- [ ] **Step 0 complete — problem type classified, predictive problems routed out**
- [ ] All symptoms collected (not just the first one mentioned)
- [ ] User confirmed symptom list is complete
- [ ] Symptoms grouped into problem classes
- [ ] Root causes are technical/architectural (not symptoms restated)

### Before Iterating

- [ ] Every target has a defined backpressure method
- [ ] Backpressure can run without manual judgment (or has an explicit rubric for LLM-as-judge)
- [ ] Targets are independent (fixing T1 doesn't break T2)
- [ ] Fix order is bottom-up (data → API → UI)
- [ ] **No target implicitly asks "does this predict well?" — if any do, route to eval-driven-scoring**

### Before Declaring Done

- [ ] All target tests pass
- [ ] Full regression suite run (all targets, not just the last one fixed)
- [ ] Results logged to eval-results.jsonl
- [ ] eval-session.md updated with final state
- [ ] User shown the verification results (screenshots, test output)

---

## Product Standard (Cross-Page Quality Checklist)

Individual symptoms are reactive — you fix what's broken. But **product standards** are proactive — they define what "done" means for EVERY page before it ships. A product standard is a set of rules that apply uniformly, not per-symptom.

**When to apply:** After fixing specific symptoms, step back and ask: "Does every page in this product meet the same bar?" If not, the eval loop isn't done — you fixed the symptom but not the class.

### How to Define a Product Standard

A product standard is a checklist derived from the generalized problem classes. Each item is a rule that applies to every page/component, not to a specific instance.

```markdown
## [Product Name] Quality Standard

### Entity Linking
- Every company name → links to CRM (HubSpot, Salesforce, etc.)
- Every company name → links to internal account detail page
- Every contact name → links to LinkedIn profile (when URL available)
- Every contact name → links to CRM contact page (when ID available)
- Every email → mailto: link
- Every external URL → opens in new tab with rel="noopener"

### Data Provenance
- Every signal/insight → traceable to source data in ≤2 clicks
- Every AI-generated content → "Why?" expandable showing reasoning
- Every score/metric → breakdown visible on hover or expand

### Actionability
- No buttons that 404 or error — hide what's not built yet
- No empty states without explanation ("No data" → "No signals generated yet. Next run: 9am UTC")
- Every card/row has a clear primary action (approve, view detail, open in CRM)

### Consistency
- Same entity type links to the same destination across all pages
- Same visual pattern for the same data type (scores, dates, status badges)
- Nav reflects actual available pages — no links to removed routes
```

### How to Use It

**Step 0 (before Step 1 of the eval loop):** Check if a product standard exists for this product. If yes, run the checklist against every page FIRST. Any failures become automatic targets.

**After Step 5 (after fixing specific symptoms):** Re-run the product standard checklist against ALL pages. Specific symptoms may be fixed but the standard may reveal the same class of problem on other pages you didn't check.

**Backpressure for product standards:** Each checklist item maps to a Playwright assertion that can run against every route:

```typescript
// Product standard: every company name links to HubSpot
for (const route of ["/", "/accounts", "/linkedin", "/jobs"]) {
  test(`${route}: company names link to HubSpot`, async ({ page }) => {
    await page.goto(baseUrl + route);
    const companyLinks = page.locator('a[href*="app.hubspot.com"]');
    const count = await companyLinks.count();
    if (count > 0) {
      const href = await companyLinks.first().getAttribute("href");
      expect(href).toMatch(/app\.hubspot\.com\/contacts\/\d+\/company\/\d+/);
    }
  });
}
```

### Anti-Pattern: Fixing One Page, Forgetting the Rest

```
BAD:
  User: "Signal cards don't link to HubSpot"
  → Fix signal cards → ship
  → Accounts list has same problem → unfixed
  → User finds it next week → trust erodes

GOOD:
  User: "Signal cards don't link to HubSpot"
  → Generalize: "every entity should link to CRM"
  → Define product standard: entity linking rules
  → Apply to ALL pages before shipping
  → No surprise gaps on other pages
```

---

## References

- `references/backpressure-patterns.md` — Detailed patterns for each verification type
- `references/llm-judge-rubrics.md` — How to write effective rubrics for LLM-as-judge
- `eval-driven-scoring/references/statistical-validity-checks.md` — What scoring problems need (you shouldn't — Step 0 routes you out)

---

## Evidence Base

This skill generalizes patterns from:
- `eval-driven-scoring` — LLM classification eval loops (autoresearch + RLM patterns)
- Signal card quality iteration (client engagement, 2026) — UX + data + agent prompt multi-layer fix
- LinkedIn Intelligence Pipeline (20-hour refactor) — specification-driven with TDD backpressure
- Cold email quality iteration (PVP methodology) — content quality via rubric scoring
- **Client engagement retrospective (2026)** — user applied this skill (or eval-driven-scoring) to a lead scoring PRD. Skill over-indexed on a small set of contacts from known deals, derived scoring rules backwards from outcomes. Root cause: no Step 0 routing gate, no statistical validity discipline. This version hard-routes predictive problems OUT to eval-driven-scoring.
