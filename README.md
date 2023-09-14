# AWS GitHub Actions OIDC module

This module creates an IAM role and a trust policy for GitHub Actions to assume in the current AWS account.
See the [GitHub OIDC documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services) for more information on subject values. 

## Usage

```hcl
module "github_oidc" {
  source = "github.com/tamu-edu/it-ae-tfmod-github-oidc?ref=v1.0.0"
  # source = "git@github.com:tamu-edu/it-ae-tfmod-github-oidc?ref=v1.0.0"

  name = "allow-my-repo"
  subjects = [
    "repo:tamu-edu/it-ae-foo:*"
  ]

  inline_policies = {
    "MyPolicy1" = <<-EOF
        {
            "Version": "2012-10-17",
            "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                "s3:ListAllMyBuckets",
                "s3:ListBucket"
                ],
                "Resource": "*"
            }
            ]
        }
    EOF
  }

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}
```

## Inputs

| Name | Description | Type | Default |
| -- | -- | -- | -- |
| `name` | The name of the role. | `string` | Required |
| `subjects` | A list of GitHub subject values. | `list(string)` | Required |
| `inline_policies` | A map of inline policies to attach to the role. | `map(string)` | Optional |
| `managed_policy_arns` | A list of managed policies ARNs to attach to the role. | `list(string)` | Optional
| `add_oidc_provider` | Whether to add the OIDC provider to the account. | `bool` | `true` |
| `tags` | A map of tags to add to the role. | `map(string)` | Optional |

## Outputs

| Name | Description |
| -- | -- |
| `role_arn` | The ARN of the role. |

## Semantic Versioning

This module uses [Semantic Versioning](https://semver.org/). Major (`v1`), minor (`v1.0`), and patch (`v1.0.0`) tags are created or incremented with every release for use in your module source ref.
