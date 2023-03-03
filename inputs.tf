variable "name" {
  type        = string
  description = "The name to use for this role"
  default     = "github_actions_role"
}

variable "subjects" {
  type        = list(string)
  description = "The list of subjects to allow to assume this role."
}

variable "inline_policies" {
  type        = map(string)
  description = "A map of inline policies (JSON) to attach to this role. Keys will be used as the policy name."
  default     = {}
}

variable "managed_policy_arns" {
  type        = list(string)
  description = "A list of AWS managed policies arns to attach to this role."
  default     = []
}

variable "add_oidc_provider" {
  type        = bool
  description = "Whether to add the OIDC provider for GitHub Actions. Default true"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to the role."
  default     = {}
}
