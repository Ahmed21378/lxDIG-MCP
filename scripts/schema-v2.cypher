// ============================================================================
// lxDIG MCP — Graph Schema v2 for Memgraph
// ============================================================================
//
// Run this script in Memgraph Lab (Query Execution) to bootstrap the schema.
// It is idempotent — safe to run multiple times.
//
// Design principles:
//   - Physical layer (FOLDER → FILE) exists for localization ("where is this?")
//   - Logical layer (CLASS, FUNCTION, VARIABLE) is the primary target for
//     tests, docs, rules, features, tasks, and communities
//   - A single file may contain the entire logical graph if never refactored
//   - FILE → symbol CONTAINS edges bridge physical to logical
//
// Schema layers:
//   0 — Structure   : FOLDER
//   1 — Files       : FILE
//   2 — Symbols     : FUNCTION, CLASS, VARIABLE, IMPORT, EXPORT
//   3 — Tests       : TEST_SUITE, TEST_CASE
//   4 — Docs        : DOCUMENT, SECTION
//   5 — Intelligence: COMMUNITY, RULE, FEATURE, TASK
//   6 — Agent Memory: EPISODE, LEARNING, CLAIM, GRAPH_TX
//
// Relationship types (21 unique, 33 variants):
//   CONTAINS (8), IMPORTS, EXPORTS, REFERENCES, DEPENDS_ON (2),
//   CALLS_TO, EXTENDS, IMPLEMENTS, TESTS (5), SECTION_OF, NEXT_SECTION,
//   DOC_DESCRIBES (3), BELONGS_TO, ANCHORED_BY, VIOLATES_RULE (3),
//   HAS_TASK, IMPLEMENTED_BY (4), TARGETS, INVOLVES, NEXT_EPISODE,
//   APPLIES_TO
//
// Reference: scripts/schema.json (full property definitions)
// ============================================================================


// ---------------------------------------------------------------------------
// 1. INDEXES — Primary lookup (id) + projectId scoping
// ---------------------------------------------------------------------------

// Layer 0 — Structure
CREATE INDEX ON :FOLDER(id);
CREATE INDEX ON :FOLDER(projectId);

// Layer 1 — Files
CREATE INDEX ON :FILE(id);
CREATE INDEX ON :FILE(projectId);
CREATE INDEX ON :FILE(path);
CREATE INDEX ON :FILE(relativePath);

// Layer 2 — Symbols
CREATE INDEX ON :FUNCTION(id);
CREATE INDEX ON :FUNCTION(projectId);
CREATE INDEX ON :FUNCTION(name);

CREATE INDEX ON :CLASS(id);
CREATE INDEX ON :CLASS(projectId);
CREATE INDEX ON :CLASS(name);

CREATE INDEX ON :VARIABLE(id);
CREATE INDEX ON :VARIABLE(projectId);

CREATE INDEX ON :IMPORT(id);
CREATE INDEX ON :IMPORT(projectId);

CREATE INDEX ON :EXPORT(id);
CREATE INDEX ON :EXPORT(projectId);

// Layer 3 — Tests
CREATE INDEX ON :TEST_SUITE(id);
CREATE INDEX ON :TEST_SUITE(projectId);

CREATE INDEX ON :TEST_CASE(id);
CREATE INDEX ON :TEST_CASE(projectId);

// Layer 4 — Docs
CREATE INDEX ON :DOCUMENT(id);
CREATE INDEX ON :DOCUMENT(projectId);

CREATE INDEX ON :SECTION(id);
CREATE INDEX ON :SECTION(projectId);

// Layer 5 — Intelligence
CREATE INDEX ON :COMMUNITY(id);
CREATE INDEX ON :COMMUNITY(projectId);

CREATE INDEX ON :RULE(id);

CREATE INDEX ON :FEATURE(id);
CREATE INDEX ON :FEATURE(projectId);

CREATE INDEX ON :TASK(id);
CREATE INDEX ON :TASK(projectId);

