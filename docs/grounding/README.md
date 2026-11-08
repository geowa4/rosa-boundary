# Grounding drafts (issue bodies)

These files are the drafted bodies of a GitHub parent issue and its sub-issues: a runtime-action grounding for ontological verification and risk analysis, pinned to commit `509078b`. Start with [00-parent.md](00-parent.md). Each other file is one sub-issue body, sized to GitHub's issue limit.

| File | Title |
|---|---|
| [00-parent.md](00-parent.md) | Grounding for ontological verification and risk analysis of rosa-boundary (runtime actions) |
| [01-kc.md](01-kc.md) | Grounding — Keycloak identity provider (runtime): claims, flows, token lifetimes, IdP state |
| [02-id1.md](02-id1.md) | Grounding — CLI and AWS identity chain (1/2): actors, identifiers, data-flow traces, lifecycle |
| [03-id2.md](03-id2.md) | Grounding — CLI and AWS identity chain (2/2): IAM/code assertions, artifacts, failure modes, config, open questions |
| [04-pr1.md](04-pr1.md) | Grounding — Investigation and task provisioning (1/2): actors, identifiers, start-task/handover/create/list/join traces |
| [05-pr2.md](05-pr2.md) | Grounding — Investigation and task provisioning (2/2): lifecycle, assertions, artifacts, failure modes, config, open questions |
| [06-td1.md](06-td1.md) | Grounding — Teardown and reaping (1/2): stop-task, close-investigation, reap-tasks, reap-investigations traces |
| [07-td2.md](07-td2.md) | Grounding — Teardown and reaping (2/2): lifecycle, assertions, artifacts, failure modes, config, open questions |
| [08-rt1.md](08-rt1.md) | Grounding — Container runtime and interactive session (1/2): boot, join-task/ECS Exec, OCM credentials, Bedrock, kube-proxy traces |
| [09-rt2.md](09-rt2.md) | Grounding — Container runtime and interactive session (2/2): lifecycle, assertions, artifacts, failure modes, config, open questions |
| [10-au.md](10-au.md) | Grounding — Audit evidence: CloudWatch, ECS Exec transcripts, S3 sync and WORM, Bedrock logging, CloudTrail, drift summary |
| [11-ta1.md](11-ta1.md) | Grounding — Trusted Actions (1/3): scope, actors, identifiers, configuration conditionals |
| [12-ta2.md](12-ta2.md) | Grounding — Trusted Actions (2/3): data-flow traces (startup, run request, worker/executor/Backplane/AWS, reads, cleanup, clients) |
| [13-ta3.md](13-ta3.md) | Grounding — Trusted Actions (3/3): resource lifecycle, assertions, artifacts, failure modes, open questions |
| [14-in1.md](14-in1.md) | Grounding — Resource inventory (1/3): Boundary Terraform roots (account, network, regional) with runtime actor mapping |
| [15-in2.md](15-in2.md) | Grounding — Resource inventory (2/3): Trusted Actions Terraform roots, TA variables, TA workspace definitions |
| [16-in3.md](16-in3.md) | Grounding — Resource inventory (3/3): Boundary variables, HCP workspace definitions, Keycloak objects, runtime-created resources |
