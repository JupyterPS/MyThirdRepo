FROM jupyter/base-notebook:latest

# Upgrade pip
RUN python -m pip install --upgrade pip

# Install dependencies for Jupyter and .NET
RUN python -m pip install --upgrade --no-deps --force-reinstall notebook
RUN python -m pip install --user numpy spotipy scipy matplotlib ipython jupyter pandas sympy nose
RUN python -m pip install jupyter_contrib_nbextensions ipywidgets jupyterthemes

# Install curl and other system dependencies as root
USER root
RUN apt-get update && apt-get install -y curl libicu-dev libssl1.1

# Install .NET SDK
RUN dotnet_sdk_version=3.1.301 \
    && curl -SL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/$dotnet_sdk_version/dotnet-sdk-$dotnet_sdk_version-linux-x64.tar.gz \
    && dotnet_sha512='dd39931df438b8c1561f9a3bdb50f72372e29e5706d3fb4c490692f04a3d55f5acc0b46b8049bc7ea34dedba63c71b4c64c57032740cbea81eef1dce41929b4e' \
    && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -ozxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
    # Trigger first run experience by running arbitrary cmd
    && dotnet help

# Set environment variables for .NET
ENV DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    NUGET_XMLDOC_MODE=skip \
    DOTNET_TRY_CLI_TELEMETRY_OPTOUT=true

# Configure working directory
WORKDIR $HOME

# Set the user and home directory
ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}

# Install PowerShell (Optional, if needed for scripts)
RUN apt-get update && apt-get install -y wget \
    && wget https://github.com/PowerShell/PowerShell/releases/download/v7.2.3/powershell-7.2.3-linux-x64.tar.gz \
    && mkdir /opt/microsoft/powershell/7 \
    && tar -xvf ./powershell-7.2.3-linux-x64.tar.gz -C /opt/microsoft/powershell/7 \
    && ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

# Optional: If using .NET interactive, you can install the tool
RUN dotnet tool install --global Microsoft.dotnet-interactive --version 1.0.155302 --add-source "https://dotnet.myget.org/F/dotnet-try/api/v3/index.json"

# Copy configuration files and PowerShell scripts
COPY ./config ${HOME}/.jupyter/
COPY ./ ${HOME}/WindowsPowerShell/

# Copy NuGet configuration
COPY ./NuGet.config ${HOME}/nuget.config

# Set ownership and switch to jovyan user
RUN chown -R ${NB_UID} ${HOME}
USER ${USER}

# Install nteract
RUN pip install nteract_on_jupyter

# Install kernel specifications
RUN dotnet interactive jupyter install

# Enable telemetry once Jupyter is installed for the image
ENV DOTNET_TRY_CLI_TELEMETRY_OPTOUT=false

# Set the working directory to the Windows PowerShell scripts
WORKDIR ${HOME}/WindowsPowerShell/

