#!/bin/bash

set -e

BACKUP_FOLDER=/var/shared/assets
SKIP_TABLES=cache_bootstrap,cache_config,cache_container,cache_data,cache_default,cache_discovery,cache_dynamic_page_cache,cache_entity,cache_menu,cache_render,cachetags,watchdog,sessions,search_index,search_dataset,search_total


while read -r ALIAS DIRECTROY _; do

    BRANCH_NAME="$(echo $ALIAS | grep -Pe '[^.]*$' -o)"

    mkdir -p $BACKUP_FOLDER/$DIRECTROY/archive/$BRANCH_NAME
    drush "$ALIAS" sql-dump --skip-tables-list "$SKIP_TABLES" > $BACKUP_FOLDER/$DIRECTROY/archive/$BRANCH_NAME/$BRANCH_NAME-db-$(date +"%Y-%m-%d_%H-%M").sql
    ln -sf $BACKUP_FOLDER/$DIRECTROY/archive/$BRANCH_NAME/$(ls $BACKUP_FOLDER/$DIRECTROY/archive/$BRANCH_NAME -t | head -n1) $BACKUP_FOLDER/$DIRECTROY/$BRANCH_NAME.latest.sql

done < <(grep -v '^$\|^\s*\#' /etc/pantheon-backup-sites)
