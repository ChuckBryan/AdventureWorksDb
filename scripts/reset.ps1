# Reset script for AdventureWorks SQL Server container
Write-Host "Stopping and removing AdventureWorks SQL Server container..." -ForegroundColor Yellow
docker-compose down
Write-Host "Container stopped and removed successfully." -ForegroundColor Green
