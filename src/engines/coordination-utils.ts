/**
 * @file engines/coordination-utils
 * @description Pure helper functions for coordination IDs, mapping, and normalization.
 * @remarks Utility functions are side-effect free and independently testable.
 */

import type { AgentClaim, ClaimType, InvalidationReason } from "./coordination-types.js";

/**
 * Unwrap a neo4j Node object into a plain properties object.
 * The neo4j-driver returns Node instances with `{ identity, labels, properties }`
 * where user data lives inside `.properties`.  Calling code that expects flat
 * property access (e.g., `node.id`) gets `undefined` because `id` is actually
 * at `node.properties.id`.
 *
 * This helper detects Node-shaped objects (has `properties` + `labels` keys)
 * and returns `.properties`; plain objects pass through unchanged.
 */
function unwrapNodeProperties(obj: Record<string, unknown>): Record<string, unknown> {
  // Neo4j Node objects have exactly: identity, labels, properties, elementId.
  // Plain row objects from `RETURN c.id AS id, ...` have user keys directly.
  if (
    obj &&
    typeof obj === "object" &&
    "properties" in obj &&
    "labels" in obj &&
    typeof obj.properties === "object" &&
    obj.properties !== null
  ) {
    return obj.properties as Record<string, unknown>;
  }
  return obj;
}

/**
 * Maps a raw Memgraph row (or the nested `c` property) to an AgentClaim.
 * Handles both flat rows (`RETURN c.id AS id, ...`) and full node returns
 * (`RETURN c`) including neo4j Node objects whose properties live under
 * `.properties`.
 *
 * Returns null if the row lacks a required `id` field.
 */
export function rowToClaim(row: Record<string, unknown>): AgentClaim | null {
  let claim = (row.c as Record<string, unknown>) || (row.claim as Record<string, unknown>) || row;

  if (!claim || typeof claim !== "object") {
    return null;
  }

  // Unwrap neo4j Node.properties if the driver returned a Node object.
  claim = unwrapNodeProperties(claim);

  if (!claim.id) {
    return null;
  }

  return {
    id: String(claim.id),
    agentId: String(claim.agentId ?? "unknown"),
    sessionId: String(claim.sessionId ?? "unknown"),
    taskId: claim.taskId ? String(claim.taskId) : undefined,
    claimType: (claim.claimType ?? "task") as ClaimType,
    targetId: String(claim.targetId ?? ""),
    intent: String(claim.intent ?? ""),
    validFrom: Number(claim.validFrom ?? Date.now()),
    targetVersionSHA: claim.targetVersionSHA ? String(claim.targetVersionSHA) : undefined,
    validTo: claim.validTo == null ? null : Number(claim.validTo),
    invalidationReason: claim.invalidationReason
      ? (String(claim.invalidationReason) as InvalidationReason)
      : undefined,
    outcome: claim.outcome ? String(claim.outcome) : undefined,
    projectId: String(claim.projectId ?? "unknown"),
  };
}

/**
 * Generate a time-prefixed pseudo-unique ID.
 * @param prefix  e.g. "claim"
 * @param now     injectable timestamp (ms) — defaults to Date.now(); pass a
 *                fixed value in tests to get deterministic IDs.
 */
export function makeClaimId(prefix: string, now: number = Date.now()): string {
  return `${prefix}-${now}-${Math.random().toString(36).slice(2, 10)}`;
}