// Layer 6 — Agent Memory
CREATE INDEX ON :EPISODE(id);
CREATE INDEX ON :EPISODE(projectId);
CREATE INDEX ON :EPISODE(agentId);
CREATE INDEX ON :EPISODE(sessionId);

CREATE INDEX ON :LEARNING(id);
CREATE INDEX ON :LEARNING(projectId);

CREATE INDEX ON :CLAIM(id);
CREATE INDEX ON :CLAIM(projectId);
CREATE INDEX ON :CLAIM(agentId);

CREATE INDEX ON :GRAPH_TX(id);
CREATE INDEX ON :GRAPH_TX(projectId);


// ---------------------------------------------------------------------------
// 2. EXISTENCE CONSTRAINTS
// ---------------------------------------------------------------------------

CREATE CONSTRAINT ON (n:FOLDER)     ASSERT EXISTS (n.id);
CREATE CONSTRAINT ON (n:FILE)       ASSERT EXISTS (n.id);
CREATE CONSTRAINT ON (n:FUNCTION)   ASSERT EXISTS (n.id);
CREATE CONSTRAINT ON (n:CLASS)      ASSERT EXISTS (n.id);
CREATE CONSTRAINT ON (n:VARIABLE)   ASSERT EXISTS (n.id);
CREATE CONSTRAINT ON (n:IMPORT)     ASSERT EXISTS (n.id);
CREATE CONSTRAINT ON (n:EXPORT)     ASSERT EXISTS (n.id);
CREATE CONSTRAINT ON (n:TEST_SUITE) ASSERT EXISTS (n.id);
CREATE CONSTRAINT ON (n:TEST_CASE)  ASSERT EXISTS (n.id);
CREATE CONSTRAINT ON (n:DOCUMENT)   ASSERT EXISTS (n.id);
CREATE CONSTRAINT ON (n:SECTION)    ASSERT EXISTS (n.id);
CREATE CONSTRAINT ON (n:COMMUNITY)  ASSERT EXISTS (n.id);
CREATE CONSTRAINT ON (n:RULE)       ASSERT EXISTS (n.id);
CREATE CONSTRAINT ON (n:FEATURE)    ASSERT EXISTS (n.id);
CREATE CONSTRAINT ON (n:TASK)       ASSERT EXISTS (n.id);
CREATE CONSTRAINT ON (n:EPISODE)    ASSERT EXISTS (n.id);
CREATE CONSTRAINT ON (n:LEARNING)   ASSERT EXISTS (n.id);
CREATE CONSTRAINT ON (n:CLAIM)      ASSERT EXISTS (n.id);
CREATE CONSTRAINT ON (n:GRAPH_TX)   ASSERT EXISTS (n.id);


// ---------------------------------------------------------------------------
// 3. UNIQUENESS CONSTRAINTS
// ---------------------------------------------------------------------------

CREATE CONSTRAINT ON (n:FOLDER)     ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:FILE)       ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:FUNCTION)   ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:CLASS)      ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:VARIABLE)   ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:IMPORT)     ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:EXPORT)     ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:TEST_SUITE) ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:TEST_CASE)  ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:DOCUMENT)   ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:SECTION)    ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:COMMUNITY)  ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:RULE)       ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:FEATURE)    ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:TASK)       ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:EPISODE)    ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:LEARNING)   ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:CLAIM)      ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:GRAPH_TX)   ASSERT n.id IS UNIQUE;


// ---------------------------------------------------------------------------
// 4. VERIFICATION
// ---------------------------------------------------------------------------
// SHOW INDEX INFO;
// SHOW CONSTRAINT INFO;
// Expected: 33 indexes, 19 existence constraints, 19 uniqueness constraints


// ============================================================================
// 5. SCHEMA VISUALIZATION — Sample graph for Memgraph Lab
// ============================================================================
// All nodes use "_schema:" prefix. Clean up with:
//   MATCH (n) WHERE n.id STARTS WITH '_schema:' DETACH DELETE n;
//
// Visualize with:
//   MATCH (n)-[r]->(m)
//   WHERE n.id STARTS WITH '_schema:' AND m.id STARTS WITH '_schema:'
//   RETURN n, r, m;


