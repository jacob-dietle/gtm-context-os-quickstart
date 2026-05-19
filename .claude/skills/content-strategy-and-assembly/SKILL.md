---
name: content-strategy-and-assembly
description: This skill should be used when producing content (newsletter posts, blog posts, LinkedIn posts) from existing corpus material. Discovers relevant context from the knowledge graph, selects the right content framework, assembles a draft against a spec, then runs an eval loop of anti-slop checks until the output clears quality gates. Built from real content production pipelines with 142 automated anti-slop tests and the eval-loop methodology.
---

# Content Strategy and Assembly

Methodology for producing content by discovering what already exists in the corpus, assembling it against a content-type spec, and iterating through anti-slop quality gates until the output reads like a human wrote it.

**Core philosophy:** The author's taste is primary. This skill handles the grunt work of discovery, assembly, and slop removal. The author edits for voice, judgment, and the things only they can add.

---

## When to Use This Skill

Apply this skill when:
- Producing a newsletter post, blog post, or LinkedIn post from existing corpus material
- Filling in an outline the author has already created
- Turning raw notes, transcripts, or KB nodes into publishable content
- Assembling content from multiple sources that need to be synthesized

Do NOT use for:
- Writing from scratch with no existing material (write raw thought first)
- Technical documentation (use `technical-business-writing`)
- Sales copy or landing pages (use `copywriting-masters`)
- Content editing only, no assembly (use a dedicated content-editing skill)
- One-shot generation (this skill is explicitly multi-step)

---

## Core Principles

### 1. Never One-Shot

Content generation is a multi-step process. One-shotting produces the worst possible output because the model has to predict tokens for structure, evidence, transitions, and tone simultaneously.

**Pattern:** Discover → Select → Spec → Assemble → Validate → Refine

Each step narrows the problem space for the next. By the time assembly happens, the model knows exactly what to write, what evidence to use, and what structure to follow.

### 2. Voice Floor, Not Voice Ceiling

This skill does not try to perfectly replicate the author's voice. That is impossible and attempting it produces uncanny-valley slop.

Instead, enforce a **floor**: the output must NOT read like AI wrote it. The author's edits add the rest.

**The distinction:**
- Ceiling approach: "Write like the author" → produces mimicry slop
- Floor approach: "Don't write like an AI" → produces clean prose the author can work with

**Read:** `references/voice-calibration.md` for the author's voice fingerprint and anti-patterns.

### 3. Evidence-First Assembly

Every claim in the output must trace to a source in the corpus. Content without evidence is opinion dressed as insight.

**Attribution during assembly:**
```
[SOURCE: knowledge_base/technical/context-engineering.md] — direct reference
[SOURCE: transcript, client call 2026-01-15] — from conversation
[INFERRED: from patterns across 3+ sources] — synthesis
[AUTHOR: original thought from outline] — the author's own contribution
```

After assembly, strip attribution markers from the draft but keep a separate evidence map so the author can verify any claim.

### 4. Anti-Slop as Eval Loop

Content quality follows the eval-loop pattern:

```
SYMPTOM: "This paragraph reads like ChatGPT wrote it"
    │
    ▼
GENERALIZE: Which anti-slop class? (hedge words? colon-sentences? filler?)
    │
    ▼
ROOT CAUSE: Specific pattern (e.g., "3 em-dashes in one paragraph")
    │
    ▼
TARGET: "Zero filler phrases, ≤2 em-dashes per article"
    │
    ▼
FIX: Replace specific patterns
    │
    ▼
VERIFY: Run detection regexes
    Pass → next section
    Fail → fix and re-verify
```

**Read:** `references/anti-slop-rules.md` for the full detection catalog with regexes.

---

## Workflow

### Step 1: DISCOVER — What Do We Already Have?

Before writing anything, find what exists in the corpus on this topic.

**1a. Search the knowledge base:**
```bash
# Find relevant KB nodes
Grep: pattern="[topic]" glob="knowledge_base/**/*.md"

# Check synthesis docs first (95% of answers)
Grep: pattern="[topic]" glob="**/_synthesis/*.md"
```

