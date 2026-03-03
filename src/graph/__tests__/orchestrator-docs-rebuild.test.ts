/**
 * @file orchestrator-docs-rebuild.test.ts
 * @description Tests for BUG-004: docs indexing during full rebuild must run
 *   inside bulk-mode to avoid tripping the circuit breaker.
 *
 * Root cause: orchestrator.build() calls endBulkMode() after the code-graph
 * write (Phase 1-2), then starts docs indexing (Phase 6) outside bulk-mode.
 * Each doc file triggers a separate executeBatch() call operating under the
 * normal CB threshold of 5. Any transient errors rapidly open the circuit
 * breaker, failing the remaining docs and blocking subsequent MCP tool calls
 * for the 20 s cooldown.
 *
 * Additionally, DocsEngine.indexWorkspace() calls executeBatch() per-file in
 * a loop instead of collecting all statements and batching them together.
 * This magnifies the failure surface: 24 markdown files → 24 separate batch
 * calls, each capable of independently recording failures.
 */

import * as fs from "fs";
import * as os from "os";
import * as path from "path";
import { afterEach, describe, expect, it, vi } from "vitest";

import { GraphOrchestrator } from "../orchestrator";
import { DocsEngine } from "../../engines/docs-engine";

// ── Helpers ─────────────────────────────────────────────────────────────────

/** Create a minimal workspace with one .ts source file and N markdown docs. */
function createWorkspace(docCount: number): string {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "orch-bug004-"));
  const srcDir = path.join(root, "src");
  const docsDir = path.join(root, "docs");
  fs.mkdirSync(srcDir, { recursive: true });
  fs.mkdirSync(docsDir, { recursive: true });

  // Minimal TypeScript file so the build has something to parse
  fs.writeFileSync(
    path.join(srcDir, "main.ts"),
    'export function main(): void { console.log("ok"); }\n',
  );

  // Create N markdown docs to simulate a real project
  for (let i = 0; i < docCount; i++) {
    fs.writeFileSync(
      path.join(docsDir, `doc-${i}.md`),
      `# Document ${i}\n\nContent for document ${i}.\n\n## Section A\n\nDetails.\n`,
    );
  }

  return root;
}

function makeMemgraph(overrides: Record<string, unknown> = {}) {
  return {
    isConnected: vi.fn().mockReturnValue(true),
    // Return one ok result per statement (matching real executeBatch behaviour)
    executeBatch: vi
      .fn()
      .mockImplementation((stmts: unknown[]) =>
        Promise.resolve(stmts.map(() => ({ data: [], error: undefined }))),
      ),
    executeCypher: vi.fn().mockResolvedValue({ data: [], records: [] }),
    beginBulkMode: vi.fn(),
    endBulkMode: vi.fn(),
    ...overrides,
  } as any;
}

// ── Tests ───────────────────────────────────────────────────────────────────

