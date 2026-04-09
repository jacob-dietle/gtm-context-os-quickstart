# GTM Context OS Quickstart

**Purpose:** Help users build their first context operating system in 10 minutes.

---

## What This Plugin Does

Provides guided setup for creating a Context OS — a structured knowledge graph where AI compounds intelligence over time. The system uses stigmergic coordination: agents read and modify the shared environment, knowledge compounds through use.

### Commands

| Command | Purpose |
|---------|---------|
| `/quickstart` | 10-minute guided setup experience |
| `/ingest` | Process raw content into knowledge graph |

### Skills

| Skill | Purpose |
|-------|---------|
| `context-os-basics` | Foundation patterns for context OS |
| `epistemic-context-grounding` | Ground decisions in domain knowledge before designing |
| `context-gap-analysis` | Check what exists before building |
| `context-os-cli` | Query work context, file activity, heat metrics, and knowledge graph via context-os CLI |

---

## Quick Start

Run `/quickstart` to begin. The guide will:

1. Ask what your context OS is for (GTM, Product, Research)
2. Create the two-layer directory structure (knowledge graph + operational docs)
3. Generate CLAUDE.md navigation guide with context-os CLI commands
4. Process your first piece of content into a structured knowledge node
5. Verify it works

Total time: ~10 minutes

---

## How Context OS Works

### Two-Layer Architecture

**Knowledge Graph** (knowledge_base/)
- Atomic, reusable concepts with frontmatter metadata
- Linked via [[wiki-links]] — the graph has structure
- Lifecycle: `emergent` → `validated` (2+ citations) → `canonical`

**Operational Docs** (00_foundation/)
- Strategic documents that compose from the graph
- They reference atomic concepts, they don't redefine them

### Key Principle: SENSE → ORIENT → ACT → DEPOSIT

Every interaction follows this loop:
- **SENSE** — Check what exists (graph-exec, heat queries)
- **ORIENT** — Find hub nodes, read coordination surfaces
- **ACT** — Create/update content
- **DEPOSIT** — Link to existing nodes, reinforce the graph through use

### Context-OS CLI

The CLI provides structural queries over your knowledge graph:

```bash
context-os graph-exec --graph knowledge_base '<js>'  # Structural graph queries
context-os query heat --time <N>d                     # What's active
context-os context "<query>"                          # Broad project context
```

---

## Templates Included

| Template | Purpose |
|----------|---------|
| `CLAUDE_MD_STARTER.md` | Navigation guide with CLI integration |
| `node_template.md` | Knowledge node frontmatter format |
| `sample-transcript.md` | Example content for testing ingestion |

---

## Learn More

For advanced patterns (multi-agent orchestration, client engagement systems, enterprise context architectures):
https://taste.systems
