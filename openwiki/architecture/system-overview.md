---
type: architecture
title: System overview and boundaries
description: Maps the ROSA Boundary CLI, AWS identity, investigation Lambda, Fargate runtime, persistent and task-scoped storage, and the two independent scheduled reaper Lambdas by responsibility.
tags: [architecture, system-overview, aws, ecs, investigations]
sources:
  - id: openwiki-source-40c7b4fa49977c539f479848
    resource: repo://cmd/rosa-boundary/main.go
  - id: openwiki-source-f1bd1e0a9201f149b775a09c
    resource: repo://deploy/regional/ecs.tf
  - id: openwiki-source-81b84da9542934c33f2e42d7
    resource: repo://deploy/regional/lambda-reap-investigations.tf
  - id: openwiki-source-e9906b078522ed0a08c64ff1
    resource: repo://entrypoint.sh
  - id: openwiki-source-7a5e071b6b6192c80a6918aa
    resource: repo://internal/cmd/root.go
  - id: openwiki-source-253b57ec87256e726a724093
    resource: repo://lambda/create-investigation/handler.py
  - id: openwiki-source-d796a031add13f67891a2f24
    resource: repo://lambda/reap-investigations/handler.py
  - id: openwiki-source-6e447421bb9d1456afb165d9
    resource: repo://lambda/reap-tasks/handler.py
  - id: openwiki-source-30a9bbeef6a7c1bda59eab80
    resource: repo://tests/localstack/integration/test_full_workflow.py
verified:
  - by: openwiki/0.7.1
    at: 2026-10-15T16:03:34.007Z
generated: { by: "openwiki/0.7.1", at: "2026-10-15T16:03:34.007Z" }
---

# System overview and boundaries

ROSA Boundary is an operator CLI plus a regional AWS runtime for ephemeral SRE investigations. The system separates operator authentication and orchestration from privileged resource creation and task execution: the Go CLI obtains OIDC-backed AWS credentials, the create-investigation Lambda validates the user's token and provisions the investigation, and ECS Fargate runs the SRE tool container. Two independent scheduled Lambdas reclaim resources on different horizons — one enforces per-task deadlines, the other garbage-collects whole stale investigations. Terraform owns the regional AWS resources; the repository's Kustomize manifests separately define the Keycloak deployment components.

## Responsibility boundaries

- **CLI (`cmd/rosa-boundary`, `internal/`)** — exposes login/configuration and investigation/task commands. Shared command setup resolves configuration and performs OIDC-to-STS authentication. `start-task` invokes Lambda directly through the AWS SDK, assumes the shared SRE role for ECS operations, optionally waits for task readiness, and can configure credentials or connect.
- **Create-investigation Lambda (`lambda/create-investigation/`)** — is the authorization and provisioning boundary. It validates the OIDC token and group claims, establishes the ABAC identity, creates or reuses the investigation's EFS access point, and when requested registers a task definition and launches a Fargate task.
- **ECS task (`Containerfile`, `entrypoint.sh`)** — is the ephemeral operator environment. ECS Exec sessions enter as `sre`; the root entrypoint performs controlled setup, verifies task-scoped credential overlays, then launches the requested workload as `sre`. On shutdown it attempts a bounded S3 sync of the persistent home while excluding credential state.
- **Terraform (`deploy/account/`, `deploy/regional/`)** — the account root owns shared IAM identities and OIDC providers; regional Terraform declares ECS, EFS, regional IAM grants, S3, KMS/logging and Lambda resources. The regional task definition mounts a shared EFS home and empty per-task overlays at OCM and kubeconfig paths; the investigation Lambda replaces the home volume with an investigation-specific access point at launch.
- **Reap-tasks Lambda (`lambda/reap-tasks/`)** — runs on a short schedule (every `var.reaper_schedule_minutes` minutes) and enforces the *per-task* deadline: it lists RUNNING tasks, stops those past their `deadline` tag, and defers stopping a task with an active ECS Exec/SSM session.
- **Reap-investigations Lambda (`lambda/reap-investigations/`)** — is a third, independent scheduled component with a distinct, broader scope. Rather than enforcing an individual task's deadline, it runs on a long schedule (every `var.investigation_reaper_schedule_hours` hours) and garbage-collects an entire stale *investigation* — its EFS access point, the EFS directory contents, and any matching per-investigation task definitions — once that investigation has had no running task for a configurable grace period (`var.investigation_grace_period_hours`, default 72h). These two reapers must not be conflated: "the reaper" is not singular, and a reader reasoning about cleanup needs to know which of the two scopes (task timeout vs. whole-investigation GC) a given behavior belongs to.
- **Tests** — Go and Lambda unit tests isolate logic with fakes/mocks; bats tests exercise shell boundaries; Terraform tests validate input constraints; LocalStack integration tests exercise AWS resource/API interactions using fixture-created resources.

