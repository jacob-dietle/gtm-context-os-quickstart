# Context OS Quickstart

Build your first context operating system in 10 minutes. A structured knowledge graph where AI compounds intelligence over time.

<!-- TODO: Add video embed when published -->
<!-- [![Context OS v2: Stigmergic Design](thumbnail.png)](VIDEO_URL) -->

---

## v1 → v2: What Changed and Why

This quickstart was rebuilt from the ground up based on 4 months of production use across client engagements.

**v1 (ceremony era)** taught users to create taxonomy files, ontology rules, and governance infrastructure. In practice, agents never read those files. We measured it — taxonomy.yaml had 2 accesses in 90 days, ontology.yaml had 1, and the node lifecycle doc had zero. The ceremony was concrete paths nobody walked.

**v2 (stigmergic design)** removes the ceremony and replaces it with patterns that actually work:

| | v1 | v2 |
|---|---|---|
| **Graph health** | `/graph-health` command | Inline `graph-exec` queries you can run anytime |
| **Tag governance** | taxonomy.yaml + ontology.yaml | Agent uses existing tags from the graph — no governance files |
| **Node lifecycle** | Separate lifecycle document | One line: "emergent → validated with 2+ citations" |
| **System structure** | `_system/` directory with governance files | Two layers only: `knowledge_base/` + `00_foundation/` |
| **Navigation** | Read synthesis docs first, then detail | SENSE → ORIENT → ACT → DEPOSIT loop with CLI tools |
| **CLI tooling** | None | context-os CLI for graph queries, heat tracking, co-access |

**The principle:** Desire paths are stigmergy. Agents coordinate by reading and modifying the shared environment — not by following procedures. If a file has zero heat, it's the concrete path nobody walks. Pave the desire paths.

[Compare the versions: `git diff v1.0-ceremony..v2.0-stigmergic`](https://github.com/jacob-dietle/gtm-context-os-quickstart/compare/v1.0-ceremony...v2.0-stigmergic)

---

## Prerequisites

### 1. Claude Code

Install [Claude Code](https://claude.ai/code) — the CLI for Claude.

### 2. Context-OS CLI

The context-os CLI gives your system structural intelligence — graph queries, file heat tracking, and behavioral co-access analysis.

**macOS/Linux:**
```bash
curl -fsSL https://install.tastematter.dev/install-context-os.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://install.tastematter.dev/install-context-os.ps1 | iex
```

Verify: `context-os --version`

---

## Quick Start

1. Fork this repo (or clone it)
2. Open in Claude Code: `claude`
3. Run: `/quickstart`
4. Follow the guided setup (~10 minutes)

The quickstart will:
- Ask what your context OS is for (GTM, Product, Research)
- Create the two-layer directory structure
- Generate your CLAUDE.md navigation guide with CLI commands
- Process your first piece of content into a structured knowledge node
- Verify it works

---

## What You Get

A knowledge system with two layers:

**Knowledge Graph** (`knowledge_base/`) — Atomic concepts linked via `[[wiki-links]]`. Each concept has structured frontmatter, a lifecycle (`emergent` → `validated` → `canonical`), and connections to related ideas.

**Operational Docs** (`00_foundation/`) — Strategic documents (positioning, messaging, brand) that compose from the knowledge graph. They reference concepts via wiki-links — they don't redefine them.

### The SENSE → ORIENT → ACT → DEPOSIT Loop

Every interaction follows the same pattern:

- **SENSE** — Check what exists before acting (`graph-exec`, `heat`)
- **ORIENT** — Find hub nodes, read coordination surfaces
- **ACT** — Create or update content
- **DEPOSIT** — Link to existing nodes, reinforce the graph through use

### Context-OS CLI

After setup, initialize the CLI:
```bash
context-os init          # Index your sessions, build chains
context-os daemon start  # Background sync (auto-tracks file access)
```

Then query your system:
```bash
# Graph structure — find orphans, hubs, node counts
context-os graph-exec --graph knowledge_base '(() => {
  const r = codemode.graph_query({ filter: {}, limit: 500 });
  return JSON.stringify({ total: r.total,
    orphans: r.nodes.filter(n => n.link_count.outbound === 0 && n.link_count.inbound === 0).length
  });
})()'

# File heat — what's been active
context-os query heat --time 14d --limit 10 --format csv

# Co-access — which files travel together
context-os query co-access knowledge_base/technical/my-concept.md

# Broad context search
context-os context "positioning"
```

---

## Commands

| Command | Purpose |
|---------|---------|
| `/quickstart` | Guided setup experience |
| `/ingest` | Process raw content into the knowledge graph |

---

## Learn More

For advanced patterns (multi-agent orchestration, client engagement systems, enterprise context architectures): [taste.systems](https://taste.systems)
