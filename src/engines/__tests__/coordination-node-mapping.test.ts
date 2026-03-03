/**
 * @file coordination-node-mapping.test.ts
 * @description Tests for BUG-002: agent_status and coordination_overview return
 *   empty activeClaims despite valid claims existing in Memgraph.
 *
 * Root cause: Queries like AGENT_ACTIVE_CLAIMS use `RETURN c` which returns a
 * neo4j Node object. The Node object stores user properties in .properties
 * (e.g., Node.properties.id) — NOT as top-level keys (Node.id is undefined).
 * rowToClaim() checked claim.id on the raw Node, got undefined, returned null.
 *
 * These tests use real neo4j Node objects to reproduce the actual runtime shape,
 * proving the existing tests passed because they used plain JS objects.
 */

import { describe, expect, it, vi } from "vitest";
import neo4j from "neo4j-driver";
import CoordinationEngine from "../coordination-engine";
import { rowToClaim } from "../coordination-utils";

// ── Helpers ─────────────────────────────────────────────────────────────────

/** Create a real neo4j Node the way Memgraph's bolt driver returns them. */
function makeNeo4jNode(
  id: number,
  labels: string[],
  properties: Record<string, unknown>,
): InstanceType<typeof neo4j.types.Node> {
  return new neo4j.types.Node(id, labels, properties);
}

/** Standard claim properties for test fixtures. */
function claimProps(overrides: Record<string, unknown> = {}) {
  return {
    id: "claim-neo4j-1",
    agentId: "agent-a",
    sessionId: "sess-1",
    taskId: "task-x",
    claimType: "file",
    targetId: "file:src/foo.ts",
    intent: "editing foo.ts",
    validFrom: 1000,
    targetVersionSHA: "abc123",
    validTo: null,
    invalidationReason: null,
    outcome: null,
    projectId: "proj",
    ...overrides,
  };
}

// ── rowToClaim with real Node objects ────────────────────────────────────────

describe("BUG-002 — rowToClaim with neo4j Node objects", () => {
  it("extracts claim properties from a neo4j Node (RETURN c shape)", () => {
    const node = makeNeo4jNode(42, ["CLAIM"], claimProps());
    // This is the shape executeCypher returns for `RETURN c`:
    const row = { c: node };

    const claim = rowToClaim(row);

    expect(claim).not.toBeNull();
    expect(claim?.id).toBe("claim-neo4j-1");
    expect(claim?.agentId).toBe("agent-a");
    expect(claim?.claimType).toBe("file");
    expect(claim?.targetId).toBe("file:src/foo.ts");
    expect(claim?.intent).toBe("editing foo.ts");
    expect(claim?.validFrom).toBe(1000);
    expect(claim?.validTo).toBeNull();
    expect(claim?.projectId).toBe("proj");
  });

  it("handles Node with no taskId", () => {
    const node = makeNeo4jNode(43, ["CLAIM"], claimProps({ taskId: null }));
    const row = { c: node };
    const claim = rowToClaim(row);

    expect(claim).not.toBeNull();
    expect(claim?.taskId).toBeUndefined();
  });

  it("handles closed claim (validTo set)", () => {
    const node = makeNeo4jNode(44, ["CLAIM"], claimProps({ validTo: 5000 }));
    const row = { c: node };
    const claim = rowToClaim(row);

    expect(claim).not.toBeNull();
    expect(claim?.validTo).toBe(5000);
  });
});

// ── CoordinationEngine.status with real Node objects ────────────────────────

describe("BUG-002 — CoordinationEngine.status with neo4j Node shapes", () => {
  it("returns non-empty activeClaims when Memgraph returns Node objects", async () => {
    const node = makeNeo4jNode(100, ["CLAIM"], claimProps());

    const memgraph = {
      executeCypher: vi
        .fn()
        .mockResolvedValueOnce({ data: [{ c: node }] }) // AGENT_ACTIVE_CLAIMS
        .mockResolvedValueOnce({ data: [] }), // AGENT_RECENT_EPISODES
    } as any;

    const engine = new CoordinationEngine(memgraph);
    const status = await engine.status("agent-a", "proj");

    expect(status.activeClaims).toHaveLength(1);
    expect(status.activeClaims[0]?.id).toBe("claim-neo4j-1");
    expect(status.activeClaims[0]?.agentId).toBe("agent-a");
    expect(status.currentTask).toBe("task-x");
  });

  it("returns non-empty activeClaims with flat row data (new query shape)", async () => {
    // New queries use RETURN c.id AS id, c.agentId AS agentId, ...
    // which produces flat rows without the c: wrapper
    const flatRow = claimProps();

    const memgraph = {
      executeCypher: vi
        .fn()
        .mockResolvedValueOnce({ data: [flatRow] })
        .mockResolvedValueOnce({ data: [] }),
    } as any;

    const engine = new CoordinationEngine(memgraph);
    const status = await engine.status("agent-a", "proj");

    expect(status.activeClaims).toHaveLength(1);
    expect(status.activeClaims[0]?.id).toBe("claim-neo4j-1");
    expect(status.activeClaims[0]?.agentId).toBe("agent-a");
  });

  it("returns multiple active claims correctly", async () => {
    const node1 = makeNeo4jNode(101, ["CLAIM"], claimProps({ id: "c1", taskId: "t1" }));
    const node2 = makeNeo4jNode(102, ["CLAIM"], claimProps({ id: "c2", taskId: "t2" }));

    const memgraph = {
      executeCypher: vi
        .fn()
        .mockResolvedValueOnce({ data: [{ c: node1 }, { c: node2 }] })
        .mockResolvedValueOnce({ data: [] }),
    } as any;

    const engine = new CoordinationEngine(memgraph);
    const status = await engine.status("agent-a", "proj");

    expect(status.activeClaims).toHaveLength(2);
    expect(status.activeClaims[0]?.id).toBe("c1");
    expect(status.activeClaims[1]?.id).toBe("c2");
  });
});

// ── CoordinationEngine.overview with real Node objects ──────────────────────

describe("BUG-002 — CoordinationEngine.overview with neo4j Node shapes", () => {
  it("returns non-empty activeClaims from OVERVIEW_ACTIVE with Node objects", async () => {
    const activeNode = makeNeo4jNode(200, ["CLAIM"], claimProps({ id: "active-1" }));
    const staleNode = makeNeo4jNode(201, ["CLAIM"], claimProps({ id: "stale-1" }));

    const memgraph = {
      executeCypher: vi
        .fn()
        .mockResolvedValueOnce({ data: [{ c: activeNode }] }) // OVERVIEW_ACTIVE
        .mockResolvedValueOnce({ data: [{ c: staleNode }] }) // OVERVIEW_STALE
        .mockResolvedValueOnce({ data: [] }) // OVERVIEW_CONFLICTS
        .mockResolvedValueOnce({ data: [] }) // OVERVIEW_AGENT_SUMMARY
        .mockResolvedValueOnce({ data: [{ totalClaims: 2 }] }), // OVERVIEW_TOTAL
    } as any;

    const engine = new CoordinationEngine(memgraph);
    const overview = await engine.overview("proj");

    expect(overview.activeClaims).toHaveLength(1);
    expect(overview.activeClaims[0]?.id).toBe("active-1");
    expect(overview.staleClaims).toHaveLength(1);
    expect(overview.staleClaims[0]?.id).toBe("stale-1");
    expect(overview.totalClaims).toBe(2);
  });
});
