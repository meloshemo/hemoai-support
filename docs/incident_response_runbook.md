# Incident Response Runbook – HemoAI

_Version 1.0 • Last updated: 2025-11-10_

## 1. Purpose
Provide a repeatable procedure for detecting, triaging, containing and reporting security incidents involving HemoAI systems and user data (including hemogram and other sensitive health information).

## 2. Stakeholders & Roles
| Role | Name / Contact | Responsibilities |
|------|----------------|------------------|
| Incident Commander (IC) | _Assign_ | Overall coordination, decision making, communication with execs |
| Deputy IC | _Assign_ | Backup for IC, handles documentation |
| Security Lead | _Assign_ | Technical investigation, containment, eradication |
| Engineering Lead | _Assign_ | Application fixes, deployments |
| Legal / Compliance | _Assign_ | Regulatory obligations (KVKK/GDPR/HIPAA) |
| Communications Lead | _Assign_ | User & media notifications |
| Support Lead | _Assign_ | Handle inbound user queries |
| DPO | _Assign_ | Supervisory authority liaison, DPIA updates |

Maintain this table in sync with team changes. All members must be reachable 24/7 via on-call rota.

## 3. Incident Classification Matrix
| Severity | Definition | Examples | Notification Requirement |
|----------|------------|----------|--------------------------|
| SEV-1 (Critical) | Confirmed compromise of health data, active exploitation, availability loss > 4h | Database breach, ransomware, widespread phishing success | Notify management immediately; regulatory authority ≤72h; users without undue delay |
| SEV-2 (High) | Potential exposure or major service disruption | Misconfigured access rules, credential leak | Management within 2h; evaluate notification |
| SEV-3 (Moderate) | Contained incident with minimal impact | Targeted credential stuffing blocked, minor DoS | Log internally, monitor |
| SEV-4 (Low) | False positives, routine alerts | Failed login flood | Log and close |

## 4. Response Lifecycle
1. **Preparation**
   - Up-to-date inventories, logging, monitoring, backups.
   - Team trained annually; run tabletop exercises.
2. **Identification**
   - Confirm incident via logs (Firebase, Cloud Logging, SendGrid, Stripe), IDS alerts, user reports.
   - Document initial findings in incident ticket (`/docs/incidents/YYYYMMDD-<slug>.md`).
3. **Containment**
   - Short-term: disable compromised credentials, revoke API keys, block malicious IPs with Cloud Armor.
   - Long-term: patch vulnerabilities, rotate secrets, strengthen monitoring.
4. **Eradication**
   - Remove malware, backdoors, malicious accounts.
   - Validate system integrity (checksums, code reviews).
5. **Recovery**
   - Restore services from clean backups.
   - Closely monitor metrics for recurrence.
6. **Lessons Learned**
   - Post-incident review within 5 business days.
   - Update DPIA, security controls, training.

## 5. 72-Hour Reporting Timeline (KVKK/GDPR/HIPAA)
- **Hour 0**: Incident detected, IC appointed, severity assigned.
- **≤12h**: Gather facts, identify impacted data subjects and jurisdictions.
- **≤24h**: Draft notification material (authority + user templates).
- **≤72h**: Submit reports to KVKK Authority & relevant EU supervisory authority; HIPAA covered entities within 60 days (if applicable).
- Maintain evidence trail: logs, emails, screenshots, forensic images.

## 6. Communication Templates
Store editable templates in `/legal/incident_notifications/`:
- Authority notification (KVKK/GDPR) – include nature of breach, categories, mitigation.
- User notification – plain language, recommended precautions, support contact.
- Media statement (if required).

## 7. Tooling & Access
- **Logging:** Firebase Crashlytics, Cloud Logging, Supabase logs (future).
- **Monitoring:** Alerting via Google Cloud Monitoring (email/SMS/Slack).
- **Forensics:** Retain VM snapshots, database exports.
- **Ticketing:** Use incident ticket template, assign IC.
- **Secure comms:** Encrypted Slack channel or Signal group for incident team.

## 8. After-Action Checklist
- [ ] Incident timeline documented.
- [ ] Root cause identified.
- [ ] Vulnerabilities patched.
- [ ] Secrets rotated.
- [ ] Users/regulators notified (if required).
- [ ] Financial/contractual obligations assessed (e.g., penalties, credits).
- [ ] Post-mortem published internally; action items assigned with due dates.

## 9. Maintenance
- Review runbook quarterly.
- Update contact list and tooling descriptions immediately after changes.
- Archive closed incidents in `/docs/incident_archive/`.

---

**Note:** Replace placeholders, fill in names, and obtain management approval. Without full execution this runbook serves as a template only.***

