#!/bin/bash

# Restores a Postgres database with TimescaleDB from pg_dump file
# 1. Creates db user with password
# 2. Creates a new database of the same name as the user
# 3. Grants ownership and priviliges of new database to the user
# 4. Creates Timesacle extension on new database
# 5. Runs the timescale pre-restore function
# 6. Executes the pg_restore to new database using file passed
# 7. Runs the timescale post-restore function

set -euo pipefail

usage() {
        echo "Usage: $0 -u <postgres-user> -p <postgres-user-password> <path/to/restore/file> [-h for help]"
}

run_db_command() {
        local OPTIND=1
        local db=""
        while getopts "d:" opt; do
                case $opt in
                  d) db=${OPTARG} ;;
                  *) 
                    echo "Invalid option passed to run_db_command"
                    exit 1
                    ;;
                esac
        done
        shift $((OPTIND - 1))
        local sql_command="$1"

        if [[ -n "$db" ]]; then
                sudo -u postgres psql -X -d "$db" -c "$sql_command"
        else
                sudo -u postgres psql -X -c "$sql_command"
        fi
}

while getopts "u:p:h" opt; do
        case $opt in 
                u) user=${OPTARG} ;;
                p) password=${OPTARG} ;;
                h)
                  usage
                  exit 0
                  ;;
                \?) 
                  echo "Invalid option: -$OPTARG" 
                  usage
                  exit 1
                  ;;
                :) 
                  echo "Option -$opt requires an argument" 
                  usage
                  exit 1
                  ;; 
        esac
done

shift $((OPTIND - 1))
file="$1"

echo "User $user"
echo "Password $password"
echo "File $file"


run_db_command "CREATE USER $user WITH PASSWORD '$password';"

echo "Created user $user"

run_db_command "CREATE DATABASE $user;"

echo "Created database $user"

run_db_command "ALTER DATABASE $user OWNER TO $user;" 

echo "Set owner of database $user to $user"

run_db_command "GRANT ALL PRIVILEGES ON DATABASE $user to $user;" 

echo "Granted all privileges on database $user to $user"

run_db_command "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $user;" 

echo "Granted all privileges in public schema in database $user to $user"

echo "Creating timescale extension on database $user.."

run_db_command -d "$user" "CREATE EXTENSION IF NOT EXISTS timescaledb;"

echo "Running timescale pre restore command.."

run_db_command -d "$user" "SELECT timescaledb_pre_restore();"

echo "Ready for restore.."

sudo -u postgres pg_restore -Fc -v -d "$user" "$file"

echo "Restore OK, running timescale post-restore command.."

run_db_command -d "$user" "SELECT timescaledb_post_restore();"

echo "Done. Post-restore complete, database is ready to run."