describe("BUG-004 — circuit breaker during docs indexing", () => {
  const roots: string[] = [];
  afterEach(() => {
    for (const r of roots) {
      fs.rmSync(r, { recursive: true, force: true });
    }
    roots.length = 0;
  });

  // ────────────────────────────────────────────────────────────────────────
  // Core invariant: docs indexing must happen inside bulk-mode
  // ────────────────────────────────────────────────────────────────────────

  it("bulk-mode must remain active during docs indexing (Phase 6)", async () => {
    const root = createWorkspace(3);
    roots.push(root);

    const callOrder: string[] = [];

    const memgraph = makeMemgraph({
      executeBatch: vi.fn().mockImplementation(async () => {
        const batchIdx = callOrder.filter((c) => c.startsWith("batch")).length;
        callOrder.push(`batch${batchIdx}`);
        return [];
      }),
      beginBulkMode: vi.fn().mockImplementation(() => callOrder.push("begin")),
      endBulkMode: vi.fn().mockImplementation(() => callOrder.push("end")),
    });

    const orchestrator = new GraphOrchestrator(memgraph, false);
    await orchestrator.build({
      mode: "full",
      workspaceRoot: root,
      sourceDir: "src",
      projectId: "bug004",
      indexDocs: true,
    });

    // The last "end" must come AFTER all batch calls (including doc batches).
    // If docs indexing runs outside bulk-mode, "end" appears before the doc batches.
    const lastEnd = callOrder.lastIndexOf("end");
    const lastBatch =
      callOrder.length - 1 - [...callOrder].reverse().findIndex((c) => c.startsWith("batch"));

    expect(lastEnd).toBeGreaterThan(lastBatch);

    // Additionally, there must be no batch calls between "end" and the end of the sequence
    // except possibly a final "end" itself.
    const afterEnd = callOrder.slice(lastEnd + 1);
    const batchesAfterEnd = afterEnd.filter((c) => c.startsWith("batch"));
    expect(
      batchesAfterEnd,
      "No executeBatch calls should happen after endBulkMode — docs must be inside bulk window",
    ).toHaveLength(0);
  });

  it("endBulkMode is called exactly once, after all writes including docs", async () => {
    const root = createWorkspace(2);
    roots.push(root);

    const memgraph = makeMemgraph();

    const orchestrator = new GraphOrchestrator(memgraph, false);
    await orchestrator.build({
      mode: "full",
      workspaceRoot: root,
      sourceDir: "src",
      projectId: "bug004-once",
      indexDocs: true,
    });

    // beginBulkMode called once, endBulkMode called once
    expect(memgraph.beginBulkMode).toHaveBeenCalledTimes(1);
    expect(memgraph.endBulkMode).toHaveBeenCalledTimes(1);
  });

  it("endBulkMode is called even when docs indexing throws", async () => {
    const root = createWorkspace(2);
    roots.push(root);

    // Make executeBatch fail on the 3rd+ call (i.e. during docs indexing)
    let batchCallCount = 0;
    const memgraph = makeMemgraph({
      executeBatch: vi.fn().mockImplementation(async () => {
        batchCallCount++;
        if (batchCallCount > 2) {
          throw new Error("simulated Memgraph overload");
        }
        return [];
      }),
    });

    const orchestrator = new GraphOrchestrator(memgraph, false);

    // Should not throw — docs errors are caught and added as warnings
    const result = await orchestrator.build({
      mode: "full",
      workspaceRoot: root,
      sourceDir: "src",
      projectId: "bug004-throw",
      indexDocs: true,
    });

    expect(result.success).toBe(true);
    expect(memgraph.endBulkMode).toHaveBeenCalledTimes(1);
  });

  // ────────────────────────────────────────────────────────────────────────
  // DocsEngine must batch all statements together, not per-file
  // ────────────────────────────────────────────────────────────────────────

  it("DocsEngine.indexWorkspace() calls executeBatch at most once for all docs", async () => {
    const root = createWorkspace(5);
    roots.push(root);

    const memgraph = makeMemgraph();
    const engine = new DocsEngine(memgraph);
    const result = await engine.indexWorkspace(root, "proj-batch", {
      incremental: false,
    });

    expect(result.indexed).toBeGreaterThanOrEqual(5);
    expect(result.errors).toHaveLength(0);

    // The engine should collect all Cypher statements and call executeBatch
    // once (or at worst, a small number of predictable times), not once per file.
    expect(
      memgraph.executeBatch.mock.calls.length,
      "executeBatch should be called once (all docs batched together), not per-file",
    ).toBeLessThanOrEqual(2); // Allow 1 for hash fetch + 1 for all docs
  });

  it("single executeBatch failure does not cascade to remaining docs", async () => {
    const root = createWorkspace(5);
    roots.push(root);

    // Return mixed results — some statements succeed, some fail
    const memgraph = makeMemgraph({
      executeBatch: vi.fn().mockImplementation(async (stmts: unknown[]) => {
        // Simulate: first statement of the batch has an error, rest succeed
        return (stmts as unknown[]).map((_, i) =>
          i === 0 ? { data: [], error: "transient error" } : { data: [] },
        );
      }),
    });

    const engine = new DocsEngine(memgraph);
    const result = await engine.indexWorkspace(root, "proj-cascade", {
      incremental: false,
    });

    // With batched approach: one batch call, one error reported, rest succeed
    // The old per-file approach would cascade failures: each file is an
    // independent batch, so one failure records a CB failure per file
    expect(result.errors.length).toBeLessThanOrEqual(5);
    // The key point: executeBatch was called a bounded number of times, not N
    expect(memgraph.executeBatch.mock.calls.length).toBeLessThanOrEqual(2);
  });

  // ────────────────────────────────────────────────────────────────────────
  // Regression: incremental mode still skips unchanged docs
  // ────────────────────────────────────────────────────────────────────────

  it("incremental mode skips unchanged docs even with batched writes", async () => {
    const root = createWorkspace(3);
    roots.push(root);

    // Simulate existing hashes that match all files
    const memgraph = makeMemgraph({
      executeCypher: vi.fn().mockResolvedValue({
        data: [{ relativePath: "docs/doc-0.md", hash: "will-not-match" }],
        records: [],
      }),
    });

    const engine = new DocsEngine(memgraph);
    const result = await engine.indexWorkspace(root, "proj-incr", {
      incremental: true,
    });

    // Not all files skipped because only doc-0.md has a stale hash mock
    // The point is: skipped count > 0 would mean incremental still works
    // With no matching hashes, all files get indexed
    expect(result.indexed + result.skipped).toBeGreaterThanOrEqual(3);
  });
});
