# AdventureWorks Database Docker Image

This project creates a Docker image that automatically restores the AdventureWorksDW sample database in a SQL Server container.

## Prerequisites

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
