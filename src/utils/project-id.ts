/**
 * Project ID persistence
 *
 * Resolves a stable project identifier for a workspace and persists it in
 * `.lxdig/project.json`.  The canonical projectId is **always** the 4-char
 * base-36 hash produced by `computeProjectFingerprint(workspaceRoot)`.
 *
 * The optional `friendlyName` parameter is stored as a human-readable label
 * in the `name` field of the persisted metadata — it is never used as the
 * canonical DB key.  This prevents the basename-as-projectId problem
 * (BUG-009) where different machines or renamed directories would produce
 * different projectIds for the same logical project.
 */

import { readFileSync, writeFileSync, mkdirSync, existsSync } from "fs";
import path from "path";
import { computeProjectFingerprint } from "./validation.js";

const LXDIG_DIR = ".lxdig";
const PROJECT_FILE = "project.json";

interface ProjectMeta {
  /** Canonical project identifier — always the 4-char base-36 hash */
  projectId: string;
  /** Human-readable display label (from env or directory basename) */
  name: string;
  workspaceRoot: string;
  createdAt: string;
}

/**
 * Return the canonical projectId for a workspace.
 *
 * The canonical ID is always `computeProjectFingerprint(workspaceRoot)` — a
 * stable 4-char base-36 hash.  The `friendlyName`, if provided, is stored
 * as the `name` field in `.lxdig/project.json` for display purposes only.
 *
 * If a persisted `project.json` already contains the correct hash, it is
 * read without rewriting (unless the display name changed).  Stale files
 * from the old basename-based scheme are automatically migrated.
 *
 * @param workspaceRoot - Absolute path to the project root.
 * @param friendlyName  - Optional human-readable label for display purposes.
 */
export function resolvePersistedProjectId(workspaceRoot: string, friendlyName?: string): string {
  const lxdigDir = path.join(workspaceRoot, LXDIG_DIR);
  const projectFile = path.join(lxdigDir, PROJECT_FILE);

  // The canonical projectId is ALWAYS the 4-char hash fingerprint.
  const canonicalId = computeProjectFingerprint(workspaceRoot);

  // Determine the human-readable label to store alongside the hash.
  const displayName =
    friendlyName ||
    path.basename(workspaceRoot).toLowerCase().replace(/[^a-z0-9-]/g, "-");

  // ── 1. Try reading existing metadata ────────────────────────────────────
  let existingMeta: ProjectMeta | null = null;
  if (existsSync(projectFile)) {
    try {
      existingMeta = JSON.parse(readFileSync(projectFile, "utf-8"));
    } catch {
      // Corrupt file — fall through to regenerate
    }
  }

  // ── 2. If persisted hash is already correct, return it ──────────────────
  if (existingMeta?.projectId === canonicalId) {
    // Update the display name if caller provided a new one
    if (friendlyName && existingMeta.name !== friendlyName) {
      existingMeta.name = friendlyName;
      try {
        writeFileSync(projectFile, JSON.stringify(existingMeta, null, 2) + "\n", "utf-8");
      } catch {
        // Non-fatal
      }
    }
    return canonicalId;
  }

  // ── 3. Persist the canonical hash (new project or migration) ────────────
  const meta: ProjectMeta = {
    projectId: canonicalId,
    name: displayName,
    workspaceRoot,
    createdAt: existingMeta?.createdAt || new Date().toISOString(),
  };

  try {
    mkdirSync(lxdigDir, { recursive: true });
    writeFileSync(projectFile, JSON.stringify(meta, null, 2) + "\n", "utf-8");
  } catch (err) {
    console.error(
      `[resolvePersistedProjectId] Warning: Failed to persist project metadata for '${workspaceRoot}': ${err}`,
    );
  }

  return canonicalId;
}

/**
 * Read the persisted human-readable display name for a project.
 *
 * Returns `undefined` if no `.lxdig/project.json` exists or the file is corrupt.
 * This never computes or modifies anything — it is a pure read.
 *
 * @param workspaceRoot - Absolute path to the project root.
 */
export function resolveProjectDisplayName(workspaceRoot: string): string | undefined {
  const projectFile = path.join(workspaceRoot, LXDIG_DIR, PROJECT_FILE);
  try {
    const meta: ProjectMeta = JSON.parse(readFileSync(projectFile, "utf-8"));
    return meta.name || undefined;
  } catch {
    return undefined;
  }
}
