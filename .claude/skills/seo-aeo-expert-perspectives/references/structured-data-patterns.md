# Structured Data Patterns

JSON-LD schema.org patterns for common page types. All examples use JSON-LD format (preferred by Google over Microdata or RDFa).

## Placement

JSON-LD goes in `<script type="application/ld+json">` in the `<head>`. Multiple JSON-LD blocks per page are valid.

---

## Article (Brief / Blog Post / Analysis)

For pages with authored, dated analysis content.

```json
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Context Window Scaling Follows Logarithmic Returns",
  "description": "42-article analysis reveals context window scaling is logarithmic, not linear. Key implications for production agent architectures.",
  "datePublished": "2026-04-10",
  "dateModified": "2026-04-10",
  "author": {
    "@type": "Organization",
    "name": "tastematter intelligence",
    "url": "https://tastematter.dev"
  },
  "publisher": {
    "@type": "Organization",
    "name": "tastematter intelligence",
    "url": "https://tastematter.dev"
  },
  "mainEntityOfPage": {
    "@type": "WebPage",
    "@id": "https://tastematter.dev/brief/103"
  },
  "about": [
    { "@type": "DefinedTerm", "name": "context-window-management" },
    { "@type": "DefinedTerm", "name": "token-optimization" }
  ],
  "articleBody": "Executive summary text here..."
}
```

**Key fields:**
- `headline`: Lead with the insight, not the ID. Must match `<title>` closely.
- `about`: Link to concept entities. Feeds knowledge graph.
- `author`/`publisher`: E-E-A-T signal. Use Organization for editorial products.
- `datePublished`: Required for freshness signals.

---

## FAQPage (AEO Q&A Content)

For pages with question-answer pairs. Directly feeds AI Overviews and featured snippets.

```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "How does context window scaling affect agent performance?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Context window scaling follows logarithmic returns. Doubling context from 32K to 64K tokens yields roughly 15% performance improvement, while the initial 8K to 16K jump provides 40%+ gains. Production architectures should optimize for context quality over quantity."
      }
    },
    {
      "@type": "Question",
      "name": "What is the optimal context window size for production agents?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Most production agents perform optimally between 16K-32K tokens of well-structured context. Beyond 32K, retrieval quality and context relevance matter more than raw window size. Use progressive disclosure to prioritize high-signal context."
      }
    }
  ]
}
```

**Key rules (from Fishkin + King):**
- Answers MUST be ≤55 words for AI Overview extraction
- Questions should be real search queries (start with How/What/Why/When)
- Answers must be direct and definitive — no "it depends"
- Each answer must stand alone (no references to other answers)
- Can coexist with Article schema on the same page

---

## DefinedTerm (Concept / Entity Page)

For pages that define a concept, term, or entity in your knowledge graph.

```json
{
  "@context": "https://schema.org",
  "@type": "DefinedTerm",
  "name": "Multi-Agent Orchestration",
  "description": "Patterns for coordinating multiple AI agents to accomplish complex tasks, including delegation, consensus, and pipeline architectures.",
  "url": "https://tastematter.dev/concepts/multi-agent-orchestration",
  "inDefinedTermSet": {
    "@type": "DefinedTermSet",
    "name": "Context Engineering Concepts",
    "url": "https://tastematter.dev/concepts"
  }
}
```

**Key fields:**
- `inDefinedTermSet`: Links concept to the parent concept graph
- `description`: Concise (1-2 sentences), contains target keywords

---

## BreadcrumbList (Navigation Hierarchy)

For all pages — tells search engines the site structure.

```json
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    {
      "@type": "ListItem",
      "position": 1,
      "name": "Home",
      "item": "https://tastematter.dev/"
    },
    {
      "@type": "ListItem",
      "position": 2,
      "name": "Concepts",
      "item": "https://tastematter.dev/concepts"
    },
    {
      "@type": "ListItem",
      "position": 3,
      "name": "Multi-Agent Orchestration",
      "item": "https://tastematter.dev/concepts/multi-agent-orchestration"
    }
  ]
}
```

---

## CollectionPage + ItemList (Index / Listing Pages)

For pages that list items (concept index, brief archive).

```json
{
  "@context": "https://schema.org",
  "@type": "CollectionPage",
  "name": "Context Engineering Concepts",
  "description": "Concept graph for context engineering, AI agents, and MCP.",
  "url": "https://tastematter.dev/concepts",
  "mainEntity": {
    "@type": "ItemList",
    "numberOfItems": 45,
    "itemListElement": [
      {
        "@type": "ListItem",
        "position": 1,
        "url": "https://tastematter.dev/concepts/multi-agent-orchestration",
        "name": "Multi-Agent Orchestration"
      },
      {
        "@type": "ListItem",
        "position": 2,
        "url": "https://tastematter.dev/concepts/context-window-management",
        "name": "Context Window Management"
      }
    ]
  }
}
```

---

## Organization (Publisher Entity)

Include once on the homepage or as `publisher` in Article schema.

```json
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "tastematter intelligence",
  "url": "https://tastematter.dev",
  "description": "Curated intelligence on context engineering, AI agents, and MCP.",
  "sameAs": []
}
```

---

## WebSite (Sitewide — Homepage Only)

```json
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "tastematter intelligence",
  "url": "https://tastematter.dev",
  "description": "Curated intelligence on context engineering, AI agents, and MCP.",
  "publisher": {
    "@type": "Organization",
    "name": "tastematter intelligence"
  }
}
```

---

## Combining Multiple Schemas

Multiple JSON-LD blocks are valid on one page. Common combinations:

| Page Type | Schema Combination |
|-----------|-------------------|
| Brief detail | Article + FAQPage + BreadcrumbList |
| Concept detail | DefinedTerm + BreadcrumbList |
| Concept index | CollectionPage + ItemList + BreadcrumbList |
| Brief archive | CollectionPage + ItemList + BreadcrumbList |
| Homepage | WebSite + Article (latest brief) + Organization |

Use separate `<script type="application/ld+json">` blocks for each — cleaner than nesting.

---

## Validation

- Google Rich Results Test: https://search.google.com/test/rich-results
- Schema.org validator: https://validator.schema.org/
- JSON-LD Playground: https://json-ld.org/playground/

## robots.txt AI Crawler Directives

Allow AI crawlers to index content for AI Overviews and citations:

```
User-agent: *
Allow: /

User-agent: GPTBot
Allow: /

User-agent: ClaudeBot
Allow: /

User-agent: Google-Extended
Allow: /

Sitemap: https://tastematter.dev/sitemap.xml
```

Note: Blocking `GPTBot` or `ClaudeBot` removes your content from AI training but also from AI-generated answers. For AEO, allow them.
