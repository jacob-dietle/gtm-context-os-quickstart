# Search Strategies Reference

Advanced patterns for complex context queries. For most tasks, use the quick start in SKILL.md.

---

## Strategy 1: Pilot Drilling (Breadth → Depth)

**When to use:** Starting fresh, "what am I working on?", orientation

**Pattern:** Cast wide net → find hot spots → drill into clusters

```bash
# Step 1: Broad sweep
tastematter query flex --time 30d --agg count,recency,sessions,chains --limit 50 --format json

# Step 2: Identify clusters by path pattern (mental grouping)
# Look for: gtm_engagements/pixee/*, knowledge_base/*, apps/*

# Step 3: Drill into hot cluster
tastematter query flex --files "*pixee*" --agg count,recency,sessions,chains --limit 20 --format json

# Step 4: Deep dive into most active session
tastematter query session <session_id_from_step_3> --format json
```

---

## Strategy 2: Known Anchor Expansion

**When to use:** "What's related to this file?", understanding context around a known point

```bash
# Step 1: Get file history
tastematter query file <known_file> --format json

# Step 2: Find co-accessed files
tastematter query co-access <known_file> --limit 20 --format json

# Step 3: Get session context
tastematter query session <session_from_step_1> --format json

# Step 4: (Optional) Second-degree relationships
tastematter query co-access <surprising_file_from_step_2> --limit 10 --format json
```

---

## Strategy 3: Temporal Bracketing

**When to use:** "What did I do Tuesday?", finding work in specific time window

```bash
# Step 1: Week view
tastematter query flex --time 7d --agg count,recency,sessions,chains --limit 30 --format json

# Step 2: Filter by date (look at last_access timestamps)

# Step 3: Get full context for target session
tastematter query session <session_from_target_day> --format json
```

---

## Strategy 4: Triangulation for Discovery

**When to use:** Ambiguous searches with partial keywords, no specific file anchor

**Pattern:** Run 2-3 parallel searches → cross-reference → find overlapping files/sessions

```bash
# Search A: By project/tool name
tastematter query flex --files "*hubspot*" --limit 10 --format json

# Search B: By workflow/feature name
tastematter query flex --files "*pipeline*" --limit 10 --format json

# Search C: By version/iteration marker
tastematter query flex --files "*V2*" --limit 10 --format json

# Cross-reference: Files appearing in 2+ searches = strong anchor
```

---

## Strategy 5: Chain Walking

**When to use:** Reconstructing narratives, "what was that thread of work?"

```bash
# Step 1: List recent chains
tastematter query chains --limit 20 --format json

# Step 2: Get files for interesting chain
tastematter query flex --chain <chain_id> --agg count,sessions --format json

# Step 3: Get session details
tastematter query session <session_in_chain> --format json
```

---

## Strategy 6: Negative Space Search

**When to use:** Finding abandoned work, dropped threads

```bash
# Step 1: Get all files, sorted by oldest last_access
tastematter query flex --time 30d --agg count,recency --limit 50 --format json
# Look at files with oldest last_access dates

# Step 2: Check their chain status
tastematter query file <old_file> --format json

# Step 3: Did chain continue or stop?
tastematter query flex --chain <chain_id> --agg recency --format json
```

---

## Strategy 7: Cluster Discovery

**When to use:** Finding natural project boundaries, understanding work themes

```bash
# Step 1: Pick a seed file
tastematter query flex --time 14d --limit 1 --format json

# Step 2: Expand via co-access (Cluster A)
tastematter query co-access <seed_file> --limit 20 --format json

# Step 3: Pick file NOT in Cluster A, repeat (Cluster B)
tastematter query co-access <file_not_in_cluster_a> --limit 20 --format json
```

---

## Strategy 8: Recency Gradient

**When to use:** Trend detection, "where is my attention going?"

```bash
# Compare time windows
tastematter query flex --time 7d --agg count --format json   # This week
tastematter query flex --time 14d --agg count --format json  # Last 2 weeks

# Diff the results - what's new? What dropped off?
```

---

## Result Interpretation

### Access/Session Pattern Signatures

| Pattern | Meaning |
|---------|---------|
| High access, low session | Reference doc (read repeatedly) |
| Low access, high session | Config files (touched lightly) |
| High access, high session | Active development focus |
| Single access, single session | One-off reference |

### Chain Signatures

| Chain Pattern | Meaning |
|---------------|---------|
| 2-5 files | Focused task (bug fix, small feature) |
| 10-20 files | Medium feature or investigation |
| 20+ files | Major work session |
| Single session | One-off task, might be abandoned |
| Multi-session | Sustained work |

### Session Types

| Session Format | Meaning |
|----------------|---------|
| UUID (e.g., `e550ae12-...`) | Human-initiated session |
| `agent-*` prefix | Delegated agent work |
