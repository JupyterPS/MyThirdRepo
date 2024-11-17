# Use a base image with Ubuntu 22.04
FROM mcr.microsoft.com/dotnet/sdk:8.0-jammy AS build

# Set environment variables for non-interactive apt installs
ENV DEBIAN_FRONTEND=noninteractive

# Step 1: Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libicu-dev \
    libssl3 \
    libssl-dev \
    build-essential \
    git \
    ca-certificates \
    software-properties-common \
    apt-transport-https \
    lsb-release \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Step 2: Add Microsoft's APT repository for PowerShell and .NET SDK
RUN wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get update

# Step 3: Install .NET SDK
RUN apt-get install -y dotnet-sdk-8.0

# Step 4: Install .NET Interactive tools
RUN dotnet tool install -g Microsoft.dotnet-interactive \
    && export PATH=$PATH:/root/.dotnet/tools \
    && dotnet interactive jupyter install

# Step 5: Install PowerShell
RUN apt-get install -y powershell

# Step 6: Add PowerShell to PATH for access in the container
ENV PATH=$PATH:/usr/bin/pwsh

# Step 7: Install JupyterLab and its Python dependencies
RUN apt-get install -y python3-pip \
    && pip3 install --upgrade pip \
    && pip3 install jupyterlab

# Step 8: Install .NET Interactive kernels for .NET languages (C#, F#, PowerShell)
RUN dotnet interactive jupyter install --csharp --fsharp --powershell

# Step 9: Expose necessary ports and set up environment variables
ENV PATH=$PATH:/root/.dotnet/tools

# Step 10: Set working directory
WORKDIR /workspace

# Step 11: Set the default command to run JupyterLab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root"]