**1b. Search transcripts and context packages:**
```bash
# Transcripts with relevant discussion
Grep: pattern="[topic]" glob="transcripts/**/*.md"

# Context packages with implementation evidence
Grep: pattern="[topic]" glob="**context_packages**/*.md"
```

**1c. Check published content for prior art:**
```bash
# What has already been published on this topic?
Grep: pattern="[topic]" glob="published_content/**/*.md"
```

**1d. Build a source inventory:**

```markdown
## Source Inventory for [Topic]

### Direct Sources (will cite)
- [file path] — [what it contributes, 1 line]
- [file path] — [what it contributes, 1 line]

### Background Sources (informed thinking, won't cite directly)
- [file path] — [what it contributes, 1 line]

### Gaps (need author input or new research)
- [what's missing] — [why it matters for this piece]
```

Present this inventory to the author before proceeding. Gaps may change the outline.

### Step 2: SELECT — Content Type and Framework

**Match the content type to a framework from `references/content-type-specs.md`.**

| Content Type | Primary Framework | Structure |
|---|---|---|
| Newsletter post | Insight-led | Hook → Context bridge → Core argument → Evidence → Practitioner takeaway |
| Blog post (technical) | Problem-solution | Problem framing → Why it's hard → Approach → Evidence → What to try |
| Blog post (opinion) | Thesis-driven | Claim → Supporting evidence → Counterargument → Resolution |
| LinkedIn post | PAS (compressed) | Pain → Agitate → Insight (no product pitch) |

**Framework selection factors:**
- What is the author's outline already implying? Follow their structure.
- What is the goal? (teach, persuade, share experience, provoke thought)
- What is the audience? (practitioners, executives, general tech)

### Step 3: SPEC — Define the Output Document

Before writing, spec exactly what the output looks like. This is the spec-driven-dev pattern applied to content.

**For each section in the outline:**
```markdown
## Section: [Name]
- Word count target: [range]
- Source material: [which sources from Step 1]
- Purpose: [what this section accomplishes for the reader]
- Tone: [conversational/technical/provocative — match to author's register]
- Must include: [specific evidence, examples, or arguments]
- Must avoid: [specific anti-slop patterns likely for this section type]
```

**Total piece targets:**
- Newsletter post: 800-1500 words
- Blog post: 1500-3000 words
- LinkedIn post: 150-300 words

Present the spec to the author for approval before assembly.

### Step 4: ASSEMBLE — Write the Draft

**Assemble section by section, not end-to-end.**

For each section:
1. Read the source material identified in the spec
2. Write the section following the spec constraints
3. Mark evidence inline: `[SOURCE: file.md]` for every claim
4. Move to next section

**Assembly rules:**
- Write in the voice floor register (see `references/voice-calibration.md`)
- Short paragraphs (3-4 sentences max)
- No formal transitions between sections — just start the next thought
- Concrete examples over abstract claims
- If a section needs the author's personal experience, leave a placeholder: `[AUTHOR: need your example of X here]`

**After full assembly, create the evidence map:**
```markdown
## Evidence Map
| Claim | Source | Verification |
|---|---|---|
| "context drift affects 80% of long sessions" | context-drift.md:14 | Direct quote |
| "multi-step processing reduces verbosity" | anti-slop post, line 77 | Author's prior published claim |
```

### Step 5: VALIDATE — Run Anti-Slop Checks

**This is the eval loop applied to the draft.**

**5a. Automated detection (run all regexes from `references/anti-slop-rules.md`):**

