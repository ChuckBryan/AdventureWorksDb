# Instructions for Creating a Docker Image to Restore AdventureWorksDW.bak

## 1. Prepare the Dockerfile

- Use the official Microsoft SQL Server image as the base.
- Use Docker build arguments to securely pass the SA password.
- Copy the `AdventureWorksDW.bak` backup file into the image.
- Use an initialization script to restore the database on container startup.

## 2. Example Dockerfile
