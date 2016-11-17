#!/bin/bash

set -e

CONFIG_FILE=${CONFIG_FILE:-/etc/pantheon-backup-sites}
BACKUP_FOLDER=${BACKUP_FOLDER:-/var/shared/assets}
SKIP_TABLES=cache_bootstrap,cache_config,cache_container,cache_data,cache_default,cache_discovery,cache_dynamic_page_cache,cache_entity,cache_menu,cache_render,cachetags,watchdog,sessions,search_index,search_dataset,search_total

grep -E '^[^#]+' "$CONFIG_FILE" | while read CONFIGS; do
    ALIAS="awk -F ":" '{print \$1}' < <(echo $CONFIGS)"
    DIRECTORY="awk -F ":" '{print \$2}' < <(echo $CONFIGS)"

    BRANCH_NAME="$(eval $ALIAS | grep -Pe '[^.]*$' -o)"

    mkdir -p $BACKUP_FOLDER/$(eval $DIRECTORY)/archive/$BRANCH_NAME
    drush "$(eval $ALIAS)" sql-dump --skip-tables-list "$SKIP_TABLES" > $BACKUP_FOLDER/$(eval $DIRECTORY)/archive/$BRANCH_NAME/$BRANCH_NAME-db-$(date +"%Y-%m-%d_%H-%M").sql
    ln -sf $BACKUP_FOLDER/$(eval $DIRECTORY)/archive/$BRANCH_NAME/$(ls $BACKUP_FOLDER/$(eval $DIRECTORY)/archive/$BRANCH_NAME -t | head -n1) $BACKUP_FOLDER/$(eval $DIRECTORY)/$BRANCH_NAME.latest.sql

done
