_deletion_approvals = [
  {
    address    = "module.aws_dynamic_creds.tfe_variable_set.this[\"default:rosa-trusted-actions\"]"
    expires_at = "2026-10-31T00:00:00Z" # e.g. "2026-08-01T00:00:00Z"
  },
  {
    address    = "module.aws_dynamic_creds.tfe_variable.apply_role_arn[\"default:rosa-trusted-actions\"]"
    expires_at = "2026-10-31T00:00:00Z" # e.g. "2026-08-01T00:00:00Z"
  },
  {
    address    = "module.aws_dynamic_creds.tfe_variable.plan_role_arn[\"default:rosa-trusted-actions\"]"
    expires_at = "2026-10-31T00:00:00Z" # e.g. "2026-08-01T00:00:00Z"
  },
  {
    address    = "module.aws_dynamic_creds.tfe_variable.provider_auth[\"default:rosa-trusted-actions\"]"
    expires_at = "2026-10-31T00:00:00Z" # e.g. "2026-08-01T00:00:00Z"
  },
]
