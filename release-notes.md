# Release Notes — CloudNotes Release Lab

Fill in this template as you diagnose and fix each of the three planted faults.

## Task 1 — Terraform/HCL validation fault

**Original error (paste `terraform validate` output):**

```
╷
│ Error: Reference to undeclared input variable
│ 
│   on main.tf line 33, in resource "local_file" "release_manifest":
│   33:     bucket      = var.bucket_name_old
│ 
│ An input variable with the name "bucket_name_old" has not been declared.
│ This variable can be declared with a variable "bucket_name_old" {} block.
╵
```

**Root cause:**

In `terraform/main.tf`, the `local_file.release_manifest` resource referenced `var.bucket_name_old`, which was not declared in `terraform/variables.tf`. The actual declared input variable is `var.bucket_name`.

**Fix applied:**

Updated `terraform/main.tf` to reference the declared input variable `var.bucket_name` in the `local_file.release_manifest` resource.

**Evidence (clean validate output):**

```
Success! The configuration is valid.
```

---

## Task 2 — Reusable module + state isolation fault

**Original problem:**

1. **Reusable module violation:** `terraform/main.tf` hand-defined a duplicate `local_file.cloudnotes_bucket` resource instead of invoking the reusable module defined in `terraform/modules/storage/`. Additionally, `terraform/outputs.tf` was directly reading from `local_file.cloudnotes_bucket.filename`.
2. **State isolation fault:** `terraform/envs/staging/backend.hcl` was configured with `path = "envs/dev/terraform.tfstate"`, reusing the exact same state file path as the `dev` environment (`terraform/envs/dev/backend.hcl`), leading to state collision and lack of isolation between environments.

**Fix applied:**

1. In `terraform/main.tf`, replaced the hand-defined `local_file.cloudnotes_bucket` resource with a call to `module "storage"` referencing `./modules/storage` and passing `bucket_name`, `environment`, and `labels`.
2. In `terraform/outputs.tf`, updated `bucket_metadata_path` to read from the module output `module.storage.bucket_path`.
3. In `terraform/envs/staging/backend.hcl`, changed the state path to `path = "envs/staging/terraform.tfstate"`.

**Evidence:**

```
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # local_file.release_manifest will be created
  + resource "local_file" "release_manifest" {
      + content              = jsonencode(
            {
              + bucket      = "cloudnotes-artifacts"
              + environment = "dev"
            }
        )
      + content_base64sha256 = (known after apply)
      + content_base64sha512 = (known after apply)
      + content_md5          = (known after apply)
      + content_sha1         = (known after apply)
      + content_sha256       = (known after apply)
      + content_sha512       = (known after apply)
      + directory_permission = "0777"
      + file_permission      = "0777"
      + filename             = "./.generated/dev-release-manifest.json"
      + id                   = (known after apply)
    }

  # module.storage.local_file.bucket_metadata will be created
  + resource "local_file" "bucket_metadata" {
      + content              = jsonencode(
            {
              + bucket_name = "cloudnotes-artifacts"
              + environment = "dev"
              + labels      = {
                  + owner   = "platform-team"
                  + project = "cloudnotes"
                }
            }
        )
      + content_base64sha256 = (known after apply)
      + content_base64sha512 = (known after apply)
      + content_md5          = (known after apply)
      + content_sha1         = (known after apply)
      + content_sha256       = (known after apply)
      + content_sha512       = (known after apply)
      + directory_permission = "0777"
      + file_permission      = "0777"
      + filename             = "modules/storage/../../.generated/dev-cloudnotes-artifacts.json"
      + id                   = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + bucket_metadata_path  = "modules/storage/../../.generated/dev-cloudnotes-artifacts.json"
  + release_manifest_path = "./.generated/dev-release-manifest.json"
```

---

## Task 3 — Container build + secret fault

**Original error (paste `docker build` output):**

```
=> ERROR [runtime 2/3] COPY --from=build /app/node_modules ./node_modules
------
 > [runtime 2/3] COPY --from=build /app/node_modules ./node_modules:
------
failed to solve: invalid from flag value build: stage --from=build not found
```

**Root cause:**

1. **Stage name mismatch:** The `Dockerfile` multi-stage build attempted to copy artifacts using `COPY --from=build /app/node_modules ./node_modules`, but the dependency installation stage was named `deps` (`FROM node:20-alpine AS deps`).
2. **Hardcoded secret:** The `Dockerfile` contained `ENV API_KEY=sk_live_examplekey123`, baking a fake secret directly into the Docker image layers instead of retrieving secrets at runtime from environment variables or a Compose secret / `.env` file.

**Fix applied:**

1. Updated the runtime stage in `Dockerfile` to copy from the correct stage name: `COPY --from=deps /app/node_modules ./node_modules`.
2. Removed the hardcoded `ENV API_KEY=sk_live_examplekey123` from `Dockerfile`, leaving configuration to runtime injection via `.env` (gitignored) / compose.

**Evidence (`curl http://localhost:8080/health`):**

```
{
  "status": "ok",
  "service": "cloudnotes-api",
  "version": "0.1.0",
  "apiKeyConfigured": true
}
```
