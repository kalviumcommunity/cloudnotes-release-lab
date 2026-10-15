# Release Notes — CloudNotes Release Lab

Fill in this template as you diagnose and fix each of the three planted faults.

## Task 1 — Terraform/HCL validation fault

**Original error (paste `terraform validate` output):**

```
Refrence to undeclared input variable
33: bucket = var.bucket_name_old
```

**Root cause:**

the bucket name was wrong

**Fix applied:**

changed the name to just bucket_path

**Evidence (clean validate output):**

```
Success! The configuration is valid.
```

---

## Task 2 — Reusable module + state isolation fault

**Original problem:**

Storage module was duplicated

**Fix applied:**

<describe the change — module call + unique backend paths>

**Evidence:**

```
<paste here>
```

---

## Task 3 — Container build + secret fault

**Original error (paste `docker build` output):**

```
was refrencing build instead of deps
```

**Root cause:**

<explain>

**Fix applied:**

refrence deps

**Evidence (`curl http://localhost:8080/health`):**

```
<paste here>
```
