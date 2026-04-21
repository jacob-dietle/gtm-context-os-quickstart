---
name: coordinated-agent-teams
description: This skill should be used when decomposing a spec into a multi-agent implementation plan with dependency ordering, parallelism decisions, contract testing, and verification strategy. Applies evidence from 5 verified multi-agent builds (sequential handoff, parallel fanout, mixed waves, corpus-wide single-agent, phased query engine) to prevent the common failure modes — integration surprises, context loss, silent failures, and over-specification overhead. Use when the implementation involves 3+ agents, has parallelization opportunities, or requires handoffs across context windows.
---

# Coordinated Agent Teams

Methodology for decomposing implementation specs into agent DAGs with verified coordination patterns. Prevents integration surprises through contract-first boundaries, evidence-based parallelism decisions, and independent verification.

**Meta-Principle:** "The coordination overhead must cost less than the parallelism saves. If the DAG plan takes longer to write than sequential execution would take, just build it sequentially."

---

## When to Use This Skill

**Apply this skill when:**
- Implementation spec exists and needs decomposition into agent tasks
- 3+ agents will work on interdependent modules
- Parallel execution would save meaningful wall-clock time
- Work spans multiple context windows or worktrees
- Integration risk is high (multiple agents writing to connected systems)

**Do NOT use for:**
- Solo agent implementations (< 3 agents)
- Embarrassingly parallel work (no dependencies, e.g., batch processing)
- Exploratory work without a spec (use `feature-planning` first)
- Work that fits in a single context window

**The tell:** If you're drawing arrows between agents on a napkin, use this skill. If you can describe the build as "just do steps 1-5 in order," don't.

---

## The Coordination Overhead Test (Run First)

Before planning ANY multi-agent build, answer honestly:

```
Total estimated agent-hours:        ___ hours
Estimated spec-writing time:        ___ hours
Estimated merge/integration time:   ___ hours
Coordination overhead:              ___ hours (spec + merge)

Sequential build time:              ___ hours (agent-hours, no parallelism)
Parallel build time:                ___ hours (critical path + coordination)

Is parallel faster?                 ___ yes/no
By how much?                        ___ hours saved
```

**If coordination overhead > 30% of sequential build time → just build sequentially.**

The LinkedIn Pipeline succeeded with sequential agents (~15 hours, zero context loss). A transcript processing build succeeded with ~15 parallel agents (minutes end-to-end). The difference: transcript processing was embarrassingly parallel (disjoint batches). Pipeline phases were interdependent (sequential was correct).

---

## Three Verified Coordination Patterns

### Pattern 1: Sequential File-Based Handoffs

```
Agent 0 → Agent 1 → Agent 2 → Agent 3
  types     impl      impl     integration
```

**When to use:** Phases are interdependent. Each agent's output informs the next.

**Evidence:** LinkedIn Pipeline (~6 agents across multiple sessions, zero context loss), Query Engine Build (~6 phases, 200+ tests).

**How it works:**
1. Each agent writes a completion report before finishing
2. Next agent reads the report (not conversation history)
3. Type contracts defined upfront, refined by each agent
4. Git commit after each agent completes

**Strengths:** Reliable. Simple. Proven 5x. Each agent benefits from prior agent's discoveries.

**Weaknesses:** Wall-clock time = sum of all agents. No parallelism.

**Use when:** Agents discover things that change downstream work. Integration complexity is high. Team size < 5 agents.

---

### Pattern 2: Parallel Fanout-Fanin

```
         Agent 0 (foundation)
        /    |    \
  Agent 1  Agent 2  Agent 3  (parallel, disjoint)
        \    |    /
         Agent 4 (integration)
```

**When to use:** Work units are disjoint — each agent writes to different files with no shared state.

**Evidence:** Transcript processing build (~15 parallel agents, ~150 transcripts, 100% success), KB Orchestration Wave 1 (3 parallel analysts → synthesis).

**How it works:**
1. Foundation agent produces type contracts + test fixtures
2. Parallel agents work in worktrees or on disjoint file sets
3. Each produces output conforming to pre-defined contracts
4. Integration agent merges, runs contract tests, verifies