// ═══════════════════════════════════════════════════════════════════════════
// NODES — Layer 0: Structure
// ═══════════════════════════════════════════════════════════════════════════

CREATE (:FOLDER {
  id: '_schema:folder:root',
  name: 'src/',
  path: '/project/src',
  projectId: '_schema'
});

CREATE (:FOLDER {
  id: '_schema:folder:child',
  name: 'graph/',
  path: '/project/src/graph',
  projectId: '_schema'
});


// ═══════════════════════════════════════════════════════════════════════════
// NODES — Layer 1: Files
// ═══════════════════════════════════════════════════════════════════════════

CREATE (:FILE {
  id: '_schema:file:server',
  name: 'server.ts',
  path: '/project/src/server.ts',
  relativePath: 'src/server.ts',
  language: 'TypeScript',
  LOC: 150,
  hash: '',
  projectId: '_schema'
});

CREATE (:FILE {
  id: '_schema:file:builder',
  name: 'builder.ts',
  path: '/project/src/graph/builder.ts',
  relativePath: 'src/graph/builder.ts',
  language: 'TypeScript',
  LOC: 800,
  hash: '',
  projectId: '_schema'
});

CREATE (:FILE {
  id: '_schema:file:helpers',
  name: 'helpers.ts',
  path: '/project/src/utils/helpers.ts',
  relativePath: 'src/utils/helpers.ts',
  language: 'TypeScript',
  LOC: 80,
  hash: '',
  projectId: '_schema'
});


// ═══════════════════════════════════════════════════════════════════════════
// NODES — Layer 2: Symbols (the logical core)
// ═══════════════════════════════════════════════════════════════════════════

CREATE (:FUNCTION {
  id: '_schema:fn:handleRequest',
  name: 'handleRequest',
  kind: 'function',
  filePath: '/project/src/server.ts',
  startLine: 10, endLine: 45, LOC: 35,
  projectId: '_schema'
});

CREATE (:FUNCTION {
  id: '_schema:fn:parseFile',
  name: 'parseFile',
  kind: 'function',
  filePath: '/project/src/utils/helpers.ts',
  startLine: 20, endLine: 40, LOC: 20,
  projectId: '_schema'
});

CREATE (:FUNCTION {
  id: '_schema:fn:buildGraph',
  name: 'buildFromParsedFile',
  kind: 'method',
  filePath: '/project/src/graph/builder.ts',
  startLine: 163, endLine: 200, LOC: 37,
  projectId: '_schema'
});

CREATE (:CLASS {
  id: '_schema:cls:GraphBuilder',
  name: 'GraphBuilder',
  kind: 'class',
  filePath: '/project/src/graph/builder.ts',
  startLine: 1, endLine: 800, LOC: 800,
  projectId: '_schema'
});

CREATE (:CLASS {
  id: '_schema:cls:BaseBuilder',
  name: 'BaseBuilder',
  kind: 'class',
  projectId: '_schema'
});

CREATE (:CLASS {
  id: '_schema:cls:IBuilder',
  name: 'IBuilder',
  kind: 'interface',
  projectId: '_schema'
});

CREATE (:VARIABLE {
  id: '_schema:var:config',
  name: 'config',
  kind: 'const',
  startLine: 5,
  projectId: '_schema'
});

CREATE (:IMPORT {
  id: '_schema:imp:helpers',
  source: './utils/helpers',
  specifiers: ['parseFile', 'logger'],
  startLine: 1,
  projectId: '_schema'
});

CREATE (:EXPORT {
  id: '_schema:exp:GraphBuilder',
  name: 'GraphBuilder',
  isDefault: true,
  startLine: 800,
  projectId: '_schema'
});


// ═══════════════════════════════════════════════════════════════════════════
// NODES — Layer 3: Tests
// ═══════════════════════════════════════════════════════════════════════════

CREATE (:TEST_SUITE {
  id: '_schema:suite:builder',
  name: 'GraphBuilder tests',
  type: 'describe',
  category: 'unit',
  startLine: 1, endLine: 100,
  filePath: 'src/graph/__tests__/builder.test.ts',
  projectId: '_schema'
});

