# AdventureWorks Database Docker Image

This project provides a Docker image that automatically restores the AdventureWorksDW sample database in a SQL Server container.

## Quick Start - Using Pre-built Docker Image

The fastest way to get started is by pulling the pre-built image from Docker Hub:

```powershell
# Pull the latest AdventureWorks database image from Docker Hub
docker pull swampyfox/adventureworksdb:latest

# Run the container
docker run -d --name adventureworks-sql-server -p 1433:1433 -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=YourStrong!Passw0rd" swampyfox/adventureworksdb:latest
```

After running these commands, SQL Server will start and the AdventureWorksDW database will be automatically restored (this may take a few minutes).

You can check the status of the restore process by viewing the container logs:

```powershell
docker logs -f adventureworks-sql-server
```

Once complete, you can connect to SQL Server with the following details:
- Server: localhost,1433
- Username: SA
- Password: YourStrong!Passw0rd
- Database: AdventureWorksDW

## Prerequisites (For Building Your Own Image)

- Docker and Docker Compose installed on your machine
- The AdventureWorksDW.bak backup file in the root directory of this project

## How to Use

### 1. Build and start the container

```powershell
docker-compose up -d
```

This will:

- Build the Docker image
- Start the SQL Server container
- Automatically restore the AdventureWorksDW database

### 2. Connect to the database

You can connect to the database using SQL Server Management Studio or any other SQL client with the following credentials:

- Server: localhost,1433
- Username: SA
- Password: YourStrong!Passw0rd (as defined in docker-compose.yml)
- Database: AdventureWorksDW

### 3. Stop the container

```powershell
docker-compose down
```

## Security Note

For production use, you should:

- Change the SA password in the docker-compose.yml file
- Consider using Docker secrets or environment variables to manage sensitive information
- Implement proper network security measures

## License

The AdventureWorks database is a sample database provided by Microsoft.
