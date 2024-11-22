# Use the official .NET ASP.NET Core image as the base image
FROM mcr.microsoft.com/dotnet/aspnet:3.1

# Switch to root user to install additional dependencies
USER root

# Install required packages, n package manager, and Node.js
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-dev \
    curl \
    && curl -L https://raw.githubusercontent.com/tj/n/master/bin/n -o /usr/local/bin/n \
    && chmod +x /usr/local/bin/n \
    && n 14.17.0 \
    && python3 -m pip install --upgrade pip \
    && python3 -m pip install notebook numpy spotipy scipy matplotlib ipython jupyter pandas sympy nose

# Install JupyterLab separately to avoid memory issues
RUN python3 -m pip install jupyterlab

# Create jovyan user and group only if they don't already exist
RUN if ! id -u jovyan >/dev/null 2>&1; then \
        groupadd -g 1000 users; \
        useradd -m -d /home/jovyan -s /bin/bash -u 1000 -g users jovyan; \
    fi

# Set working directory
WORKDIR /home/jovyan
