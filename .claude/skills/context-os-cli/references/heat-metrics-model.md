# Heat Metrics Model

**Purpose:** Quantify file/directory usage patterns to distinguish active work (RAM) from reference material (HDD) from vestigial cruft (should be archived).

**When to use:** System health checks, identifying vestigial components, understanding actual vs declared system usage.

---

## Core Metrics

### 1. Specificity (replaces RCR)

**Definition:** Inverse of session spread. Files touched in many sessions have low specificity (infrastructure/config). Files touched in few sessions have high specificity (topical/focused work).

```
session_spread = sessions_touching_file / total_sessions_in_window
specificity = 1.0 - session_spread
```

**Why this replaced RCR:** The old metric (RCR = count_7d / count_long) approached 1.0 for any active user, making all files appear HOT. Specificity uses an IDF-like principle: files that appear in many sessions are less interesting, similar to how common words score low in TF-IDF.

**Interpretation:**
| Specificity | Meaning |
|-------------|---------|
| > 0.9 | Very focused - touched in <10% of sessions |
| 0.7 - 0.9 | Focused - topical work file |
| 0.4 - 0.7 | Mixed - regular reference or multi-purpose |
| 0.2 - 0.4 | Broad - infrastructure or config |
| < 0.2 | Ubiquitous - touched in nearly every session |

---

### 2. Access Velocity (AV)

**Definition:** Average accesses per day since file first appeared.

```
AV = total_accesses / days_since_first_access
```

**Interpretation:**
| AV | Meaning |
|----|---------|
| > 5.0 | Extremely active - core working file |
| 2.0 - 5.0 | Very active - daily use |
| 0.5 - 2.0 | Active - regular use |
| 0.1 - 0.5 | Occasional - reference material |
| < 0.1 | Rare - cold storage or vestigial |

---

### 3. Recency (Exponential Decay)

**Definition:** How recently the file was accessed, using smooth exponential decay instead of step function.

```
recency = e^(-0.1 * days_since_last_access)
```

**Decay curve:**
| Days | Recency |
|------|---------|
| 0 | 1.000 |
| 1 | 0.905 |
| 3 | 0.741 |
| 7 | 0.497 |
| 14 | 0.247 |
| 30 | 0.050 |

**Why this replaced the step function:** The old function returned 1.0/0.5/0.0 in three buckets, so files accessed 1 day and 6 days ago scored identically. Exponential decay provides smooth differentiation.

---

### 4. Session Density (SD)

**Definition:** How many sessions touched this file relative to access count.

```
SD = session_count / access_count
```

**Interpretation:**
| SD | Meaning |
|----|---------|
| ~1.0 | One touch per session - typical pattern |
| 0.5 - 1.0 | Light multi-touch - checked multiple times per session |
| < 0.5 | Heavy multi-touch - deep work file, heavily edited |

---

## Composite Heat Score

```
Heat Score = (normalized_AV * 0.30) + (specificity * 0.35) + (recency * 0.35)

Where:
- normalized_AV = min(AV / 5.0, 1.0)  # Cap at 5 accesses/day
- recency = e^(-0.1 * days_since_last_access)  # Exponential decay
- specificity = 1.0 - (sessions_touching_file / total_sessions)
```

**Percentile Classification (overrides absolute thresholds):**
| Percentile | Level | Action |
|------------|-------|--------|
| Top 10% | HOT | Current working set |
| 10% - 30% | WARM | Regular reference |
| 30% - 60% | COOL | Occasional reference |
| Bottom 40% | COLD | Archive candidate |

This ensures distribution across heat levels regardless of how the absolute scores cluster. The old absolute thresholds (>0.7 HOT, etc.) caused all files to be HOT when RCR was uniformly ~1.0.

---

## CLI Usage

```bash
tastematter query heat --time 30d --format table

# Output:
FILE                                    7D  TOTAL  SPEC    VEL   SCORE HEAT
apps/tastematter/core/src/types.rs       8     42  0.85   1.40   0.773 HOT
_system/state/workstreams.yaml           5     20  0.72   0.67   0.625 WARM
04_knowledge_base/technical/...          1      3  0.95   0.10   0.412 COOL
_system/knowledge_graph/taxonomy.yaml    0      5  0.15   0.11   0.071 COLD

# Sort by specificity
tastematter query heat --sort specificity --format csv
```

---

## Interpreting Results

### Healthy Patterns

| File Type | Expected Specificity | Expected AV |
|-----------|---------------------|-------------|
| Active dev files | 0.6 - 0.9 | > 2.0 |
| State files (workstreams, pipeline) | 0.3 - 0.6 | 1.0 - 3.0 |
| Skills (actively used) | 0.5 - 0.8 | 0.5 - 2.0 |
| Reference docs | 0.7 - 0.95 | 0.1 - 0.5 |
| Cold storage (knowledge base) | 0.9+ | < 0.1 |
| Config/infra files | < 0.3 | < 0.5 |

### Warning Signs

| Pattern | Meaning | Action |
|---------|---------|--------|
| Low specificity + high AV | Infrastructure file - everywhere | Expected for config/state |
| High specificity + low AV | Rarely touched, focused when touched | Archive candidate or one-off |
| All files same heat level | Formula miscalibration | Check percentile classification |
| High accesses, low sessions | Burst activity | One-time deep work |
| Never accessed but exists | Ghost file | Archive or delete |

---

## Vestigial Detection

Compare declared purpose (from CLAUDE.md or docs) with actual usage:

| Declared | Actual | Verdict |
|----------|--------|---------|
| "Config - rarely changes" | Specificity < 0.3, AV < 0.1 | Aligned |
| "Read first every session" | Specificity < 0.1, AV < 0.1 | Vestigial |
| "Active development" | Specificity 0.7+, AV > 2.0 | Aligned |
| "Reference material" | Specificity 0.8+, AV 0.1-0.3 | Aligned |
| Not documented | HOT percentile | Undocumented hot spot |

---

**Last Updated:** 2026-02-12
**Version:** 2.0 (Heat formula redesign: RCR replaced with specificity, step function replaced with exponential decay, percentile classification added)
