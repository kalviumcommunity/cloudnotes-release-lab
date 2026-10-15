# Release Notes — CloudNotes Release Lab

Fill in this template as you diagnose and fix each of the three planted faults.

## Task 1 — Terraform/HCL validation fault

**Original error (paste `terraform validate` output):**

```
 C:\Users\anany\Desktop\cloudnotes-release-lab-ca3> terraform -chdir=terraform validate    
╷
│ Error: Reference to undeclared input variable
│ 
│   on main.tf line 33, in resource "local_file" "release_manifest":
│   33:     bucket      = var.bucket_name_old
│ 
│ An input variable with the name "bucket_name_old" has not been declared. This variable can be declared with a variable "bucket_name_old" {} block.
╵

```

**Root cause:**

The Error indicates a "Reference to undeclared input variable" which means `var.bucket_name_old` is being used in main.tf file in line 33 , but hasnt been declared anywhere .

**Fix applied:**

So i made sure that the file indicates to the right bucket name as mentioned in the main.tf file itself.

**Evidence (clean validate output):**

```
PS C:\Users\anany\Desktop\cloudnotes-release-lab-ca3> terraform -chdir=terraform validate  
Success! The configuration is valid.

PS C:\Users\anany\Desktop\cloudnotes-release-lab-ca3> 
```

---

## Task 2 — Reusable module + state isolation fault

**Original problem:**

The env files were indicating to dev causing a problem 

**Fix applied:** and **Evidence:**

This below change should pointto its own state file, than being isolated
Change output :
1) backend.hcl :
```
path = "envs/staging/terraform.tfstate"

```


2) terraform\modules\storage\main.tf
```
module "storage"{
  source = "./module/storage"
  bucket_name = var.bucket_name
  environment = var.environment
  labels      = var.labels
}
```

3) terraform\modules\storage\outputs.tf
```
  value       = module.storage.bucket_path
```

---

## Task 3 — Container build + secret fault

**Original error (paste `docker build` output):**

```
PS C:\Users\anany\Desktop\cloudnotes-release-lab-ca3> docker build -t cloudnotes-api:0.1.0 .
[+] Building 1.8s (3/3) FINISHED                                                                                                                                                                                                                         docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                                                                                                                                                                     0.0s
 => => transferring dockerfile: 880B                                                                                                                                                                                                                                     0.0s
 => CANCELED [internal] load metadata for docker.io/library/node:20-alpine                                                                                                                                                                                               1.7s
 => ERROR [internal] load metadata for docker.io/library/build:latest                                                                                                                                                                                                    1.7s
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
PS C:\Users\anany\Desktop\cloudnotes-release-lab-ca3> 
```

```
PS C:\Users\anany\Desktop\cloudnotes-release-lab-ca3> docker build -t cloudnotes-api:0.1.0 .
[+] Building 1.0s (11/11) FINISHED                                                                                                                                                                                                                       docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                                                                                                                                                                     0.0s
 => => transferring dockerfile: 858B                                                                                                                                                                                                                                     0.0s
 => [internal] load metadata for docker.io/library/node:20-alpine                                                                                                                                                                                                        0.9s
 => [internal] load .dockerignore                                                                                                                                                                                                                                        0.0s
 => => transferring context: 112B                                                                                                                                                                                                                                        0.0s
 => [internal] load build context                                                                                                                                                                                                                                        0.0s
 => => transferring context: 949B                                                                                                                                                                                                                                        0.0s
 => [deps 1/4] FROM docker.io/library/node:20-alpine@sha256:fb4cd12c85ee03686f6af5362a0b0d56d50c58a04632e6c0fb8363f609372293                                                                                                                                             0.0s
 => CACHED [deps 2/4] WORKDIR /app                                                                                                                                                                                                                                       0.0s
 => CACHED [deps 3/4] COPY app/package.json ./                                                                                                                                                                                                                           0.0s
 => CACHED [deps 4/4] RUN npm install --omit=dev                                                                                                                                                                                                                         0.0s
 => CACHED [runtime 3/4] COPY --from=deps /app/node_modules ./node_modules                                                                                                                                                                                               0.0s
 => CACHED [runtime 4/4] COPY app/ ./                                                                                                                                                                                                                                    0.0s
 => exporting to image                                                                                                                                                                                                                                                   0.0s
 => => exporting layers                                                                                                                                                                                                                                                  0.0s
 => => writing image sha256:90179d13765abd0dc2ffb2e129c1990f1b20f45fb243a7fffb3e829f738b62ad                                                                                                                                                                             0.0s
 => => naming to docker.io/library/cloudnotes-api:0.1.0                                                                                                                                                                                                                  0.0s

 1 warning found (use docker --debug to expand):
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "API_KEY") (line 20)
PS C:\Users\anany\Desktop\cloudnotes-release-lab-ca3> 


```

