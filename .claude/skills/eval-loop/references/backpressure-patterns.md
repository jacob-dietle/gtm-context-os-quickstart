# Backpressure Patterns

Detailed implementation patterns for each verification type in the eval loop.

## Unit Tests (Data, Logic, Contracts)

**When:** Verifying data shape, pipeline output, business logic, API contracts.

```typescript
// Target: 95% of signals include source post URL
describe("signal evidence completeness", () => {
  it("includes post_url in evidence for linkedin_post signals", () => {
    const signals = getLatestRunSignals();
    const linkedinSignals = signals.filter(s => s.discovery_source === "linkedin_post");
    const withUrl = linkedinSignals.filter(s => {
      const ev = JSON.parse(s.evidence_json);
      return ev.post_url && ev.post_url.startsWith("http");
    });
    expect(withUrl.length / linkedinSignals.length).toBeGreaterThanOrEqual(0.95);
  });
});
```

**Pattern:** Query the real system (D1, API, Supabase), assert on the response. Not mocks — eval loops test the actual output.

## Integration Tests (API, Data Flow)

**When:** Verifying API responses include required fields, data flows correctly between layers.

```typescript
// Target: /signals/:id returns contact_linkedin
it("signal detail includes contact LinkedIn URL", async () => {
  const res = await fetch(`${WORKER_URL}/signals/${signalId}`);
  const signal = await res.json();
  expect(signal.contact_linkedin).toMatch(/linkedin\.com\/in\//);
});
```

## Playwright Assertions (UI Presence, Interaction)

**When:** Verifying UI elements exist, are clickable, show correct data.

```typescript
// Target: Contact name links to LinkedIn profile
test("signal card has clickable LinkedIn link for contact", async ({ page }) => {
  await page.goto("https://example.com/");
  const firstCard = page.locator(".signal-card").first();
  const linkedinLink = firstCard.locator('a[href*="linkedin.com/in/"]');
  await expect(linkedinLink).toBeVisible();
  const href = await linkedinLink.getAttribute("href");
  expect(href).toMatch(/^https:\/\/linkedin\.com\/in\//);
});

// Target: Reasoning trace expandable is visible
test("signal card shows reasoning trace on expand", async ({ page }) => {
  await page.goto("https://example.com/");
  const firstCard = page.locator(".signal-card").first();
  const reasoningBtn = firstCard.locator('button:has-text("Why this signal")');
  await expect(reasoningBtn).toBeVisible();
  await reasoningBtn.click();
  const trace = firstCard.locator(".reasoning-trace");
  await expect(trace).toBeVisible();
  const text = await trace.textContent();
  expect(text.length).toBeGreaterThan(50); // Not empty placeholder
});
```

**Pattern:** Use playwright-cli for quick manual checks during development. Write proper Playwright tests for regression.

## Playwright + Screenshot (Visual Quality)

**When:** Verifying visual design, layout, aesthetic quality that can't be expressed as DOM assertions.

```typescript
test("signal card visual quality", async ({ page }) => {
  await page.goto("https://example.com/");
  const card = page.locator(".signal-card").first();
  await card.screenshot({ path: "signal-card-current.png" });
  // Compare against reference screenshot or send to LLM judge
});
```

## LLM-as-Judge (Content Quality, Tone, Rubric)

**When:** Quality is inherently subjective but can be expressed as a rubric.

```typescript
async function judgeEmailQuality(email: string, rubric: string): Promise<{ score: number; reasons: string[] }> {
  const response = await anthropic.messages.create({
    model: "claude-sonnet-4-5-20250929",
    messages: [{
      role: "user",
      content: `## Rubric\n${rubric}\n\n## Email to Evaluate\n${email}\n\n## Task\nScore this email 1-10 on each rubric dimension. Return JSON: { "scores": { "dimension": score }, "overall": number, "reasons": ["..."] }`
    }],
  });
  return JSON.parse(response.content[0].text);
}

// Target: Cold emails score ≥ 8/10 on PVP rubric
it("cold email quality meets PVP standard", async () => {
  const signals = getLatestRunSignals();
  const scores = await Promise.all(
    signals.map(s => judgeEmailQuality(s.body, PVP_RUBRIC))
  );
  const mean = scores.reduce((a, b) => a + b.overall, 0) / scores.length;
  expect(mean).toBeGreaterThanOrEqual(8);
  expect(scores.every(s => s.overall >= 6)).toBe(true); // No individual < 6
});
```

## Rubric Scoring (Structured Quality Assessment)

**When:** Need a repeatable, structured assessment across multiple dimensions.

```markdown
## PVP Cold Email Rubric

Score each dimension 1-10:

| Dimension | 1-3 (Fail) | 4-6 (Okay) | 7-8 (Good) | 9-10 (Excellent) |
|-----------|-----------|-----------|-----------|-----------------|
| Specificity | Generic pitch | Mentions company | References specific signal | Quotes their own words |
| Brevity | >100 words | 75-100 words | 50-75 words | <50 words, nothing wasted |
| CTA | Asks for meeting | Asks open question | Asks specific question about their pain | Question they'd answer even without buying |
| Personalization | Template | Uses name/company | References their tech stack | Connects their post to their stack to your product |
| Stat usage | >2 stats | 2 stats | 1 stat | 1 stat that directly maps to their situation |
```

**Key:** Rubric dimensions must be **independent** (scoring high on one doesn't require scoring high on another) and **observable** (the judge can determine the score from the text alone).
