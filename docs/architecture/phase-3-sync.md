# Phase 3 architecture: optional accounts and sync

Status: planned architecture, 9 October 2026. Accounts, transport and backend
components below are not implemented. The existing guest app supplies the
SQLite command/query foundation. See the [delivery plan](../proposals/2026-10-09-phase-3-plan.md)
for milestones and [verification tracker](../verification/phase-3.md) for evidence.

## Component overview

The expanded client represents either Android or Windows. Each device has its
own SQLite files, outbox, credentials and worker. Both devices synchronize
through the account backend; they do not write directly to one another.

```mermaid
flowchart TB
  subgraph CLIENT["Android or Windows device"]
    UI["Flutter UI<br/>Tasks, account status, conflict recovery"]
    CMD["Domain commands / repository<br/>Validation and field patches"]
    DB[("Active profile SQLite<br/>Visible tasks, history, outbox<br/>Shadow, conflicts, checkpoint")]
    WORKER["Sync coordinator<br/>One worker per active profile<br/>Retry, catch-up, snapshot recovery"]
    PORT["SyncTransport port<br/>Supabase adapter"]
    SESSION["Profile and session manager<br/>Account identity + generation"]
    AUTHCLIENT["Auth adapter<br/>System browser + PKCE"]
    SECURE[("Platform secure storage<br/>Account-scoped credentials")]
    GUEST[("Separate guest SQLite")]
    ADOPT["Explicit adoption<br/>Preview + resumable mapping"]

    UI -->|"local mutations"| CMD
    CMD -->|"atomic commit"| DB
    DB -->|"SQLite query streams"| UI
    DB -->|"durable pending operations"| WORKER
    WORKER -->|"atomic remote apply + cursor"| DB
    WORKER <-->|"versioned requests / results"| PORT
    SESSION -->|"activate profile / stop stale work"| WORKER
    SESSION -->|"verify identity and open file"| DB
    SESSION <--> AUTHCLIENT
    AUTHCLIENT <--> SECURE
    AUTHCLIENT -->|"active account authorization"| PORT
    GUEST -->|"read only after consent"| ADOPT
    ADOPT -->|"new account commands"| CMD
  end

  subgraph CLOUD["Optional Supabase backend"]
    AUTH["Supabase Auth<br/>GitHub OAuth"]
    RPC["Authenticated protocol RPCs<br/>Apply, pull, snapshots, resolve<br/>Owner checks + restricted grants"]
    PG[("PostgreSQL with RLS<br/>Canonical entities + field revisions<br/>Change log, receipts, tombstones<br/>Conflicts, snapshots, device watermarks")]
    HINT["Realtime<br/>Account revision hints only"]
    DELETE["Account deletion service<br/>Recent auth + resumable cleanup"]

    AUTH -->|"authenticated identity"| RPC
    RPC -->|"account lock + atomic commit"| PG
    PG -.->|"committed revision"| HINT
    DELETE -->|"revoke access and delete owned data"| PG
    DELETE -->|"delete auth account"| AUTH
  end

  AUTHCLIENT <-->|"sign-in / refresh"| AUTH
  PORT <-->|"HTTPS outside SQLite transactions"| RPC
  HINT -.->|"wake up and pull"| WORKER
  AUTHCLIENT -->|"explicit confirmed deletion"| DELETE

  OTHER["Second device<br/>Same client architecture<br/>Independent local SQLite + outbox"]
  OTHER <-->|"authenticated sync protocol"| RPC
  HINT -.->|"wake up and pull"| OTHER
```

Solid arrows carry commands, data or lifecycle control. Dotted arrows are
notification hints; they never replace the durable change log. The diagram
expands an account-active session. Guest mode uses the same local command/query
path against the guest file, with transport disabled. Other accounts have
separate inactive files, omitted here for readability.

## One edit travelling between devices

The UI reports Saved after the first local commit. Server acknowledgement and
download progress are separate; pending operations prevent a Synced claim.

```mermaid
sequenceDiagram
  autonumber
  participant UA as Device A UI
  participant LA as Device A SQLite
  participant WA as Device A worker
  participant S as Backend RPC / PostgreSQL
  participant WB as Device B worker
  participant LB as Device B SQLite
  participant UB as Device B UI

  UA->>LA: Validated command through repository
  Note over LA: One transaction: entity + history<br/>outbox sequence + reminder-dirty intent
  LA-->>UA: Committed query update: Saved
  LA-->>WA: Pending operation available
  WA->>S: Apply immutable operation with original bases
  Note over S: Lock account row; validate identity and sequence<br/>Commit fields, conflicts, revision, log and receipt together
  S-->>WA: Durable result / acknowledgement
  WA->>LA: Commit result and pending-state update
  S-->>WB: Optional realtime revision hint
  Note over WB: Also catch up on launch, resume and reconnect<br/>Foreground polling covers missed hints
  WB->>S: Pull complete revision groups after cursor
  S-->>WB: Committed changes and cursor
  WB->>LB: Apply shadow, replay pending edits, advance cursor
  Note over LB: One local transaction; original edit bases retained
  LB-->>UB: SQLite query stream updates visible tasks
```

A lost server response leaves the same operation retryable. Receipts and durable
device sequence watermarks prevent applying it twice. A same-field conflict
retains base/local/server alternatives for recovery; unrelated fields can merge.
Deletion dominates visibility without silently discarding concurrent edits.
Conflict resolution follows the same local command/outbox path and checks the
current field versions again.

## Boundaries that the diagrams preserve

- **Local durability:** network calls never occur inside SQLite transactions.
  Backend/auth failure cannot prevent an already-open profile from local editing.
- **Account isolation:** file metadata, credentials, workers and callbacks are
  scoped to the account. Profile generations reject responses from an old session.
  Signing out retains pending work by default; reopening requires authentication.
- **Guest consent:** adoption copies through stable mappings and new authorized
  commands. Guest history is not uploaded as an account queue. Destination writes
  are atomic, while the manifest handles recovery across the two files.
- **Download recovery:** snapshots use durable staging and checkpoints. Installing
  accepted state preserves pending local edits and their original causal bases.
  Expired cursors or server-epoch changes trigger recovery rather than overwrite.
- **Server authorization:** RPCs derive ownership from authentication; RLS and
  restricted grants prevent cross-account reads and protocol-bypassing writes.
  Privileged deletion credentials stay server-side.
- **Phase boundary:** reminder-dirty intent stays durable, but OS scheduling,
  recurrence and calendar UI remain Phase 4. Dependency sequencing and precise
  wire/schema changes still need the plan's 3.0 contract fixtures.

The [accepted design](../proposals/2026-10-03-offline-first-architecture.md)
sections 5, 8 and 9 define the full policies. These diagrams describe intended
behavior; they do not establish runtime support or close any acceptance gate.
