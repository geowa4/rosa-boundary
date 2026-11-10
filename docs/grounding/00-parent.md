# Grounding for ontological verification and risk analysis of rosa-boundary (runtime actions)

## Purpose

This document and its per-domain companions are a committed mirror of GitHub issue [#1](https://github.com/geowa4/rosa-boundary/issues/1) and its sub-issues #2–#17, which are the canonical, commentable copy. Together they are the **grounding** for a later ontology of rosa-boundary and for risk analysis of the actions the system takes at runtime. The grounding records, with source citations:

- which actors exist and under which identity and credential each one acts;
- which entities and identifiers exist, where each is minted and where it is consumed;
- how data flows through AWS, Keycloak, OCM and Backplane resources, step by step;
- which resources are created, mutated and destroyed, by whom and when;
- which assertions should hold at each junction, and whether anything enforces them;
- which artifacts are expected to exist afterwards, where, and for how long.

It is **not** the ontology. It proposes no classes or relations; it records facts, enforcement, drift and gaps. The ontology will be built on top of it later.

## Ground rules (apply to every sub-issue)

- **Pinned commit:** [`509078b`](https://github.com/geowa4/rosa-boundary/tree/509078b49c2c7ac478d0dbb49acb0c2fac5b0b7f) (`main` on 2026-11-08). Every citation is a permalink to that commit with line numbers verified at that commit. Re-verify before reusing against a later commit.
- **Source and tests are authoritative.** Markdown docs and the generated OpenWiki are hints. Where they disagree with source the disagreement is recorded as **DRIFT**.
- **Runtime scope only.** Everything that happens once infrastructure exists: CLI commands, Lambda executions, container lifecycle, scheduled reapers, Trusted Actions requests, Keycloak token issuance. Terraform applies, HCP Terraform runs, Konflux/Tekton builds and ECR replication are static preconditions and are not traced.
- **Code as written.** Conditionals are described with their controlling variable and default. Staging and production values appear only as "the workspace definition sets"; no live state is asserted.
- **Enforcement classes** on every assertion:
  - `[IAM-enforced]` an IAM policy, trust policy, condition key or bucket policy makes the violation impossible at the AWS API;
  - `[code-enforced]` application code checks it and fails closed;
  - `[convention-only]` naming, tags or ordering the code relies on but nothing checks;
  - `[documented-not-enforced]` the docs say it; nothing in code or IAM makes it true.
- **`UNVERIFIED`** marks a claim that source alone cannot settle, with what would settle it.
- **`[maintainer-stated]`** marks a claim that rests on the maintainers' statements of 2026-11-09 and not on source. It outranks docs and ranks below source. Where it disagrees with source the item is marked **Conflict** and stays open.
- Each sub-issue follows the same ten sections: scope; actors and principals; entities and identifiers; data-flow traces; resource lifecycle; junction assertions; artifacts; failure modes and partial states; configuration conditionals; open questions. Domains were split into several files sized to fit GitHub issue bodies (65,536 characters), so each file can become one issue.

## Domain map (sub-issues)

| # | Domain | Part | Contents |
|---|---|---|---|
| [Keycloak identity provider (runtime): claims, flows, token lifetimes, IdP state](01-kc.md) | Identity | 1/3 | Keycloak IdP at token-issuance time: realm/client/mappers as documented vs deployed, claims, lifetimes, PKCE and device flow, CNPG/ESO state |
| [CLI and AWS identity chain (1/2): actors, identifiers, data-flow traces, lifecycle](02-id1.md) | Identity | 2/3 | CLI and AWS identity chain: login flows, token cache, `configure`/`get_config`, two-step STS, SigV4 Lambda invoke, Lambda validation, SRE-role commands, mid-workflow expiry |
| [CLI and AWS identity chain (2/2): IAM/code assertions, artifacts, failure modes, config, open questions](03-id2.md) | Identity | 3/3 | Every runtime IAM statement with exact condition keys, code/convention assertions, artifacts, failure modes, config, open questions |
| [Investigation and task provisioning (1/2): actors, identifiers, start-task/handover/create/list/join traces](04-pr1.md) | Provisioning | 1/2 | `start-task`, handover, `create-investigation`, `list-tasks`, `list-investigations`, `join-task` wait, `get_config` traces |
| [Investigation and task provisioning (2/2): lifecycle, assertions, artifacts, failure modes, config, open questions](05-pr2.md) | Provisioning | 2/2 | Lifecycle of access points, task definitions and tasks; assertions; artifacts; 20 failure/partial states; config; open questions |
| [Teardown and reaping (1/2): stop-task, close-investigation, reap-tasks, reap-investigations traces](06-td1.md) | Teardown | 1/2 | `stop-task`, `close-investigation`, `reap-tasks`, `reap-investigations` traces |
| [Teardown and reaping (2/2): lifecycle, assertions, artifacts, failure modes, config, open questions](07-td2.md) | Teardown | 2/2 | What each teardown path destroys and leaves; assertions; artifacts; 24 failure/partial states; config; open questions |
| [Container runtime and interactive session (1/2): boot, join-task/ECS Exec, OCM credentials, Bedrock, kube-proxy traces](08-rt1.md) | Runtime | 1/2 | Container boot, `join-task`/ECS Exec, OCM credential transfer, Bedrock path, kube-proxy sidecar |
| [Container runtime and interactive session (2/2): lifecycle, assertions, artifacts, failure modes, config, open questions](09-rt2.md) | Runtime | 2/2 | Runtime lifecycle, assertions, artifacts, failure modes, config, open questions |
| [Audit evidence: CloudWatch, ECS Exec transcripts, S3 sync and WORM, Bedrock logging, CloudTrail, drift summary](10-au.md) | Runtime | 3/3 | Audit evidence: CloudWatch groups and streams, ECS Exec transcripts, S3 sync and Object Lock, Bedrock logging, CloudTrail, plus the runtime drift summary |
| [Trusted Actions (1/3): scope, actors, identifiers, configuration conditionals](11-ta1.md) | Trusted Actions | 1/3 | Scope, actors, identifiers, configuration conditionals |
| [Trusted Actions (2/3): data-flow traces (startup, run request, worker/executor/Backplane/AWS, reads, cleanup, clients)](12-ta2.md) | Trusted Actions | 2/3 | Traces: startup guards, `POST .../run`, worker/executor/Backplane/AWS scopes, read endpoints, cleanup (none), `action-cli`, `rta` |
| [Trusted Actions (3/3): resource lifecycle, assertions, artifacts, failure modes, open questions](13-ta3.md) | Trusted Actions | 3/3 | Resource lifecycle, assertions, artifacts, failure modes, open questions |
| [Resource inventory (1/3): Boundary Terraform roots (account, network, regional) with runtime actor mapping](14-in1.md) | Inventory | 1/3 | Every declared resource in `deploy/account`, `deploy/network`, `deploy/regional` with runtime read/write actor mapping, data sources, handoffs, outputs |
| [Resource inventory (2/3): Trusted Actions Terraform roots, TA variables, TA workspace definitions](15-in2.md) | Inventory | 2/3 | Trusted Actions Terraform roots, TA variables, TA HCP workspace definitions |
| [Resource inventory (3/3): Boundary variables, HCP workspace definitions, Keycloak objects, runtime-created resources](16-in3.md) | Inventory | 3/3 | Boundary variables and their runtime effect, HCP workspace definitions (staging/prod, non-secret values as written), Keycloak K8s objects, runtime-created resource kinds |

## The spine: one investigation end to end

Each step names the sub-issue that traces it in detail.

1. **Token issuance** — SRE runs `rosa-boundary login`; browser PKCE (or device code) against the configured issuer; the CLI keeps only the ID token, cached on disk scoped by issuer and client id. The production issuer is Red Hat EmployeeIDP, external to the repo; the committed Keycloak manifests contain no realm, client or mapper. → [Keycloak identity provider (runtime): claims, flows, token lifetimes, IdP state](01-kc.md), [CLI and AWS identity chain (1/2): actors, identifiers, data-flow traces, lifecycle](02-id1.md)
2. **First role assumption** — `AssumeRoleWithWebIdentity` into `lambda-invoker`; trust requires `aud = oidc_client_id` and session-tag conditions; the role can only invoke the create-investigation Lambda. → [CLI and AWS identity chain (1/2): actors, identifiers, data-flow traces, lifecycle](02-id1.md), [CLI and AWS identity chain (2/2): IAM/code assertions, artifacts, failure modes, config, open questions](03-id2.md)
3. **Lambda invocation** — SigV4 `lambda:InvokeFunction` with the ID token in an `x-oidc-token` header. The Lambda routes JWKS by the *unverified* `iss`, verifies RS256/`aud`/`exp`, requires a `required_groups` match, extracts the ABAC value from `https://aws.amazon.com/tags.principal_tags.<abac_tag_key>` (default key `uuid`). A `get_config` action is served *before* any OIDC validation. → [CLI and AWS identity chain (1/2): actors, identifiers, data-flow traces, lifecycle](02-id1.md), [Investigation and task provisioning (1/2): actors, identifiers, start-task/handover/create/list/join traces](04-pr1.md)
4. **Handover check** — if a task is already RUNNING for `(cluster_id, investigation_id)` (found by deterministic `startedBy` hash), the Lambda stops it unless an active SSM session exists (then 409). → [Investigation and task provisioning (1/2): actors, identifiers, start-task/handover/create/list/join traces](04-pr1.md)
5. **Workspace** — create-or-reuse the EFS access point at `/{cluster_id}/{investigation_id}` (uid/gid 1000; tags `Name`, `ClusterID`, `InvestigationID`, `oidc_sub`, `username`, `ManagedBy`, `CreatedAt`; owner tags frozen to the creator). → [Investigation and task provisioning (1/2): actors, identifiers, start-task/handover/create/list/join traces](04-pr1.md), [Investigation and task provisioning (2/2): lifecycle, assertions, artifacts, failure modes, config, open questions](05-pr2.md)
6. **Task definition** — clone the base family into `{base}-{cluster_id}-{investigation_id}-{timestamp}`, swap the EFS volume to the investigation access point, force empty task-scoped volumes for `.config/ocm` and `.kube`, bake `CLUSTER_ID`/`INVESTIGATION_ID`/`OC_VERSION`/`S3_AUDIT_BUCKET`/`TASK_TIMEOUT`, inject the kube-proxy kubeconfig secret reference. → [Investigation and task provisioning (1/2): actors, identifiers, start-task/handover/create/list/join traces](04-pr1.md)
7. **Launch** — `RunTask` (Fargate, `enableExecuteCommand`, `startedBy` hash, tags `oidc_sub`, `<abac_tag_key>`, `investigation_id`, `cluster_id`, `oc_version`, `access_point_id`, `task_timeout`, `created_at`, `deadline` when timeout > 0), then explicit `TagResource`; rollback paths deregister/stop/delete on failure; an EMF metric records the outcome. → [Investigation and task provisioning (1/2): actors, identifiers, start-task/handover/create/list/join traces](04-pr1.md), [Investigation and task provisioning (2/2): lifecycle, assertions, artifacts, failure modes, config, open questions](05-pr2.md)
8. **Container boot** — root entrypoint verifies the credential paths are non-NFS task-scoped mounts, seeds skel files, writes a kubeconfig stub if `KUBE_PROXY_PORT` is set, traps SIGTERM/SIGINT/SIGHUP, drops to `sre` for the workload. → [Container runtime and interactive session (1/2): boot, join-task/ECS Exec, OCM credentials, Bedrock, kube-proxy traces](08-rt1.md)
9. **Second role assumption and session** — `AssumeRoleWithWebIdentity` into `sre-shared`; `ecs:ExecuteCommand` is allowed on the cluster plus on tasks whose `ecs:ResourceTag/<abac_tag_key>` equals `aws:PrincipalTag/<abac_tag_key>`; the CLI execs into `session-manager-plugin`. Session I/O goes to the KMS-encrypted `ssm-sessions` log group. → [CLI and AWS identity chain (2/2): IAM/code assertions, artifacts, failure modes, config, open questions](03-id2.md), [Container runtime and interactive session (1/2): boot, join-task/ECS Exec, OCM credentials, Bedrock, kube-proxy traces](08-rt1.md), [Audit evidence: CloudWatch, ECS Exec transcripts, S3 sync and WORM, Bedrock logging, CloudTrail, drift summary](10-au.md)
10. **Work inside** — `oc`/`ocm`/`claude` as `sre` with passwordless sudo; the only AWS identity is the shared task role (S3 `PutObject` on the whole audit bucket, Bedrock invoke, `PutLogEvents` to the session log group). OCM access tokens arrive over ECS Exec stdin into the task-scoped volume; refresh tokens never cross. → [Container runtime and interactive session (1/2): boot, join-task/ECS Exec, OCM credentials, Bedrock, kube-proxy traces](08-rt1.md), [Container runtime and interactive session (2/2): lifecycle, assertions, artifacts, failure modes, config, open questions](09-rt2.md)
11. **Stop** — `stop-task` (ABAC-scoped `ecs:StopTask`), handover, or `reap-tasks` (every `reaper_schedule_minutes`; stops tasks whose `deadline` tag has passed **unless** an active ECS Exec session exists; tasks without a deadline are never reaped). SIGTERM → `sync_to_s3` to `s3://{bucket}/{cluster_id}/{investigation_id}/{YYYYMMDD}/{task_id}/` under a 300 s timeout, while ECS `stopTimeout` is 120 s. → [Teardown and reaping (1/2): stop-task, close-investigation, reap-tasks, reap-investigations traces](06-td1.md), [Audit evidence: CloudWatch, ECS Exec transcripts, S3 sync and WORM, Bedrock logging, CloudTrail, drift summary](10-au.md)
12. **Close** — `close-investigation` stops tasks, deregisters task definitions by family prefix and deletes the access point (any `ManagedBy=rosa-boundary-lambda` access point; no owner check), leaving EFS data and S3 objects. `reap-investigations` (every `reaper_schedule_hours`) backs up and deletes stale, idle, tagged investigations after the grace period; a missing `CreatedAt` counts as stale. → [Teardown and reaping (1/2): stop-task, close-investigation, reap-tasks, reap-investigations traces](06-td1.md), [Teardown and reaping (2/2): lifecycle, assertions, artifacts, failure modes, config, open questions](07-td2.md)
13. **Trusted Actions (separate component)** — an OCM-JWT caller posts an action; AMS AccessReview and a role allowlist gate it; a worker executes through a per-action Backplane trusted-action session or STS credentials from backplane-cli; outputs land in SQLite on an EBS volume attached to an EC2 ECS host; audit records go to CloudWatch → Firehose → S3. Shares the staging VPC/subnets with Boundary; shares no Boundary IAM roles, buckets or Lambdas. → [Trusted Actions (1/3): scope, actors, identifiers, configuration conditionals](11-ta1.md), [Trusted Actions (2/3): data-flow traces (startup, run request, worker/executor/Backplane/AWS, reads, cleanup, clients)](12-ta2.md), [Trusted Actions (3/3): resource lifecycle, assertions, artifacts, failure modes, open questions](13-ta3.md)

## Actors and the credential each acts with

| Actor | Identity / credential | Lifetime | Detail |
|---|---|---|---|
| SRE at a workstation | Keycloak/EmployeeIDP ID token (cached, `exp`-bounded, no refresh) | token lifespan | [CLI and AWS identity chain (1/2): actors, identifiers, data-flow traces, lifecycle](02-id1.md) |
| CLI as `lambda-invoker` | STS web-identity session, session tags from the JWT | ≤ role max (3600 s) | [CLI and AWS identity chain (2/2): IAM/code assertions, artifacts, failure modes, config, open questions](03-id2.md) |
| CLI as `sre-shared` | STS web-identity session, `PrincipalTag/<abac_tag_key>` drives ABAC | ≤ `oidc_session_duration` | [CLI and AWS identity chain (2/2): IAM/code assertions, artifacts, failure modes, config, open questions](03-id2.md) |
| create-investigation Lambda | its execution role: ECS run/stop/tag/register, EFS access points, `ssm:DescribeSessions`, `iam:PassRole` | per invocation | [Investigation and task provisioning (1/2): actors, identifiers, start-task/handover/create/list/join traces](04-pr1.md) |
| reap-tasks Lambda | its role: `ListTasks` (cluster-conditioned), `DescribeTasks`, `StopTask` only on tasks with a `deadline` tag, `ssm:DescribeSessions` | scheduled | [Teardown and reaping (1/2): stop-task, close-investigation, reap-tasks, reap-investigations traces](06-td1.md) |
| reap-investigations Lambda | its role plus a dedicated root-posix EFS access point for directory deletion; S3 put for final backup | scheduled | [Teardown and reaping (1/2): stop-task, close-investigation, reap-tasks, reap-investigations traces](06-td1.md) |
| ECS task (container) | task role: S3 `PutObject`/`ListBucket` on the audit bucket, Bedrock invoke, ssmmessages, logs, KMS | task lifetime | [Container runtime and interactive session (1/2): boot, join-task/ECS Exec, OCM credentials, Bedrock, kube-proxy traces](08-rt1.md) |
| ECS agent | execution role: ECR pull, Secrets Manager `rosa-boundary/*`, awslogs | task lifetime | [Resource inventory (1/3): Boundary Terraform roots (account, network, regional) with runtime actor mapping](14-in1.md) |
| SSM Session Manager | AWS-managed relay; transcripts to the `ssm-sessions` log group | session | [Audit evidence: CloudWatch, ECS Exec transcripts, S3 sync and WORM, Bedrock logging, CloudTrail, drift summary](10-au.md) |
| Bedrock | invocation logging role to CloudWatch and the large-payload bucket | per call | [Audit evidence: CloudWatch, ECS Exec transcripts, S3 sync and WORM, Bedrock logging, CloudTrail, drift summary](10-au.md) |
| Trusted Actions service | ECS task role; OCM client-credentials connection(s); Backplane sessions; STS creds via backplane-cli | process / per action | [Trusted Actions (1/3): scope, actors, identifiers, configuration conditionals](11-ta1.md) |
| TA callers (SRE via Boundary container, CAD, ROSA AI agent) | OCM JWT; roles via AMS AccessReview | per request | [Trusted Actions (1/3): scope, actors, identifiers, configuration conditionals](11-ta1.md) |
| Keycloak (dev) | RHBK operator workload; CNPG Postgres; DB creds via External Secrets from SSM Parameter Store | continuous | [Keycloak identity provider (runtime): claims, flows, token lifetimes, IdP state](01-kc.md) |

## Resource kinds that exist only at runtime

Per-investigation EFS access points and directory trees; per-investigation ECS task definitions; Fargate tasks and their ENIs; SSM/ECS Exec sessions; CloudWatch log streams (container, session, Lambda, Bedrock); the `TaskCreationRequests` EMF metric; S3 objects (task audit sync, reaper final backup, Bedrock large payloads); task-scoped credential volumes and persistent home files; CLI config and token-cache files; STS sessions; TA SQLite rows, EC2 host filesystem, config file copies, Firehose audit objects. Full table with name/path patterns and creators: [Resource inventory (3/3): Boundary variables, HCP workspace definitions, Keycloak objects, runtime-created resources](16-in3.md) section E.

## Maintainer review of 2026-11-09

George Adams and Tim Williams walked the consolidated question list on 2026-11-09. This issue and sub-issues [#2](https://github.com/geowa4/rosa-boundary/issues/2), [#4](https://github.com/geowa4/rosa-boundary/issues/4), [#6](https://github.com/geowa4/rosa-boundary/issues/6), [#8](https://github.com/geowa4/rosa-boundary/issues/8), [#10](https://github.com/geowa4/rosa-boundary/issues/10), [#11](https://github.com/geowa4/rosa-boundary/issues/11) and [#14](https://github.com/geowa4/rosa-boundary/issues/14) were updated on 2026-11-10 with the outcome. Each of those sub-issues now carries a "Maintainer review" section, placed just before its open-questions section, with the full answer per question and the effect on that part's assertions.

- Statements from the conversation are tagged `[maintainer-stated]`. They are testimony. Where one could be checked against source it was, and the citation is in the sub-issue.
- The conversation ran out of time. It covered Identity and Provisioning in order, then selected items from Teardown, Runtime, Audit and Inventory. Trusted Actions was set aside.
- Many findings were confirmed as defects, from docs drift to behavioural bugs. Fixing them is tracked separately by the maintainers and is out of scope here; the grounding only records which side is authoritative.

### Domain statements established by the maintainers

These are the statements the ontology can build on. Detail and citations are in the sub-issue named.

**Identity and trust**

- Staging and production authenticate against the Red Hat EmployeeIDP Keycloak. Its realm, client, mappers and token lifetimes are outside Boundary's control and slow to change. No Boundary-owned Keycloak serves any deployed flow. ([#2](https://github.com/geowa4/rosa-boundary/issues/2))
- `uuid` is the only reliable person identifier. EmployeeIDP's `preferred_username` is not guaranteed unique; `username` values are display data. ([#4](https://github.com/geowa4/rosa-boundary/issues/4))
- `principal_tags` carries `uuid` and `roles`; `transitive_tag_keys` includes both but nothing uses role chaining. The device grant and PKCE enforcement are on. Access tokens live 15 minutes. ([#2](https://github.com/geowa4/rosa-boundary/issues/2))
- The required group is the trust boundary. Investigations are a shared SRE resource: any member may hand over, reuse or close any investigation. Only ECS Exec and task stop are per-person, through ABAC. ([#4](https://github.com/geowa4/rosa-boundary/issues/4))
- Requirement, not yet met: every action must be attributable to the person who performed it. ([#4](https://github.com/geowa4/rosa-boundary/issues/4), [#11](https://github.com/geowa4/rosa-boundary/issues/11))
- The organization SCP and the audit-reader role are external preconditions, not defined in this repository. ([#4](https://github.com/geowa4/rosa-boundary/issues/4), [#11](https://github.com/geowa4/rosa-boundary/issues/11))

**Investigations and sessions**

- An investigation **is** an EFS access point plus the directory behind it, identified by `(cluster_id, investigation_id)`. A task mounts its investigation's directory. ([#6](https://github.com/geowa4/rosa-boundary/issues/6))
- An investigation has many tasks over its life and at most one running at a time. Sequential tasks, possibly run by different SREs, share the same files; that sharing is the purpose. ([#6](https://github.com/geowa4/rosa-boundary/issues/6))
- Parallel work on one cluster requires separate investigations. A cluster may have any number of investigations. An investigation requires a cluster ID, although nothing currently depends on that link. ([#6](https://github.com/geowa4/rosa-boundary/issues/6))
- The access point's owner tags name the creator permanently. ([#6](https://github.com/geowa4/rosa-boundary/issues/6))
- Handover is intended so that a different SRE can take over an investigation whose previous user left a task running. Taking over from yourself is a bug. ([#6](https://github.com/geowa4/rosa-boundary/issues/6))
- Every task has a deadline, and deadlines are meant to be enforced strictly. Source currently contradicts strict enforcement; see the open items. ([#6](https://github.com/geowa4/rosa-boundary/issues/6), [#8](https://github.com/geowa4/rosa-boundary/issues/8))
- "Task" is being renamed "session" in the CLI and has been on `main` since the pin.

**Teardown**

- The investigation reaper backs up to S3 before deleting, as a safety net against a wrong deletion. `investigation close` deliberately makes no backup. ([#8](https://github.com/geowa4/rosa-boundary/issues/8), [#11](https://github.com/geowa4/rosa-boundary/issues/11))
- There is no in-product reconciliation for orphaned resources. The remedy is break-glass operator access, which today is the standard SRE route into the AWS account; a Boundary-specific procedure is still to be defined. ([#8](https://github.com/geowa4/rosa-boundary/issues/8))

**Dormant or obsolete**

- `deploy/keycloak/` and its runbooks are orphaned and to be removed. ([#2](https://github.com/geowa4/rosa-boundary/issues/2))
- `OC_VERSION` / `--oc-version` are obsolete and to be removed; the image ships one current `oc`. ([#6](https://github.com/geowa4/rosa-boundary/issues/6), [#10](https://github.com/geowa4/rosa-boundary/issues/10))
- The kube-proxy sidecar is unused and disabled in every deployment; it is kept for possible restricted environments. SREs do not normally hold a kubeconfig for customer clusters. ([#6](https://github.com/geowa4/rosa-boundary/issues/6), [#10](https://github.com/geowa4/rosa-boundary/issues/10))
- Trusted Actions is out of focus for now. Its audit sink is a placeholder mock logger; a real one is intended. ([#14](https://github.com/geowa4/rosa-boundary/issues/14))

### Decisions recorded

| Topic | Decision | When |
|---|---|---|
| Handover vs 409 | **Decided.** Handover across users is intended; same-user handover is a bug; the docs' unconditional 409 is wrong. The rule when the other user's session is still active was left vague (OQ-PR-2). | 2026-11-09 |
| Ownership | **Intended.** Any member of the required group may manage any investigation. A post-pin CLI owner check on `investigation close` contradicts this (OQ-ID-7). | 2026-11-09 |
| Deadline | **Intent stated: strict.** Source shows the reaper sparing tasks with an active session. Unresolved (OQ-TD-4). | 2026-11-09 |
| In-container privilege | **To be tightened.** Passwordless sudo and the shared task role are a deviation to fix, not accepted risk (OQ-RT-4, OQ-RT-5, OQ-AU-7). Not revisited on 2026-11-09. | 2026-11-08 |
| `oc` version selection | **Remove.** Always ship the latest `oc` (OQ-PR-6, OQ-RT-1). | 2026-11-09 |
| Dev Keycloak | **Remove** `deploy/keycloak/` and its runbooks (OQ-KC-1, OQ-KC-6, OQ-KC-7, OQ-IN-5). | 2026-11-09 |
| kube-proxy sidecar | **Keep, dormant** (OQ-PR-7, OQ-RT-6, OQ-IN-1). | 2026-11-09 |
| `get_config` without an OIDC token | **Provisionally accepted**; a review story is to be raised (OQ-ID-8). | 2026-11-09 |
| Launch and access-point races | **Deferred** as too rare to matter (OQ-PR-5, OQ-PR-9). | 2026-11-09 |
| Trusted Actions questions | **Deferred** wholesale, except the unused grants follow-up (OQ-TA-9, OQ-IN-2). | 2026-11-09 |

---

## ⚠️ Still open: follow-up for George

> Everything below is unresolved after the 2026-11-09 review. Answers can be left as comments here.

### A. What was said disagrees with what the source does

1. **OQ-TD-4, deadline strictness.** Tim recalls testing that a task is killed at its timeout even with an active session. `reap-tasks` at the pinned commit and on `main` skips expired tasks that have an active ECS Exec session, and nothing else enforces the deadline. Needs a recorded test in a personal dev environment, then a decision on whether the session protection stays. Detail in [#8](https://github.com/geowa4/rosa-boundary/issues/8).
2. **OQ-ID-7, who may close an investigation.** The stated intent is any SRE. Since the CLI refresh, `investigation close` refuses unless the caller's `sub` matches the access point's `oidc_sub`; IAM still permits anyone in the role. Which is the contract? Detail in [#4](https://github.com/geowa4/rosa-boundary/issues/4).
3. **OQ-PR-2, handover while the other user is still connected.** The code returns 409 when any active session exists. The conversation said takeover is allowed "if they don't have a session or in certain cases". Gemini's quick notes state the opposite (takeover "when active SSM sessions exist"); the transcript does not support that reading. Please state the rule. Detail in [#6](https://github.com/geowa4/rosa-boundary/issues/6).

### B. Decisions or facts still needed

- **OQ-ID-3 / OQ-PR-10.** What should the STS session duration be for the two role assumptions? Today none is sent and the STS default applies.
- **OQ-ID-4.** Is it acceptable that a session outlives the SRE-role credentials? Where does the recalled one-hour idle timeout come from? Nothing in the repository sets one.
- **OQ-ID-12 / OQ-IN-3.** Ten `deploy/regional` variables are set by workspaces but used by no regional resource. Tim needed the specifics; the list is in [#4](https://github.com/geowa4/rosa-boundary/issues/4). Keep for workspace compatibility, or remove?
- **OQ-KC-4.** Does STS still enforce the pinned OIDC thumbprint for EmployeeIDP's CA? Nobody knew.
- **OQ-KC-2 / OQ-KC-3.** Record a redacted EmployeeIDP ID-token claim shape and its real lifetime. The 15 minutes quoted was for access tokens.
- **OQ-TD-1.** Confirm that a missing `CreatedAt` is meant to count as immediately stale (code) and not as protected by the grace period (docs).
- **OQ-AU-9.** `investigation close` leaves the EFS directory on the file system with no backup and no cleanup path, because reaper discovery is driven by access points (G24 in [#8](https://github.com/geowa4/rosa-boundary/issues/8)). Accept, or fix?
- **OQ-AU-8.** Who may assume the audit-reader role, and who can read ECS Exec transcripts, which the runbook says that role cannot?
- **OQ-ID-10 / OQ-AU-4 / OQ-AU-5.** How will attribution be achieved: CloudTrail session tags, per-person role session names, S3 data events, or Lambda logs?
- **OQ-RT-4 / OQ-RT-5 / OQ-AU-7.** The tightening of in-container privilege has a decision but no design.
- **OQ-PR-1.** Is the Lambda's `DeleteAccessPoint` grant on the file-system ARN effective? Suspected bug; current state unknown.
- **OQ-TD-3.** Is the reaper's 300 s budget enough for real workspaces?
- **OQ-TA-9 / OQ-IN-2.** Are the unused Trusted Actions S3 and metrics grants reserved for the real audit logger?

### C. Not reached in the conversation

- **Teardown ([#8](https://github.com/geowa4/rosa-boundary/issues/8)):** OQ-TD-5 family-prefix coupling to the ECS cluster name; OQ-TD-7 access-point deletion under a live mount and directory re-creation; OQ-TD-11 proof of a completed S3 sync on stop.
- **Runtime ([#10](https://github.com/geowa4/rosa-boundary/issues/10)):** OQ-RT-3 `curl` in the final image; OQ-RT-7 default exec command docs; OQ-RT-8 VPC endpoints listed in docs but not declared; OQ-RT-9 AWS CLI path docs; OQ-RT-10 OCM token not revoked on clear or stop.
- **Audit ([#11](https://github.com/geowa4/rosa-boundary/issues/11)):** OQ-AU-1 `stopTimeout` 120 s vs `SYNC_TIMEOUT` 300 s; OQ-AU-2 no sync completion marker; OQ-AU-3 session log stream naming; OQ-AU-6 whether the OCM payload appears in session transcripts; OQ-AU-10 untested areas.
- **Inventory:** OQ-IN-4 Trusted Actions placeholder security groups; OQ-IN-6 Trusted Actions workspace bindings and co-location in the Boundary staging VPC.
- **Trusted Actions ([#14](https://github.com/geowa4/rosa-boundary/issues/14)):** OQ-TA-1 to OQ-TA-14, deferred.

---

## Status of every question

Full answers are in the sub-issue named in each heading. Status values: **Answered**; **Intended**; **Bug** (defect or gap, fix tracked separately); **Docs** (code authoritative); **Deferred**; **Conflict**; **Open**.

### Identity: Keycloak IdP ([#2](https://github.com/geowa4/rosa-boundary/issues/2))

| ID | Question | Status | Outcome |
|---|---|---|---|
| OQ-KC-1 | Where is the realm definition? | Answered | None by design; EmployeeIDP is external; `deploy/keycloak/` is orphaned and to be removed |
| OQ-KC-2 | EmployeeIDP client configuration | Answered in part | Tags `uuid`, `roles`; both transitive; device grant and PKCE on; mapper name and claim shape still open |
| OQ-KC-3 | ID-token lifespan | Answered in part | 15 min quoted for access tokens; confirm on an ID token |
| OQ-KC-4 | Does STS enforce the thumbprint? | Open | Unknown; thumbprint is not a secret |
| OQ-KC-5 | ESO/CNPG password rotation | Deferred | Dev Keycloak only; out of scope |
| OQ-KC-6 | Orphaned overlay files | Answered | Leftover; removed with the directory |
| OQ-KC-7 | Keycloak doc drift | Docs | Docs to be removed or fixed |

### Identity: CLI and AWS chain ([#4](https://github.com/geowa4/rosa-boundary/issues/4))

| ID | Question | Status | Outcome |
|---|---|---|---|
| OQ-ID-1 | Is `aws:PrincipalTag/uuid` set? | Answered | Yes; transitive keys unused; no CloudTrail evidence captured |
| OQ-ID-2 | ID-token lifespan | Answered in part | 15 min, same caveat as OQ-KC-3 |
| OQ-ID-3 | STS `DurationSeconds` | Bug | Omitted by oversight; intended value undecided |
| OQ-ID-4 | Session survives credential expiry | Answered as current behaviour | Yes; acceptability and the idle timeout's origin open |
| OQ-ID-5 | No test with `ABAC_TAG_KEY=uuid` | Bug | Tests predate EmployeeIDP; CLI usernames come from `preferred_username` |
| OQ-ID-6 | No test tying Lambda env to IAM key | Bug | Add a Terraform test |
| OQ-ID-7 | Ownership gap | Intended, Conflict | Shared resource by design; post-pin CLI owner check contradicts it |
| OQ-ID-8 | `get_config` exposure | Deferred | Provisionally accepted; review story to be raised |
| OQ-ID-9 | SCP not in repo | Deferred | External precondition |
| OQ-ID-10 | CloudTrail attribution | Open | Attribution is a stated requirement; tag capture unverified |
| OQ-ID-11 | Identity doc drift | Docs | Code authoritative |
| OQ-ID-12 | Unused regional variables | Open | Specifics to be sent to Tim |

### Provisioning and discovery ([#6](https://github.com/geowa4/rosa-boundary/issues/6))

| ID | Question | Status | Outcome |
|---|---|---|---|
| OQ-PR-1 | `DeleteAccessPoint` resource type | Bug (suspected), Open | Follow up; settle with policy simulation |
| OQ-PR-2 | Handover vs 409 | Answered | Cross-user handover intended; same-user is a bug; docs wrong; active-session rule open |
| OQ-PR-3 | Default timeout drift | Docs | Code authoritative; every task has a deadline while the minimum is above 0 |
| OQ-PR-4 | Tag-set drift | Docs | Code authoritative |
| OQ-PR-5 | Launch race | Deferred | Real, too rare to pursue |
| OQ-PR-6 | `oc_version` unvalidated | Answered | Obsolete; to be removed |
| OQ-PR-7 | Hard-coded secret prefix | Deferred | Part of the dormant kube-proxy feature |
| OQ-PR-8 | Creator tags frozen | Intended | Owner means creator |
| OQ-PR-9 | Concurrent access-point creation | Deferred | Not pursued now |
| OQ-PR-10 | STS session duration | Bug | Same as OQ-ID-3 |

### Teardown and reaping ([#8](https://github.com/geowa4/rosa-boundary/issues/8))

| ID | Question | Status | Outcome |
|---|---|---|---|
| OQ-TD-1 | Missing `CreatedAt` handling | Open | Assumed code is right; unconfirmed |
| OQ-TD-2 | Regex mismatch | Bug | Creator regex authoritative; fix the reaper |
| OQ-TD-3 | Reaper backup robustness | Bug, Open | Missing multipart abort confirmed; time budget untested |
| OQ-TD-4 | Soft deadline | Conflict, Open | Intent strict; source spares active sessions |
| OQ-TD-5 | Family prefix coupling | Open | Not covered |
| OQ-TD-6 | Orphan task definitions | Answered | No reconciliation; break-glass, procedure to be defined |
| OQ-TD-7 | Access-point deletion under mount | Open | Not covered |
| OQ-TD-8 | Reaper errors do not raise | Bug | Follow up for both reapers |
| OQ-TD-9 | `ForAnyValue` and skipped test | Deferred | Harmless; LocalStack limitation; real-IAM check outstanding |
| OQ-TD-10 | Account-wide task-definition listing | Bug | Confirmed |
| OQ-TD-11 | Partial S3 sync on stop | Open | Not covered |

### Container runtime and session ([#10](https://github.com/geowa4/rosa-boundary/issues/10))

| ID | Question | Status | Outcome |
|---|---|---|---|
| OQ-RT-1 | `OC_VERSION` is dead | Answered | To be removed |
| OQ-RT-2 | Exec shell environment | Answered in part | Claude Code works; region mechanism unverified |
| OQ-RT-3 | `curl` in the image | Open | Not covered |
| OQ-RT-4 | sudo breadth | Open | To be tightened; no design yet |
| OQ-RT-5 | Shared task role | Open | To be tightened; no design yet |
| OQ-RT-6 | Kubeconfig secret provisioning | Deferred | Dormant feature |
| OQ-RT-7 | Default exec command docs | Open | Not covered |
| OQ-RT-8 | VPC endpoints docs | Open | Not covered |
| OQ-RT-9 | AWS CLI path docs | Open | Not covered |
| OQ-RT-10 | OCM token not revoked | Open | Not covered |

### Audit evidence ([#11](https://github.com/geowa4/rosa-boundary/issues/11))

| ID | Question | Status | Outcome |
|---|---|---|---|
| OQ-AU-1 | `stopTimeout` vs `SYNC_TIMEOUT` | Open | Not covered |
| OQ-AU-2 | No completion marker | Open | Not covered |
| OQ-AU-3 | Session log stream naming | Open | Not covered |
| OQ-AU-4 | CloudTrail | Open | Believed not to record session tags; unverified |
| OQ-AU-5 | Identity correlation | Open | Attribution is a requirement |
| OQ-AU-6 | Stdin in session logs | Open | Not covered |
| OQ-AU-7 | Task role can write session logs | Open | To be tightened; no design yet |
| OQ-AU-8 | Audit reader role | Answered in part | Exists outside the repo; trust undefined |
| OQ-AU-9 | Reaper vs close backup | Answered in part | Close makes no backup by design; directory fate after close open |
| OQ-AU-10 | Untested areas | Open | Not covered |

### Trusted Actions ([#14](https://github.com/geowa4/rosa-boundary/issues/14)) and resource inventory ([#16](https://github.com/geowa4/rosa-boundary/issues/16), [#15](https://github.com/geowa4/rosa-boundary/issues/15), [#17](https://github.com/geowa4/rosa-boundary/issues/17))

| ID | Question | Status | Outcome |
|---|---|---|---|
| OQ-TA-1 to OQ-TA-8, OQ-TA-10 to OQ-TA-14 | See [#14](https://github.com/geowa4/rosa-boundary/issues/14) | Deferred | Trusted Actions set aside |
| OQ-TA-9 | Unused config and IAM surface | Open | Follow-up agreed |
| OQ-IN-1 | Kubeconfig secret has no creator | Deferred | Dormant kube-proxy feature |
| OQ-IN-2 | Unused Trusted Actions grants | Open | Follow-up agreed; likely reserved for the real audit logger |
| OQ-IN-3 | Unused regional variables | Open | Same as OQ-ID-12 |
| OQ-IN-4 | Placeholder security groups | Open | Not covered |
| OQ-IN-5 | Orphan Keycloak overlay files | Answered | Leftover; to be removed |
| OQ-IN-6 | Trusted Actions workspace bindings | Open | Not covered |
| OQ-IN-7 | Mock audit logger in production | Answered | Placeholder; a real logger is intended and not yet written |

### Defects and gaps confirmed in the review

Recorded so the grounding marks them as deviations, not design. Fixes are tracked separately by the maintainers.

- Same-user handover is possible (OQ-PR-2).
- No `DurationSeconds` on either role assumption (OQ-ID-3, OQ-PR-10).
- Reaper identifier regex is stricter than the creator's (OQ-TD-2).
- Reaper role cannot abort failed multipart uploads (OQ-TD-3).
- Reaping Lambdas return error dictionaries instead of raising (OQ-TD-8).
- `reap-investigations` lists task definitions account-wide (OQ-TD-10).
- Possible orphaned access points from the Lambda's `DeleteAccessPoint` grant (OQ-PR-1, suspected).
- Tests keyed on `username`; no test with `uuid`; no Terraform test tying the Lambda's ABAC key to the IAM condition (OQ-ID-5, OQ-ID-6).
- Docs wrong where code is right: timeouts, tag sets, identity model, Keycloak setup (OQ-PR-3, OQ-PR-4, OQ-ID-11, OQ-KC-7).
- To remove: `deploy/keycloak/` with its runbooks; `OC_VERSION` and `--oc-version` (OQ-KC-1, OQ-PR-6).
- To define: a Boundary break-glass procedure (OQ-TD-6); a review of `get_config` disclosure (OQ-ID-8); a real Trusted Actions audit logger (OQ-IN-7).

---

## Changes on `main` since the pinned commit

Checked on 2026-11-10 against `main` at [`9dc6bbe`](https://github.com/geowa4/rosa-boundary/tree/9dc6bbe). The grounding stays pinned to `509078b`.

**Unchanged, so every trace, IAM statement and inventory row for them still holds:** `lambda/` handlers, `deploy/`, `hcp-terraform/`, `entrypoint.sh`, `skel/`, `.tekton/`. Trusted Actions changed only in `go.mod`. The `Containerfile` changed only in pinned versions (`oc` 4.22.18 to 4.22.22, AWS CLI 2.39.5 to 2.39.6).

**Changed: the CLI was restructured (#447).** Commands, files and line numbers in the CLI-side traces of [#3](https://github.com/geowa4/rosa-boundary/issues/3), [#5](https://github.com/geowa4/rosa-boundary/issues/5), [#7](https://github.com/geowa4/rosa-boundary/issues/7) and [#9](https://github.com/geowa4/rosa-boundary/issues/9) describe the pinned commit and no longer match `main`.

| At the pin | On `main` | Behavioural difference that touches the grounding |
|---|---|---|
| `start-task` | `session create <cluster-id>` | `--session-timeout` defaults to 1 h, range 0 to 24 h, always sent explicitly, so an explicit 0 can now be requested (the Lambda rejects it under the default minimum). New flags `--connect`, `--no-wait`, `--with-credentials ocm`. |
| `join-task` | `session join <session-id>` | none found |
| `stop-task` | `session close <session-id>` | none found |
| `list-tasks` | `session list` | none found |
| `create-investigation` | `investigation create <cluster-id>` | none found |
| `list-investigations` | `investigation list` | none found |
| `close-investigation` | `investigation close <cluster-id> <investigation-id>` | **new client-side owner check** on `oidc_sub`; `--dry-run`, `--yes`, `--force`; verifies each task definition mounts the investigation's access point before deregistering |
| `configure` | `config init`, `config list-profiles`, `config use-profile <name>`, `config get` | named deployment profiles replace the flat config file |
| OCM credential commands | `session credentials configure ocm`, `session credentials clear ocm` | omitting the session ID only discovers sessions owned by the caller's `sub` |
| `login` | `login` | none found |

Role session names on `main` are `rosa-boundary-invoker`, `rosa-boundary-session`, `rosa-boundary-config-init`, and `rosa-boundary-<owner>` for the SRE-role assumption inside `session create`.

Docs under `docs/` and the README were partly rewritten for the new command names; most drift listed below is still present. Before the CLI-side traces are used for the ontology they should be re-pinned to a commit that contains the new command tree.

---

## Headline doc-vs-source drift (details in the sub-issues)

Unless a bullet says otherwise, the 2026-11-09 review confirmed the code as authoritative and the docs as stale.

- A second launch for an investigation performs **handover**, not an unconditional 409. Neither side matches the intended contract: cross-user handover is intended and same-user handover is a bug ([#5](https://github.com/geowa4/rosa-boundary/issues/5), [#6](https://github.com/geowa4/rosa-boundary/issues/6)).
- Default task timeout: docs 1 h, Terraform 28800 s, CLI 3600 s. Code is authoritative. At the pin the CLI could not send 0; on `main` it can, and the Lambda rejects it under the default minimum ([#6](https://github.com/geowa4/rosa-boundary/issues/6)).
- Task tags carry `oidc_sub` and the configurable ABAC key (default `uuid`), not `username`; access-point tags also carry `Name` and `CreatedAt`. Code is authoritative ([#6](https://github.com/geowa4/rosa-boundary/issues/6), [#4](https://github.com/geowa4/rosa-boundary/issues/4)).
- The deadline is soft while an ECS Exec session is active; the reaper also fails closed when session state is unknown. **Unresolved conflict** with the stated intent of strict deadlines ([#7](https://github.com/geowa4/rosa-boundary/issues/7), [#8](https://github.com/geowa4/rosa-boundary/issues/8)).
- `reap-investigations` treats a missing `CreatedAt` as immediately stale; docs say the opposite. Not yet confirmed which side is right ([#8](https://github.com/geowa4/rosa-boundary/issues/8)).
- No `KeycloakRealmImport`, client or mapper is committed. Explained: the Boundary-owned Keycloak is obsolete and its manifests and docs are to be removed ([#2](https://github.com/geowa4/rosa-boundary/issues/2)).
- `docs/configuration/aws-iam-policies.md` describes an IAM-user/group model with no Terraform counterpart. Docs to be fixed ([#4](https://github.com/geowa4/rosa-boundary/issues/4)).
- `OC_VERSION` switching is a no-op: one `oc` is installed and `/opt/openshift` does not exist. The variable is to be removed ([#10](https://github.com/geowa4/rosa-boundary/issues/10)).
- No ssmmessages/kms/logs/ecr/ecs VPC interface endpoints exist; only an S3 gateway and a Bedrock Runtime interface endpoint. Not reviewed ([#10](https://github.com/geowa4/rosa-boundary/issues/10)).
- `SYNC_TIMEOUT` (300 s) exceeds ECS `stopTimeout` (120 s), so a long sync is killed, not timed out; there is no completion marker. Not reviewed ([#11](https://github.com/geowa4/rosa-boundary/issues/11)).
- CloudTrail is documented as an audit source but configured nowhere in the repository. Not reviewed; attribution of every action is a stated requirement ([#11](https://github.com/geowa4/rosa-boundary/issues/11)).
- Trusted Actions ARCHITECTURE says Aurora; the Terraform deploys SQLite on an EBS volume attached to an EC2 ECS host; read endpoints are role-agnostic. Not reviewed ([#14](https://github.com/geowa4/rosa-boundary/issues/14)).

## How to use and extend this grounding

- Rank evidence as source and tests first, then `[maintainer-stated]`, then docs. Do not model an item marked **Conflict** either way until it is settled.
- Treat each sub-issue's assertion table as the checklist for the ontology's constraints, and its artifact table as the list of observables a verifier can look for.
- When code changes, re-pin: update the commit in the sub-issue header, re-verify the cited line ranges, and amend the affected rows rather than rewriting the trace.
- Live-environment questions marked `UNVERIFIED` should be answered against a personal dev environment per `docs/runbooks/personal-dev-bootstrap.md`, never against staging or production, and the evidence linked back here.
