# Nextcloud Upgrade Runbook

>**Note**
>
> Environment-specific data (domains, IP addresses, app versions, credentials) is intentionally excluded.

## Environment

- OS: Ubuntu
- Web server: Nginx
- PHP
- Database: SQLite
- Cache: Redis + APCu

## Pre-upgrade checklist

- [ ] Verify backup availability
- [ ] Check disk space
- [ ] Check Nextcloud status
- [ ] Backup SQLite database (sqlite3 /path/to/ncdata/owncloud.db ".backup /path/to/nextcloud-db-backup-$(date +%Y%m%d).db")
- [ ] Download target Nextcloud release from stable branch (wget -c https://download.nextcloud.com/server/releases/nextcloud-x.y.z.zip)

## Upgrade procedure

1. Create rollback point:
   - Boot storage snapshot

2. Enable maintenance mode

```
sudo -u www-data php occ maintenance:mode --on
```

3. Rename current installation:

```
mv /var/www/nextcloud /var/www/nextcloud.old
```

4. Unzip and mv /tmp/nc /var/www/nextcloud + chown -R www-data:www-data /var/www/nextcloud
5. Perform application upgrade:

```
sudo -u www-data php /var/www/nextcloud/occ upgrade
```

6. Verify application health:

```
systemctl status nginx
systemctl status phpX.X-fpm
```

## Post-upgrade verification

- Check Nextcloud status:

```
sudo -u www-data php /var/www/nextcloud/occ status
```
and
```
grep -E "OC_VersionString|OC_Version" /var/www/nextcloud/version.php
```

- Rebuild db indexes:

```
sudo -u www-data php /var/www/nextcloud/occ db:add-missing-indices
```

- Run database repair:

```
sudo -u www-data php /var/www/nextcloud/occ maintenance:repair
```

- Review application logs
- Switch maintenance mode off:

```
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off
```
- Confirm user access

## Rollback procedure

If upgrade fails:

1. Enable maintenance mode
2. Restore application directory
3. Restore database backup
4. Verify services
5. Disable maintenance mode

