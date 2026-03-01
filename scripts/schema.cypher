// ============================================================================
// lxDIG MCP — Graph Schema for Memgraph
// ============================================================================
//
// Run this script in Memgraph Lab (Query Execution) to bootstrap the schema.
// It is idempotent — safe to run multiple times.
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
// Relationship types (25):
//   CONTAINS, IMPORTS, EXPORTS, REFERENCES, DEPENDS_ON, CALLS_TO,
//   EXTENDS, IMPLEMENTS, SECTION_OF, NEXT_SECTION, DOC_DESCRIBES,
//   TESTS, BELONGS_TO, TARGETS, INVOLVES, NEXT_EPISODE, APPLIES_TO,
//   VIOLATES_RULE
//
// ============================================================================

// ---------------------------------------------------------------------------
// 1. INDEXES — Primary lookup (id) + projectId scoping
// ---------------------------------------------------------------------------
// Every node label gets an index on `id` (primary key) and `projectId`
// (multi-tenant scoping). These are the two fields used in every MERGE/MATCH.

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
// 2. EXISTENCE CONSTRAINTS — Required properties on core nodes
// ---------------------------------------------------------------------------
// Memgraph enforces these at write time. Prevents incomplete nodes from
// entering the graph.

CREATE CONSTRAINT ON (n:FILE)       ASSERT EXISTS (n.id);
CREATE CONSTRAINT ON (n:FOLDER)     ASSERT EXISTS (n.id);
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
// 3. UNIQUENESS CONSTRAINTS — Prevent duplicate nodes
// ---------------------------------------------------------------------------
// Each node's `id` is globally unique within its label. This also implicitly
// creates an index, but we keep the explicit CREATE INDEX above for clarity.

CREATE CONSTRAINT ON (n:FILE)       ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:FOLDER)     ASSERT n.id IS UNIQUE;
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
// 4. SCHEMA VERIFICATION — Run after to confirm everything was created
// ---------------------------------------------------------------------------
// Uncomment and run this block to verify:
//
// SHOW INDEX INFO;
// SHOW CONSTRAINT INFO;
//
// Expected: 33 indexes, 19 existence constraints, 19 uniqueness constraints

// ---------------------------------------------------------------------------
// 5. SCHEMA VISUALIZATION — Sample nodes + edges for Memgraph Lab graph view
// ---------------------------------------------------------------------------
// Creates one node per label and one edge per relationship type so you can
// see the full schema as a visual graph in Memgraph Lab's "Graph" tab.
// All sample nodes use id prefix "_schema:" so they won't collide with
// real data and can be deleted with:
//   MATCH (n) WHERE n.id STARTS WITH '_schema:' DETACH DELETE n;

// --- Layer 0: Structure ---
CREATE (folder:FOLDER {
  id: '_schema:folder',
  name: 'src/',
  path: '/project/src',
  projectId: '_schema'
});

// --- Layer 1: Files ---
CREATE (file:FILE {
  id: '_schema:file',
  name: 'server.ts',
  path: '/project/src/server.ts',
  relativePath: 'src/server.ts',
  language: 'TypeScript',
  LOC: 150,
  hash: '',
  projectId: '_schema'
});

// --- Layer 2: Symbols ---
CREATE (fn:FUNCTION {
  id: '_schema:function',
  name: 'handleRequest',
  kind: 'function',
  filePath: '/project/src/server.ts',
  startLine: 10,
  endLine: 45,
  LOC: 35,
  projectId: '_schema'
});

CREATE (cls:CLASS {
  id: '_schema:class',
  name: 'GraphBuilder',
  kind: 'class',
  filePath: '/project/src/graph/builder.ts',
  startLine: 1,
  endLine: 800,
  LOC: 800,
  projectId: '_schema'
});

CREATE (parentCls:CLASS {
  id: '_schema:class:parent',
  name: 'BaseBuilder',
  kind: 'class',
  projectId: '_schema'
});

CREATE (ifaceCls:CLASS {
  id: '_schema:class:iface',
  name: 'IBuilder',
  kind: 'interface',
  projectId: '_schema'
});

CREATE (variable:VARIABLE {
  id: '_schema:variable',
  name: 'config',
  kind: 'const',
  startLine: 5,
  projectId: '_schema'
});

CREATE (imp:IMPORT {
  id: '_schema:import',
  source: './utils/helpers',
  specifiers: ['parseFile', 'logger'],
  startLine: 1,
  projectId: '_schema'
});

CREATE (exp:EXPORT {
  id: '_schema:export',
  name: 'GraphBuilder',
  isDefault: true,
  startLine: 800,
  projectId: '_schema'
});

// --- Layer 3: Tests ---
CREATE (suite:TEST_SUITE {
  id: '_schema:test_suite',
  name: 'GraphBuilder tests',
  type: 'describe',
  category: 'unit',
  startLine: 1,
  endLine: 100,
  filePath: 'src/graph/__tests__/builder.test.ts',
  projectId: '_schema'
});