**Strengths:** Wall-clock time drops to longest-agent + coordination. Linear speedup for disjoint work.

**Weaknesses:** Can't adapt to discoveries mid-flight. Merge step adds complexity. Over-specification risk.

**Use when:** File boundaries perfectly match agent boundaries. Type contracts are stable (won't change during implementation). Each agent's work is 1+ hours (parallelism overhead only pays off above this threshold).

---

### Pattern 3: Foundation + Waves

```
  Agent 0 (foundation: types, migration, test helpers)
      │
  ┌───┼───┐  Wave 1 (parallel, disjoint modules)
  A1  A2  A3
  └───┼───┘
      │
  A4 → A5    Wave 2 (sequential, builds on Wave 1)
      │
  Agent 6    Wave 3 (integration + verification)
```

**When to use:** Mixed dependency structure — some modules are independent, others are sequential.

**Evidence:** KB Orchestration build (Wave 1 parallel → Wave 2 sequential → synthesis), another multi-agent build (foundation → 2 parallel agents → integration).

**How it works:**
1. Foundation agent establishes all contracts and shared infrastructure
2. Wave 1: parallel agents build independent modules
3. Wave 2: sequential agents that depend on Wave 1 outputs
4. Final wave: integration agent runs E2E verification

**Strengths:** Best of both patterns. Parallel where possible, sequential where necessary.

**Weaknesses:** Most complex to plan. Requires accurate dependency analysis upfront. Wave boundaries must be correct.

**Use when:** Dependency graph has both independent and dependent subgraphs. Build is large enough (5+ agents) that parallelism savings justify planning overhead.

---

## The 8 Pre-Launch Questions

Answer ALL of these before launching any agent team. If any answer is "I don't know," stop and figure it out.

### Q1: Can each agent's work be defined by its file outputs?

List every file each agent creates or modifies. If two agents write to the same file, they cannot run in parallel.

```markdown
| Agent | Creates | Modifies | Reads |
|-------|---------|----------|-------|
| A0 | types.ts, migration.sql, helpers.ts | - | spec |
| A1 | hubspot.ts, hubspot.test.ts | - | types.ts |
| A2 | db.ts, db.test.ts | - | types.ts |
| A3 | slack-digest.ts, slack.test.ts | - | types.ts |

Conflicts: NONE → safe to parallelize A1, A2, A3
```

**If conflicts exist:** Either redesign boundaries or sequence the conflicting agents.

### Q2: What is the contract test for each boundary?

For every arrow in the DAG, write a one-line contract test:

```markdown
| Boundary | Contract Test |
|----------|--------------|
| A0 → A1 | types.ts compiles, HubSpotContact interface importable |
| A1 → A4 | fetchModifiedContacts() returns HubSpotContact[] matching fixture |
| A4 → A5 | triageContact() returns TriageResult matching fixture |
| A5 → A6 | enrichLead() returns EnrichmentResult matching fixture |
| A6 → A7 | runPipeline() returns PipelineRunResult matching fixture |
```

**If you can't write the contract test:** The boundary isn't defined well enough. Refine the type contract before launching agents.

### Q3: What happens when an agent fails?

For each agent, define the failure mode:

```markdown
| Agent | If Fails | Impact | Recovery |
|-------|----------|--------|----------|
| A0 | Nothing works | BLOCKING | Must fix before any other agent |
| A1 | No HubSpot data | Pipeline runs with test data only | Re-run A1 |
| A2 | No D1 operations | Pipeline can't persist | Re-run A2 |
| A5 | No enrichment | Pipeline triages but doesn't enrich | Skip enrichment, deliver raw triage |
```

### Q4: Is the spec-writing time justified?

```
Agent count:              ___
Spec lines per agent:     ___ (150-200 for thin, 500-700 for thick)
Total spec-writing time:  ___ hours
Total implementation:     ___ hours

Ratio: spec / implementation = ___

If ratio > 0.5 → specs are too thick. Trim to contracts + success criteria + pitfalls.
If ratio < 0.1 → specs are too thin. Agents will re-explore and waste time.
Sweet spot: 0.15 - 0.30
```

### Q5: What is the merge strategy?

| Strategy | When to Use | Risk |
|----------|-------------|------|
| **Same branch, sequential** | Agents run in same session | Lowest risk, no merge |
| **Worktrees, auto-merge** | Disjoint file sets, no conflicts expected | Low risk if file boundaries are clean |
| **Worktrees, manual merge** | Overlapping file sets | Higher risk, needs human review |
| **Branches, PR-based** | Multiple humans involved | Highest coordination cost |

### Q6: Who verifies the final integration?

Self-reported "✅ COMPLETE" is insufficient. The final agent must be a **verification agent**:

- Runs ALL tests (not just its own)
- Runs the E2E test with real(ish) data
- Verifies every contract test passes
- Reports discrepancies between agents' claims and reality

### Q7: What's the minimum viable team size?

Every agent adds coordination overhead (~15-30 minutes of spec + handoff). Calculate:

```
Overhead per agent:           ~20 min
Parallelism savings per wave: ~60 min per parallel agent

Break-even: 3+ parallel agents per wave
Below 3: sequential is faster including overhead
```

**Rule of thumb:** If the build is under 5 hours of agent work, use 2-3 agents sequentially. Reserve large teams (5+) for builds over 8 hours.

### Q8: What are the test fixtures?

Before any agent starts, produce test fixtures for every boundary:

```typescript
// fixtures/hubspot-contacts.ts
export const TEST_CONTACTS: HubSpotContact[] = [
  makeContact({ company: undefined }),           // → DISMISS
  makeContact({ company: "Ok Corp" }),            // → MONITOR
  makeContact({ source: "demo-request" }),        // → ESCALATE
];

// fixtures/triage-results.ts
export const EXPECTED_TRIAGE: TriageResult[] = [
  { tier: "DISMISS", score: 10, matched_rule: "no_identity" },
  { tier: "MONITOR", score: 55, matched_rule: "default_monitor" },
  { tier: "ESCALATE", score: 92, matched_rule: "demo_request" },
];
```

These fixtures ARE the coordination mechanism. Each agent implements logic that transforms its input fixture into its output fixture. The integration agent verifies the chain: fixture A → Agent 1 → fixture B → Agent 2 → fixture C.

---

## Agent Task Spec Template

Each agent receives a task spec. Thickness depends on isolation level:

### Thin Spec (150-200 lines) — For Sequential Agents in Same Session

```markdown
## Agent N: [Name]

**Mission:** [One sentence — what this agent builds]

**Reads:** [Files to read before starting]
**Creates:** [Files this agent produces]
**Modifies:** [Existing files this agent changes — be specific]

**Type contracts:**
- Input: [TypeName from types.ts]
- Output: [TypeName from types.ts]

**Contract tests (write first):**
1. [Test name]: [One-line description]
2. [Test name]: [One-line description]

**Success criteria:**
- [ ] All contract tests pass
- [ ] [Domain-specific criterion]
- [ ] No modifications to files outside "Creates" and "Modifies" lists

**Pitfalls:**
- [Specific gotcha from consequence analysis]
- [Specific gotcha from evidence base]
```

### Thick Spec (500+ lines) — For Worktree/Parallel Agents

Add to the thin spec:
- Step-by-step implementation guide
- Full type contract source (not just references)
- Example code snippets for tricky patterns
- Common error messages and their fixes
- Integration notes for downstream agents

**When to use thick specs:** Agent runs in a worktree (can't ask questions), agent is implementing unfamiliar patterns (e.g., first HubSpot integration), or prior agents have failed at this task.

---

## DAG Validation Checklist

Before launching any agent:

- [ ] Coordination Overhead Test passed (overhead < 30% of sequential time)
- [ ] All 8 pre-launch questions answered
- [ ] File output matrix has zero conflicts for parallel agents
- [ ] Contract test exists for every DAG edge
- [ ] Test fixtures exist for every boundary
- [ ] Failure mode documented for every agent
- [ ] Merge strategy chosen and documented
- [ ] Verification agent is the final agent (not just integration)
- [ ] Minimum viable team size justified (not over-decomposed)

---

## Anti-Patterns

| Anti-Pattern | What Happens | Evidence | Instead |
|---|---|---|---|
| **Over-decomposition** | 7 agents for 5 hours of work. Coordination overhead exceeds savings. | LinkedIn Pipeline worked in ~15 hours with 6 sequential agents | Use minimum viable team size |
| **Parallel agents with shared writes** | Merge conflicts, integration surprises | Worktree agents modifying same file | Design file boundaries to match agent boundaries |
| **Thick specs for simple agents** | 2 hours speccing a 1-hour task | Spec-to-implementation ratio > 0.5 | Use thin specs: contracts + criteria + pitfalls |
| **No contract tests** | "It compiled" but outputs don't match expectations | Bug #19: silent persistence failure | Write boundary tests before any implementation |
| **Self-reported verification** | Agent says "✅ COMPLETE" but output is wrong | Try/catch masking real failures | Independent E2E test as final gate |
| **Parallel discovery** | 3 agents run, Agent 2 discovers something Agent 3 needs | Can't communicate mid-flight in parallel | Only parallelize when contracts are stable and complete |
| **Conversation-based handoffs** | Next agent reads chat history instead of completion report | Context loss on compaction | File-based handoffs: completion report + context package |

---

## Integration with Other Skills

### Upstream (use BEFORE this skill)

| Skill | What It Provides |
|---|---|
| `product-thinking` | The job — what gets built |
| `feature-planning-and-decomposition` | Architecture — how it decomposes |
| `consequence-driven-design` | Design decisions — what to watch for |
| `specification-driven-development` | The spec — what agents implement |

### This Skill Produces

| Output | Used By |
|---|---|
| Agent DAG with dependency ordering | Human orchestrator |
| Task specs per agent | Each agent |
| Contract tests + fixtures | All agents + verification agent |
| Merge strategy | Human or integration agent |

### Downstream (use DURING execution)

| Skill | When |
|---|---|
| `test-driven-execution` | Each agent writes tests first |
| `epistemic-context-grounding` | Agents ground in domain knowledge |
| `context-package` | Agents preserve state at completion |
| `debugging-and-complexity-assessment` | When agents hit blockers |

---

## Evidence Base

**5 verified multi-agent builds inform this skill:**

| Build | Pattern | Agents | Key Metric | Lesson |
|---|---|---|---|---|
| LinkedIn Intelligence Pipeline | Sequential handoffs | ~6 agents across multiple sessions | Zero context loss, many bugs fixed first try | File-based handoffs work. Thick specs prevent re-exploration. |
| Transcript Processing | Parallel fanout | ~15 agents | 100% success, <$0.20/item, minutes end-to-end | Embarrassingly parallel = massive speedup. Disjoint batches only. |
| KB Orchestration | Wave 1 parallel → Wave 2 sequential | ~6 agents across 2 waves | 3 analysis → 1 synthesis | Mixed patterns work when wave boundaries are correct. |
| Query Engine Build | Sequential phases | ~6 phases | 200+ tests passing | TDD at each phase prevents cascading failures. |
| META Analysis | Single agent, corpus-wide | 1 agent | ~150 items across ~10 segments | Sometimes 1 agent is better than many. Corpus-wide > per-item. |

**The META Analysis lesson is critical:** The best "team" for corpus-wide analysis was a single agent with grep. Don't parallelize when a single agent with good tools is faster.

---

## Quick Reference

**Coordination Overhead Test:** If overhead > 30% of sequential time, don't parallelize.

**Three patterns:** Sequential (reliable, slow), Fanout-fanin (fast, rigid), Foundation + Waves (flexible, complex).

**8 questions:** File outputs? Contract tests? Failure modes? Spec thickness? Merge strategy? Verification agent? Minimum team size? Test fixtures?

**Contract tests ARE coordination.** Each agent implements logic that transforms input fixtures into output fixtures. The chain of fixtures IS the integration test.

**Self-reported "✅ COMPLETE" is not verification.** The final agent runs the E2E test independently.

**When in doubt, go sequential.** It has 5 verified successes and zero failures. Parallelism has higher variance.
