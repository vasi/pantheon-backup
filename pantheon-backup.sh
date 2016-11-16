#!/bin/bash

set -e

BACKUP_FOLDER=/var/shared/assets
SKIP_TABLES=cache_bootstrap,cache_config,cache_container,cache_data,cache_default,cache_discovery,cache_dynamic_page_cache,cache_entity,cache_menu,cache_render,cachetags,watchdog,sessions,search_index,search_dataset,search_total


while read -r ALIAS DIRECTROY _; do
    mkdir -p $BACKUP_FOLDER/$DIRECTROY/
    drush "$ALIAS" sql-dump --skip-tables-list "$SKIP_TABLES" > $BACKUP_FOLDER/$DIRECTROY/"$(echo $ALIAS | grep -Pe '[^.]*$' -o)"-db-$(date +"%Y-%m-%d_%H-%M").sql
done < <(grep -v '^$\|^\s*\#' /etc/pantheon-backup-sites)
