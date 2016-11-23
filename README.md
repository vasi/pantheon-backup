# Pantheon Backup Script

_Quick Usage_: Clone this repository, edit config, add drush aliases, and create a cron to run `pantheon-backup.sh` periodically.

## How to Install

- Download and install `drush`
- Login to Pantheon in your web browser.
- Click `Drush Aliases` to download all `drush` aliases for said Pantheon account.
- Create a `drush` alias config file where `drush` is installed (if installed with composer this is located in `vendor/drush/drush`)

  - This file must be called `prefix.aliases.drushrc.php` you may replace `prefix` with whatever prefix you desire. Multiple `prefix.aliases.drushrc.php` may exist.
  - Copy and past the desired aliases from the `pantheon.aliases.drushrc.php`file that you downloaded from Pantheon into your `prefix.aliases.drushrc.php` file.

- Run `drush sa` to verify available aliases.
- Add SSH key for user that will be running the backup script to pantheon.
- Add a cron to run this script.

You may want to create a new user on the system who's purpose is solely to run this cron with it's own SSH key for added security.

## Overview

This script will take an example config such as this and automatically back up databases with the below filesystem structure.

```
# Drawn & Quarterly
@pantheon.drawn-quarterly.live:dnq
@pantheon.drawn-quarterly.dev:dnq
```

The above config will generate the fallowing filesystem structure when backing up databases.

```
/var/shared
`-- assets
    `-- dnq
        `-- archive
            |-- dev
            |   |-- dev-2016-11-23-18:44.sql.gz
            |   |-- dev-2016-11-23-18:46.sql.gz
            |   `-- dev.sql
            `-- live
                |-- live-2016-11-23-18:44.sql.gz
                |-- live-2016-11-23-18:46.sql.gz
                `-- live.sql
```

The sql.gz files are archives. Each time the script is run a new archive is created with it's time stamp. The `dev.sql` and `live.sql` files that you see are the extracted latest version of this database. Each time the script is run `dev.sql` and `live.sql` will be overwritten with the latest version.

## Modifying Config

The `config` file fallows the below format.

`@alias.pantheon_branch:folder:table_prefix`

The `:` is used as a field separator that denotes different columns.

The first column is your drush alias. This will always start with `@` symbol. The available aliases can be viewed by running the command `drush sa`. The script anticipates the alias to conform to Pantheons formatting. For example an alias may be `@pantheon.drawn-quarterly.live`. The `.live` part denotes the branch on pantheon (eg. live, test, dev), the script fetches the last word in the alias with a `.` prefix in front of it and makes a directory corresponding to the databases of which those branches are saved under.

The second column denotes the folder in `/var/shared/assets` to save these backups in. The branch (eg. `.live`) is saved the a sub directory created in the `folder`.

The third column is optional. This column denotes the `table_prefix`. Should the Drupal installation being backedup use a table_prefix then this must be defined so the script is aware of it. The `table_prefix` has no effect on the filesystem layout of the backup folder.