CREATE (:TEST_CASE {
  id: '_schema:tc:buildNodes',
  name: 'should build file nodes',
  startLine: 10, endLine: 25,
  filePath: 'src/graph/__tests__/builder.test.ts',
  projectId: '_schema'
});


// ═══════════════════════════════════════════════════════════════════════════
// NODES — Layer 4: Docs
// ═══════════════════════════════════════════════════════════════════════════

CREATE (:DOCUMENT {
  id: '_schema:doc:readme',
  relativePath: 'README.md',
  filePath: '/project/README.md',
  title: 'lxDIG MCP',
  kind: 'readme',
  wordCount: 2500,
  hash: '',
  projectId: '_schema'
});

CREATE (:SECTION {
  id: '_schema:sec:arch',
  heading: 'Architecture',
  level: 2,
  content: 'The GraphBuilder class orchestrates...',
  wordCount: 350,
  startLine: 42,
  projectId: '_schema'
});

CREATE (:SECTION {
  id: '_schema:sec:api',
  heading: 'API Reference',
  level: 2,
  content: 'The handleRequest function processes...',
  wordCount: 200,
  startLine: 80,
  projectId: '_schema'
});


// ═══════════════════════════════════════════════════════════════════════════
// NODES — Layer 5: Intelligence
// ═══════════════════════════════════════════════════════════════════════════

CREATE (:COMMUNITY {
  id: '_schema:comm:graph',
  label: 'Graph subsystem',
  summary: 'Core graph builder and orchestrator',
  memberCount: 8,
  centralNode: '_schema:cls:GraphBuilder',
  computedAt: 0,
  projectId: '_schema'
});

CREATE (:RULE {
  id: '_schema:rule:engineIsolation',
  severity: 'error',
  pattern: 'engine-isolation',
  description: 'Engines must not import from tools'
});

CREATE (:RULE {
  id: '_schema:rule:layerAssignment',
  severity: 'warning',
  pattern: 'layer-assignment',
  description: 'Every symbol must belong to exactly one architectural layer'
});

CREATE (:FEATURE {
  id: '_schema:feat:graphMVP',
  name: 'Code Graph MVP',
  status: 'completed',
  description: 'Core graph building and querying',
  projectId: '_schema'
});

CREATE (:TASK {
  id: '_schema:task:cbFix',
  name: 'Fix circuit breaker',
  status: 'in-progress',
  featureId: '_schema:feat:graphMVP',
  projectId: '_schema'
});


// ═══════════════════════════════════════════════════════════════════════════
// NODES — Layer 6: Agent Memory
// ═══════════════════════════════════════════════════════════════════════════

CREATE (:EPISODE {
  id: '_schema:ep:decision1',
  type: 'DECISION',
  content: 'Adopted chunked writes for Memgraph',
  agentId: 'copilot-01',
  sessionId: 'session-001',
  timestamp: 0,
  outcome: 'success',
  projectId: '_schema'
});

CREATE (:EPISODE {
  id: '_schema:ep:decision2',
  type: 'LEARNING',
  content: 'Bulk mode prevents CB trips during rebuild',
  agentId: 'copilot-01',
  sessionId: 'session-001',
  timestamp: 1,
  outcome: 'success',
  projectId: '_schema'
});

CREATE (:LEARNING {
  id: '_schema:learn:builder',
  content: 'Repeated activity around builder.ts',
  extractedAt: 0,
  confidence: 0.8,
  projectId: '_schema'
});

CREATE (:CLAIM {
  id: '_schema:claim:refactor',
  agentId: 'copilot-01',
  intent: 'Refactoring builder for two-phase pipeline',
  status: 'active',
  projectId: '_schema'
});

CREATE (:GRAPH_TX {
  id: '_schema:tx:rebuild1',
  type: 'rebuild',
  timestamp: 0,
  mode: 'full',
  sourceDir: '/project/src',
  projectId: '_schema'
});


