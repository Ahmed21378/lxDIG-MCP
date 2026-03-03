# lxDIG Agent Guide — @stratsolver/graph-server

Reference for agents working with this codebase via lxDIG tools.
Read this file when you need tool details — do not inline it into copilot-instructions.md.

## Tool Decision Guide

| Goal | First choice | Fallback |
|---|---|---|
| Count/list nodes | `graph_query` (Cypher) | `graph_health` |
| Understand a symbol | `code_explain` (symbol name) | `semantic_slice` |
| Find related code | `find_similar_code` | `semantic_search` |
| Check arch violations | `arch_validate` | `blocking_issues` |
| Place new code | `arch_suggest` | — |
| Docs lookup | `search_docs` → `index_docs` if count=0 | file read |
| Tests for changed code | `test_select` → `test_run` | `suggest_tests` |
| Record a design choice | `episode_add` (type: DECISION) | — |
| Release an agent lock | `agent_release` with `claimId` | — |

## Correct Tool Signatures

```jsonc
// Session start
init_project_setup({ "projectId": "proj", "workspaceRoot": "/abs/path" })
graph_health({ "profile": "balanced" })

// Graph — capture txId from graph_rebuild for use in diff_since
graph_rebuild({ "projectId": "proj", "mode": "full" })   // → { txId }
diff_since({ "since": "<txId | ISO-8601>" })             // NOT a git ref

// Semantic
code_explain({ "element": "SymbolName", "depth": 2 })    // symbol name, NOT qualified ID
semantic_diff({ "elementId1": "...", "elementId2": "..." })  // NOT elementA/elementB
semantic_slice({ "symbol": "MyClass" })                  // NOT entryPoint
find_similar_code({ "description": "...", "type": "function" })

// Architecture
code_clusters({ "type": "file" })  // type: "function"|"class"|"file"  NOT granularity
arch_suggest({ "name": "NewEngine", "codeType": "engine" })  // NOT codeName
arch_validate({ "files": ["src/x.ts"] })

// Memory — DECISION requires metadata.rationale; all types are UPPERCASE
episode_add({ "type": "DECISION", "content": "...", "outcome": "success",
             "metadata": { "rationale": "because..." } })
episode_add({ "type": "LEARNING", "content": "..." })
decision_query({ "query": "..." })   // NOT topic
progress_query({ "query": "..." })   // query is required, NOT status
context_pack({ "task": "Description..." })  // task string is REQUIRED

// Coordination — capture claimId from agent_claim, pass it to agent_release
agent_claim({ "agentId": "a1", "targetId": "src/file.ts", "intent": "edit X" })  // NOT target
agent_release({ "claimId": "claim-xxx" })  // NOT agentId/taskId

// Tests — suggest_tests needs a fully-qualified element ID
suggest_tests({ "elementId": "proj:file.ts:symbolName:line" })
test_select({ "changedFiles": ["src/x.ts"] })
test_run({ "testFiles": ["..."] })
```

## Common Pitfalls

| Wrong | Correct |
|---|---|
| `code_explain({ elementId: ... })` | `code_explain({ element: "SymbolName" })` |
| `semantic_diff({ elementA, elementB })` | `semantic_diff({ elementId1, elementId2 })` |
| `code_clusters({ granularity: "module" })` | `code_clusters({ type: "file" })` |
| `arch_suggest({ codeName: "X" })` | `arch_suggest({ name: "X" })` |
| `episode_add({ type: "decision" })` | `episode_add({ type: "DECISION" })` (uppercase) |
| DECISION without `metadata.rationale` | always include `metadata: { rationale: "..." }` |
| `decision_query({ topic: "X" })` | `decision_query({ query: "X" })` |
| `agent_claim({ target: "f.ts" })` | `agent_claim({ targetId: "f.ts" })` |
| `agent_release({ agentId, taskId })` | `agent_release({ claimId: "claim-xxx" })` |
| `diff_since({ since: "HEAD~3" })` | `diff_since({ since: "<txId from graph_rebuild>" })` |

## Usage Patterns

### Explore an unfamiliar codebase
```
1. init_project_setup({ projectId, workspaceRoot })
2. graph_query({ query: "MATCH (n) RETURN labels(n)[0], count(n) ORDER BY count(n) DESC LIMIT 10", language: "cypher" })
3. code_explain({ element: "MainEntryPoint" })
4. code_clusters({ type: "file" })   // identify module groups
```

### Safe refactor with impact analysis
```
1. impact_analyze({ changedFiles: ["src/x.ts"] })
2. test_select({ changedFiles: ["src/x.ts"] })
3. arch_validate({ files: ["src/x.ts"] })
4. // make your changes
5. test_run({ testFiles: [...from test_select...] })
6. episode_add({ type: "DECISION", content: "why I changed X",
               metadata: { rationale: "..." } })
```

### Multi-agent safe edit (claim → change → release)
```
1. agent_claim({ agentId: "me", targetId: "src/file.ts", intent: "refactor Y" }) → { claimId }
2. // make changes
3. agent_release({ claimId })  // always release, even on error
```

### Docs cold start
```
1. search_docs({ query: "topic" })           // if count=0:
2. index_docs({ paths: ["/abs/README.md"] })
3. search_docs({ query: "topic" })           // now returns results
```
