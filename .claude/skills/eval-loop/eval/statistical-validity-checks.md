# Statistical Validity Checks for Scoring Skills

Operational runbook for preventing the backwards-reasoning failure mode: agent derives scoring rules from known positives, declares victory, real deployment falls over.

**Apply before and during any iteration of an LLM-powered scorer/classifier/ranker.**

---

## 1. Ground Truth Provenance — The First Gate

### Contaminated sources (STOP — do not use as ground truth)

| Source | Why it's contaminated |
|---|---|
| "Contacts associated with closed/won deals" | Pre-filtered on the outcome you're predicting. Using outcomes as predictors = tautology. |
| "Accounts in active pipeline past stage X" | Pipeline stage is an outcome of prior scoring — training on your own output. |
| "Leads that our sales team engaged with" | Sales engagement is already scored informally — you're copying existing bias. |
| "Companies we consider good-fit" | Circular — unless "good-fit" was labeled before any data was seen, it's hindsight. |

### Clean sources (USE)

| Source | Why it's clean |
|---|---|
| Expert labeled N items blind to scores (ideally pre-registered) | Independent judgment, not outcome-derived |
| Historical labels from before current system existed | Temporally independent |
| External benchmark (published industry data, research dataset) | Provenance documented, selection known |
| Adversarial dual labeling (two experts, disagreement resolved) | Inter-rater reliability measurable |

### Acceptable with caveat

| Source | Caveat |
|---|---|
| Production override/feedback data | Encodes past model's blind spots — do not claim generalization beyond those errors |
| Domain expert proxy criteria (codified rules) | You're testing the rules, not the reality — rules can be wrong |

---

## 2. Selection Bias Audit

Every labeled set is a sample from some population. Write out:

```
Population P: [full addressable universe]
Sampling filter F: [how items entered the labeled set]
Inclusion rate: |labeled| / |P|
Excluded subpopulation E: [P minus labeled — what's missing]
```

**Red flag:** E is much larger than labeled, AND E was excluded for reasons correlated with the target variable.

Example:
- P = all leads in CRM (2000)
- Labeled = 8 contacts associated with won deals
- F = "reached deal close stage" → selects on conversion, which IS the target
- E = 1992 leads that didn't close for many reasons (no fit, bad timing, wrong decision-maker, reached out too early, competitor won, etc.)

Any rule derived from the 8 will treat "no fit" and "bad timing" as equivalent to "good fit" — both just "not in labeled set."

---

## 3. Base Rate Denominator

### The number you must have

```
Base rate = P(positive class | full universe)
```

If you don't know this, you cannot compute discriminative power of any rule.

### How to estimate when exact is impossible

1. **Direct count** — if full universe is queryable (e.g., HubSpot export), just count
2. **Reasonable bounds** — "certainly not more than 20%, certainly not less than 1%" — bounds let you reason directionally
3. **Proxy from similar company** — industry benchmark (e.g., B2B SaaS MQL→SQL ~2-10%)

### Example computation (SQL template)

```sql
-- Base rate of "positive" in universe
SELECT
  COUNT(*) FILTER (WHERE is_positive) * 1.0 / COUNT(*) AS base_rate,
  COUNT(*) FILTER (WHERE is_positive) AS positives,
  COUNT(*) AS total
FROM leads;

-- Rule fire rate in positive class vs negative class
SELECT
  is_positive,
  AVG(CASE WHEN has_vp_title THEN 1.0 ELSE 0.0 END) AS rule_fire_rate
FROM leads
GROUP BY is_positive;
```

---

## 4. Discriminative Ratio Check

```
DR = P(rule fires | positive) / P(rule fires | negative)
```

| DR | Verdict | Example |
|---|---|---|
| ≥ 3.0 | STRONG signal | 85% positives have trait X, 15% negatives → DR 5.7 |
| 2.0-3.0 | ACCEPTABLE signal | 60% positives, 25% negatives → DR 2.4 |
| 1.5-2.0 | WEAK signal (flag) | 50% positives, 30% negatives → DR 1.67 |
| 1.0-1.5 | REJECT (base rate artifact) | 60% positives, 55% negatives → DR 1.09 |
| < 1.0 | REJECT (anti-signal) | Rule fires MORE on negatives |

**Insufficient sample warning:** If either class has < 20 items, DR is unstable. Treat as directional, not decisive.

---

## 5. Holdout Split Procedure

### When to split

Any predictive rule that will be iterated on based on measured accuracy.

### How to split

1. Before any iteration: random sample 30% of labeled set → `holdout`
2. Write holdout IDs to `eval-holdout-ids.txt` — commit this file, do not read during iteration
3. Iterate on remaining 70% (`iteration set`)
4. At convergence, run scoring on holdout ONCE, record accuracy
5. Report both numbers — the gap is the generalization cost