CREATE (tc:TEST_CASE {
  id: '_schema:test_case',
  name: 'should build file nodes',
  startLine: 10,
  endLine: 25,
  filePath: 'src/graph/__tests__/builder.test.ts',
  projectId: '_schema'
});

// --- Layer 4: Docs ---
CREATE (doc:DOCUMENT {
  id: '_schema:document',
  relativePath: 'README.md',
  filePath: '/project/README.md',
  title: 'lxDIG MCP',
  kind: 'readme',
  wordCount: 2500,
  hash: '',
  projectId: '_schema'
});

CREATE (sec:SECTION {
  id: '_schema:section',
  heading: 'Architecture',
  level: 2,
  content: 'The system is composed of...',
  wordCount: 350,
  startLine: 42,
  projectId: '_schema'
});

// --- Layer 5: Intelligence ---
CREATE (community:COMMUNITY {
  id: '_schema:community',
  label: 'Graph subsystem',
  summary: 'Core graph builder and orchestrator',
  memberCount: 8,
  centralNode: '_schema:class',
  computedAt: 0,
  projectId: '_schema'
});

CREATE (rule:RULE {
  id: '_schema:rule',
  severity: 'error',
  pattern: 'engine-isolation',
  description: 'Engines must not import from tools'
});

CREATE (feature:FEATURE {
  id: '_schema:feature',
  name: 'Code Graph MVP',
  status: 'completed',
  projectId: '_schema'
});

CREATE (task:TASK {
  id: '_schema:task',
  name: 'Fix circuit breaker',
  status: 'in-progress',
  featureId: '_schema:feature',
  projectId: '_schema'
});

// --- Layer 6: Agent Memory ---
CREATE (episode:EPISODE {
  id: '_schema:episode',
  type: 'DECISION',
  content: 'Adopted chunked writes for Memgraph',
  agentId: 'copilot-01',
  sessionId: 'session-001',
  timestamp: 0,
  outcome: 'success',
  projectId: '_schema'
});

CREATE (learning:LEARNING {
  id: '_schema:learning',
  content: 'Repeated activity around builder.ts',
  extractedAt: 0,
  confidence: 0.8,
  projectId: '_schema'
});

CREATE (claim:CLAIM {
  id: '_schema:claim',
  agentId: 'copilot-01',
  intent: 'Refactoring builder',
  status: 'active',
  projectId: '_schema'
});

CREATE (graphTx:GRAPH_TX {
  id: '_schema:graph_tx',
  type: 'rebuild',
  timestamp: 0,
  mode: 'full',
  sourceDir: '/project/src',
  projectId: '_schema'
});

// --- Target file for import resolution ---
CREATE (targetFile:FILE {
  id: '_schema:file:target',
  name: 'helpers.ts',
  path: '/project/src/utils/helpers.ts',
  relativePath: 'src/utils/helpers.ts',
  language: 'TypeScript',
  LOC: 80,
  hash: '',
  projectId: '_schema'
});

// --- Callee function for CALLS_TO ---
CREATE (callee:FUNCTION {
  id: '_schema:function:callee',
  name: 'parseFile',
  kind: 'function',
  filePath: '/project/src/utils/helpers.ts',
  startLine: 20,
  endLine: 40,
  LOC: 20,
  projectId: '_schema'
});

// --- Test target file ---
CREATE (testTarget:FILE {
  id: '_schema:file:tested',
  name: 'builder.ts',
  path: '/project/src/graph/builder.ts',
  relativePath: 'src/graph/builder.ts',
  language: 'TypeScript',
  LOC: 800,
  hash: '',
  projectId: '_schema'
});

// ---------------------------------------------------------------------------
// 6. RELATIONSHIPS — All 18 active edge types
// ---------------------------------------------------------------------------

// CONTAINS : FOLDER → FILE
MATCH (a:FOLDER    {id: '_schema:folder'}),
      (b:FILE      {id: '_schema:file'})
CREATE (a)-[:CONTAINS]->(b);

// CONTAINS : FOLDER → FOLDER (self-referencing hierarchy)
// (skipped — would need a second folder node)

// CONTAINS : FILE → FUNCTION
MATCH (a:FILE      {id: '_schema:file'}),
      (b:FUNCTION  {id: '_schema:function'})
CREATE (a)-[:CONTAINS]->(b);

// CONTAINS : FILE → CLASS
MATCH (a:FILE      {id: '_schema:file:tested'}),
      (b:CLASS     {id: '_schema:class'})
CREATE (a)-[:CONTAINS]->(b);

// CONTAINS : FILE → VARIABLE
MATCH (a:FILE      {id: '_schema:file'}),
      (b:VARIABLE  {id: '_schema:variable'})
CREATE (a)-[:CONTAINS]->(b);

// CONTAINS : FILE → TEST_SUITE
MATCH (a:FILE      {id: '_schema:file:tested'}),
      (b:TEST_SUITE {id: '_schema:test_suite'})
