/**
 * Project ID persistence
 *
 * Resolves a stable project identifier for a workspace and persists it in
 * `.lxdig/project.json`.  When the caller provides an explicit `friendlyName`
 * (i.e. the user-supplied `projectId` from tool arguments), that value is
 * used directly.  Otherwise falls back to a 4-char base-36 hash fingerprint
 * derived from the workspace path.
 */

import { readFileSync, writeFileSync, mkdirSync, existsSync } from "fs";
import path from "path";
import { computeProjectFingerprint } from "./validation.js";

const LXDIG_DIR = ".lxdig";
const PROJECT_FILE = "project.json";

interface ProjectMeta {
  /** Canonical project identifier — user-supplied name or hash fallback */
  projectId: string;
  /** Human-readable label */
  name: string;
  workspaceRoot: string;
  createdAt: string;
}

/**
 * Return the canonical projectId for a workspace.
 *
 * Resolution order:
 *  1. If the caller explicitly provides a `friendlyName`, use it as the
 *     canonical projectId (the common case when a user passes `projectId`
 *     through tool arguments).  The name is persisted so that subsequent
 *     calls without an explicit name can retrieve it.
 *  2. If no name is given, try to read the persisted id from
 *     `.lxdig/project.json`.
 *  3. As a last resort, compute a stable 4-char base-36 hash of the path
 *     and persist it.
 *
 * @param workspaceRoot - Absolute path to the project root.
 * @param friendlyName  - Optional explicit projectId supplied by the user.
 */
export function resolvePersistedProjectId(workspaceRoot: string, friendlyName?: string): string {
  const lxdigDir = path.join(workspaceRoot, LXDIG_DIR);
  const projectFile = path.join(lxdigDir, PROJECT_FILE);

  // ── 1. Explicit name provided → use it and persist ──────────────────────
  if (friendlyName) {
    const meta: ProjectMeta = {
      projectId: friendlyName,
      name: friendlyName,
      workspaceRoot,
      createdAt: new Date().toISOString(),
    };

    try {
      mkdirSync(lxdigDir, { recursive: true });
      writeFileSync(projectFile, JSON.stringify(meta, null, 2) + "\n", "utf-8");
    } catch {
      // Non-fatal: project.json creation failed (e.g., read-only FS)
    }

    return friendlyName;
  }

  // ── 2. No explicit name → try persisted file ───────────────────────────
  if (existsSync(projectFile)) {
    try {
      const meta: ProjectMeta = JSON.parse(readFileSync(projectFile, "utf-8"));
      if (meta.projectId && typeof meta.projectId === "string") {
        return meta.projectId;
      }
    } catch {
      // Corrupt file — fall through to regenerate
    }
  }

  // ── 3. Generate hash fingerprint as fallback ───────────────────────────
  const projectId = computeProjectFingerprint(workspaceRoot);
  const defaultName = path
    .basename(workspaceRoot)
    .toLowerCase()
    .replace(/[^a-z0-9-]/g, "-");

  const meta: ProjectMeta = {
    projectId,
    name: defaultName,
    workspaceRoot,
    createdAt: new Date().toISOString(),
  };

  try {
    mkdirSync(lxdigDir, { recursive: true });
    writeFileSync(projectFile, JSON.stringify(meta, null, 2) + "\n", "utf-8");
  } catch (err) {
    console.error(
      `[resolvePersistedProjectId] Warning: Failed to persist project metadata for '${workspaceRoot}': ${err}`,
    );
  }

  return projectId;
}