// ============================================================================
// 6. RELATIONSHIPS — All 33 edge variants across 21 unique types
// ============================================================================

// ─────────────────────────────────────────────────────────────────────────
// PHYSICAL LAYER: Folder hierarchy + folder→file containment
// ─────────────────────────────────────────────────────────────────────────

// CONTAINS : FOLDER → FOLDER (folder hierarchy)
MATCH (a:FOLDER {id: '_schema:folder:root'}),
      (b:FOLDER {id: '_schema:folder:child'})
CREATE (a)-[:CONTAINS]->(b);

// CONTAINS : FOLDER → FILE
MATCH (a:FOLDER {id: '_schema:folder:root'}),
      (b:FILE   {id: '_schema:file:server'})
CREATE (a)-[:CONTAINS]->(b);

MATCH (a:FOLDER {id: '_schema:folder:child'}),
      (b:FILE   {id: '_schema:file:builder'})
CREATE (a)-[:CONTAINS]->(b);

// ─────────────────────────────────────────────────────────────────────────
// BRIDGE: Physical → Logical (FILE contains symbols)
// ─────────────────────────────────────────────────────────────────────────

// CONTAINS : FILE → FUNCTION
MATCH (a:FILE     {id: '_schema:file:server'}),
      (b:FUNCTION {id: '_schema:fn:handleRequest'})
CREATE (a)-[:CONTAINS]->(b);

MATCH (a:FILE     {id: '_schema:file:helpers'}),
      (b:FUNCTION {id: '_schema:fn:parseFile'})
CREATE (a)-[:CONTAINS]->(b);

MATCH (a:FILE     {id: '_schema:file:builder'}),
      (b:FUNCTION {id: '_schema:fn:buildGraph'})
CREATE (a)-[:CONTAINS]->(b);

// CONTAINS : FILE → CLASS
MATCH (a:FILE  {id: '_schema:file:builder'}),
      (b:CLASS {id: '_schema:cls:GraphBuilder'})
CREATE (a)-[:CONTAINS]->(b);

// CONTAINS : FILE → VARIABLE
MATCH (a:FILE     {id: '_schema:file:server'}),
      (b:VARIABLE {id: '_schema:var:config'})
CREATE (a)-[:CONTAINS]->(b);

// ─────────────────────────────────────────────────────────────────────────
// IMPORTS / EXPORTS / REFERENCES / DEPENDS_ON
// ─────────────────────────────────────────────────────────────────────────

// IMPORTS : FILE → IMPORT
MATCH (a:FILE   {id: '_schema:file:server'}),
      (b:IMPORT {id: '_schema:imp:helpers'})
CREATE (a)-[:IMPORTS]->(b);

// EXPORTS : FILE → EXPORT
MATCH (a:FILE   {id: '_schema:file:builder'}),
      (b:EXPORT {id: '_schema:exp:GraphBuilder'})
CREATE (a)-[:EXPORTS]->(b);

// REFERENCES : IMPORT → FILE (resolved target)
MATCH (a:IMPORT {id: '_schema:imp:helpers'}),
      (b:FILE   {id: '_schema:file:helpers'})
CREATE (a)-[:REFERENCES]->(b);

// DEPENDS_ON : FILE → FILE
MATCH (a:FILE {id: '_schema:file:server'}),
      (b:FILE {id: '_schema:file:helpers'})
CREATE (a)-[:DEPENDS_ON]->(b);

// ─────────────────────────────────────────────────────────────────────────
// LOGICAL LAYER: Call graph + inheritance (behavior)
// ─────────────────────────────────────────────────────────────────────────

// CALLS_TO : FUNCTION → FUNCTION
MATCH (a:FUNCTION {id: '_schema:fn:handleRequest'}),
      (b:FUNCTION {id: '_schema:fn:parseFile'})
CREATE (a)-[:CALLS_TO {line: 15}]->(b);

MATCH (a:FUNCTION {id: '_schema:fn:handleRequest'}),
      (b:FUNCTION {id: '_schema:fn:buildGraph'})
CREATE (a)-[:CALLS_TO {line: 30}]->(b);