### Gap interpretation

| Iteration − Holdout | Interpretation | Action |
|---|---|---|
| < 3pp | Generalizes well | Ship |
| 3-10pp | Mild overfit | Ship with caveat |
| > 10pp | Overfit | Revert last N iterations, remeasure |

### When splitting is not possible

- Labeled N < 30 → cannot split and retain meaningful size on either side
- In this case, do NOT iterate. Produce a "hypothesis-generating" output labeled as directional.

---

## 6. Confounder Identification

For every proposed rule, ask:

1. Is there a third variable that correlates with BOTH the rule and the outcome?
2. Example: "Positives are all construction" and "Positives all have >$1M revenue" → rule "construction + $1M" might just be "any large industrial firm"
3. Check by conditioning: does the rule still discriminate WITHIN a single confounder level?

### Test

```
P(rule fires | positive, conditional on Z) / P(rule fires | negative, conditional on Z)
```

If the ratio collapses toward 1 when you control for Z, Z was the real signal.

---

## 7. Sample Size Power Table

Approximate minimum N per class to detect effects:

| Effect size (DR) | Minimum N per class | Total labeled |
|---|---|---|
| Very strong (DR ≥ 5) | 10 | 20 |
| Strong (DR ≥ 3) | 20 | 40 |
| Moderate (DR ≥ 2) | 50 | 100 |
| Weak (DR ≥ 1.5) | 200 | 400 |

Below these thresholds, your ability to detect the effect is weak — you cannot distinguish "no signal" from "signal masked by noise."

---

## 8. Backwards Reasoning Detector

Before accepting any proposed rule, ask:

**Q1:** Did I derive this hypothesis by examining known positive examples?

- If YES → the rule will fit those examples by construction. Must prove with:
  - Independent discriminative ratio computation
  - Holdout set validation
  - Preferably: replication on fresh sample

- If NO → hypothesis came from domain knowledge / theory / expert statement. Still must pass DR check, but lower burden.

**Q2:** What would FALSIFY this rule? Describe the observation that would make you reject it.

- If you cannot describe falsification → the hypothesis is unfalsifiable. Do not use.

**Q3:** If the rule is wrong, what is the cost of the false positive / false negative?

- Asymmetric costs mean your acceptance threshold should be asymmetric.

---

## 9. Iteration Log Template

Every iteration writes to `eval-session.md`:

```markdown
### Iteration N: [one-line description]
- **Hypothesis source:** [domain expert / theory / error pattern / BACKWARDS-FROM-POSITIVES]
- **Backwards reasoning check:** [YES/NO — if YES, required evidence below]
- **Base rate in universe:** [number with source]
- **Rule fire rate on positives:** [number]
- **Rule fire rate on negatives:** [number]
- **Discriminative ratio:** [computed] → [PASS/WEAK/FAIL]
- **Confounders considered:** [list]
- **Change:** [what was modified]
- **Result (iteration set only):** [accuracy before → after]
- **Holdout:** UNTOUCHED
- **Decision:** [KEEP / REVERT]
```

Without all fields completed, no iteration proceeds.

---

## 10. Convergence and Holdout Validation

Only run this ONCE, after iteration stops:

```markdown
## Final Validation

**Iteration set accuracy (final config):** [X%]
**Holdout set accuracy (measured once, first time):** [Y%]
**Gap:** [X - Y]pp
**Verdict:** [GENERALIZES / OVERFIT]

**If overfit:** revert the last N iterations that over-indexed on iteration set peculiarities. Document which iterations were reverted and why.

**If generalizes:** ship. Record the expected production accuracy as Y%, not X%.
```

---

## Common Traps (Checklist)

- [ ] "All our customers have X" — what % of non-customers have X too?
- [ ] "N=8 is enough to see the pattern" — no, N=8 fits ANY pattern perfectly by accident
- [ ] "The scoring model has 90% accuracy on our test set" — same test set you iterated on?
- [ ] "We know good-fit when we see it" — can you label 30 items blind to any other data?
- [ ] "The rule matches 7/8 positive examples" — and how many of the other 1992 items does it match?
- [ ] "This feels right" — is there any number attached to that feeling?

---

## Evidence Base

- **Client engagement retrospective (2026)** — a lead scoring PRD in which the agent derived rules from a small set of contacts associated with known deals; the user had to manually override multiple conclusions. The resulting ask — "basic sanity checks on correlation does not equal causation ... basic data validation from a stats perspective" — motivates this document.
- **Standard ML / statistics practice** — train/test split, base rates, discriminative power are not novel; they are table stakes in any responsible scoring pipeline. This document codifies them at the skill level so they become unavoidable.
