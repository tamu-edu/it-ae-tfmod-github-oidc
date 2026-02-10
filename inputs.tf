variable "name" {
  type        = string
  description = "The name to use for this role"
  default     = "github_actions_role"
}

variable "subjects" {
  type        = list(string)
  description = "The list of subjects to allow to assume this role."
}

variable "policies" {
  type        = map(string)
  description = "A map of policies (JSON) to attach to this role. Keys will be used as the policy name."
  default     = {}
}

variable "managed_policy_arns" {
  type        = list(string)
  description = "A list of AWS managed policy ARNs to attach to this role."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to the role."
  default     = {}
}

variable "max_session_duration" {
  type        = number
  description = "The maximum session duration (in seconds) for the role (can be between 1 hour and 12 hours)."
  default     = 3600
}
