---
type: infrastructure
title: Regional AWS runtime infrastructure
description: Describes the Terraform-owned regional ECS, EFS, IAM, audit storage, Lambda, encryption, and Bedrock resources and their key configuration constraints.
tags: [terraform, aws, ecs, efs, iam, bedrock]
sources:
  - id: openwiki-source-7182e154441e0f90fda05986
    resource: repo://deploy/account/bedrock-model-agreements.tf
  - id: openwiki-source-af67bd84d6fb827de35fd527
    resource: repo://deploy/regional/bedrock-endpoint.tf
  - id: openwiki-source-43a5f7fe8e3da821d41a4dba
    resource: repo://deploy/regional/bedrock-large-payloads.tf
  - id: openwiki-source-86eaa81471e45a1fc5290cf1
    resource: repo://deploy/regional/bedrock-logging.tf
  - id: openwiki-source-f1bd1e0a9201f149b775a09c
    resource: repo://deploy/regional/ecs.tf
  - id: openwiki-source-e1ea6906f2471c7921ff32ce
    resource: repo://deploy/regional/efs.tf
  - id: openwiki-source-d176128a85129af793772942
    resource: repo://deploy/regional/lambda-create-investigation.tf
  - id: openwiki-source-81b84da9542934c33f2e42d7
    resource: repo://deploy/regional/lambda-reap-investigations.tf
  - id: openwiki-source-a7f1ddde1efa89d5bfad2d5c
    resource: repo://deploy/regional/lambda-reap-tasks.tf
  - id: openwiki-source-a467cf2af07b3f58e60a50ab
    resource: repo://deploy/regional/main.tf
  - id: openwiki-source-dcec1f4680246d4606ff71f8
    resource: repo://deploy/regional/s3.tf
  - id: openwiki-source-92cccd8107e9e4386a317d7a
    resource: repo://deploy/regional/tests/claude_default_model.tftest.hcl
  - id: openwiki-source-a055ff9a3fcbd2c0a0fc4ee2
    resource: repo://deploy/regional/variables.tf
  - id: openwiki-source-d796a031add13f67891a2f24
    resource: repo://lambda/reap-investigations/handler.py
generated: { by: "openwiki/0.7.1", at: "2026-10-15T16:03:34.007Z" }
verified:
  - by: openwiki/0.7.1
    at: 2026-10-15T16:03:34.007Z
---

# Regional AWS runtime infrastructure

`deploy/regional/` defines the AWS resources that host investigations. Terraform takes the account, region, VPC, subnet, container-image, and identity inputs; the provider restricts deployment to the configured 12-digit account ID. Configuration includes checks for at least two task subnets and usable default routes, because Fargate needs outbound access to ECR. The directory Makefile sources the repository `.env` for **local dev**, exposes Terraform targets, and builds create-investigation Lambda dependencies before local apply; HCP staging uses Git-managed variables and remote execution instead.

## ECS, EFS, and task roles

The regional stack creates an ECS cluster with Container Insights and ECS Exec logging/encryption configuration, CloudWatch log groups, a Fargate security group, and a task definition. The task definition runs the `rosa-boundary` container, mounts the baseline EFS home through an EFS access point, and overlays empty task-scoped volumes at `/home/sre/.config/ocm` and `/home/sre/.kube`. An optional `kube-proxy` sidecar consumes a cluster kubeconfig secret and exposes its proxy only on localhost; the main container waits for its health check when enabled.

EFS is encrypted and mounted through dedicated per-subnet mount targets. The baseline access point presents UID/GID 1000 and `/home/sre`; the filesystem policy's `EnforceAccessViaAccessPoint` statement requires the task role to mount via an access point. At investigation creation, Lambda creates a separate access point rooted at `/<cluster-id>/<investigation-id>` and rewrites the per-investigation task definition to use it.

