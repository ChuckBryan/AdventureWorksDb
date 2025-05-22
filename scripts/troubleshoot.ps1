# Troubleshooting script for AdventureWorks SQL Server container

Write-Host "Running diagnostics for AdventureWorks SQL Server container..." -ForegroundColor Yellow

$containerName = "adventureworks-sql-server"

# Check if the container is running
$containerStatus = docker ps --filter "name=$containerName" --format "{{.Status}}" 2>$null
if ($containerStatus) {
    Write-Host "Container status: Running" -ForegroundColor Green
    Write-Host "Container uptime: $containerStatus" -ForegroundColor Green
    
    # Display container logs
    Write-Host "`nContainer logs:" -ForegroundColor Yellow
    docker logs $containerName
    
    # Try SQL connection
    Write-Host "`nTesting SQL connection..." -ForegroundColor Yellow
    docker exec $containerName /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$env:SA_PASSWORD" -Q "SELECT @@VERSION" -C
} else {
    # Check if container exists but is stopped
    $containerExists = docker ps -a --filter "name=$containerName" --format "{{.Status}}" 2>$null
    if ($containerExists) {
        Write-Host "Container exists but is not running. Status: $containerExists" -ForegroundColor Red
        
        # Display container logs
        Write-Host "`nContainer logs:" -ForegroundColor Yellow
        docker logs $containerName
    } else {
        Write-Host "Container does not exist. Please run build-and-run.ps1 first." -ForegroundColor Red
    }
}

Write-Host "`nTroubleshooting complete." -ForegroundColor Yellow
