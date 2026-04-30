# MikroTik Google Sheets Sync Automation

This project provides a lightweight automation system to synchronize **MikroTik RouterOS PPPoE secrets** and **local system users** from **Google Sheets**, using **Google Apps Script as a REST endpoint** and **RouterOS scripts for synchronization**.

The goal is to allow centralized account management from Google Sheets while MikroTik routers automatically pull and apply updates on schedule.

---

# Overview

The system consists of:

1. **Google Sheets**

   * Stores PPPoE accounts
   * Stores RouterOS system users

2. **Google Apps Script**

   * Publishes sheet data as plain text endpoints

3. **MikroTik RouterOS Scripts**

   * Fetch remote data
   * Parse account records
   * Create, update, disable, or remove accounts

4. **Scheduler Tasks**

   * Automatically run synchronization scripts at intervals

---

# Architecture

```text id="v01x8r"
Google Sheets
    ↓
Google Apps Script Web App
    ↓
HTTPS endpoint:
?action=pppoe
?action=user
    ↓
MikroTik RouterOS Fetch
    ↓
Sync PPP Secrets / System Users
```

---

# Google Sheets Layout

---

# 1. PPPoE Sheet

The `pppoe` sheet stores PPPoE user accounts.

### Columns:

| Column |  Purpose |
| ------ | -------: |
| A      | Username |
| B      | Password |
| C      |  Profile |
| D      |   Status |

### Example:

```text id="g3h0qk"
username | password | profile | status
DAVR0000 | DAr0o9sT | B4 | active
MILK0000 | MIka18rN | B1 | suspended
```

### Status values:

* `active`
* `suspended`

---

# 2. System User Sheet

The `user` sheet stores RouterOS local users.

### Columns:

| Column |  Purpose |
| ------ | -------: |
| A      | Username |
| B      | Password |
| C      |   Status |

### Example:

```text id="u74q3s"
username   | password      | status
SuperAdmin | SuperPassword | active
```

### Status values:

* `active`
* `suspended`

---

# Google Apps Script API

Google Apps Script reads data from the sheets and exposes it as a plain text feed.

Example endpoints:

```text id="4m6y0n"
https://script.google.com/macros/s/YOUR_DEPLOYMENT_ID/exec?action=pppoe
https://script.google.com/macros/s/YOUR_DEPLOYMENT_ID/exec?action=user
```

These endpoints return:

---

## PPPoE Output

```text id="q7k8d2"
DAVR0000|password|B4|active
MILK0000|password|B1|suspended
```

---

## User Output

```text id="b9x5r1"
SuperAdmin|SuperPassword|active
```

---

# MikroTik Sync Scripts

Two RouterOS scripts are used:

---

# 1. `sync_pppoe.rsc`

Synchronizes `/ppp secret` entries.

### Actions:

* Downloads PPPoE records from Apps Script
* Creates missing PPP secrets
* Updates profile and disabled state
* Disables users removed from the sheet
* Removes users already disabled and still missing
* Tags managed entries with:

```routeros id="i4c2nm"
comment=gsync
```

---

# 2. `sync_user.rsc`

Synchronizes `/user` accounts.

### Actions:

* Downloads user records from Apps Script
* Creates missing local users
* Enables/disables based on status
* Disables removed users
* Removes previously disabled users still absent
* Tags managed users with:

```routeros id="r7m9ta"
comment=gsync
```

---

# IMPORTANT: Replace the Web App URL

In both MikroTik scripts, replace:

```routeros id="s8l4ve"
https://script.google.com/macros/s/YOUR_DEPLOYMENT_ID/exec
```

with your actual deployed Apps Script URL.

Then append the action parameter:

---

## PPPoE Script URL

```routeros id="j9d2ok"
?action=pppoe
```

Example:

```routeros id="n1q7yu"
:local url "https://script.google.com/macros/s/YOUR_DEPLOYMENT_ID/exec?action=pppoe"
```

---

## User Script URL

```routeros id="z2w6mc"
?action=user
```

Example:

```routeros id="e5v1ph"
:local url "https://script.google.com/macros/s/YOUR_DEPLOYMENT_ID/exec?action=user"
```

---

# Deployment Steps

---

# 1. Create the Google Sheets

Create:

* `pppoe` sheet
* `user` sheet

Use the layouts described above.

---

# 2. Deploy the Google Apps Script

Deploy as:

```text id="f2p9ga"
Web App
```

Access:

```text id="d7u4kr"
Anyone with the link
```

Copy the generated deployment URL.

---

# 3. Upload RouterOS Scripts

Create the RouterOS scripts:

* `sync_pppoe`
* `sync_user`

Paste the provided `.rsc` script contents.

---

# 4. Update URLs

Replace the placeholder URL in each script with your deployment URL and the correct action parameter:

```routeros id="k8y3mw"
?action=pppoe
?action=user
```

---

# 5. Create Scheduler Tasks

Create scheduled tasks so MikroTik automatically syncs the data.

---

## PPPoE Scheduler

```routeros id="x6t1fj"
/system scheduler add \
    name=sync-pppoe \
    interval=5m \
    on-event=sync_pppoe
```

---

## User Scheduler

```routeros id="c3n7lu"
/system scheduler add \
    name=sync-user \
    interval=5m \
    on-event=sync_user
```

This makes the router automatically pull updates every 5 minutes.

---

# Logging

Synchronization events are logged in RouterOS:

```text id="m9s4aq"
PPP UPDATED: DAVR0000
PPP CREATED: NEWUSER0001
USER DISABLED: SuperAdmin
User CREATED: admin2
```

This provides visibility into all automated changes.

---

# Safety Notes

---

# 1. Managed Entries Only

Only accounts with:

```routeros id="a5h2dx"
comment=gsync
```

are managed by the scripts.

This prevents interference with manually created accounts.

---

# 2. Local Users Are Created With Full Permissions

Current user sync creates accounts with:

```routeros id="l4v9bn"
group=full
```

This grants full administrative rights.

For production deployments, it is strongly recommended to:

* create a restricted group
* replace `group=full` with least-privilege permissions

---

# 3. Public Web App Endpoint

The Apps Script endpoint is publicly accessible by URL.

This means:

* anyone with the URL can retrieve usernames
* passwords are transmitted in plaintext from the script output

This is acceptable for testing, but **not recommended for production**.

Production improvements should include:

* token authentication
* IP restrictions
* encrypted credentials
* limited permissions

---

# Future Improvements

Planned enhancements:

* Password change detection
* API authentication token
* Hash verification of downloaded data
* Retry logic for failed downloads
* Error alerting
* Secure credential handling
* Better rollback behavior
* Group synchronization for system users

---

# Purpose

This project was built as a lightweight centralized synchronization solution for MikroTik routers where:

* Google Sheets acts as the control panel
* Google Apps Script acts as the API
* MikroTik automatically applies changes

It is intended as a working foundation that can be expanded into a more secure and production-ready management platform.

---

# License

MIT License
