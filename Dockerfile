# Use the official Microsoft SQL Server image as base
FROM mcr.microsoft.com/mssql/server:2022-latest

# Set environment variables
ENV ACCEPT_EULA=Y

# Use ARG for build-time SA password (more secure than ENV for passwords)
ARG SA_PASSWORD
ENV SA_PASSWORD=${SA_PASSWORD}

# Switch to root for package installation
USER root

# Install necessary packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       dos2unix \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create directory for backup file
WORKDIR /opt/mssql/backup

# Copy backup file and make it accessible
COPY AdventureWorksDW.bak .

# Create scripts directory
RUN mkdir -p /opt/mssql/scripts

# Copy initialization scripts
COPY scripts/ /opt/mssql/scripts/

# Ensure the scripts have the correct line endings and are executable
RUN dos2unix /opt/mssql/scripts/*.sh && chmod +x /opt/mssql/scripts/*.sh

# Healthcheck to determine if SQL Server is running
HEALTHCHECK --interval=10s --timeout=5s --start-period=120s --retries=12 \
    CMD /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "${SA_PASSWORD}" -C -Q "SELECT 1" || exit 1

# Expose SQL Server port
EXPOSE 1433

# Set the entrypoint
ENTRYPOINT ["/bin/bash", "/opt/mssql/scripts/restore-db.sh"]
