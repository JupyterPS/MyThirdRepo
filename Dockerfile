# Use the official .NET ASP.NET Core image as the base image
FROM mcr.microsoft.com/dotnet/aspnet:3.1

# Switch to root user to install additional dependencies
USER root

# Install required packages and Node.js from the official source
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-dev \
    curl \
    && curl -sL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get install -y nodejs \
    && python3 -m pip install --upgrade pip \
    && python3 -m pip install notebook numpy spotipy scipy matplotlib ipython jupyter pandas sympy nose \
    && jupyter lab build --minimize=False

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

# Set path for .NET tools
ENV PATH="${PATH}:/home/jovyan/.dotnet/tools"

# Enable telemetry
ENV DOTNET_TRY_CLI_TELEMETRY_OPTOUT=false

# Final working directory
WORKDIR /home/jovyan/WindowsPowerShell/
