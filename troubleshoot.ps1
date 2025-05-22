# Troubleshooting script for AdventureWorks Docker setup
# This script helps diagnose common issues with Docker, SQL Server, and the database restore process

Write-Host "AdventureWorks Docker Troubleshooting Tool" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Check Docker installation
Write-Host "1. Checking Docker installation..." -ForegroundColor Yellow
try {
    $dockerVersion = docker version --format '{{.Server.Version}}' 2>$null
    if ($LASTEXITCODE -eq 0 -and $dockerVersion) {
        Write-Host "   ✓ Docker is installed (version: $dockerVersion)" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Docker doesn't appear to be running" -ForegroundColor Red
        Write-Host "     Make sure Docker Desktop (Windows) or Docker Engine (Linux) is running" -ForegroundColor Red
    }
} catch {
    Write-Host "   ✗ Docker is not installed or not in PATH" -ForegroundColor Red
    Write-Host "     Please install Docker: https://docs.docker.com/get-docker/" -ForegroundColor Red
}

# Check required files
Write-Host ""
Write-Host "2. Checking required project files..." -ForegroundColor Yellow
$requiredFiles = @{
    "AdventureWorksDW.bak" = "Database backup file"
    "Dockerfile" = "Docker image definition"
    "restore-db.sh" = "Database restore script"
    "docker-compose.yml" = "Docker Compose configuration"
}

foreach ($file in $requiredFiles.Keys) {
    if (Test-Path -Path ".\$file") {
        Write-Host "   ✓ $($requiredFiles[$file]) found: $file" -ForegroundColor Green
    } else {
        Write-Host "   ✗ $($requiredFiles[$file]) missing: $file" -ForegroundColor Red
    }
}

# Check docker-compose.yml content
Write-Host ""
Write-Host "3. Validating docker-compose.yml..." -ForegroundColor Yellow
if (Test-Path -Path ".\docker-compose.yml") {
    $composeContent = Get-Content -Path ".\docker-compose.yml" -Raw
    
    # Simple validation checks
    $hasVersion = $composeContent -match "version:"
    $hasServices = $composeContent -match "services:"
    $hasSqlServer = $composeContent -match "sql-server:"
    $hasPassword = $composeContent -match "SA_PASSWORD="
    
    if ($hasVersion -and $hasServices -and $hasSqlServer) {
        Write-Host "   ✓ docker-compose.yml has valid structure" -ForegroundColor Green
    } else {
        Write-Host "   ✗ docker-compose.yml may have structural issues" -ForegroundColor Red
    }
    
    if ($hasPassword) {
        Write-Host "   ✓ SA_PASSWORD is defined in docker-compose.yml" -ForegroundColor Green
    } else {
        Write-Host "   ✗ SA_PASSWORD not found in docker-compose.yml" -ForegroundColor Red
    }
    
    # Check for common syntax errors
    try {
        docker-compose config -q
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✓ docker-compose.yml syntax is valid" -ForegroundColor Green
        } else {
            Write-Host "   ✗ docker-compose.yml has syntax errors" -ForegroundColor Red
        }
    } catch {
        Write-Host "   ✗ Could not validate docker-compose.yml" -ForegroundColor Red
    }
}

# Check Dockerfile
Write-Host ""
Write-Host "4. Validating Dockerfile..." -ForegroundColor Yellow
if (Test-Path -Path ".\Dockerfile") {
    $dockerfileContent = Get-Content -Path ".\Dockerfile" -Raw
    
    # Simple validation checks
    $hasFrom = $dockerfileContent -match "FROM"
    $hasCopy = $dockerfileContent -match "COPY"
    $hasBackupFile = $dockerfileContent -match "AdventureWorksDW.bak"
    $hasRestoreScript = $dockerfileContent -match "restore-db.sh"
    
    if ($hasFrom) {
        Write-Host "   ✓ Dockerfile has valid FROM directive" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Dockerfile missing FROM directive" -ForegroundColor Red
    }
    
    if ($hasCopy -and $hasBackupFile) {
        Write-Host "   ✓ Dockerfile copies AdventureWorksDW.bak file" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Dockerfile may not be copying the backup file" -ForegroundColor Red
    }
    
    if ($hasCopy -and $hasRestoreScript) {
        Write-Host "   ✓ Dockerfile copies restore-db.sh script" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Dockerfile may not be copying the restore script" -ForegroundColor Red
    }
}

# Check container status
Write-Host ""
Write-Host "5. Checking container status..." -ForegroundColor Yellow
$containerName = "adventureworks-sql-server"
$containerExists = docker ps -a --filter "name=$containerName" --format "{{.Status}}" 2>$null