**Root cause:**

1) required to keep a place holder for api key , but had a hardcoded value .
2) Copy statemnet was wrong , it copied from build .


**Fix applied:**

1) Change it to copy from deps : `COPY --from=deps /app/node_modules ./node_modules`
2) gave a placeholder for api key : `ENV API_KEY=`

**Evidence (`curl http://localhost:8080/health`):**

1) Copying the env from runtime :
```
 C:\Users\anany\Desktop\cloudnotes-release-lab-ca3> Copy-Item .env.example .env   

```

2) Successful build :
```
PS C:\Users\anany\Desktop\cloudnotes-release-lab-ca3> docker compose up -d --build          
#1 [internal] load local bake definitions
#1 reading from stdin 608B done
#1 DONE 0.0s

#2 [internal] load build definition from Dockerfile
#2 transferring dockerfile: 858B done
#2 DONE 0.0s

#3 [internal] load metadata for docker.io/library/node:20-alpine
#3 DONE 1.3s

#4 [internal] load .dockerignore
#4 transferring context: 112B done
#4 DONE 0.0s

#5 [deps 1/4] FROM docker.io/library/node:20-alpine@sha256:fb4cd12c85ee03686f6af5362a0b0d56d50c58a04632e6c0fb8363f609372293
#5 DONE 0.0s

#6 [internal] load build context
#6 transferring context: 94B done
#6 DONE 0.0s

#7 [deps 2/4] WORKDIR /app
#7 CACHED

#8 [deps 3/4] COPY app/package.json ./
#8 CACHED

#9 [runtime 3/4] COPY --from=deps /app/node_modules ./node_modules
#9 CACHED

#10 [deps 4/4] RUN npm install --omit=dev
#10 CACHED

#11 [runtime 4/4] COPY app/ ./
#11 CACHED

#12 exporting to image
#12 exporting layers done
#12 writing image sha256:f2cd47c66663f1ae2f8a3523a867965dffcbf1455d32fb1900e2af4d0e8e283e done
#12 naming to docker.io/library/cloudnotes-api:0.1.0 done
#12 DONE 0.0s

#13 resolving provenance for metadata file
#13 DONE 0.0s
[+] up 3/3
 ✔ Image cloudnotes-api:0.1.0                            Built                                                                                                                                                                                                      1.9s
 ✔ Container cloudnotes-release-lab-ca3-cloudnotes-api-1 Running                                                                                                                                                                                                    0.0s
 ✔ Container cloudnotes-release-lab-ca3-registry-1       Running                                                                                                                                                                                                    0.0s
PS C:\Users\anany\Desktop\cloudnotes-release-lab-ca3> 

```

3)  curl http://localhost:8080/health  

```
PS C:\Users\anany\Desktop\cloudnotes-release-lab-ca3> curl http://localhost:8080/health     

Security Warning: Script Execution Risk
Invoke-WebRequest parses the content of the web page. Script code in the web page might be run when the page is parsed.
      RECOMMENDED ACTION:
      Use the -UseBasicParsing switch to avoid script code execution.

      Do you want to continue?
    
[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "N"): y


StatusCode        : 200
StatusDescription : OK
Content           : {"status":"ok","service":"cloudnotes-api","version":"0.1.0","apiKeyConfigured":true}
RawContent        : HTTP/1.1 200 OK
                    Connection: keep-alive
                    Keep-Alive: timeout=5
                    Content-Length: 84
                    Content-Type: application/json; charset=utf-8
                    Date: Thu, 15 Oct 2026 05:17:18 GMT
                    ETag: W/"54-tH7vx0lW+bHuwTbhLnU8...
Forms             : {}
Headers           : {[Connection, keep-alive], [Keep-Alive, timeout=5], [Content-Length, 84], [Content-Type, application/json; charset=utf-8]...}
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        : mshtml.HTMLDocumentClass
RawContentLength  : 84



PS C:\Users\anany\Desktop\cloudnotes-release-lab-ca3> 

```

4) Security Check :
```

anany@Ananya MINGW64 ~/Desktop/cloudnotes-release-lab-ca3 (fix/ca3-release)
$ bash ./security/check.sh 
== Checking for hardcoded secrets in Dockerfile/compose.yaml ==
OK: no obvious hardcoded secrets found.

== Checking .env is gitignored ==
OK: .env is listed in .gitignore.

Security check PASSED.
(Optional) run 'trivy image cloudnotes-api:0.1.0' if Trivy is installed for a deeper scan.

anany@Ananya MINGW64 ~/Desktop/cloudnotes-release-lab-ca3 (fix/ca3-release)
$ 

```
