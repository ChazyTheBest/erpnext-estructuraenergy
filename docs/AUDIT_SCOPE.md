Audit Scope & Guardrails
========================

Purpose
-------
This repository orchestrates an ERPNext deployment via Docker. Local scripts wrap the upstream `frappe_docker` project to provision Traefik, MariaDB, and ERPNext services, render environment files, configure a production site, and install a backup routine. The goal of every review or audit is to keep this deployment reliable, secure, and maintainable **without** diverging from upstream conventions unless there is a clear defect or risk.

In-Scope Surfaces
-----------------
- **Shell scripts** under `scripts/` that render secrets, start/stop stacks, configure the site, or install backups.
- **Compose overlays** in `compose/` and the pinned `config/site.env` that define networks, routers, and host metadata.
- **Makefile targets** or helper scripts that wrap the above artifacts.
- **Security posture** directly related to this stack (credential generation, HTTPS redirects, backups, access control).
- **Operational reliability** items such as idempotency, credential rotation, and data retention mechanics.

Out-of-Scope / Non-Goals
------------------------
- Rewriting or expanding `vendor/frappe_docker` (upstream is pinned; treat it as immutable).
- Changing ERPNext application code or bench customizations beyond what is required to bootstrap a site.
- Opinionated refactors, stylistic tweaks, or performance optimizations that do not mitigate a documented risk.
- Infrastructure beyond this host (e.g., S3 backups, external monitoring) unless explicitly requested.
- Introducing new services or broad architectural shifts (k8s, swarm, etc.) without a separate project brief.

Quality Bar & Acceptance Criteria
---------------------------------
Every proposed change should satisfy the following gates:
1. **Severity driven:** Only High/Critical or clear Medium issues (security, data loss, broken automation) must be addressed. Low-level “nice to haves” are advisory and should not block sign-off.
2. **Deterministic tooling:** `make lint` must succeed; no other mandatory tooling is required unless added here.
3. **Upstream compatibility:** Keep compatibility with `FRAPPE_DOCKER_COMMIT` and the pinned `ERPNEXT_VERSION`.
4. **Idempotency:** Provisioning scripts must remain safe to re-run against an already-provisioned deployment.
5. **Secret handling:** Never emit generated secrets to stdout beyond what is already logged; stored secrets must remain on disk within `secrets/` or `/etc/default` as documented.

Audit Checklist
---------------
When performing an audit/review:
1. Run `make lint`.
2. Inspect recent changes in `scripts/`, `compose/`, `config/`, and `Makefile`.
3. Validate backup automation (`scripts/60_backups_install.sh`) for path assumptions, retention, and credential usage.
4. Confirm ingress/SSL configuration (Traefik overlays) still enforces canonical hosts and certificates.
5. Review credential generation and rotations for strong defaults.
6. Note only findings that violate the quality bar above; everything else is informational.

Reporting Format
----------------
- List findings ordered by severity (`Critical`, `High`, `Medium`). Only include `Low` if they directly support a Medium+ fix or provide essential context.
- Each finding should reference `path:line` and contain a concise justification plus actionable remediation.
- Summaries should be brief; avoid enumerating additional exploratory work unless scoped in advance.

Future Changes
--------------
- If new tooling or checks become mandatory, record them here (e.g., integration tests, additional lint steps).
- If the deployment scope expands (new services, cloud storage, etc.), document the new surface area and update the out-of-scope list accordingly before requesting a fresh audit.