if ($containerExists) {
    if ($containerExists -match "Up") {
        Write-Host "   ✓ Container is running: $containerExists" -ForegroundColor Green
        
        # Check SQL Server port
        $portCheck = docker port $containerName 2>$null
        if ($portCheck -match "1433") {
            Write-Host "   ✓ SQL Server port 1433 is mapped correctly" -ForegroundColor Green
        } else {
            Write-Host "   ✗ SQL Server port mapping issue" -ForegroundColor Red
            Write-Host "     Port mapping: $portCheck" -ForegroundColor Gray
        }
        
        # Check recent logs
        Write-Host ""
        Write-Host "6. Checking container logs..." -ForegroundColor Yellow
        $recentLogs = docker logs --tail 20 $containerName 2>$null
        if ($recentLogs) {
            Write-Host "   Recent container logs:" -ForegroundColor Cyan
            Write-Host "   ------------------------" -ForegroundColor Cyan
            Write-Host "   $recentLogs" -ForegroundColor Gray
            Write-Host "   ------------------------" -ForegroundColor Cyan
            
            if ($recentLogs -match "Error") {
                Write-Host "   ⚠ Possible errors detected in logs" -ForegroundColor Yellow
            }
            if ($recentLogs -match "Database restore completed successfully") {
                Write-Host "   ✓ Database restore appears to have completed successfully" -ForegroundColor Green
            }
        } else {
            Write-Host "   ✗ Could not retrieve container logs" -ForegroundColor Red
        }
    } else {
        Write-Host "   ✗ Container exists but is not running: $containerExists" -ForegroundColor Red
        
        # Show exit reason if available
        $exitReason = docker inspect $containerName --format "{{.State.Error}}" 2>$null
        if ($exitReason -and $exitReason -ne "<no value>") {
            Write-Host "     Exit reason: $exitReason" -ForegroundColor Red
        }
        
        Write-Host ""
        Write-Host "   Container logs (last 20 lines):" -ForegroundColor Cyan
        $logs = docker logs --tail 20 $containerName 2>$null
        if ($logs) {
            Write-Host "   $logs" -ForegroundColor Gray
        } else {
            Write-Host "   No logs available" -ForegroundColor Red
        }
    }
} else {
    Write-Host "   ✗ Container '$containerName' does not exist" -ForegroundColor Red
    Write-Host "     Try running build-and-run.ps1 first" -ForegroundColor Yellow
}

# Check restore-db.sh file permissions and format
Write-Host ""
Write-Host "7. Checking restore-db.sh..." -ForegroundColor Yellow
if (Test-Path -Path ".\restore-db.sh") {
    $content = Get-Content -Path ".\restore-db.sh" -Raw
    
    # Check for Windows line endings which can cause issues in Linux containers
    if ($content -match "\r\n") {
        Write-Host "   ⚠ restore-db.sh has Windows line endings (CRLF) which may cause issues" -ForegroundColor Yellow
        Write-Host "     Consider converting to Unix line endings (LF) using VS Code or git" -ForegroundColor Yellow
    } else {
        Write-Host "   ✓ restore-db.sh has Unix line endings (LF)" -ForegroundColor Green
    }
    
    # Check file contains essential SQL commands
    if ($content -match "RESTORE DATABASE") {
        Write-Host "   ✓ restore-db.sh contains database restore command" -ForegroundColor Green
    } else {
        Write-Host "   ✗ restore-db.sh may not contain proper restore command" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "8. Common troubleshooting tips:" -ForegroundColor Yellow
Write-Host "   • If Docker can't access your files, check file permissions" -ForegroundColor White
Write-Host "   • If the container starts and immediately stops, check restore-db.sh for errors" -ForegroundColor White
Write-Host "   • Make sure restore-db.sh has Unix line endings (LF not CRLF)" -ForegroundColor White
Write-Host "   • Check that the .bak file path in restore-db.sh matches the location in the container" -ForegroundColor White
Write-Host "   • SQL Server SA password must meet complexity requirements (uppercase, lowercase, numbers, and symbols)" -ForegroundColor White
Write-Host "   • To clean up and try again, run: docker-compose down && docker-compose up -d --build" -ForegroundColor White
Write-Host "   • To rebuild image from scratch: docker-compose down && docker system prune -f && docker-compose up -d --build" -ForegroundColor White

Write-Host ""
Write-Host "Troubleshooting complete!" -ForegroundColor Cyan