#!/bin/bash

set -e

CONFIG_FILE=${CONFIG_FILE:-/etc/pantheon-backup-sites}
BACKUP_FOLDER=${BACKUP_FOLDER:-/var/shared/assets}
SKIP_TABLES='cache*,watchdog,sessions,search_index,search_dataset,search_total'

grep -o -E '^[^#]+' "$CONFIG_FILE" | while read CONFIGS; do
    ALIAS="$(echo "$CONFIGS" | awk -F: '{print $1}')"
    DIRECTORY="$(echo "$CONFIGS" | awk -F: '{print $2}')"
    PREFIX="$(echo "$CONFIGS" | awk -F: '{print $3}')"
    BRANCH_NAME="$(echo "$ALIAS" | awk -F. '{print $NF}')"

    # Make sure the site has a new enough Drush version
    DRUSH_VERSION="$(drush --strict=0 "$ALIAS" version --pipe < /dev/null)"
    if echo "$DRUSH_VERSION" | grep -q -E '^[123456]\.'; then
      echo "Drush version $DRUSH_VERSION for site $ALIAS is too old, skipping"
      continue
    fi

    echo "Fetching $ALIAS"

    DIR="$BACKUP_FOLDER/$DIRECTORY/archive/$BRANCH_NAME"
    mkdir -p "$DIR"

    # Add a prefix to the tables
    TABLES=$(echo "$SKIP_TABLES" | sed -Ee "s/(^|,)/\1$PREFIX/g")

    DATE="$(date +%F-%R)"
    FILE="$DIR/$BRANCH_NAME-$DATE.sql.gz"


    if drush "$ALIAS" sql-dump --structure-tables-list "$TABLES" --gzip \
        > "$FILE" < /dev/null; then
      gzip -cd < "$FILE" > "$DIR/$BRANCH_NAME.sql"
    else
      echo "Error fetching $ALIAS"
    fi
done
