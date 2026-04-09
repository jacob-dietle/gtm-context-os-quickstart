"""
Cleanroom eval for GTM Context OS Quickstart CLAUDE.md.

Tests whether the quickstart CLAUDE.md + CLAUDE_MD_STARTER template
guide agents correctly for new users building their first Context OS.

Usage:
    python eval_quickstart.py                     # Run all tests
    python eval_quickstart.py --test T1 T3        # Run specific tests
    python eval_quickstart.py --version old        # Test v1.0-ceremony
    python eval_quickstart.py --version new        # Test v2.0-stigmergic (default)
"""

import asyncio
import json
import sys
import time
from pathlib import Path
from dataclasses import dataclass, field

sys.stdout.reconfigure(encoding="utf-8")

from claude_agent_sdk import (
    query,
    ClaudeAgentOptions,
    AssistantMessage,
    ResultMessage,
    TextBlock,
    ToolUseBlock,
)

SCRIPT_DIR = Path(__file__).parent
QUICKSTART_CLAUDE_MD = SCRIPT_DIR / "CLAUDE.md"
STARTER_TEMPLATE = SCRIPT_DIR / "templates" / "CLAUDE_MD_STARTER.md"

# For old version comparison, checkout v1.0-ceremony tag and point here
OLD_CLAUDE_MD = SCRIPT_DIR / "eval_old_claude.md"


TEST_CASES = {
    "T1": {
        "name": "Understand two-layer architecture",
        "prompt": "I'm new to Context OS. Explain the directory structure — what goes where and why?",
        "pass_criteria": "Explains knowledge_base/ (atomic concepts) and 00_foundation/ (operational docs that compose from the graph). Gets the direction of dependency right.",
        "fail_criteria": "Mentions _system/ as a primary directory or doesn't explain the two-layer relationship",
        "critical_fail": "References taxonomy.yaml or ontology.yaml as key system files",
    },
    "T2": {
        "name": "Create first knowledge node",
        "prompt": "I just had a sales call where the prospect mentioned they're struggling with lead scoring. Create a knowledge node for this concept.",
        "pass_criteria": "Creates node with status: emergent, proper frontmatter, wiki-links, placed in knowledge_base/ (business/ or emergent/)",
        "fail_criteria": "Creates node without frontmatter or without wiki-links",
        "critical_fail": "Checks taxonomy.yaml for blessed tags before creating, or creates a staging file",
    },
    "T3": {
        "name": "Check graph health",
        "prompt": "How do I check if my knowledge graph is healthy? What should I look for?",
        "pass_criteria": "Suggests graph-exec command to check node count and orphans. Provides an executable command.",
        "fail_criteria": "Says to run /graph-health (removed command)",
        "critical_fail": "References taxonomy.yaml tag sprawl checking or _system/knowledge_graph/",
    },
    "T4": {
        "name": "Ingest a transcript",
        "prompt": "I have a meeting transcript at raw_sources/prospect_call.md. How do I get insights from it into my knowledge base?",
        "pass_criteria": "Either uses /ingest command or describes manual extraction: read transcript → create nodes in knowledge_base/emergent/ with frontmatter → link via wiki-links",
        "fail_criteria": "Creates files in _system/knowledge_graph/ingestion_staging/",
        "critical_fail": "References ingestion staging workflow or taxonomy validation",
    },
    "T5": {
        "name": "Attribution format",
        "prompt": "I want to claim that our ICP is mid-market SaaS companies. How should I document this in the system?",
        "pass_criteria": "Uses attribution tags: [VERIFIED], [INFERRED], or [UNVERIFIABLE]. Creates or updates a node/doc with proper sourcing.",
        "fail_criteria": "Makes the claim without any attribution format",
        "critical_fail": "No mention of evidence or sourcing at all",
    },
    "T6": {
        "name": "Foundation doc relationship to KB",
        "prompt": "I want to write a positioning document. Should I put it in knowledge_base/ or 00_foundation/? How does it relate to my knowledge nodes?",
        "pass_criteria": "00_foundation/ for the positioning doc. It should reference/compose from atomic concepts in knowledge_base/ via [[wiki-links]]. Foundation docs don't redefine concepts.",
        "fail_criteria": "Puts positioning doc in knowledge_base/",
        "critical_fail": "No understanding of the two-layer architecture",
    },
    "T7": {
        "name": "Use CLI for orientation",
        "prompt": "I've been using this system for a month and have ~30 nodes. I feel lost. How do I orient myself?",
        "pass_criteria": "Suggests context-os CLI commands: graph-exec to find hubs and orphans, heat to see what's active. Provides executable commands.",
        "fail_criteria": "Only suggests reading files manually or checking synthesis docs",
        "critical_fail": "No mention of context-os CLI tools",
    },
    "T8": {
        "name": "Emergent to validated lifecycle",
        "prompt": "I have a concept 'consultative-selling' that I've now used successfully with 3 different prospects. Should I change its status?",
        "pass_criteria": "Promote to validated (or canonical with 2+). Update validated_by frontmatter with specific engagement citations.",
        "fail_criteria": "Doesn't know about the lifecycle",
        "critical_fail": "References node_lifecycle.md or says to check the lifecycle documentation",
    },
}


@dataclass
class EvalResult:
    test_id: str
    version: str
    response: str = ""
    tool_calls: list = field(default_factory=list)
    duration_s: float = 0.0
    error: str | None = None