// EXTENDS : CLASS → CLASS
MATCH (a:CLASS {id: '_schema:cls:GraphBuilder'}),
      (b:CLASS {id: '_schema:cls:BaseBuilder'})
CREATE (a)-[:EXTENDS]->(b);

// IMPLEMENTS : CLASS → CLASS (interface)
MATCH (a:CLASS {id: '_schema:cls:GraphBuilder'}),
      (b:CLASS {id: '_schema:cls:IBuilder'})
CREATE (a)-[:IMPLEMENTS]->(b);

// ─────────────────────────────────────────────────────────────────────────
// TESTS — Connected to logical symbols (FUNCTION, CLASS), not just files
// ─────────────────────────────────────────────────────────────────────────

// CONTAINS : FILE → TEST_SUITE
MATCH (a:FILE       {id: '_schema:file:builder'}),
      (b:TEST_SUITE {id: '_schema:suite:builder'})
CREATE (a)-[:CONTAINS]->(b);

// CONTAINS : FILE → TEST_CASE
MATCH (a:FILE      {id: '_schema:file:builder'}),
      (b:TEST_CASE {id: '_schema:tc:buildNodes'})
CREATE (a)-[:CONTAINS]->(b);

// CONTAINS : TEST_SUITE → TEST_CASE
MATCH (a:TEST_SUITE {id: '_schema:suite:builder'}),
      (b:TEST_CASE  {id: '_schema:tc:buildNodes'})
CREATE (a)-[:CONTAINS]->(b);

// TESTS : TEST_SUITE → CLASS (primary link: test covers a class)
MATCH (a:TEST_SUITE {id: '_schema:suite:builder'}),
      (b:CLASS      {id: '_schema:cls:GraphBuilder'})
CREATE (a)-[:TESTS]->(b);

// TESTS : TEST_SUITE → FUNCTION (test covers a function)
MATCH (a:TEST_SUITE {id: '_schema:suite:builder'}),
      (b:FUNCTION   {id: '_schema:fn:buildGraph'})
CREATE (a)-[:TESTS]->(b);

// TESTS : TEST_CASE → FUNCTION (individual test verifies a function)
MATCH (a:TEST_CASE {id: '_schema:tc:buildNodes'}),
      (b:FUNCTION  {id: '_schema:fn:buildGraph'})
CREATE (a)-[:TESTS]->(b);

// TESTS : TEST_CASE → CLASS (individual test verifies a class)
MATCH (a:TEST_CASE {id: '_schema:tc:buildNodes'}),
      (b:CLASS     {id: '_schema:cls:GraphBuilder'})
CREATE (a)-[:TESTS]->(b);

// TESTS : TEST_SUITE → FILE (fallback when symbol-level resolution not possible)
MATCH (a:TEST_SUITE {id: '_schema:suite:builder'}),
      (b:FILE       {id: '_schema:file:builder'})
CREATE (a)-[:TESTS]->(b);

// ─────────────────────────────────────────────────────────────────────────
// DOCS — Describes functions, classes, AND files
// ─────────────────────────────────────────────────────────────────────────

// SECTION_OF : SECTION → DOCUMENT
MATCH (a:SECTION  {id: '_schema:sec:arch'}),
      (b:DOCUMENT {id: '_schema:doc:readme'})
CREATE (a)-[:SECTION_OF]->(b);

MATCH (a:SECTION  {id: '_schema:sec:api'}),
      (b:DOCUMENT {id: '_schema:doc:readme'})
CREATE (a)-[:SECTION_OF]->(b);

// NEXT_SECTION : SECTION → SECTION
MATCH (a:SECTION {id: '_schema:sec:arch'}),
      (b:SECTION {id: '_schema:sec:api'})
CREATE (a)-[:NEXT_SECTION]->(b);

// DOC_DESCRIBES : SECTION → CLASS
MATCH (a:SECTION {id: '_schema:sec:arch'}),
      (b:CLASS   {id: '_schema:cls:GraphBuilder'})
