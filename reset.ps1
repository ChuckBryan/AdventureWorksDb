# Script to completely reset the Docker environment for AdventureWorks
# This will stop all containers, remove them, and rebuild from scratch

Write-Host "AdventureWorks Docker Environment Reset Tool" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "WARNING: This will stop and remove the SQL Server container and its data!" -ForegroundColor Yellow
Write-Host "Press Ctrl+C now to abort, or any key to continue..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Step 1: Stop and remove containers
Write-Host ""
Write-Host "1. Stopping and removing containers..." -ForegroundColor Yellow
docker-compose down
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ⚠ Warning: Issue stopping containers, trying to force stop..." -ForegroundColor Yellow
    docker stop adventureworks-sql-server 2>$null
    docker rm adventureworks-sql-server 2>$null
}

# Step 2: Remove the Docker image
Write-Host ""
Write-Host "2. Removing Docker images..." -ForegroundColor Yellow
$imageName = "adventureworksdb_sql-server"
docker rmi $imageName 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ⚠ Warning: Could not remove image $imageName (it may not exist)" -ForegroundColor Yellow
}

# Step 3: Prune Docker system
Write-Host ""
Write-Host "3. Pruning Docker system..." -ForegroundColor Yellow
docker system prune -f
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ⚠ Warning: Issue pruning Docker system" -ForegroundColor Yellow
}

# Step 4: Validate necessary files
Write-Host ""
Write-Host "4. Checking necessary files..." -ForegroundColor Yellow
$requiredFiles = @("AdventureWorksDW.bak", "Dockerfile", "restore-db.sh", "docker-compose.yml")
$allFilesExist = $true
foreach ($file in $requiredFiles) {
    if (Test-Path -Path ".\$file") {
        Write-Host "   ✓ $file exists" -ForegroundColor Green
    } else {
        Write-Host "   ✗ $file is missing!" -ForegroundColor Red
        $allFilesExist = $false
    }
}

if (-not $allFilesExist) {
    Write-Host ""
    Write-Host "ERROR: Some required files are missing. Please restore them before proceeding." -ForegroundColor Red
    exit 1
}

# Step 5: Fix line endings in shell script
Write-Host ""
Write-Host "5. Fixing shell script line endings..." -ForegroundColor Yellow

# Use PowerShell to fix line endings directly
try {
    $content = Get-Content -Path ".\restore-db.sh" -Raw
    $content = $content.Replace("`r`n", "`n")
    $content | Set-Content -Path ".\restore-db.sh" -NoNewline -Encoding UTF8
    Write-Host "   ✓ Fixed line endings with PowerShell" -ForegroundColor Green
} catch {
    Write-Host "   ⚠ Warning: Could not fix line endings, but Docker will handle this" -ForegroundColor Yellow
}

# Step 6: Rebuild and start
Write-Host ""
Write-Host "6. Rebuilding and starting container..." -ForegroundColor Yellow
docker-compose build --no-cache
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ✗ Error during Docker build" -ForegroundColor Red
    Write-Host "   Please check error messages above for details." -ForegroundColor Red
    exit 1
}

docker-compose up -d
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ✗ Error starting container" -ForegroundColor Red
    Write-Host "   Please check error messages above for details." -ForegroundColor Red
    exit 1
}

# Step 7: Monitor container startup
Write-Host ""
Write-Host "7. Monitoring container startup..." -ForegroundColor Yellow
$containerName = "adventureworks-sql-server"
$maxWaitTime = 120 # seconds
$elapsed = 0
$interval = 5 # check every 5 seconds

while ($elapsed -lt $maxWaitTime) {
    $containerStatus = docker ps --filter "name=$containerName" --format "{{.Status}}" 2>$null
    
    if (-not $containerStatus) {
        # Container stopped running
        Write-Host "   ✗ Container stopped running unexpectedly" -ForegroundColor Red
        $logs = docker logs $containerName 2>&1
        Write-Host ""
        Write-Host "Container logs:" -ForegroundColor Yellow
        Write-Host $logs -ForegroundColor Gray
        exit 1
    }
    
    # Show startup progress
    Write-Host "   Container running for $elapsed seconds..." -ForegroundColor Yellow
    
    # Check logs for successful database restore
    $logs = docker logs --tail 10 $containerName 2>&1
    if ($logs -match "Database restore completed successfully") {
        Write-Host ""
        Write-Host "SUCCESS! Container is running and database has been restored." -ForegroundColor Green
        break
    }
    
    Start-Sleep -Seconds $interval
    $elapsed += $interval
}

if ($elapsed -ge $maxWaitTime) {
    Write-Host ""
    Write-Host "⚠ Timed out waiting for database restore to complete." -ForegroundColor Yellow
    Write-Host "The container is still running, but the database may not be fully restored." -ForegroundColor Yellow
    Write-Host "Check container logs with: docker logs $containerName" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Reset completed successfully!" -ForegroundColor Green
    Write-Host "Connection details:" -ForegroundColor Cyan
    Write-Host " - Server: localhost,1433" -ForegroundColor Cyan
    Write-Host " - Username: SA" -ForegroundColor Cyan
    Write-Host " - Password: YourStrong!Passw0rd (as defined in docker-compose.yml)" -ForegroundColor Cyan
    Write-Host " - Database: AdventureWorksDW" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "To check container status, run: .\troubleshoot.ps1" -ForegroundColor White