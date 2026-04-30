# MikroTik RouterOS User Sync via Google Sheets

This project provides a **RouterOS script** that synchronizes local MikroTik users with data provided by a **Google Apps Script web endpoint**.

It was created as a lightweight solution for centrally managing MikroTik `/user` accounts from a remote data source.

---

## Features

The script performs the following actions:

* Downloads a user feed from a remote HTTPS endpoint
* Parses user records in the format:

```txt
username|password|status
```

* Creates missing users
* Enables or disables users based on status
* Tags managed users using a comment identifier
* Detects users removed from the source feed
* Disables or removes users no longer present in the feed
* Logs all changes to the MikroTik system log

---

## Managed User Format

The remote endpoint must return plain text records in this format:

```txt
admin1|password123|active
admin2|password456|suspended
```

### Fields

| Field      |             Description |
| ---------- | ----------------------: |
| `username` | MikroTik local username |
| `password` |   Password for the user |
| `status`   | `active` or `suspended` |

---

## Script Behavior

### 1. Download User Feed

The script fetches the latest user list from:

```routeros
https://script.google.com/macros/s/.../exec?action=user
```

and stores it locally as:

```routeros
user_sync.txt
```

---

### 2. Parse Records

Each line is split into:

```txt
username | password | status
```

Malformed lines are skipped and logged.

---

### 3. Sync Users

For every valid record:

* If the user does not exist, it is created
* If the user exists, the script checks:

  * whether the account should be disabled
* Updates only happen when required

Managed users are tagged with:

```routeros
comment=gsync
```

---

### 4. Reconcile Removed Users

After syncing, the script checks all tagged users:

* If a tagged user is **missing from the source feed**, it is disabled
* If it is already disabled, it is removed

This creates a two-stage cleanup process:

1. Missing user → disable account
2. Missing again → remove account

---

## Example Workflow

### Source feed contains:

```txt
alice|pass123|active
bob|pass456|suspended
```

### Result:

* `alice` → created or enabled
* `bob` → created or disabled

If `alice` is later removed from the feed:

* First sync → `alice` is disabled
* Next sync → `alice` is removed

---

## Installation

### 1. Upload Script

Save the script on the MikroTik router:

```routeros
/system script add name=sync_user source={...}
```

Or paste the script contents into a new RouterOS script.

---

### 2. Schedule Execution

Create a scheduler entry:

```routeros
/system scheduler add \
    name=user-sync \
    interval=5m \
    on-event=sync_user
```

This runs the synchronization every 5 minutes.

---

## Logging

The script writes events to the MikroTik log:

```txt
User CREATED: alice
User UPDATED: bob
USER DISABLED: charlie
USER ALREADY DISABLED: charlie
```

This allows visibility into synchronization changes.

---

## Current Limitations

This is the first working implementation and has room for improvement.

### Current limitations:

* Password changes are **not detected**
* User group changes are **not synchronized**
* No retry/error handling for failed downloads
* No checksum or change detection on source file
* Entire file is parsed manually line-by-line
* No rollback logic if partial sync fails

---

## Planned Improvements

Potential future enhancements:

* Detect and update password changes
* Support group assignment from the feed
* Improve parser efficiency
* Add HTTPS fetch validation
* Implement source integrity checks
* Add better failure handling and alerting
* Improve cleanup logic to avoid immediate removal on repeated failures

---

## Safety Note

The script creates users with:

```routeros
group=full
```

This grants **full administrative access**.

For production use, it is strongly recommended to:

* create a dedicated limited-access group
* assign users to the minimum required permissions

---

## Purpose

This project was built as a **quick functional prototype** to prove remote user synchronization on MikroTik RouterOS.

It is intentionally simple, but provides a solid base for building a more robust centralized account management system.

---

## License

MIT License
