# LLM-as-Judge Rubrics

How to write effective rubrics for when quality is inherently subjective and unit tests can't capture it.

## When to Use LLM-as-Judge

- Content tone/voice (does this sound like our brand?)
- Email quality (is this something an SDR would be proud to send?)
- Explanation clarity (would a non-expert understand this?)
- Design intent (does this screenshot communicate the right hierarchy?)
- Any dimension where a human would say "I know it when I see it"

## Rubric Structure

A good rubric has:
1. **Independent dimensions** — scoring high on one doesn't require scoring high on another
2. **Observable criteria** — the judge can determine the score from the artifact alone
3. **Anchor examples** — what a 2, 5, and 9 look like for each dimension
4. **Weighted overall** — some dimensions matter more than others

```markdown
## [Rubric Name]

### Dimensions

#### D1: [Dimension Name] (weight: X%)
| Score | Description | Example |
|-------|-------------|---------|
| 1-3 | [What failure looks like] | [Concrete example] |
| 4-6 | [What mediocre looks like] | [Concrete example] |
| 7-8 | [What good looks like] | [Concrete example] |
| 9-10 | [What excellent looks like] | [Concrete example] |

#### D2: [Dimension Name] (weight: Y%)
...

### Overall Score
Weighted average of dimensions. Round to nearest integer.

### Pass Criteria
- Overall ≥ [threshold]
- No individual dimension < [floor]
```

## Judge Prompt Template

```markdown
## Your Role
You are a quality evaluator. Score the following artifact against the rubric below.

## Rubric
{rubric_content}

## Artifact to Evaluate
{artifact}

## Instructions
1. Score each dimension independently (1-10)
2. Provide a one-sentence justification per dimension
3. Calculate weighted overall score
4. List the single most impactful improvement

Respond in JSON:
{
  "scores": {
    "dimension_name": { "score": N, "reason": "..." },
    ...
  },
  "overall": N,
  "top_improvement": "..."
}
```

## Calibration

Before using a rubric in an eval loop, calibrate it:

1. Score 3 artifacts manually (you as the human judge)
2. Have the LLM score the same 3
3. Compare — are the scores within ±1 on each dimension?
4. If not, adjust the rubric descriptions until alignment

**Common calibration failures:**
- Rubric descriptions are too vague → LLM defaults to 7/10 for everything
- Anchor examples are missing → LLM can't distinguish 6 from 8
- Dimensions overlap → double-counting the same quality
- No failure examples → LLM doesn't know what a 3 looks like

## Combining LLM Judge with Automated Tests

For mixed-quality targets, combine hard tests with soft judgment:

```typescript
// Hard: word count must be in range
expect(email.split(/\s+/).length).toBeLessThanOrEqual(75);
expect(email.split(/\s+/).length).toBeGreaterThanOrEqual(30);

// Soft: content quality via rubric
const judgment = await judgeEmail(email, COLD_EMAIL_RUBRIC);
expect(judgment.overall).toBeGreaterThanOrEqual(8);
expect(judgment.scores.specificity.score).toBeGreaterThanOrEqual(7);
```

The hard tests catch mechanical failures. The soft tests catch quality regressions. Together they form complete backpressure.
