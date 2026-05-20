---
name: SEO & AEO Expert Perspectives
description: This skill should be used when making SEO, AEO (Answer Engine Optimization), or search visibility decisions. Apply expert perspectives (Eli Schwartz, Mike King, Lily Ray, Rand Fishkin, Cyrus Shepard) to diagnose what actually matters for search performance — programmatic page generation, structured data, title tags, E-E-A-T signals, and AI Overview optimization. Use when building pages for search visibility, adding structured data, evaluating whether programmatic pages have search value, or optimizing for AI-generated answers.
---

# SEO & AEO Expert Perspectives

Systematic methodology for applying expert mental models to search visibility decisions, ensuring implementation goes beyond checklists to expert-grade optimization.

**Meta-Principle:** "Checklists produce 6/10 SEO. Expert lenses produce 9/10. The difference is asking the right diagnostic questions before writing a single meta tag."

## When to Use This Skill

**Apply this skill when:**
- Building or optimizing pages for search engine visibility
- Deciding what structured data (JSON-LD, schema.org) to add
- Evaluating whether programmatic pages have search value
- Making AEO decisions (AI Overview, featured snippet optimization)
- Reviewing title tags, meta descriptions, on-page signals
- Adding SEO infrastructure (sitemaps, robots.txt, canonical URLs)
- Generating content with AI for search purposes
- Designing internal linking architecture

**Do NOT use for:**
- Paid search / SEM campaigns
- Social media optimization (unless OG tags specifically)
- Email marketing
- General content writing without search intent

## Core Principle: Expert Diagnosis Before Implementation

Most SEO work fails because it follows checklists instead of asking diagnostic questions.

**The Pattern:**
```
Checklist approach:   "Add JSON-LD Article schema to every page"
Expert approach:      "Which pages have search demand? What structured data
                       feeds the RAG pipeline? Does the title survive Google's
                       rewrite algorithm?"
```

**Always diagnose before implementing.**

---

## The Expert Perspectives Framework

Apply these expert lenses IN ORDER. Each perspective asks different questions.

### Perspective 1: Eli Schwartz (Product-Led SEO)

**Background:** Author of *Product-Led SEO*. Growth consultant for WordPress, Coinbase, Shutterstock, Quora, Zendesk. Coined the Product-Led SEO methodology.

**Core belief:** "If you aren't helping a human solve a problem, you're just making digital noise."

**Questions to ask:**
1. Does search demand actually exist for this page?
2. What problem does a searcher solve by landing here?
3. Is this programmatic page generation from real inventory, or content generation from nothing?
4. Would a human find this page useful if they landed on it from search?

**Schwartz's Gate:** No page without validated search intent. If nobody would search for it, don't optimize it — optimize the pages people actually want.

**Key distinctions:**
- *Product-led SEO* = exposing existing inventory to search (concept pages, brief content)
- *Programmatic SEO* = creating pages without exposable inventory (mass content gen)
- Product-led is sustainable. Programmatic without intent is noise.

**Application example:**
```
Page: "/brief/103"
Title: "Brief #103 — Thursday, April 10, 2026"
Schwartz's question: "What does someone search to find this?"
Answer: Nobody searches "Brief #103." They search the INSIGHT.
Fix: Title = lead pattern name ("Context Window Size Doesn't Scale Linearly")
```

**Diagnostic checklist:**
- [ ] Can you name the search query this page answers?
- [ ] Would you click this result if you saw it in Google?
- [ ] Is this real content/inventory, or generated filler?
- [ ] Does the page solve a problem the searcher has?

---

### Perspective 2: Mike King (Relevance Engineering & Structured Data)

**Background:** Founder & CEO of iPullRank. 2025 Search Marketer of the Year (Search Engine Land). Consults SAP, American Express, HSBC. Author of *The Science of SEO*. Created the Relevance Engineering framework.

**Core belief:** "Structured data can be ingested during the RAG pipeline." Studies show GPT-4 goes from 16% to 54% correct responses when content has structured data.

**Questions to ask:**
1. Can generative AI systems structurally parse this page?
2. What JSON-LD types accurately describe this content?
3. Does the internal linking graph reflect entity relationships?
4. Is there structured data beyond what yields rich results? (Generative systems use ALL of it)

**King's Principle:** Structured data isn't for rich snippets anymore — it feeds the RAG pipeline. Use anything relevant to your content, not just types that yield traditional rich results.

**Relevance Engineering framework (2025):**
- Content strategy + information retrieval + UX + digital PR + AI
- SEO is semantic and contextual, not just keyword matching
- Structured data is the bridge between your content and AI understanding

**Schema.org types that matter for different page types:**

