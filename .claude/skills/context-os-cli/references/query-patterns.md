# Query Pattern Reference

## Common Patterns by Intent

| User Intent | Key CLI Commands | Synthesis Focus |
|-------------|------------------|-----------------|
| Client context | search -> file -> session | Work areas, recent activity |
| Recent work | recent -> chains -> session | Time-based grouping |
| File relationships | file -> co-access | Related files, sessions |
| Session details | session -> chains | Files touched, chain context |

## Path Substring Patterns

When exact paths are unknown, use these substring strategies:

| Looking For | Try Pattern |
|-------------|-------------|
| Client work | Client name: "pixee", "nickel" |
| Feature area | Feature name: "social_media", "hubspot" |
| Document type | "ARCHITECTURE", "SCOPE", "SPEC" |
| Code files | ".py", ".ts", "cli" |
| Test files | "test_", "_test.py" |

## Interpreting Results

### Access Counts
- 5+ accesses = actively worked on
- 2-4 accesses = touched but not focus
- 1 access = briefly referenced

### Session Patterns
- Multiple sessions on same file = deep work
- Many files in one session = exploration/refactoring
- Created files = new initiative starting

### Chain Context
- Long chains = extended work sessions
- Branched chains = parallel exploration
- Single-session chains = quick tasks

## CLI Command Quick Reference

```bash
# Discovery
tastematter query flex --files "*pattern*" --format json  # Find files by path pattern
tastematter query flex --time 7d --format json            # Recent activity

# File Intelligence
tastematter query file <path> --format json               # Sessions that touched file
tastematter query co-access <path> --format json          # Files accessed together

# Session Intelligence
tastematter query session <id> --format json              # Files touched by session
tastematter query chains --limit N --format json          # Conversation chains

# Verification
tastematter query verify <receipt_id>                     # Verify a previous result
```

## Example Workflow: "What am I working on for Pixee?"

```bash
# Step 1: Find Pixee files (CLI narrows)
tastematter query flex --files "*pixee*" --agg count,recency,sessions,chains --format json
# Result: 147 files, receipt [q_abc123]

# Step 2: Read hot files (understand content)
Read: <top_file_from_results>
# Result: This is the social media CLI implementation

# Step 3: Search for specific concepts (grep for content)
Grep: pattern="hubspot|integration" path=apps/clients/pixee/
# Result: Found references in 3 files

# Step 4: Check git for evolution
git log --oneline -5 -- apps/clients/pixee/
# Result: Recent commits show active development

# Synthesis with citation:
# Working on 147 Pixee files [q_abc123]. Main areas:
# - Social Media CLI (active development)
# - HubSpot integration (3 files mention it)
```
