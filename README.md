# DevOps Assessment Scenario

Welcome! This repository contains only the application code you need to demonstrate modern Azure DevOps engineering skills. Everything around deployment, automation, governance, and operations is intentionally left for you to design.

## 1. Goal (What You’re Showing Us)
Demonstrate how you would deploy and operate a small React frontend plus a Python FastAPI Azure Function on Azure using Azure DevOps in a constrained timeframe. Depth is traded for clarity: show core mechanics working, and describe (briefly) how you would extend to a full production setup.

### Scope & Priority Levels
We categorize expectations so you can focus on essentials first.

| Category | Item | Expectation |
|----------|------|-------------|
| MUST | Working build & deploy of Function + React app | Deployed (or clearly runnable) on Azure (or well‑described if time blocks actual deploy) |
| MUST | Basic pipeline (Azure DevOps) | Single pipeline that builds & deploys (can be sequential); artifact handling implicit or simple |
| MUST | Explanation of secret handling | Verbal / doc description of using Key Vault or alternative (even if not fully wired) |
| MUST | Basic observability plan | App Insights (or equivalent) referenced; minimal instrumentation/logging explanation |
| DESIRABLE | Infrastructure as Code | Partial / skeleton (e.g. one Bicep/Terraform module & structure outline) |
| DESIRABLE | API Management fronting the Function | Basic APIM import/policy OR clear reasoning why deferred; direct Function call is acceptable with CORS justification |
| DESIRABLE | Environment separation approach | Parameters/variables strategy description |
| BONUS | Multi‑stage pipeline with approvals | Promotion (dev -> prod) using environments |
| BONUS | Quality gates (tests, lint, linting, security scan) | Implemented or stubbed stage |
| BONUS | Deployment safety strategy | Slots / blue‑green / canary described |
| BONUS | Cost & scalability considerations | Autoscale, pricing tier rationale |
| BONUS | APIM policies (rate limit, headers) | Example snippet or outline |

Direct React → Function calls ARE acceptable for this exercise (ensure or describe CORS/host configuration). Using APIM adds design points but is not required.

## 2. What You Get (Code Only)
Directory | Purpose
--------- | -------
`frontend/` | React (Vite) SPA calling `/api/products` (local proxy expectation).
`api-function/` | FastAPI exposed via Azure Functions HTTP trigger (catch‑all route) returning sample products.

No infrastructure, pipeline YAML, or APIM definitions are provided on purpose.

## 3. Your Mission
Deliver (or outline) the MUST items first, then add DESIRABLE/BONUS if time permits:
1. Minimal pipeline that: builds frontend, builds/tests function, deploys both.
2. Function reachable from the frontend (locally or via Azure). If APIM is omitted, note CORS/security considerations.
3. Short description (markdown or comments) of how secrets would be stored & referenced (Key Vault / managed identity / variable groups).
4. Observability: how Application Insights (or alternative) would capture logs/metrics; mention any custom logging planned.
5. (Time permitting) Add one IaC file showing structure/naming conventions. Skeleton with TODOs is fine.
6. (Time permitting) APIM outline or initial Bicep/Terraform fragment / import command.
7. (Optional) Notes on pipeline evolution to multi‑stage with approvals.

## 4. Deliverables (Flexible Mix)
You can provide any combination of:
* Pipeline YAML (multi‑stage) with comments
* IaC modules + parameter files or variable sets
* APIM policy or OpenAPI import scripts
* Docs: short ADRs / README additions / diagrams (ASCII or link to an image)
* Test/lint configs or stubs (even if minimal)

If something is only described (not implemented) clearly mark it as DESIGN‑ONLY.

## 5. Suggested Evaluation Criteria
Area | Focus For This Exercise
---- | -----------------------
Working Delivery | Code builds & deploys (or is clearly deployable) with a simple pipeline
Clarity | Simplicity, readable YAML / scripts, concise explanations
Security Awareness | Correct handling/description of secrets (no hardcoded sensitive data)
Observability | Reasonable plan for App Insights integration (even if partially implemented)
Extensibility | Evident path to add stages, environments, APIM, IaC depth
Trade‑Offs | Clear reasoning for what was deferred and why

## 6. Local Run (Code Verification Only)
Prereqs: Node.js 18+, Python 3.11, Azure Functions Core Tools v4, Azure CLI.

Frontend:
```
cd frontend
npm install
npm run dev
```

Function:
```
cd api-function
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp local.settings.example.json local.settings.json
func start
```

Test endpoint:
```
curl http://localhost:7071/api/products
```

Tests:
```
cd api-function && pytest -q
cd frontend && npm test -- --run
```

## 7. Assumptions You May Declare
It’s fine to state assumptions (e.g., “Prod uses Front Door”, “We’ll introduce Container Apps later”) — just keep them explicit.

## 8. Out of Scope (Unless You Want Bonus Points)
* Full-blown auth (JWT/Entra ID) – a brief outline is enough
* Advanced networking (private endpoints, hub/spoke) – can be conceptual
* Full test matrix / performance tests

## 9. Submission Guidance
You will demo from your own Azure environment. Provide ONE zip containing:
* Source code (original + any added pipeline/IaC/docs)
* RUNBOOK.md (how to build, deploy, rollback; any prerequisites)
* Optional diagram or sanitized screenshots

Mark deferred/outline-only items with a clear prefix (e.g. `DESIGN-ONLY:`).

Be prepared to discuss (even if not fully implemented): multi‑stage promotion, APIM benefits, rollback path, scaling.

## 10. Tips
* Keep secrets abstract (e.g., `KEYVAULT_SECRET_REF`) – no dummy values that look real.
* Prefer small reusable IaC modules over one giant template.
* Don’t over‑automate if a comment/placeholder communicates intent faster.

## 11. Compatibility Note
Use Python 3.11 for the Azure Function locally (other versions may fail to load with current tooling).