| Page Type | Primary Schema | Supporting Schema |
|-----------|---------------|-------------------|
| Article/brief | `Article` | `BreadcrumbList`, `Organization` |
| Entity/concept page | `DefinedTerm` or `Thing` | `BreadcrumbList`, `ItemList` |
| FAQ content | `FAQPage` | nested `Question` + `Answer` |
| Index/listing | `CollectionPage` + `ItemList` | `BreadcrumbList` |
| Product page | `SoftwareApplication` or `Product` | `Organization`, `Offer` |
| Person/author | `Person` | `Organization` |

**Internal linking diagnostic:**
- [ ] Do entity pages link to related entities?
- [ ] Do content pages link to the entities they mention?
- [ ] Is the linking bidirectional (entity → content, content → entity)?
- [ ] Does the link graph mirror the knowledge graph?

**Application example:**
```
Page: Concept detail page for "multi-agent-orchestration"
Checklist approach: Add Article JSON-LD
King's approach: Add DefinedTerm JSON-LD with:
  - name, description, url
  - sameAs links to related concepts
  - isPartOf linking to concept index
  - mentions/about linking to briefs that discuss it
  Also: ensure every brief mentioning this concept links TO this page
```

---

### Perspective 3: Lily Ray (E-E-A-T & AI Content Quality)

**Background:** VP of SEO Strategy & Research at Amsive Digital. Foremost expert on Google's E-E-A-T quality signals. Keynote speaker on AI content risks. Named one of the most influential SEOs globally.

**Core belief:** "Mass-producing AI content on a large scale presents SEO risks. Using AI creatively and intelligently can dramatically improve the process."

**Questions to ask:**
1. Who is behind this content and can Google verify it?
2. What experience and expertise signals are visible on the page?
3. Is AI-generated content adding genuine value or inflating page count?
4. Does the page have clear provenance — where did this information come from?

**Ray's Warning Signs (AI content that gets demoted):**
- Thousands of similar templated pages with thin content
- No author attribution or editorial oversight signals
- Content that reads generically without domain expertise
- FAQ sections that are clearly machine-generated filler

**Ray's Quality Signals (AI content that succeeds):**
- Clear editorial process (human review, curation status)
- Source attribution (N articles analyzed, source URLs)
- Author/publisher entity with verifiable expertise
- Content that couldn't exist without real underlying data

**E-E-A-T Schema Signals:**

| Signal | Implementation |
|--------|---------------|
| Experience | `author` with linked `Person` schema, `datePublished` |
| Expertise | `publisher` with `Organization` schema, `about` topics |
| Authority | Source count, citation links, `citation` properties |
| Trust | `reviewedBy`, editorial curation status, provenance chain |

**Application example:**
```
AI-generated brief with 5 patterns from 42 articles:
Risk: Looks like mass AI content
Defense: Surface the provenance chain
  - "Synthesized from 42 articles" (visible, not hidden)
  - Source URLs in each pattern
  - Curation status ("Curated" = human reviewed)
  - Organization publisher entity
  - Clear date and editorial context
```

**Diagnostic checklist:**
- [ ] Is there a visible author or publisher entity?
- [ ] Can a reader tell where this content came from?
- [ ] Is there evidence of human editorial oversight?
- [ ] Would Google's quality raters rate this as "expertise" or "thin content"?
- [ ] Are you generating pages faster than you can ensure quality?

---

### Perspective 4: Rand Fishkin (Zero-Click & Answer Engine Visibility)

**Background:** Founder of SparkToro, co-founder of Moz. Pioneered zero-click search research. His SparkToro clickstream studies are the definitive source on how search behavior is changing.

**Core belief:** "58.5% of Google searches end without a click. AI Overviews appear on 48% of queries. If you're not in the answer, you're invisible."

**Key data (SparkToro 2024-2026):**
- 58.5% of US Google searches = zero external clicks
- AI Overviews on 48% of queries (up from 31% 12 months prior)
- When AI Mode is active, 93% zero-click rate
- AI search traffic converts at 4x traditional search rates when it does click

**Questions to ask:**
1. Is your content structured to be extracted into an AI Overview?
2. Are you optimizing for visibility (being cited) or just for clicks?
3. Does your page have concise, definitive answers that AI can extract?
4. Is your content in FAQPage schema that AI Overviews prefer?

**Fishkin's AEO Hierarchy:**
```
1. Be the cited source in AI Overviews (highest value)
2. Be in featured snippets (still drives some clicks)
3. Rank in top 3 organic (decreasing click share)
4. Rank on page 1 (minimal visibility in AI era)
```

**AEO-optimized content patterns:**
- Direct, definitive answers (no hedge words, no "it depends")
- Answers ≤55 words for AI Overview extraction
- FAQPage JSON-LD schema (direct feed to AI systems)
- Concise paragraph answers that start with the answer, not the question