CREATE (a)-[:DOC_DESCRIBES {strength: 1.0, matchedName: 'GraphBuilder'}]->(b);

// DOC_DESCRIBES : SECTION → FUNCTION
MATCH (a:SECTION  {id: '_schema:sec:api'}),
      (b:FUNCTION {id: '_schema:fn:handleRequest'})
CREATE (a)-[:DOC_DESCRIBES {strength: 1.0, matchedName: 'handleRequest'}]->(b);

// DOC_DESCRIBES : SECTION → FILE
MATCH (a:SECTION {id: '_schema:sec:arch'}),
      (b:FILE    {id: '_schema:file:builder'})
CREATE (a)-[:DOC_DESCRIBES {strength: 0.9, matchedName: 'builder.ts'}]->(b);

// ─────────────────────────────────────────────────────────────────────────
// INTELLIGENCE — Rules, communities, features, tasks anchored to symbols
// ─────────────────────────────────────────────────────────────────────────

// BELONGS_TO : symbol → COMMUNITY
MATCH (a:CLASS     {id: '_schema:cls:GraphBuilder'}),
      (b:COMMUNITY {id: '_schema:comm:graph'})
CREATE (a)-[:BELONGS_TO]->(b);

MATCH (a:FUNCTION  {id: '_schema:fn:buildGraph'}),
      (b:COMMUNITY {id: '_schema:comm:graph'})
CREATE (a)-[:BELONGS_TO]->(b);

// ANCHORED_BY : COMMUNITY → symbol (central node)
MATCH (a:COMMUNITY {id: '_schema:comm:graph'}),
      (b:CLASS     {id: '_schema:cls:GraphBuilder'})
CREATE (a)-[:ANCHORED_BY]->(b);

// VIOLATES_RULE : FILE → RULE
MATCH (a:FILE {id: '_schema:file:server'}),
      (b:RULE {id: '_schema:rule:engineIsolation'})
CREATE (a)-[:VIOLATES_RULE {severity: 'warning', message: 'Cross-layer import detected'}]->(b);

// VIOLATES_RULE : CLASS → RULE
MATCH (a:CLASS {id: '_schema:cls:GraphBuilder'}),
      (b:RULE  {id: '_schema:rule:layerAssignment'})
CREATE (a)-[:VIOLATES_RULE {severity: 'info', message: 'No layer annotation'}]->(b);

// VIOLATES_RULE : FUNCTION → RULE
MATCH (a:FUNCTION {id: '_schema:fn:buildGraph'}),
      (b:RULE     {id: '_schema:rule:engineIsolation'})
CREATE (a)-[:VIOLATES_RULE {severity: 'error', message: 'Engine function imports from tools layer'}]->(b);

// DEPENDS_ON : RULE → RULE (rule dependency chain)
MATCH (a:RULE {id: '_schema:rule:engineIsolation'}),
      (b:RULE {id: '_schema:rule:layerAssignment'})
CREATE (a)-[:DEPENDS_ON]->(b);

// HAS_TASK : FEATURE → TASK
MATCH (a:FEATURE {id: '_schema:feat:graphMVP'}),
      (b:TASK    {id: '_schema:task:cbFix'})
CREATE (a)-[:HAS_TASK]->(b);

// IMPLEMENTED_BY : FEATURE → CLASS
MATCH (a:FEATURE {id: '_schema:feat:graphMVP'}),
      (b:CLASS   {id: '_schema:cls:GraphBuilder'})
CREATE (a)-[:IMPLEMENTED_BY]->(b);

// IMPLEMENTED_BY : FEATURE → FUNCTION
MATCH (a:FEATURE  {id: '_schema:feat:graphMVP'}),
      (b:FUNCTION {id: '_schema:fn:buildGraph'})
CREATE (a)-[:IMPLEMENTED_BY]->(b);

// IMPLEMENTED_BY : TASK → CLASS
MATCH (a:TASK  {id: '_schema:task:cbFix'}),
      (b:CLASS {id: '_schema:cls:GraphBuilder'})
CREATE (a)-[:IMPLEMENTED_BY]->(b);

