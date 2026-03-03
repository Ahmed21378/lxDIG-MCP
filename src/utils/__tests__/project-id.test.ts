import * as fs from "fs";
import * as os from "os";
import * as path from "path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import {
  resolvePersistedProjectId,
  resolveProjectDisplayName,
} from "../project-id.js";
import { computeProjectFingerprint } from "../validation.js";

/**
 * Tests for project ID resolution — BUG-009
 *
 * The canonical projectId must ALWAYS be the 4-char base-36 hash produced by
 * computeProjectFingerprint(workspaceRoot).  The "friendlyName" parameter
 * (originally from env.LXDIG_PROJECT_ID or user-supplied overrides) must only
 * be stored as a human-readable label in `.lxdig/project.json`, never as the
 * canonical projectId.
 */

describe("resolvePersistedProjectId", () => {
  let root: string;

  beforeEach(() => {
    root = fs.mkdtempSync(path.join(os.tmpdir(), "projid-"));
  });

  afterEach(() => {
    fs.rmSync(root, { recursive: true, force: true });
  });

  // ── Core invariant: projectId is always the 4-char hash ─────────────────

  it("returns the 4-char fingerprint hash, never the friendlyName", () => {
    const expectedHash = computeProjectFingerprint(root);

    const result = resolvePersistedProjectId(root, "my-cool-project");

    expect(result).toBe(expectedHash);
    expect(result).not.toBe("my-cool-project");
    expect(result).toHaveLength(4);
    expect(result).toMatch(/^[0-9a-z]{4}$/);
  });

  it("returns the 4-char hash even without a friendlyName", () => {
    const expectedHash = computeProjectFingerprint(root);

    const result = resolvePersistedProjectId(root);

    expect(result).toBe(expectedHash);
    expect(result).toHaveLength(4);
  });

  it("returns the same hash for the same workspace path across calls", () => {
    const first = resolvePersistedProjectId(root, "name-one");
    const second = resolvePersistedProjectId(root, "name-two");
    const third = resolvePersistedProjectId(root);

    expect(first).toBe(second);
    expect(second).toBe(third);
  });

  it("returns different hashes for different workspace paths", () => {
    const root2 = fs.mkdtempSync(path.join(os.tmpdir(), "projid2-"));
    try {
      const hash1 = resolvePersistedProjectId(root);
      const hash2 = resolvePersistedProjectId(root2);
      // Technically could collide, but astronomically unlikely for temp dirs
      expect(hash1).not.toBe(hash2);
    } finally {
      fs.rmSync(root2, { recursive: true, force: true });
    }
  });

  // ── Persistence: project.json stores hash as projectId ──────────────────

  it("persists the hash as projectId in .lxdig/project.json", () => {
    const expectedHash = computeProjectFingerprint(root);

    resolvePersistedProjectId(root, "SomeProject");

    const metaPath = path.join(root, ".lxdig", "project.json");
    expect(fs.existsSync(metaPath)).toBe(true);

    const meta = JSON.parse(fs.readFileSync(metaPath, "utf-8"));
    expect(meta.projectId).toBe(expectedHash);
    expect(meta.projectId).not.toBe("SomeProject");
  });

  it("stores the friendlyName as the name field, not as projectId", () => {
    resolvePersistedProjectId(root, "MyFriendlyProject");

    const meta = JSON.parse(
      fs.readFileSync(path.join(root, ".lxdig", "project.json"), "utf-8"),
    );
    expect(meta.name).toBe("MyFriendlyProject");
    expect(meta.projectId).toBe(computeProjectFingerprint(root));
  });

  it("uses a sanitized basename as display name when no friendlyName given", () => {
    resolvePersistedProjectId(root);

    const meta = JSON.parse(
      fs.readFileSync(path.join(root, ".lxdig", "project.json"), "utf-8"),
    );
    // Display name should be the lowercase, sanitized basename
    const expected = path
      .basename(root)
      .toLowerCase()
      .replace(/[^a-z0-9-]/g, "-");
    expect(meta.name).toBe(expected);
    expect(meta.projectId).toBe(computeProjectFingerprint(root));
  });

  // ── Migration: old basename-based project.json is corrected ─────────────

  it("migrates a stale project.json that has a basename as projectId", () => {
    const lxdigDir = path.join(root, ".lxdig");
    fs.mkdirSync(lxdigDir, { recursive: true });

    // Simulate the BUG-009 state: projectId is a basename, not a hash
    const staleMeta = {
      projectId: "lxDIG-MCP",
      name: "lxDIG-MCP",
      workspaceRoot: root,
      createdAt: "2026-01-01T00:00:00.000Z",
    };
    fs.writeFileSync(
      path.join(lxdigDir, "project.json"),
      JSON.stringify(staleMeta, null, 2) + "\n",
    );

    const result = resolvePersistedProjectId(root, "lxDIG-MCP");

    // Must return the hash, not the stale basename
    const expectedHash = computeProjectFingerprint(root);
    expect(result).toBe(expectedHash);
    expect(result).not.toBe("lxDIG-MCP");

    // The file must be updated with the correct hash
    const updatedMeta = JSON.parse(
      fs.readFileSync(path.join(lxdigDir, "project.json"), "utf-8"),
    );
    expect(updatedMeta.projectId).toBe(expectedHash);
    // The original createdAt should be preserved
    expect(updatedMeta.createdAt).toBe("2026-01-01T00:00:00.000Z");
  });

  it("migrates a stale project.json even without a friendlyName", () => {
    const lxdigDir = path.join(root, ".lxdig");
    fs.mkdirSync(lxdigDir, { recursive: true });

    const staleMeta = {
      projectId: "some-old-basename",
      name: "some-old-basename",
      workspaceRoot: root,
      createdAt: "2025-12-01T00:00:00.000Z",
    };
    fs.writeFileSync(
      path.join(lxdigDir, "project.json"),
      JSON.stringify(staleMeta, null, 2) + "\n",
    );

    const result = resolvePersistedProjectId(root);

    expect(result).toBe(computeProjectFingerprint(root));
  });

  // ── Correct hash in project.json: read without rewrite ──────────────────

  it("reads from persisted file without rewriting when hash is already correct", () => {
    const expectedHash = computeProjectFingerprint(root);
    const lxdigDir = path.join(root, ".lxdig");
    fs.mkdirSync(lxdigDir, { recursive: true });

    const correctMeta = {
      projectId: expectedHash,
      name: "my-project",
      workspaceRoot: root,
      createdAt: "2026-02-01T00:00:00.000Z",
    };
    fs.writeFileSync(
      path.join(lxdigDir, "project.json"),
      JSON.stringify(correctMeta, null, 2) + "\n",
    );

    const result = resolvePersistedProjectId(root);

    expect(result).toBe(expectedHash);

    // Verify file wasn't unnecessarily rewritten
    const meta = JSON.parse(
      fs.readFileSync(path.join(lxdigDir, "project.json"), "utf-8"),
    );
    expect(meta.createdAt).toBe("2026-02-01T00:00:00.000Z");
    expect(meta.name).toBe("my-project");
  });

  it("updates the name field when a different friendlyName is provided and hash is correct", () => {
    const expectedHash = computeProjectFingerprint(root);
    const lxdigDir = path.join(root, ".lxdig");
    fs.mkdirSync(lxdigDir, { recursive: true });

    const correctMeta = {
      projectId: expectedHash,
      name: "old-name",
      workspaceRoot: root,
      createdAt: "2026-02-01T00:00:00.000Z",
    };
    fs.writeFileSync(
      path.join(lxdigDir, "project.json"),
      JSON.stringify(correctMeta, null, 2) + "\n",
    );

    const result = resolvePersistedProjectId(root, "new-display-name");

    expect(result).toBe(expectedHash);

    const meta = JSON.parse(
      fs.readFileSync(path.join(lxdigDir, "project.json"), "utf-8"),
    );
    expect(meta.name).toBe("new-display-name");
    expect(meta.projectId).toBe(expectedHash);
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  it("handles corrupt project.json by regenerating", () => {
    const lxdigDir = path.join(root, ".lxdig");
    fs.mkdirSync(lxdigDir, { recursive: true });
    fs.writeFileSync(path.join(lxdigDir, "project.json"), "NOT VALID JSON!!!");

    const result = resolvePersistedProjectId(root, "salvaged-project");
    const expectedHash = computeProjectFingerprint(root);

    expect(result).toBe(expectedHash);

    // File should now be valid
    const meta = JSON.parse(
      fs.readFileSync(path.join(lxdigDir, "project.json"), "utf-8"),
    );
    expect(meta.projectId).toBe(expectedHash);
    expect(meta.name).toBe("salvaged-project");
  });

  it("creates .lxdig directory if it does not exist", () => {
    expect(fs.existsSync(path.join(root, ".lxdig"))).toBe(false);

    resolvePersistedProjectId(root);

    expect(fs.existsSync(path.join(root, ".lxdig", "project.json"))).toBe(true);
  });

  it("never returns a string longer than 4 characters", () => {
    // Even with a very long friendlyName, the canonical ID must be the hash
    const longName = "a".repeat(200);
    const result = resolvePersistedProjectId(root, longName);
    expect(result).toHaveLength(4);
    expect(result).toMatch(/^[0-9a-z]{4}$/);
  });
});

describe("resolveProjectDisplayName", () => {
  let root: string;

  beforeEach(() => {
    root = fs.mkdtempSync(path.join(os.tmpdir(), "projdisp-"));
  });

  afterEach(() => {
    fs.rmSync(root, { recursive: true, force: true });
  });

  it("returns the persisted display name from project.json", () => {
    // First, persist a project with a friendly name
    resolvePersistedProjectId(root, "MyProject");

    const displayName = resolveProjectDisplayName(root);
    expect(displayName).toBe("MyProject");
  });

  it("returns undefined when no project.json exists", () => {
    const displayName = resolveProjectDisplayName(root);
    expect(displayName).toBeUndefined();
  });

  it("returns undefined for corrupt project.json", () => {
    const lxdigDir = path.join(root, ".lxdig");
    fs.mkdirSync(lxdigDir, { recursive: true });
    fs.writeFileSync(path.join(lxdigDir, "project.json"), "INVALID");

    const displayName = resolveProjectDisplayName(root);
    expect(displayName).toBeUndefined();
  });
});
