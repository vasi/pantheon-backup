#!/bin/bash

set -e

CONFIG_FILE=${CONFIG_FILE:-/etc/pantheon-backup-sites}
BACKUP_FOLDER=${BACKUP_FOLDER:-/var/shared/assets}
SKIP_TABLES=cache_bootstrap,cache_config,cache_container,cache_data,cache_default,cache_discovery,cache_dynamic_page_cache,cache_entity,cache_menu,cache_render,cachetags,watchdog,sessions,search_index,search_dataset,search_total

grep -o -E '^[^#]+' "$CONFIG_FILE" | while read CONFIGS; do
    ALIAS="$(echo "$CONFIGS" | awk -F: '{print $1}')"
    DIRECTORY="$(echo "$CONFIGS" | awk -F: '{print $2}')"
    BRANCH_NAME="$(echo "$ALIAS" | awk -F. '{print $NF}')"
    echo "Fetching $ALIAS"

    DIR="$BACKUP_FOLDER/$DIRECTORY/archive/$BRANCH_NAME"
    mkdir -p "$DIR"

    DATE="$(date +%F-%R)"
    FILE="$DIR/$BRANCH_NAME-$DATE.sql.gz"
    drush "$ALIAS" sql-dump --gzip --skip-tables-list "$SKIP_TABLES" > "$FILE" \
      < /dev/null
    gzip -cd < "$FILE" > "$DIR/$BRANCH_NAME.sql"
done