The filesystem policy carries a second statement, `AllowReaperViaDedicatedAccessPoint`, granting the reap-investigations Lambda role `ClientMount`/`ClientWrite`/`ClientRootAccess` scoped by `elasticfilesystem:AccessPointArn` to a single dedicated access point (`aws_efs_access_point.reaper`), rooted at `/` with UID/GID 0 for full filesystem reach. This grant is separate from the task role's access-point-scoped statement and is deliberately not extended to the dynamically created per-investigation access points. Removing *other* investigations' access points is instead handled by a distinct `DeleteAccessPoint` permission on the reap-investigations Lambda role, scoped to resources carrying the `ManagedBy=rosa-boundary-lambda` tag so the role cannot delete unrelated access points.

IAM separates the ECS execution role from the task role. The execution role supports image pulls/logging and secret retrieval; the task role carries runtime permissions for audit S3 writes, Bedrock, ECS Exec messaging, session logging, KMS, and EFS access. Shared role identities/trust live in the **account** root; their regional inline permissions live here. See [identity and access](../architecture/identity-and-access.md) for trust and task-level controls.

## Audit and session records

The investigation audit bucket is versioned, uses S3 Object Lock compliance retention, blocks public access, encrypts objects with AES-256, and denies non-TLS requests. An optional cross-account replication configuration requires the destination account ID and transfers ownership to the destination account. Container shutdown syncs the SRE home to this bucket; task-scoped credential paths are excluded by the runtime script.

ECS Exec sessions use a rotating KMS key. The ECS cluster sends session output to a dedicated encrypted CloudWatch log group; container stdout uses its own log group. Bedrock invocation payload logging has separate resources and retention: CloudWatch receives enabled text payload delivery and a dedicated S3 bucket receives large payloads. This logging configuration is account/Region-wide rather than limited to Boundary tasks, so access to those logs and objects has broader sensitivity implications than container logs.

## Lambda deployment and task timeout

The regional stack ships three Lambda functions: create-investigation, reap-tasks, and reap-investigations.

The create-investigation Lambda can be packaged as ZIP (the default) or as a container image; both modes receive the same runtime configuration. Image mode requires a repository and an immutable tag; staging sets image mode for remote execution. Its AWS-IAM-authorized Function URL is configured separately from the CLI's direct SDK invocation path. The reap-tasks Lambda is packaged from its single handler file and gets scoped ECS list/describe/stop permissions; EventBridge invokes it at the configured schedule to stop expired tasks **without an active Exec session**.

The reap-investigations Lambda runs on its own schedule (default every 8 hours, configurable) to garbage-collect stale investigations: it lists tagged EFS access points, checks each investigation for staleness (no running tasks plus an elapsed grace period), and deletes the EFS directory, the access point, and any matching task definitions. It gets its own `aws_cloudwatch_log_group` and an `AWSLambdaVPCAccessExecutionRole` policy attachment (VPC execution is a regional concern because the account-level role only carries the basic execution policy). Its inline IAM grants are scoped narrowly: `ecs:ListTasks`/`ecs:DescribeTasks` conditioned on the regional cluster ARN, plus wildcard-resource `ecs:ListTaskDefinitions`/`ecs:DeregisterTaskDefinition` (those actions do not support resource-level permissions); `elasticfilesystem:DescribeAccessPoints` and a tag-conditioned `DeleteAccessPoint` on the filesystem; and `ClientMount`/`ClientWrite`/`ClientRootAccess` bounded to its own dedicated access point (`aws_efs_access_point.reaper`, UID/GID 0, rooted at `/`) so it can mount and write/delete stale investigation directories. It also mounts that dedicated access point directly via `file_system_config` (`/mnt/efs`) and holds scoped `s3:PutObject`/`s3:PutObjectAcl`/`s3:ListBucket` permissions for writing a final backup under `{cluster}/{investigation}/reaper-final-backup/*` in the audit bucket before deletion. A dedicated `reaper_lambda` security group permits only outbound traffic, since EventBridge — not inbound network access — triggers invocation.

## Bedrock access and approved models

Fargate tasks use a private Bedrock Runtime interface endpoint with private DNS, task-only HTTPS ingress, and one subnet per availability zone in the configured VPC. The endpoint policy grants inference calls to the task role. Task IAM does not grant Marketplace subscription; **account Terraform** owns model agreements from an explicit model-to-offer map. Regional Terraform validates the default Claude inference profile against a pinned profile-to-foundation-model mapping and the approved agreement input; it is not inferred by stripping a prefix. Terraform tests use a mocked AWS provider to accept an approved profile and reject a bare foundation-model ID or a profile whose foundation model is not approved.

