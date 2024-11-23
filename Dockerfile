# Use the official .NET SDK image as the base image
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS dotnet

# Create a new base image from the Jupyter base-notebook
FROM jupyter/base-notebook:latest

# Switch to root user to install additional dependencies
USER root

# Clear Docker cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install required packages, n package manager, and Node.js
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-dev \
    curl \
    libicu-dev \
    build-essential \
    wget \
    libssl-dev \
    && curl -L https://raw.githubusercontent.com/tj/n/master/bin/n -o /usr/local/bin/n \
    && chmod +x /usr/local/bin/n \
    && n 14.17.0 \
    && python3 -m pip install --upgrade pip \
    && python3 -m pip install notebook numpy spotipy scipy matplotlib ipython jupyter pandas sympy nose

# Install JupyterLab separately to avoid memory issues
RUN python3 -m pip install jupyterlab

# Install .NET Runtime using the official installation script
RUN curl -SL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 6.0 --install-dir /usr/share/dotnet

# Install .NET Interactive tool
RUN /usr/share/dotnet/dotnet tool install --global Microsoft.dotnet-interactive --version 1.0.155302

# Configure PATH
ENV PATH="${PATH}:/root/.dotnet/tools"

# Install the .NET Interactive kernels (including PowerShell)
RUN /root/.dotnet/tools/dotnet-interactive jupyter install

# Set working directory
WORKDIR /home/jovyan

# Copy configuration files and notebooks
COPY ./config /home/jovyan/.jupyter/
COPY ./ /home/jovyan/WindowsPowerShell/
COPY ./NuGet.config /home/jovyan/nuget.config

# Change ownership to jovyan user
RUN chown -R jovyan:users /home/jovyan

# Switch back to jovyan user
USER jovyan

# Enable telemetry
ENV DOTNET_TRY_CLI_TELEMETRY_OPTOUT=false

# Final working directory
WORKDIR /home/jovyan/WindowsPowerShell/
