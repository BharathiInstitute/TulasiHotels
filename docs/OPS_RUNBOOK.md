# Tulasi Hotels Operations Runbook

## 1. Firebase Spending Alerts Setup

### Steps (GCP Console)

1. Go to **Google Cloud Console** Ã¢â€ â€™ **Billing** Ã¢â€ â€™ **Budgets & alerts**
2. Click **Create Budget**
3. Create the following alerts:

| Budget Name | Amount (Ã¢â€šÂ¹) | Alert Thresholds |
|------------|------------|-----------------|
| Tulasi Hotels Warning | 30,000/mo | 50%, 90%, 100% |
| Tulasi Hotels Caution | 50,000/mo | 80%, 100% |
| Tulasi Hotels Critical | 75,000/mo | 90%, 100% |
| Tulasi Hotels Hard Cap | 1,00,000/mo | 100% (with auto-cap) |

4. **Notification channels**: Add all admin emails
5. **Pub/Sub topic** (optional): Create `billing-alerts` topic for programmatic handling

### Firebase-specific Alerts (Cloud Monitoring)

```
Resource type: Cloud Firestore
Metric: document_reads
Threshold: > 5,000,000 / day (warn), > 10,000,000 / day (critical)

Resource type: Cloud Functions
Metric: function/execution_count
Threshold: > 100,000 / day

Resource type: Cloud Functions  
Metric: function/execution_times
Threshold: p95 > 10s
```

### Verification
- [ ] All 4 budget alerts created
- [ ] Notification emails confirmed
- [ ] Test alert triggered (set temporary low threshold)

---

## 2. Uptime Monitoring Setup

### Option A: UptimeRobot (Recommended Ã¢â‚¬â€ Free tier)

1. Sign up at https://uptimerobot.com
2. Add monitors:

| Monitor Name | URL | Check Interval | Alert |
|-------------|-----|----------------|-------|
| Tulasi Hotels Web | `https://tulasihotels.web.app` | 5 min | Email + Slack |
| Tulasi Hotels API | `https://asia-south1-tulasihotels.cloudfunctions.net/healthcheck` | 5 min | Email |

3. Set up status page at `status.restaurants.tulasierp.com` (optional)

### Option B: Google Cloud Monitoring (Native)

1. Go to **Cloud Monitoring** Ã¢â€ â€™ **Uptime Checks**
2. Create HTTPS check:
   - **Target**: `tulasihotels.web.app`
   - **Path**: `/`
   - **Check frequency**: 5 minutes
   - **Regions**: Asia Pacific, US
   - **Response check**: Status 200
3. Create alert policy:
   - **Condition**: Uptime check failure > 2 consecutive
   - **Notification**: Email + PagerDuty (if configured)

### SLO Definition

| Metric | Target | Measurement Window |
|--------|--------|-------------------|
| Availability | 99.5% | 30-day rolling |
| Response Time (p95) | < 3s | 30-day rolling |
| Error Rate | < 1% | 30-day rolling |

### Cloud Monitoring Alert Policies

Create in **Cloud Monitoring** Ã¢â€ â€™ **Alerting** Ã¢â€ â€™ **Create Policy**:

1. **Function Error Rate**: 
   - Metric: `cloudfunctions.googleapis.com/function/execution_count` filtered by `status != "ok"`
   - Threshold: > 5% of total executions over 5 min
   
2. **Firestore Latency**:
   - Metric: `firestore.googleapis.com/document/read_count`
   - Threshold: Sudden spike > 3x baseline

3. **Crashlytics Velocity**:
   - Configure in Firebase Console Ã¢â€ â€™ Crashlytics Ã¢â€ â€™ Velocity Alerts
   - Threshold: > 1% of sessions crashing

### Incident Response

| Severity | Response Time | Escalation |
|----------|--------------|------------|
| P1 (Down) | 15 min | All hands |
| P2 (Degraded) | 1 hour | On-call |
| P3 (Minor) | 4 hours | Next business day |

---

## 3. On-Call Rotation

Set up PagerDuty or Opsgenie rotation:
- Primary: Developer on duty
- Secondary: Backup developer
- Escalation: Team lead after 30 min

---

## 4. Backup & Recovery

### Firestore Exports
- Automated daily export via `scheduledFirestoreBackup` Cloud Function
- Stored in `gs://tulasihotels-backups/`
- Retention: 30 days

### Recovery Steps
1. Identify backup timestamp
2. `gcloud firestore import gs://tulasihotels-backups/YYYY-MM-DD`
3. Verify data integrity
4. Notify affected users

---

*Last updated: $(date)*
*Status: Ready for implementation*