## Main request flow

For a new task, the CLI authenticates as the operator and assumes the Lambda invoker role. It invokes the create-investigation Lambda with cluster and investigation identifiers. The Lambda checks the caller's token and required group membership, then creates/reuses an EFS access point rooted at `/<cluster-id>/<investigation-id>`. If a task is already running for the same investigation, the Lambda performs a handover: it preflight-checks for an active SSM/ECS Exec session on each existing task (failing closed if session state cannot be verified) and, if none is active, stops the existing task(s) and waits for `STOPPED` before proceeding. For a task launch it builds a per-investigation task definition from the configured base definition — replacing the EFS home volume with the investigation's access point, enforcing task-scoped (non-EFS) overlay volumes for the OCM config and kubeconfig credential paths, baking investigation-specific environment variables into the SRE container, and injecting a Secrets Manager kubeconfig reference into the `kube-proxy` sidecar's `secrets` — then calls ECS `RunTask` with ECS Exec enabled and tags needed for ABAC, audit, and task-timeout enforcement. The CLI next assumes the shared SRE role, waits for `RUNNING` unless `--no-wait` was selected, and emits connection details (or joins when requested).

The CLI distinguishes the ROSA cluster identifier being investigated from the ECS cluster that hosts the task. Lambda receives the former as investigation context; ECS API calls use the configured ECS cluster name.

```mermaid
flowchart TD
    CLI["CLI (cmd/rosa-boundary)"]
    CreateLambda["create-investigation Lambda"]
    ECS["ECS Fargate task"]
    EFS["EFS access point\n(per investigation)"]
    TaskDef["Per-investigation\ntask definition"]
    ReapTasks["reap-tasks Lambda\n(schedule: minutes)"]
    ReapInv["reap-investigations Lambda\n(schedule: hours)"]

    CLI -- "invoke w/ OIDC token" --> CreateLambda
    CreateLambda -- "create or reuse" --> EFS
    CreateLambda -- "register" --> TaskDef
    CreateLambda -- "RunTask" --> ECS
    ECS -- "mounts" --> EFS
    TaskDef -- "defines" --> ECS
    ReapTasks -- "lists RUNNING, stops past deadline tag" --> ECS
    ReapInv -- "checks no-running-task grace period" --> ECS
    ReapInv -- "deletes directory + access point" --> EFS
    ReapInv -- "deregisters matching families" --> TaskDef
```
*How the CLI, create-investigation Lambda, ECS, EFS, and the two independent reaper Lambdas relate: reap-tasks acts on individual running tasks, reap-investigations acts on whole stale investigations across EFS and task definitions.*

## State and containment

Investigation work files persist in an EFS access point scoped to the ROSA cluster and investigation identifiers. OCM configuration and kubeconfig are mounted over that home from task-scoped empty volumes so they do not persist with EFS. The container's exit sync is best-effort and time-bounded; it excludes those credential-bearing paths and does not follow symlinks.

Two scheduled Lambdas reclaim resources independently, at different scopes and on different schedules:

- **reap-tasks** checks task deadlines from ECS tags on a short interval and stops expired tasks, but defers stopping a task with an active Exec session — the timeout printed by the container is informational, not the enforcement mechanism.
- **reap-investigations** runs on a much longer interval and operates on whole investigations rather than individual tasks. For each EFS access point tagged `ManagedBy = rosa-boundary-lambda`, it checks whether the investigation currently has any RUNNING task; an investigation with a running task is never stale regardless of age. Only once an investigation has had no running task for longer than `GRACE_PERIOD_HOURS` (derived from the access point's `CreatedAt` tag) does it become eligible for reaping. Reaping re-verifies no task is running immediately before deletion, then (1) backs up the EFS directory to S3 (refusing to delete if the backup fails or `S3_AUDIT_BUCKET` is unset), (2) deletes the EFS directory tree, (3) deletes the EFS access point, and (4) deregisters any ECS task definitions whose family matches `{TASK_DEFINITION_FAMILY}-{cluster_id}-{investigation_id}-<timestamp>`. The access point is deleted only if directory deletion succeeded, because once the access point's tags are gone the directory location can no longer be identified; task-definition deregistration is attempted regardless of the earlier steps' outcome. The reaper mounts EFS itself (via a dedicated root-level access point) and validates that resolved investigation paths stay within that mount before touching the filesystem.

Because these two Lambdas have non-overlapping responsibilities — one enforces a single task's wall-clock budget, the other garbage-collects an abandoned investigation's durable state — a task that is stopped by reap-tasks does not by itself remove the investigation's EFS data or access point; that cleanup is reap-investigations' job, and only after the grace period elapses with no running replacement task.

## Verification boundaries

LocalStack integration tests create representative IAM, ECS, and EFS resources and assert cross-service relationships such as task tags, task-definition EFS access-point wiring, deadline processing, and cleanup. They are not a substitute for the Go/Lambda unit tests or shell tests, which cover logic and failure paths unavailable from an AWS API integration test alone. The LocalStack suite may not execute task containers under the local executor; this is explicit in the slow end-to-end test's skip condition.

## Evidence-backed claims

- The CLI uses a centralized OIDC/STS pre-run hook and selects the Lambda invoker role for create/start commands, with a separate SRE role for operational commands. [CLI root](repo://internal/cmd/root.go#L154-L207) · [task-start orchestration](repo://internal/cmd/start_task.go#L90-L207)
- The Lambda validates the user, creates/reuses an investigation EFS access point, performs a session-checked handover of any existing running task, registers a per-investigation task definition with task-scoped credential overlays, and launches a Fargate task with ECS Exec and identifying/deadline tags. [authorization and dispatch](repo://lambda/create-investigation/handler.py#L175-L281) · [handover preflight and stop](repo://lambda/create-investigation/handler.py#L682-L774) · [task-definition registration](repo://lambda/create-investigation/handler.py#L469-L638) · [task launch and tagging](repo://lambda/create-investigation/handler.py#L886-L999)
- ECS task infrastructure mounts persistent EFS home plus task-scoped OCM and kubeconfig overlays; entrypoint rejects missing or EFS-backed overlays and uses a protected S3 sync on exit. [task mounts](repo://deploy/regional/ecs.tf#L62-L159) · [mount verification and sync](repo://entrypoint.sh#L3-L80)
- The reap-tasks Lambda lists RUNNING tasks and stops expired tasks without an active Exec session; missing or malformed deadlines are skipped. [reaper implementation](repo://lambda/reap-tasks/handler.py#L48-L175)
- The reap-investigations Lambda is a second, independently scheduled Lambda that garbage-collects whole stale investigations — EFS access point, EFS directory contents, and matching per-investigation task definitions — once an investigation has had no running task for a configurable grace period, distinct in scope and schedule from reap-tasks' per-task deadline enforcement. [staleness check and orchestration](repo://lambda/reap-investigations/handler.py#L85-L249) · [reap steps: directory, access point, task definitions](repo://lambda/reap-investigations/handler.py#L462-L517) · [schedule and grace-period configuration](repo://deploy/regional/lambda-reap-investigations.tf#L180-L231)
- LocalStack integration tests verify relationships between provisioned task tags, shared-role ABAC, access points, and task-definition mounts; execution of actual task containers is conditionally skipped for the local executor. [full workflow assertions](repo://tests/localstack/integration/test_full_workflow.py#L21-L137) · [container-execution condition](repo://tests/localstack/integration/test_full_workflow.py#L214-L220)
</content>