async def run_single_test(test_id: str, version: str, claude_md_path: Path) -> EvalResult:
    test = TEST_CASES[test_id]
    claude_md_content = claude_md_path.read_text(encoding="utf-8")

    # Also include the starter template as context — this is what the generated CLAUDE.md looks like
    starter_content = ""
    if STARTER_TEMPLATE.exists():
        starter_content = f"\n\n--- STARTER TEMPLATE (what users get) ---\n{STARTER_TEMPLATE.read_text(encoding='utf-8')}"

    system_prompt = f"""You are an agent helping a user who just set up a Context OS using the quickstart.
Their system's CLAUDE.md is below. Use it to answer their question.
Do not reference any knowledge about Context OS beyond what this CLAUDE.md tells you.

--- CLAUDE.md START ---
{claude_md_content}
--- CLAUDE.md END ---
{starter_content}"""

    result = EvalResult(test_id=test_id, version=version)
    start = time.time()

    try:
        text_parts = []
        tools_used = []

        async for message in query(
            prompt=test["prompt"],
            options=ClaudeAgentOptions(
                system_prompt=system_prompt,
                allowed_tools=["Read", "Glob", "Grep", "Bash"],
                permission_mode="acceptEdits",
                cwd=str(SCRIPT_DIR),
                max_turns=10,
            ),
        ):
            if isinstance(message, AssistantMessage):
                for block in message.content:
                    if isinstance(block, TextBlock):
                        text_parts.append(block.text)
                    elif isinstance(block, ToolUseBlock):
                        tools_used.append(
                            {"tool": block.name, "input_summary": str(block.input)[:200]}
                        )
            elif isinstance(message, ResultMessage):
                if message.subtype == "success" and message.result:
                    text_parts.append(message.result)

        result.response = "\n".join(text_parts)
        result.tool_calls = tools_used

    except Exception as e:
        result.error = str(e)

    result.duration_s = round(time.time() - start, 1)
    return result


def print_result(r: EvalResult):
    test = TEST_CASES[r.test_id]
    print(f"\n{'='*70}")
    print(f"  {r.test_id} | {test['name']} | version={r.version} | {r.duration_s}s")
    print(f"  Tools used: {len(r.tool_calls)}")
    print(f"{'='*70}")
    resp = r.response[:1500] + ("..." if len(r.response) > 1500 else "")
    print(resp)
    print(f"\n  PASS: {test['pass_criteria']}")
    print(f"  FAIL: {test['fail_criteria']}")
    print(f"  CRIT: {test['critical_fail']}")
    if r.error:
        print(f"  ERROR: {r.error}")


async def main():
    import argparse

    parser = argparse.ArgumentParser(description="Quickstart CLAUDE.md eval")
    parser.add_argument("--version", choices=["old", "new", "both"], default="new")
    parser.add_argument("--test", nargs="*", default=list(TEST_CASES.keys()))
    parser.add_argument("--parallel", type=int, default=2)
    args = parser.parse_args()

    versions = []
    if args.version in ("new", "both"):
        versions.append(("new", QUICKSTART_CLAUDE_MD))
    if args.version in ("old", "both"):
        if not OLD_CLAUDE_MD.exists():
            print(f"ERROR: Old CLAUDE.md not found at {OLD_CLAUDE_MD}")
            print("Run: git show v1.0-ceremony:CLAUDE.md > eval_old_claude.md")
            sys.exit(1)
        versions.append(("old", OLD_CLAUDE_MD))

    tasks = []
    for test_id in args.test:
        if test_id not in TEST_CASES:
            print(f"WARNING: Unknown test {test_id}, skipping")
            continue
        for version_name, path in versions:
            tasks.append((test_id, version_name, path))

    print(f"Running {len(tasks)} eval tasks ({len(args.test)} tests x {len(versions)} versions)")

    sem = asyncio.Semaphore(args.parallel)
    results: list[EvalResult] = []

    async def run_with_sem(test_id, version_name, path):
        async with sem:
            print(f"  Starting {test_id}/{version_name}...")
            r = await run_single_test(test_id, version_name, path)
            print(f"  Finished {test_id}/{version_name} ({r.duration_s}s)")
            return r

    all_tasks = [run_with_sem(tid, vname, p) for tid, vname, p in tasks]
    results = await asyncio.gather(*all_tasks)

    for test_id in args.test:
        test_results = [r for r in results if r.test_id == test_id]
        for r in sorted(test_results, key=lambda x: x.version):
            print_result(r)

    output_path = SCRIPT_DIR / "eval_results.jsonl"
    with open(output_path, "a", encoding="utf-8") as f:
        for r in results:
            f.write(json.dumps({
                "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
                "test_id": r.test_id,
                "version": r.version,
                "duration_s": r.duration_s,
                "tool_count": len(r.tool_calls),
                "tools": [t["tool"] for t in r.tool_calls],
                "response_length": len(r.response),
                "error": r.error,
                "response_preview": r.response[:500],
            }) + "\n")

    print(f"\nResults appended to {output_path}")

    # Quick summary
    attrs = sum(1 for r in results if any(tag in r.response for tag in ['[VERIFIED', '[INFERRED', '[UNVERIF']))
    errs = sum(1 for r in results if r.error)
    print(f"Total: {len(results)} | Errors: {errs} | Attribution: {attrs}/{len(results)}")


if __name__ == "__main__":
    asyncio.run(main())
