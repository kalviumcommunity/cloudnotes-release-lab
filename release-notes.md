# Release Notes — CloudNotes Release Lab

Fill in this template as you diagnose and fix each of the three planted faults.

## Task 1 — Terraform/HCL validation fault

**Original error (paste `terraform validate` output):**

```
 Error: Reference to undeclared input variable
│ 
│   on main.tf line 33, in resource "local_file" "release_manifest":
│   33:     bucket      = var.bucket_name_old
│ 
│ An input variable with the name "bucket_name_old" has not been declared. This variable can be declared
│ with a variable "bucket_name_old" {} block.
```

**Root cause:**
"main.tf" Incorrect variable reference 
"var.bucket_name_old"

<explain>

**Fix applied:**
changed it to "var.bucket_name_old" to "var.bucket_name".

<describe the change>

**Evidence (clean validate output):**

```
pranava.m@Pranavas-MacBook-Air cloudnotes-release-lab % terraform -chdir=terraform validate
Success! The configuration is valid.
```

---

## Task 2 — Reusable module + state isolation fault

**Original problem:**

<describe what was duplicated / misconfigured>
The storage resource was duplicated in main.tf, and dev and staging used the same terraform state path.

**Fix applied:**

<describe the change — module call + unique backend paths>
used the reusable storage module and changed the staging backend path to "envs/staging/terraform.tfstate"

**Evidence:**

```
pranava.m@Pranavas-MacBook-Air cloudnotes-release-lab % terraform -chdir=terraform validate
Success! The configuration is valid.

pranava.m@Pranavas-MacBook-Air cloudnotes-release-lab % terraform -chdir=terraform plan

Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # local_file.cloudnotes_bucket will be created
  + resource "local_file" "cloudnotes_bucket" {
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
      + filename             = "./.generated/dev-bucket.json"
      + id                   = (known after apply)
    }

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

Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + bucket_metadata_path  = "./.generated/dev-bucket.json"
  + release_manifest_path = "./.generated/dev-release-manifest.json"

────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee
to take exactly these actions if you run "terraform apply" now.


```

---

## Task 3 — Container build + secret fault

**Original error (paste `docker build` output):**

```
pranava.m@Pranavas-MacBook-Air cloudnotes-release-lab % docker build -t cloudnotes-api:0.1.0 .

[+] Building 2.0s (3/3) FINISHED                                docker:desktop-linux
 => [internal] load build definition from Dockerfile                            0.0s
 => => transferring dockerfile: 856B                                            0.0s
 => CANCELED [internal] load metadata for docker.io/library/node:20-alpine      1.9s
 => ERROR [internal] load metadata for docker.io/library/build:latest           1.9s
------
 > [internal] load metadata for docker.io/library/build:latest:
------
Dockerfile:15
--------------------
  13 |     # NOTE: this should copy from the "deps" stage, not "build" (no such stage
  14 |     # exists in this Dockerfile).
  15 | >>> COPY --from=build /app/node_modules ./node_modules
  16 |     COPY app/ ./
  17 |     
--------------------
ERROR: failed to build: failed to solve: build: failed to resolve source metadata for docker.io/library/build:latest: pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed

View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/w4672mvmj2fs0e1vtlazwsgxw
```

**Root cause:**

<explain>
The dockerfile referenced a non-existent build stage and contained a hardcoded API key

**Fix applied:**
Changed COPY --from=build to COPY --from=deps and removed the hardcoded API key.

<describe the Dockerfile / compose changes>

**Evidence (`curl http://localhost:8080/health`):**

```
pranava.m@Pranavas-MacBook-Air cloudnotes-release-lab % curl http://localhost:8080/health
{"status":"ok","service":"cloudnotes-api","version":"0.1.0","apiKeyConfigured":true}%

pranava.m@Pranavas-MacBook-Air cloudnotes-release-lab % security/check.sh
== Checking for hardcoded secrets in Dockerfile/compose.yaml ==
OK: no obvious hardcoded secrets found.

== Checking .env is gitignored ==
OK: .env is listed in .gitignore.

Security check PASSED.
(Optional) run 'trivy image cloudnotes-api:0.1.0' if Trivy is installed for a deeper scan.
```
