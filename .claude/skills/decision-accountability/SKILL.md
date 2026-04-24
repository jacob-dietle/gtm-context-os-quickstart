---
name: decision-accountability
description: This skill should be used when making architectural decisions, writing specs, or reviewing decisions that contain "future work", "v2", "simpler for now", "out of scope", or complexity claims. Verifies assumptions are grounded and catches corner-cutting disguised as pragmatism. Applies to code, specs, data models, auth flows, and context structures.
---

# Decision Accountability

Unified check for assumption verification AND ownership accountability. Both failures lead to the same outcome: decisions that cost 10x to fix later.

## When to Use

- Writing or reviewing specs
- Any architectural decision (code, auth, data model, context structure)
- When these phrases appear: "future work", "v2", "later", "simpler for now", "out of scope"
- When deferring anything that might be foundational
- Before finalizing any decision that persists

## The Dual Failure Mode

**Epistemic failure:** "I assumed X was complex without checking"
**Ownership failure:** "I avoided checking because the answer might mean more work"

Both produce: deferred foundations, duplicate implementations, tech debt disguised as pragmatism.

**The laziness cascade:**
1. See decision point
2. One path looks like more work
3. Don't verify (because verification might confirm it's the right path)
4. Pick easy path
5. Dress it up as "tradeoff" or "v1 scope"
6. Abdicate: "future work"

## Step 1: Extract Decisions and Claims

From the spec/decision, list all claims and deferrals:

| Decision | Rationale Claims | Deferrals |
|----------|------------------|-----------|
| [What was decided] | [Claims used to justify] | [What was pushed to "later"] |

**Example:**
| Decision | Rationale Claims | Deferrals |
|----------|------------------|-----------|
| MCP has own /login | "Cross-subdomain is complex" | "SSO is future work" |

## Step 2: Verify Every Claim

For each claim, attempt to falsify it:

### Complexity Claims

Write the implementation. If it's <20 lines, the claim is falsified.

```
Claim: "Cross-subdomain cookies add complexity"

Verification:
cookies.set('session', token, { domain: '.tastematter.dev' });

Verdict: FALSIFIED — one line, not complex
```

### Simplicity Claims

Show both options concretely:

```
Claim: "Separate login per service is simpler"

Option A (spec chose): MCP /login + Browser /login = 2 implementations
Option B (alternative): Browser /login only = 1 implementation

Verdict: FALSIFIED — "simpler" option is actually more complex
```

### Deferral Claims

Calculate cost now vs later:

```
Claim: "SSO is future work"

Cost now: Use parent domain cookie (1 line change)
Cost later: Migrate two auth flows, reconcile sessions, update both services, migration period

Verdict: FALSIFIED — deferral costs 10x more
```

## Step 3: Ownership Test

For each decision, answer honestly:

### The Avoidance Check
> Did you avoid verifying because the answer might mean more work?

If yes → Go verify NOW. You're avoiding, not deciding.

### The Timeline Test

| Timeframe | Question | If answer is concerning... |
|-----------|----------|---------------------------|
| 6 months | Will this be debt or foundation? | It's the wrong decision |
| 12 months | Will someone undo this to build forward? | It's the wrong decision |
| 5 years | Thank yourself or curse yourself? | It's the wrong decision |

### The Maintenance Test
> If you had to maintain this for 5 years, would you make the same decision?

If no → You're optimizing for "not my problem" — that's abdication, not engineering.

## Step 4: Classify Deferrals

| Item | Foundational? | Can Defer? |
|------|--------------|------------|
| Auth flow unification | YES | NO |
| Cookie/token scoping | YES | NO |
| Data models crossing boundaries | YES | NO |
| State multiple services share | YES | NO |
| API contracts between services | YES | NO |
| Spec architecture for multi-phase work | YES | NO |
| Additional OAuth provider | NO | YES |
| UI polish | NO | YES |
| Analytics | NO | YES |
| Documentation | NO | YES |

**Foundational items cannot be deferred.** There is no "v2" for foundations — only rewrites.

## Step 5: Block or Proceed

### If any foundational claim is falsified or deferred:

**BLOCKED.** Do not proceed. Revise decision first.

Provide:
- Which claims were falsified with evidence
- The actual implementation that disproves the complexity claim
- Revised decision based on verified assumptions

### If proceeding with legitimate deferrals:

Each deferral MUST have:

| Field | Required Content |
|-------|-----------------|
| **Why not now** | Actual blocker (not "too much work") |
| **Cost comparison** | Now vs later, with estimates |
| **Owner** | Who will do it (default: you) |
| **Trigger/deadline** | When it gets done |

No orphaned "future work." If you can't fill these out, you're abandoning, not deferring.

## Output Format

```markdown
## Decision Accountability Report

**Decision under review:** [What's being decided]

### Claims Verified

| Claim | Type | Verdict | Evidence |
|-------|------|---------|----------|
| "X is complex" | Complexity | VERIFIED/FALSIFIED | [Implementation or docs] |
| "Y is simpler" | Simplicity | VERIFIED/FALSIFIED | [Both options shown] |
| "Z can wait" | Deferral | VERIFIED/FALSIFIED | [Cost comparison] |

### Ownership Check

| Question | Answer | Concern? |
|----------|--------|----------|
| Avoided verification? | Yes/No | |
| 6mo: debt or foundation? | | |
| 12mo: undo to build forward? | | |
| 5yr: thank or curse? | | |

### Deferrals (if any)

| Item | Foundational? | Why not now | Cost now/later | Owner | Deadline |
|------|--------------|-------------|----------------|-------|----------|
| | | | | | |

### Verdict

[ ] **PROCEED** — all claims verified, no foundational deferrals
[ ] **BLOCKED** — falsified claims or foundational deferrals, revise first

### Revised Decision (if blocked)

[New decision based on verified assumptions and owned outcomes]
```

## Quick Reference

### Red Flag Phrases

| Phrase | Action |
|--------|--------|
| "adds complexity" | Verify — write the implementation |
| "simpler for now" | Show total cost comparison |
| "future work" / "v2" | Foundational or additive? |
| "we can unify later" | At what cost? Show the math |
| "accepted tradeoff" | Is the analysis actually correct? |
| "out of scope" | Is this actually out of scope or foundational? |

### Cannot Defer (Foundational)

- Auth / sessions / identity
- Data models crossing service boundaries
- Cookie / token scoping
- API contracts between services
- State that multiple services touch
- Spec architecture for complex multi-phase work

### The Core Test

> Would I make this decision if I'm maintaining it for 5 years?

If no, it's corner-cutting disguised as pragmatism. Do it right.

## Evidence Base

**Origin:** C1 MCP Auth Foundation spec review (2026-04-23)

The spec contained decision D5:
> "Login UI served from MCP worker directly (not browser worker)... Cross-subdomain cookie sharing adds complexity... Two login pages accepted for v1. Single-sign-on is future work."

**Analysis revealed:**
- "Cross-subdomain cookies" = one line: `domain: '.tastematter.dev'`
- "Two login pages simpler" = false, it's 2x implementation and maintenance
- "SSO is future work" = will cost 10x to unify later

**Root causes identified:**
1. Epistemic: Complexity claim unverified
2. Ownership: Avoided verification because answer meant more work

**Pattern extracted:** Both failures stem from optimizing for "less work now" at the cost of "much more work later" — and dressing it up as pragmatism.