```bash
# Count em-dashes (max 2)
grep -c "—" draft.md

# Find colon-sentences (max 3)
grep -cP ": [A-Z]" draft.md

# Filler phrases (must be 0)
grep -iP "(worth noting|this represents|in today's landscape|however.*important to recognize|implications extend)" draft.md

# Abstract framing (must be 0)
grep -iP "(paradox|collision|tension|dichotomy|validates|represents)" draft.md

# Formal transitions (must be 0)
grep -iP "^(Furthermore|Moreover|Subsequently|Additionally|Consequently)" draft.md

# AI composition tropes
grep -iP "(serves as|acts as a|functions as|stands as|quietly \w+|deeply \w+|fundamentally \w+)" draft.md

# False drama
grep -P "(This isn't \w+.it's|But here's the (critical|key|fundamental))" draft.md

# Hedge words
grep -iP "(might indicate|could suggest|potentially|seems to)" draft.md
```

**5b. Structural checks:**
- [ ] Every section matches spec word count (within 20%)
- [ ] No section is pure summary with no new information
- [ ] No paragraph fits seamlessly in a sales deck (pitch-slap test)
- [ ] Headline/hook passes the "would I stop scrolling?" test
- [ ] One clear takeaway per section

**5c. Voice floor checks:**
- [ ] No generic enthusiasm ("revolutionary", "game-changing", "transformative")
- [ ] No sycophantic framing ("groundbreaking", "best-in-class")
- [ ] Uses "you" not "organizations" or "teams"
- [ ] Paragraphs are ≤4 sentences
- [ ] No signposted conclusions ("In conclusion...", "To sum up...")

### Step 6: REFINE — Fix Flagged Issues and Deliver

**For each flagged issue from Step 5:**

1. Identify the specific pattern
2. Apply the fix from `references/anti-slop-rules.md`
3. Re-run the specific detection regex
4. Confirm it passes

**After all flags resolved:**
- Re-run the full validation suite (regression check)
- Present draft to author with:
  - The clean draft
  - The evidence map
  - `[AUTHOR: ...]` placeholders that need their input
  - A list of any remaining subjective calls ("I wasn't sure if X or Y is better here")

**Iteration with author feedback:**
When the author provides feedback, treat it as an eval-loop symptom:
- "This section feels flat" → diagnose (one-point dilution? missing example? too abstract?)
- "This doesn't sound like me" → check voice floor violations
- "This claim needs backing" → check evidence map, find source or mark as gap

---

## Quality Gates

### Before Assembly (Steps 1-3)
- [ ] Source inventory complete and presented to author
- [ ] Gaps identified — author confirmed whether to proceed or fill them
- [ ] Content type and framework selected
- [ ] Section-level spec written and approved
- [ ] Published content reviewed for prior art (no accidental self-plagiarism)

### Before Delivery (Steps 5-6)
- [ ] All automated anti-slop checks pass
- [ ] Em-dashes ≤2, colon-sentences ≤3, filler phrases = 0
- [ ] No AI composition tropes (Pattern Groups A-G all clear)
- [ ] No hedge words, no passive voice
- [ ] Evidence map complete — every claim sourced
- [ ] Voice floor checks pass
- [ ] Author placeholders clearly marked
- [ ] Word count within spec range

---

## Integration with Other Skills

**Before this skill:**
- `context-foundation` — Load context from package chains if working across sessions
- `context-gap-analysis` — Check what exists before building (prevents unnecessary research)

**During this skill:**
- `copywriting-masters` — For headline writing (Step 4), use the 4 U's framework
- `eval-loop` — The validation step IS an eval loop; for complex quality issues, escalate to full eval-loop methodology

**After this skill:**
- `context-package` — If session is long, save state before ending
- `publish-filter` — Decide whether to publish or keep private

---

## Evidence Base

This skill synthesizes patterns from:
- **Published articles** — voice calibration source (calibrate from your own published work)
- **Anti-slop pipeline** — 3 layers of rules, 142 automated tests, Pattern Groups A-G with detection regexes
- **ce-editorial-rules.md** — Intelligence content editorial stance (practitioner-first, falsifiability, anti-hedge)
- **spec-driven-dev skill** — "Define exactly what to produce before producing it" pattern
- **context-package skill** — Structured assembly with forced completeness via rigid section templates
- **copywriting-masters skill** — Framework selection strategy, batch slop detection (swap test)
- **eval-loop skill** — Symptom → generalize → root cause → target → iterate methodology