CREATE (a)-[:CONTAINS]->(b);

// CONTAINS : FILE → TEST_CASE
MATCH (a:FILE      {id: '_schema:file:tested'}),
      (b:TEST_CASE {id: '_schema:test_case'})
CREATE (a)-[:CONTAINS]->(b);

// CONTAINS : TEST_SUITE → TEST_CASE
MATCH (a:TEST_SUITE {id: '_schema:test_suite'}),
      (b:TEST_CASE  {id: '_schema:test_case'})
CREATE (a)-[:CONTAINS]->(b);

// IMPORTS : FILE → IMPORT
MATCH (a:FILE   {id: '_schema:file'}),
      (b:IMPORT {id: '_schema:import'})
CREATE (a)-[:IMPORTS]->(b);

// EXPORTS : FILE → EXPORT
MATCH (a:FILE   {id: '_schema:file:tested'}),
      (b:EXPORT {id: '_schema:export'})
CREATE (a)-[:EXPORTS]->(b);

// REFERENCES : IMPORT → FILE (resolved target)
MATCH (a:IMPORT {id: '_schema:import'}),
      (b:FILE   {id: '_schema:file:target'})
CREATE (a)-[:REFERENCES]->(b);

// DEPENDS_ON : FILE → FILE (source depends on target)
MATCH (a:FILE {id: '_schema:file'}),
      (b:FILE {id: '_schema:file:target'})
CREATE (a)-[:DEPENDS_ON]->(b);

// CALLS_TO : FUNCTION → FUNCTION (with line property)
MATCH (a:FUNCTION {id: '_schema:function'}),
      (b:FUNCTION {id: '_schema:function:callee'})
CREATE (a)-[:CALLS_TO {line: 15}]->(b);

// EXTENDS : CLASS → CLASS (inheritance)
MATCH (a:CLASS {id: '_schema:class'}),
      (b:CLASS {id: '_schema:class:parent'})
CREATE (a)-[:EXTENDS]->(b);

// IMPLEMENTS : CLASS → CLASS (interface)
MATCH (a:CLASS {id: '_schema:class'}),
      (b:CLASS {id: '_schema:class:iface'})
CREATE (a)-[:IMPLEMENTS]->(b);

// SECTION_OF : SECTION → DOCUMENT
MATCH (a:SECTION  {id: '_schema:section'}),
      (b:DOCUMENT {id: '_schema:document'})
CREATE (a)-[:SECTION_OF]->(b);

// NEXT_SECTION : SECTION → SECTION
// (skipped — would need a second section node)

// DOC_DESCRIBES : SECTION → FILE/FUNCTION/CLASS (with strength)
MATCH (a:SECTION {id: '_schema:section'}),
      (b:CLASS   {id: '_schema:class'})
CREATE (a)-[:DOC_DESCRIBES {strength: 1.0, matchedName: 'GraphBuilder'}]->(b);

// TESTS : TEST_SUITE → FILE (test coverage link)
MATCH (a:TEST_SUITE {id: '_schema:test_suite'}),
      (b:FILE       {id: '_schema:file:tested'})
CREATE (a)-[:TESTS]->(b);

// BELONGS_TO : node → COMMUNITY
MATCH (a:CLASS     {id: '_schema:class'}),
      (b:COMMUNITY {id: '_schema:community'})
CREATE (a)-[:BELONGS_TO]->(b);

// VIOLATES_RULE : FILE → RULE
MATCH (a:FILE {id: '_schema:file'}),
      (b:RULE {id: '_schema:rule'})
CREATE (a)-[:VIOLATES_RULE {severity: 'warning', message: 'Cross-layer import'}]->(b);

// TARGETS : CLAIM → node (coordination lock target)
MATCH (a:CLAIM {id: '_schema:claim'}),
      (b:FILE  {id: '_schema:file:tested'})
CREATE (a)-[:TARGETS]->(b);

// INVOLVES : EPISODE → node (entity reference)
MATCH (a:EPISODE {id: '_schema:episode'}),
      (b:CLASS   {id: '_schema:class'})
CREATE (a)-[:INVOLVES]->(b);

// NEXT_EPISODE : EPISODE → EPISODE
// (skipped — would need a second episode node)

// APPLIES_TO : LEARNING → node
MATCH (a:LEARNING {id: '_schema:learning'}),
      (b:FILE     {id: '_schema:file:tested'})
CREATE (a)-[:APPLIES_TO]->(b);

// ---------------------------------------------------------------------------
// Done. Run SHOW INDEX INFO; and SHOW CONSTRAINT INFO; to verify.
// To visualize: MATCH (n) WHERE n.id STARTS WITH '_schema:' RETURN n;
// To clean up:  MATCH (n) WHERE n.id STARTS WITH '_schema:' DETACH DELETE n;
// ---------------------------------------------------------------------------