**Application example:**
```
Brief page with meta_narrative:
"Analysis of 42 articles reveals context window scaling follows
logarithmic returns, not linear."

This IS the AI Overview answer. Wrap it in Article schema with
a clear headline. Add FAQPage schema for pattern-level Q&A pairs.
```

**Diagnostic checklist:**
- [ ] Does each key page have a ≤55-word definitive answer?
- [ ] Is FAQPage schema embedded for Q&A content?
- [ ] Are answers concise and direct (no "it depends")?
- [ ] Would you be satisfied with visibility without clicks?
- [ ] Are AI crawlers (GPTBot, ClaudeBot) allowed in robots.txt?

---

### Perspective 5: Cyrus Shepard (On-Page Signals & Title Tag Engineering)

**Background:** Founder of Zyppy. Former Moz. Runs the largest independent title tag studies. Analyzed 80,000+ title tags (2025 study). Data-driven approach to on-page optimization.

**Core belief:** "Google rewrites 61% of title tags. The sweet spot is exactly 51-60 characters."

**Key data (Zyppy 2025):**
- 61% of title tags get rewritten by Google
- 51-60 characters = lowest rewrite rate
- Parentheses survive rewrites better than brackets (32% vs 77% rewrite rate)
- Title tags remain the strongest CTR signal in SERPs

**Questions to ask:**
1. Is the title tag in the 51-60 character sweet spot?
2. Does the title lead with the keyword/value proposition?
3. Will Google rewrite this title? (Check for common triggers)
4. Is the meta description compelling enough to beat zero-click?

**Google Title Rewrite Triggers:**
- Title too long (>60 chars) — truncated or rewritten
- Title too short (<30 chars) — often supplemented
- Title mismatches page content — rewritten to match H1
- Brackets in title — 77% rewrite rate
- Duplicate titles across pages — rewritten to differentiate

**Title Tag Formula:**
```
[Primary keyword/insight] — [Category] | [Brand]
51-60 characters total

Examples:
"Context Window Scaling Follows Log Returns | tastematter"    (55 chars)
"Multi-Agent Orchestration Patterns (2026) | tastematter"     (54 chars)
"How MCP Servers Handle Auth — Concept | tastematter"         (50 chars)
```

**Meta Description Formula:**
```
[Definitive answer to the search query]. [Supporting detail with specificity].
≤155 characters. No generic filler.

Example:
"42-article analysis reveals context window scaling is logarithmic, not linear.
Key implications for production agent architectures and token budgeting."
```

**Diagnostic checklist:**
- [ ] Is every title 51-60 characters?
- [ ] Does every title lead with the keyword/insight?
- [ ] Are parentheses used instead of brackets?
- [ ] Is every meta description ≤155 chars with specific value?
- [ ] Are titles unique across all pages (no duplicates)?
- [ ] Does the title match the H1? (Prevents Google rewrite)

---

## The Diagnostic Process

### Step 1: Page Inventory

Before optimizing, inventory all page types and their search value:

```markdown
| Page Type | URL Pattern | Search Intent | Priority |
|-----------|------------|---------------|----------|
| [type] | [pattern] | [query people search] | [high/med/low] |
```

### Step 2: Apply Perspectives In Order

```
Schwartz: Does search demand exist for this page?
    ↓ (if no → skip optimization, focus elsewhere)
King: What structured data feeds the RAG pipeline?
    ↓
Ray: Are E-E-A-T signals visible for AI-generated content?
    ↓
Fishkin: Is this page optimized for AI Overview extraction?
    ↓
Shepard: Are title tags and meta descriptions engineered?
```

### Step 3: Synthesize Implementation Plan

After applying all perspectives, synthesize:

```markdown
## SEO/AEO Diagnosis

**Page:** [URL pattern]
**Search Intent:** [what people actually search]

**Expert Verdicts:**
- Schwartz: [Has/lacks search demand — why]
- King: [Structured data needed — specific types]
- Ray: [E-E-A-T signals present/missing — what to add]
- Fishkin: [AEO opportunity — what to extract for AI Overviews]
- Shepard: [Title/meta engineering — specific recommendations]

**Priority Actions:**
1. [Highest impact change]
2. [Second priority]
3. [Third priority]
```

### Step 4: Implementation Priority

**Hierarchy of SEO actions (prefer earlier — faster impact):**
```
1. Title tag surgery (51-60 chars, keyword-leading)     — hours, measurable
2. JSON-LD structured data (Article, FAQPage, etc.)     — hours, feeds AI
3. Meta description engineering (≤155 chars, specific)  — hours, CTR impact
4. Internal linking architecture (entity cross-links)   — days, compounding
5. FAQ/AEO content generation + schema                  — days, AI visibility
6. Programmatic page generation                         — weeks, validate first
```