## Evidence-backed claims

- Regional Terraform guards the target account, subnet count, outbound routes, and Bedrock endpoint subnet/VPC/AZ shape. [provider and routing checks](repo://deploy/regional/main.tf#L1-L69) · [Bedrock endpoint preconditions](repo://deploy/regional/bedrock-endpoint.tf#L30-L69)
- The Fargate task definition mounts persistent EFS home plus empty task-scoped credential overlays, with an optional kube-proxy sidecar whose health gates the main container. [task volumes and container configuration](repo://deploy/regional/ecs.tf#L61-L159) · [sidecar](repo://deploy/regional/ecs.tf#L175-L224)
- EFS is encrypted and its filesystem policy allows the task role to mount via an access point; the baseline access point uses the `sre` UID/GID. [filesystem and mount targets](repo://deploy/regional/efs.tf#L1-L42) · [access point and policy](repo://deploy/regional/efs.tf#L44-L75)
- The EFS filesystem policy's `AllowReaperViaDedicatedAccessPoint` statement grants the reap-investigations Lambda role `ClientMount`/`ClientWrite`/`ClientRootAccess` scoped to its own dedicated `aws_efs_access_point.reaper`, distinct from both the task role's access-point-scoped grant and the reap-investigations role's separate tag-scoped `DeleteAccessPoint` permission used to remove other investigations' access points. [dedicated reaper statement](repo://deploy/regional/efs.tf#L103-L126) · [reaper access point](repo://deploy/regional/lambda-reap-investigations.tf#L127-L150) · [tag-scoped DeleteAccessPoint](repo://deploy/regional/lambda-reap-investigations.tf#L62-L94)
- The audit bucket enables versioning and compliance-mode Object Lock, blocks public access, encrypts with AES-256, and denies non-TLS requests; replication is optional and account-scoped. [audit bucket controls](repo://deploy/regional/s3.tf#L1-L73) · [replication](repo://deploy/regional/s3.tf#L75-L120)
- Create-investigation Lambda ZIP and container-image modes share environment configuration, while image mode requires an image repository and tag; a separate EventBridge schedule invokes the task-deadline reaper. [Lambda package modes](repo://deploy/regional/lambda-create-investigation.tf#L11-L140) · [reaper schedule](repo://deploy/regional/lambda-reap-tasks.tf#L42-L66)
- The reap-investigations Lambda is a third regional function with its own log group, VPC execution policy attachment, scoped ECS list/describe/deregister-task-definition permissions, and EFS describe/delete-access-point plus mount/write/root-access permissions bounded to its dedicated access point; it mounts that access point directly and runs on an independent EventBridge schedule to clean up stale investigation directories, access points, and task definitions. [log group, VPC policy, and IAM grants](repo://deploy/regional/lambda-reap-investigations.tf#L1-L94) · [dedicated access point and function](repo://deploy/regional/lambda-reap-investigations.tf#L127-L222) · [account-level role identity](repo://deploy/account/modules/shared-iam/lambda-reap-investigations.tf#L1-L13) · [handler staleness and cleanup logic](repo://lambda/reap-investigations/handler.py#L85-L250)
- Account Terraform manages Bedrock model agreement offers by ID, while regional validation requires the configured default inference profile to map to an approved foundation model; Terraform tests reject invalid profile/agreement combinations. [account agreements](repo://deploy/account/bedrock-model-agreements.tf#L1-L40) · [default model validation](repo://deploy/regional/variables.tf#L37-L65) · [Terraform tests](repo://deploy/regional/tests/claude_default_model.tftest.hcl#L78-L115)
- Bedrock Runtime uses a private interface endpoint and invocation payload logging sends text to encrypted CloudWatch storage and larger payloads to a separate S3 bucket. [runtime endpoint](repo://deploy/regional/bedrock-endpoint.tf#L1-L69) · [invocation logging](repo://deploy/regional/bedrock-logging.tf#L1-L85) · [large-payload bucket](repo://deploy/regional/bedrock-large-payloads.tf#L1-L86)
