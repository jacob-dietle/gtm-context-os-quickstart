# Decision Accountability Failure Patterns

Reference for identifying and classifying decision failures.

## The Two Root Causes

### 1. Epistemic Failure (Unverified Assumptions)

**Pattern:** Treating "sounds complex" as "is complex" without verification.

**Mechanism:**
1. Encounter something unfamiliar
2. Pattern-match to "sounds hard"
3. Accept assumption without testing
4. Build decision on unverified foundation

**Detection:**
- Complexity claims without implementation evidence
- "This would require..." without showing what
- "Cross-X is complex" (often one line in reality)

**Fix:** Write the implementation before claiming complexity.

### 2. Ownership Failure (Corner-Cutting)

**Pattern:** Avoiding work you know (or could know) is correct.

**Mechanism:**
1. See decision point
2. One path looks like more work
3. Avoid verifying (might confirm it's the right path)
4. Pick easy path
5. Rationalize as "pragmatism"
6. Defer accountability: "future work"

**Detection:**
- Avoiding verification that might reveal more work
- "Simpler for v1" without total cost analysis
- "We can unify later" on foundational items
- Orphaned "future work" with no owner/deadline

**Fix:** Apply 5-year ownership test before deciding.

## Combined Failure: Deferred Integration Fallacy

When both failures combine:

1. **Epistemic:** Assume integration is complex (without verifying)
2. **Ownership:** Defer integration to "future work" (avoiding the work)
3. **Result:** Build two separate implementations
4. **Consequence:** 10x cost to unify later (or never unify)

**Classic example:**
> "Each service has its own login. Cross-domain SSO is future work."

**Reality:**
- Cross-domain cookie: one line
- Two login flows: 2x implementation, 2x maintenance, migration cost
- "Future work" never happens or costs 10x

## Failure Taxonomy

### Level 1: Phrase-Level Indicators

| Phrase | Likely Failure | Verification Needed |
|--------|---------------|---------------------|
| "adds complexity" | Epistemic | Write the implementation |
| "simpler for now" | Both | Show total cost |
| "future work" | Ownership | Why not now? Owner? Deadline? |
| "v2" | Ownership | Foundational or additive? |
| "out of scope" | Both | Actually out of scope? |
| "we can unify later" | Both | At what cost? |
| "accepted tradeoff" | Both | Is analysis correct? |
| "two X for now" | Both | Why not one X? |

### Level 2: Decision-Level Patterns

| Pattern | Description | Red Flag |
|---------|-------------|----------|
| Duplicate-then-merge | Build two, unify later | Foundational items |
| Scope-per-service | Each service owns its X | X crosses boundaries |
| Temporary-becomes-permanent | "Just for v1" | No removal trigger |
| Orphaned deferral | "Future work" without owner | No accountability |

### Level 3: Architectural Smells

| Smell | Example | Correct Alternative |
|-------|---------|-------------------|
| Per-service auth | MCP login + Browser login | Unified auth, shared cookie |
| Per-service state | MCP session + Browser session | Parent domain cookie |
| Per-service data model | MCP users + Browser users | Single source of truth |
| Duplicated contracts | API defined in each service | Shared types package |

## The Rationalization Spectrum

How corner-cutting gets dressed up:

| Rationalization | Reality |
|-----------------|---------|
| "Pragmatic" | Lazy |
| "Ship faster" | Pay later |
| "Simpler for v1" | More complex for v2-vN |
| "Accepted tradeoff" | Unverified assumption |
| "Out of scope" | Avoiding foundation work |
| "We can always..." | We won't |

## Verification Protocols

### For Complexity Claims

1. Write the implementation (even pseudocode)
2. Count lines / moving parts
3. <20 lines and no external dependencies = not complex

### For Simplicity Claims

1. Show Option A implementation
2. Show Option B implementation
3. Compare: LOC, dependencies, maintenance surface, integration cost

### For Deferral Claims

1. Calculate cost now (implementation effort)
2. Calculate cost later (implementation + migration + reconciliation)
3. Identify owner (default: you)
4. Set deadline or trigger

### For Ownership

1. 6-month test: Debt or foundation?
2. 12-month test: Will it need undoing?
3. 5-year test: Thank or curse yourself?

## Recovery Protocol

When a bad decision is discovered:

1. **Acknowledge** — Name the failure mode (epistemic, ownership, or both)
2. **Verify** — What's the actual complexity/cost?
3. **Assess** — Is this still fixable at 1x cost, or already 10x?
4. **Fix** — If 1x, fix now. If 10x, plan the migration.
5. **Learn** — What verification would have caught this?

## Prevention Checklist

Before finalizing any decision:

- [ ] All complexity claims verified with implementation evidence?
- [ ] All simplicity claims shown with both options?
- [ ] All deferrals classified as foundational vs additive?
- [ ] No foundational items deferred?
- [ ] All legitimate deferrals have owner + deadline?
- [ ] 5-year ownership test passed?
- [ ] Would I make this decision if maintaining it forever?
