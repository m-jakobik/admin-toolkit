# DR - Oracle Cloud VPS Disaster Recovery Documentation #

> **Note**
> 
> This document describes the recovery procedure only.
> Environment-specific information (OCIDs, IP addresses, credentials, hostnames) is intentionally excluded and stored in private documentation.


## Prerequisites

- Recovery account
- OCI Console access
- Recovery VM
- Snapshot (OCI)


## Recovery account

Purpose:
Emergency SSH access during instance recovery.

Configuration:
- dedicated recovery user
- password authentication enabled
- sudo access configured

Environment-specific configuration:
- see private documentation for environment-specific details.


# Symptoms

- SSH unavailable
- Services unavailable
- Instance running but unreachable


## OCI RECOVERY

Workflow:

1. Create Snapshot

2. Stop Main Instance

3. Detach Boot Volume from Main

4. Attach Boot Volume to Recovery Instance

5. Mount Filesystem

6. Inspect

7. Repair

8. Detach from Recovery

9. Attach back to Main

10. Boot&Verify instance


## Verification Checklist

### Access
- [ ] SSH

### Web stack
- [ ] HTTP/HTTPS
- [ ] nginx
- [ ] php-fpm

### Applications
- [ ] redis
- [ ] nextcloud

### Monitoring
- [ ] netdata
- [ ] fail2ban


### Automation
- [ ] certificate valid
- [ ] backup jobs
- [ ] cron jobs


## Boot Volume

see private documentation


## Lessons Learned

- Always create an OCI snapshot before making changes.
- Test SSH after modifying sshd_config.
