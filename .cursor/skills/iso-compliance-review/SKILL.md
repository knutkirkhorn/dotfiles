---
name: iso-compliance-review
description: Reviews code and repository evidence for potential gaps against ISO/IEC 27001:2022 and ISO 9001:2015, including their 2024 climate-action amendments. Use when assessing a repository for information-security or quality-management compliance readiness and producing an evidence-based remediation report.
---

# ISO Compliance Review

Assess repository evidence against:

- ISO/IEC 27001:2022 and Amendment 1:2024
- ISO 9001:2015 and Amendment 1:2024

## Boundaries

- Treat this as a readiness and gap assessment, not certification, legal advice, or proof of organization-wide compliance
- Do not infer that a control operates effectively merely because code or documentation exists
- Do not reproduce copyrighted standard text; identify clauses and control themes only
- Mark requirements needing organizational or operational evidence as `Not evidenced`, and state what an auditor would need
- Ask for the organization's licensed standards, Statement of Applicability, audit scope, risk criteria, and quality objectives when an authoritative clause-by-clause assessment is required

## Review workflow

1. Establish scope:
   - Repository, product, services, environments, and organizational boundaries
   - Applicable legal, contractual, customer, and regulatory requirements
   - Exclusions and justified non-applicability
2. Inventory available evidence before judging it:
   - Policies, ownership files, architecture and data-flow documentation
   - Risk register, threat models, Statement of Applicability, and treatment plans
   - CI/CD, tests, reviews, releases, change controls, and deployment approvals
   - Dependency, secret, vulnerability, backup, logging, monitoring, and incident controls
   - Requirements, acceptance criteria, quality objectives, metrics, defects, and corrective actions
   - Supplier controls, training records, internal audits, and management reviews
3. Inspect relevant source, configuration, history, and automation. Never expose secret values in the report
4. Map evidence and gaps to the review areas below
5. Report only claims supported by cited repository evidence. Separate observations from assumptions

## ISO/IEC 27001 review areas

Cover management-system clauses 4–10:

- Organizational context, interested parties, ISMS scope, and climate-change relevance
- Leadership, policy, responsibilities, and accountability
- Risk assessment, risk treatment, security objectives, and change planning
- Resources, competence, awareness, communication, and controlled documented information
- Operational planning and execution of risk treatment
- Monitoring, measurement, internal audit, and management review
- Nonconformity, corrective action, and continual improvement

Review applicable Annex A themes without assuming every control applies:

- Organizational: policies, roles, segregation, asset and information classification, access, suppliers, cloud services, incidents, continuity, legal obligations, privacy, independent review, compliance, and operating procedures
- People: screening, employment terms, awareness, disciplinary processes, role changes, confidentiality, remote work, and event reporting
- Physical: boundaries, entry, monitoring, environmental threats, secure areas, equipment, media, utilities, cabling, maintenance, and disposal
- Technological: identity and access, authentication, capacity, malware, vulnerabilities, configuration, deletion, masking, data-loss prevention, backups, redundancy, logging, monitoring, time synchronization, privileged tools, software installation, network security, cryptography, secure development, application security, architecture, coding, testing, outsourced development, environment separation, change management, test data, and audit-test protection

For secure-development evidence, inspect at minimum:

- Authentication, authorization, session management, input validation, output encoding, and error handling
- Secret and key management, encryption choices, personal-data handling, retention, and deletion
- Dependency pinning and updates, software composition analysis, provenance, and build integrity
- Branch protection indicators, peer review, automated tests, static analysis, secret scanning, and release approvals
- Logging without sensitive-data leakage, alerting, incident hooks, backups, recovery, and resilience
- Infrastructure-as-code defaults, least privilege, network boundaries, environment separation, and hardened configuration

## ISO 9001 review areas

Cover management-system clauses 4–10:

- Organizational context, interested parties, QMS scope, processes, and climate-change relevance
- Customer focus, quality policy, responsibilities, and accountability
- Risks and opportunities, measurable quality objectives, and controlled change planning
- Resources, competence, awareness, communication, organizational knowledge, and controlled documented information
- Operational planning, requirements review, design and development, externally provided processes, production or service provision, release, and nonconforming outputs
- Customer feedback, process and product metrics, analysis, internal audit, and management review
- Nonconformity, root-cause analysis, corrective action, and continual improvement

For software-quality evidence, inspect at minimum:

- Traceability from customer or product requirements to acceptance criteria, implementation, tests, and releases
- Defined review, verification, validation, approval, and change-control responsibilities
- Reproducible builds, versioning, release records, rollback, migration, and configuration control
- Test strategy and evidence across relevant levels, including regression and failure-path testing
- Defect handling, escaped-defect analysis, root cause, corrective actions, and effectiveness checks
- Supplier and dependency evaluation, acceptance criteria, monitoring, and re-evaluation
- Quality objectives and trends such as reliability, availability, performance, defects, support outcomes, or delivery predictability

## Rating rules

Assign each finding one evidence status:

- `Supported`: repository evidence directly supports the requirement within the assessed scope
- `Partial`: some evidence exists, but coverage, operation, ownership, or effectiveness is incomplete
- `Not evidenced`: no sufficient evidence was found; this does not prove the control is absent
- `Not applicable`: applicability is explicitly justified and consistent with scope and risk treatment

Assign gaps a severity:

- `Critical`: credible immediate risk of severe security, legal, safety, or customer harm
- `High`: major control failure or likely systemic nonconformity
- `Medium`: meaningful weakness that could undermine consistent operation or auditability
- `Low`: limited weakness, documentation issue, or improvement opportunity

Do not calculate a compliance percentage. ISO conformity is not established by averaging controls.

## Output format

Produce:

```markdown
# ISO 27001 and ISO 9001 readiness review

## Scope and limitations

[Assessed scope, available evidence, exclusions, assumptions, and why this is not certification]

## Executive summary

[Overall readiness, strongest evidence, largest risks, and priority actions]

## Findings

### [ID] [Short finding] — [Severity]

- Standards: [ISO/IEC 27001 clause/control theme; ISO 9001 clause where relevant]
- Evidence status: [Supported | Partial | Not evidenced | Not applicable]
- Evidence: [`path:line` citations and relevant repository behavior]
- Gap: [Specific missing, ineffective, or unverified element]
- Risk: [Concrete consequence]
- Remediation: [Smallest practical corrective action, owner/evidence needed, and verification method]

## Evidence unavailable from the repository

[Operational and organizational artifacts needed to complete the assessment]

## Prioritized remediation plan

1. [Immediate]
2. [Near term]
3. [Longer term]

## Positive evidence

[Supported practices worth preserving]
```

Use exact paths and line numbers. Consolidate findings with the same root cause. If no gap is found in an area, say what was inspected and avoid claiming full compliance.
