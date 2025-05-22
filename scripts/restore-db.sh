#!/bin/bash
set -e

# Function to log messages with timestamps
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1"
}

log "Starting SQL Server container setup..."

# Check if the backup file exists
if [ ! -f "/opt/mssql/backup/AdventureWorksDW.bak" ]; then
    log "ERROR: AdventureWorksDW.bak file not found at expected location"
    log "Please ensure the backup file is correctly mounted in the container"
    exit 1
fi

# Start SQL Server in the background
log "Starting SQL Server..."
/opt/mssql/bin/sqlservr &
SQLSERVR_PID=$!

# Wait for SQL Server to start
log "Waiting for SQL Server to start (this may take a minute)..."
for i in {1..120}; do
    # Check if SQL Server is accepting connections
    if /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -C -Q "SELECT 1" &>/dev/null; then
        log "SQL Server is now ready"
        break
    fi
    
    # Check if SQL Server process is still running
    if ! kill -0 $SQLSERVR_PID &>/dev/null; then
        log "ERROR: SQL Server process has terminated unexpectedly"
        exit 1
    fi
    
    log "Waiting for SQL Server to start... ($i/120)"
    sleep 2
done

# Check if we timed out waiting for SQL Server
if [ $i -eq 120 ]; then
    log "ERROR: Timed out waiting for SQL Server to start"
    log "Check SQL Server logs for more information"
    exit 1
fi

# Execute the restore command
log "Starting database restore process... this may take a few minutes"
RESTORE_OUTPUT=$(/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -C -Q "RESTORE DATABASE AdventureWorksDW FROM DISK = '/opt/mssql/backup/AdventureWorksDW.bak' WITH MOVE 'AdventureWorksDW2022' TO '/var/opt/mssql/data/AdventureWorksDW.mdf', MOVE 'AdventureWorksDW2022_log' TO '/var/opt/mssql/data/AdventureWorksDW_log.ldf', RECOVERY, REPLACE" 2>&1)
RESTORE_STATUS=$?

if [ $RESTORE_STATUS -ne 0 ]; then
    log "ERROR: Database restore failed with status $RESTORE_STATUS"
    log "Restore output: $RESTORE_OUTPUT"
    exit 1
fi

log "Database restore completed successfully!"
log "AdventureWorksDW database is now available"

# Keep the container running by waiting for the SQL Server process
log "SQL Server is running. Container will remain active..."
wait $SQLSERVR_PID