**Red flag:** If jumping to programmatic content generation before perfecting structured data on existing pages, revisit diagnosis.

---

## Common Patterns and Anti-Patterns

### SEO Anti-Patterns

| Anti-Pattern | Symptom | Expert Fix |
|---|---|---|
| **Generic titles** | "Blog Post #42 — Company" | Shepard: Lead with insight, 51-60 chars |
| **Missing structured data** | AI systems can't parse content | King: JSON-LD for every page type |
| **Mass AI content** | Hundreds of thin pages | Ray: Quality gate — provenance + curation signals |
| **Click-optimized only** | Ranking but not cited | Fishkin: FAQPage schema + ≤55-word answers |
| **Pages without demand** | Indexed but zero impressions | Schwartz: Kill or noindex pages without search intent |
| **Static meta descriptions** | Same description on every page | Shepard: Dynamic from content, ≤155 chars |
| **No internal linking** | Orphan pages, no entity graph | King: Bidirectional entity ↔ content links |
| **Blocking AI crawlers** | Missing from AI Overviews | Fishkin: Allow GPTBot, ClaudeBot in robots.txt |

### AEO Anti-Patterns

| Anti-Pattern | Symptom | Expert Fix |
|---|---|---|
| **Hedge answers** | "It depends on..." | Fishkin: Direct, definitive, ≤55 words |
| **FAQ without schema** | Good content, invisible to AI | King: FAQPage JSON-LD wrapping |
| **No provenance** | AI content looks generic | Ray: Source count, curation status, evidence chain |
| **Optimizing scaffolding** | Web pages as the product | (Your AEO thesis): Layer 1 = discovery, Layer 2 = MCP |

---

## Quality Gates

### Before Implementing SEO Changes

- [ ] Applied all 5 expert perspectives?
- [ ] Validated search demand exists for target pages? (Schwartz)
- [ ] Identified correct JSON-LD types per page? (King)
- [ ] E-E-A-T signals planned for AI-generated content? (Ray)
- [ ] AEO extraction points identified? (Fishkin)
- [ ] Title tags engineered to 51-60 chars? (Shepard)

### After Implementation

- [ ] Build passes with no errors?
- [ ] JSON-LD validates (Google Rich Results Test or schema.org validator)?
- [ ] Title tags are unique across all pages?
- [ ] Meta descriptions are dynamic and ≤155 chars?
- [ ] Internal links connect entities bidirectionally?
- [ ] robots.txt allows AI crawlers?
- [ ] Sitemap includes all valuable pages with correct priorities?

---

## Integration with Other Skills

| Skill | Relationship |
|-------|-------------|
| `design-engineering` | Complements. Design-engineering handles visual quality; this skill handles search visibility. Both apply to the same pages. |
| `cf-web-architecture` | Upstream. Architecture determines SSR vs CSR, routing, and rendering — all affect crawlability. |
| `content-strategy-and-assembly` | Parallel. Content strategy decides WHAT to publish. This skill decides HOW to optimize it for search. |
| `intelligence-pipeline` | Upstream. Pipeline generates briefs, patterns, AEO Q&A. This skill determines how to surface them for search. |
| `copywriting-masters` | Parallel. Copy quality affects E-E-A-T signals and title tag effectiveness. |

---

## References

For detailed structured data schemas, see: `references/structured-data-patterns.md`

## Evidence Base

This skill was created from applied analysis of tastematter.dev intelligence browser SEO/AEO strategy:

**Expert sources:**
- Eli Schwartz: *Product-Led SEO* (book), productledseo.com (Substack)
- Mike King: iPullRank, SEO Week 2025 "The Brave New World of SEO", 2025 Search Marketer of the Year
- Lily Ray: Amsive Digital, "The State of AI and SEO in 2026" (Affiliate Summit), E-E-A-T research
- Rand Fishkin: SparkToro zero-click studies (58.5% in 2024), SEO Week 2025 "You Are Bigger Than SEO"
- Cyrus Shepard: Zyppy, 80,000 title tag study (2025), Google rewrite research

**Key data points:**
- 58.5% of Google searches = zero click (SparkToro 2024)
- AI Overviews on 48% of queries (2025, up from 31%)
- 93% zero-click when AI Mode active
- Google rewrites 61% of title tags (Zyppy 2025)
- 51-60 chars = lowest title rewrite rate
- Structured data: GPT-4 accuracy 16% → 54% with schema (2025 study)
- Parentheses survive rewrites better than brackets (32% vs 77%)

**Lesson:** SEO checklists produce table-stakes results. Expert mental models diagnose what actually moves the needle for the specific site and content type.