// IMPLEMENTED_BY : TASK → FUNCTION
MATCH (a:TASK     {id: '_schema:task:cbFix'}),
      (b:FUNCTION {id: '_schema:fn:buildGraph'})
CREATE (a)-[:IMPLEMENTED_BY]->(b);

// ─────────────────────────────────────────────────────────────────────────
// AGENT MEMORY — Claims, episodes, learnings
// ─────────────────────────────────────────────────────────────────────────

// TARGETS : CLAIM → symbol (coordination lock)
MATCH (a:CLAIM {id: '_schema:claim:refactor'}),
      (b:CLASS {id: '_schema:cls:GraphBuilder'})
CREATE (a)-[:TARGETS]->(b);

// INVOLVES : EPISODE → symbol
MATCH (a:EPISODE  {id: '_schema:ep:decision1'}),
      (b:FUNCTION {id: '_schema:fn:buildGraph'})
CREATE (a)-[:INVOLVES]->(b);

MATCH (a:EPISODE {id: '_schema:ep:decision1'}),
      (b:CLASS   {id: '_schema:cls:GraphBuilder'})
CREATE (a)-[:INVOLVES]->(b);

// NEXT_EPISODE : EPISODE → EPISODE (temporal chain)
MATCH (a:EPISODE {id: '_schema:ep:decision1'}),
      (b:EPISODE {id: '_schema:ep:decision2'})
CREATE (a)-[:NEXT_EPISODE]->(b);

// APPLIES_TO : LEARNING → symbol
MATCH (a:LEARNING {id: '_schema:learn:builder'}),
      (b:CLASS    {id: '_schema:cls:GraphBuilder'})
CREATE (a)-[:APPLIES_TO]->(b);

MATCH (a:LEARNING {id: '_schema:learn:builder'}),
      (b:FILE     {id: '_schema:file:builder'})
CREATE (a)-[:APPLIES_TO]->(b);


// ============================================================================
// Done.
//
// Verify:
//   SHOW INDEX INFO;
//   SHOW CONSTRAINT INFO;
//
// Visualize the full schema:
//   MATCH (n)-[r]->(m)
//   WHERE n.id STARTS WITH '_schema:' AND m.id STARTS WITH '_schema:'
//   RETURN n, r, m;
//
// Clean up sample data:
//   MATCH (n) WHERE n.id STARTS WITH '_schema:' DETACH DELETE n;
//
// Query examples from schema.json → queryPatterns:
//
//   -- Where is this symbol?
//   MATCH (f:FILE)-[:CONTAINS]->(s) WHERE s.name = 'handleRequest'
//   RETURN f.relativePath, s.startLine;
//
//   -- What does this function call?
//   MATCH (fn:FUNCTION {name: 'handleRequest'})-[:CALLS_TO]->(c)
//   RETURN c.name, c.filePath;
//
//   -- What breaks if I change this class?
//   MATCH (c:CLASS {name: 'GraphBuilder'})<-[:TESTS]-(t)
//   RETURN t.name AS affectedTest
//   UNION
//   MATCH (c:CLASS {name: 'GraphBuilder'})<-[:EXTENDS|IMPLEMENTS]-(sub)
//   RETURN sub.name AS affectedSubclass;
//
//   -- Which functions have no tests?
//   MATCH (fn:FUNCTION) WHERE NOT (fn)<-[:TESTS]-()
//   RETURN fn.name, fn.filePath;
//
//   -- What code implements this feature?
//   MATCH (f:FEATURE {name: 'Code Graph MVP'})-[:IMPLEMENTED_BY]->(s)
//   RETURN labels(s)[0] AS type, s.name, s.filePath;
//
//   -- Which functions violate rules?
//   MATCH (fn:FUNCTION)-[v:VIOLATES_RULE]->(r:RULE)
//   RETURN fn.name, r.description, v.severity;
//
//   -- What is the anchor of each community?
//   MATCH (c:COMMUNITY)-[:ANCHORED_BY]->(s)
//   RETURN c.label, s.name, labels(s)[0];
//
// ============================================================================
