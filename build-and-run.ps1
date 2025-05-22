# Build and run the AdventureWorks SQL Server Docker container

Write-Host "Building and starting the AdventureWorks SQL Server container..." -ForegroundColor Green

# Check if Docker is running
try {
    docker info | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker is not running"
    }
} catch {
    Write-Host "Error: Docker does not appear to be running." -ForegroundColor Red
    Write-Host "Please start Docker Desktop or Docker Engine before running this script." -ForegroundColor Red
    exit 1
}

# Check if the AdventureWorksDW.bak file exists
if (-not (Test-Path -Path ".\AdventureWorksDW.bak")) {
    Write-Host "Error: AdventureWorksDW.bak file not found in the current directory." -ForegroundColor Red
    Write-Host "Please place the backup file in the same directory as this script." -ForegroundColor Red
    exit 1
}

# Check if required files exist
$requiredFiles = @("Dockerfile", "scripts/restore-db.sh", "docker-compose.yml")
foreach ($file in $requiredFiles) {
    if (-not (Test-Path -Path ".\$file")) {
        Write-Host "Error: Required file '$file' not found in the current directory." -ForegroundColor Red
        exit 1
    }
}

# Build and start the container using docker-compose with error capture
Write-Host "Running docker-compose up..." -ForegroundColor Yellow
$output = docker-compose up -d --build 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Docker Compose command failed with the following output:" -ForegroundColor Red
    Write-Host $output -ForegroundColor Red
    exit 1
}

# Wait for the container to start and restore the database
Write-Host "Waiting for the database to be restored. This may take a few minutes..." -ForegroundColor Yellow

# Check if the container is running immediately
$containerName = "adventureworks-sql-server"
$initialStatus = docker ps --filter "name=$containerName" --format "{{.Status}}" 2>$null

if (-not $initialStatus) {
    Write-Host "Warning: Container not started properly. Checking container logs..." -ForegroundColor Yellow
    $logs = docker logs $containerName 2>&1
    Write-Host "Container logs:" -ForegroundColor Yellow
    Write-Host $logs -ForegroundColor Gray
    
    # Check if the container exists but exited
    $exitedContainer = docker ps -a --filter "name=$containerName" --format "{{.Status}}" 2>$null
    if ($exitedContainer -and $exitedContainer -match "Exited") {
        Write-Host "Error: Container started but exited unexpectedly." -ForegroundColor Red
        Write-Host "You can try to debug with: docker logs $containerName" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "Error: Container '$containerName' failed to start." -ForegroundColor Red
    exit 1
}

# Wait and periodically check container status
$maxWaitTime = 120 # seconds
$elapsed = 0
$interval = 10 # check every 10 seconds

while ($elapsed -lt $maxWaitTime) {
    Write-Host "Waiting for database restore... ($elapsed/$maxWaitTime seconds)" -ForegroundColor Yellow
    Start-Sleep -Seconds $interval
    $elapsed += $interval
    
    # Check container status
    $containerStatus = docker ps --filter "name=$containerName" --format "{{.Status}}" 2>$null
    if (-not $containerStatus) {
        Write-Host "Error: Container stopped running during database restore." -ForegroundColor Red
        $logs = docker logs $containerName 2>&1
        Write-Host "Container logs:" -ForegroundColor Yellow
        Write-Host $logs -ForegroundColor Gray
        exit 1
    }
    
    # Sample logs to see if restore is still in progress
    $logs = docker logs --tail 5 $containerName 2>&1
    if ($logs -match "Database restore completed successfully") {
        Write-Host "Database restore completed!" -ForegroundColor Green
        break
    }
}

# Final status check
$containerStatus = docker ps --filter "name=$containerName" --format "{{.Status}}" 2>$null

if ($containerStatus) {
    Write-Host "AdventureWorks SQL Server is now running!" -ForegroundColor Green
    Write-Host "Connection details:" -ForegroundColor Cyan
    Write-Host " - Server: localhost,1433" -ForegroundColor Cyan
    Write-Host " - Username: SA" -ForegroundColor Cyan
    Write-Host " - Password: YourStrong!Passw0rd (as defined in docker-compose.yml)" -ForegroundColor Cyan
    Write-Host " - Database: AdventureWorksDW" -ForegroundColor Cyan
    
    # Test SQL connection if sqlcmd is available
    if (Get-Command "sqlcmd" -ErrorAction SilentlyContinue) {
        Write-Host "Testing SQL Server connection..." -ForegroundColor Yellow
        $testQuery = "sqlcmd -S localhost,1433 -U SA -P 'YourStrong!Passw0rd' -Q 'SELECT @@VERSION' -t 5"
        $result = Invoke-Expression $testQuery 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "SQL Server connection successful!" -ForegroundColor Green
        } else {
            Write-Host "Warning: Could not connect to SQL Server. It might still be initializing." -ForegroundColor Yellow
            Write-Host "Result: $result" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "Error: Container failed to start or exited unexpectedly." -ForegroundColor Red
    Write-Host "Check the container logs for more information:" -ForegroundColor Yellow
    Write-Host "docker logs $containerName" -ForegroundColor Yellow
    
    # Try to show some logs automatically
    $logs = docker logs $containerName 2>&1
    if ($logs) {
        Write-Host "Last few lines of container logs:" -ForegroundColor Yellow
        Write-Host ($logs | Select-Object -Last 20) -ForegroundColor Gray
    }
    exit 1
}