FROM jupyter/base-notebook:latest

# Upgrade pip
RUN python -m pip install --upgrade pip

# Copy requirements.txt file
COPY requirements.txt ./requirements.txt

# Install Python packages
RUN python -m pip install -r requirements.txt

# Install Jupyter Notebook and additional Python packages
RUN python -m pip install --upgrade --no-deps --force-reinstall notebook \
    && python -m pip install --user numpy spotipy scipy matplotlib ipython jupyter pandas sympy nose

# Build JupyterLab
RUN jupyter lab build --minimize=False

# Working Directory
WORKDIR $HOME
ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}
USER root

# Install curl
RUN apt-get update && apt-get install -y curl

# Debug: Check available packages
RUN apt-cache search libicu
RUN apt-cache search libssl

ENV \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    NUGET_XMLDOC_MODE=skip \
    DOTNET_TRY_CLI_TELEMETRY_OPTOUT=true

# Install .NET CLI dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        libicu-dev \
        libssl3 \
        libstdc++6 \
        zlib1g && \
    rm -rf /var/lib/apt/lists/*

# Install .NET Core SDK
RUN dotnet_sdk_version=3.1.301 \
    && curl -SL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/$dotnet_sdk_version/dotnet-sdk-$dotnet_sdk_version-linux-x64.tar.gz \
    && dotnet_sha512='dd39931df438b8c1561f9a3bdb50f72372e29e5706d3fb4c490692f04a3d55f5acc0b46b8049bc7ea34dedba63c71b4c64c57032740cbea81eef1dce41929b4e' \
    && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -ozxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
    && dotnet help

# Copy configuration files and notebooks
COPY ./config ${HOME}/.jupyter/
COPY ./ ${HOME}/WindowsPowerShell/
COPY ./NuGet.config ${HOME}/nuget.config

# Change ownership
RUN chown -R ${NB_UID} ${HOME}
USER ${USER}

# Install nteract
RUN pip install nteract_on_jupyter

# Install Microsoft.dotnet-interactive tool
RUN dotnet tool install --global Microsoft.dotnet-interactive --version 1.0.155302 --add-source "https://dotnet.myget.org/F/dotnet-try/api/v3/index.json"

# Configure PATH
ENV PATH="${PATH}:${HOME}/.dotnet/tools"

# Install kernel specs
RUN dotnet interactive jupyter install

# Re-enable telemetry
ENV DOTNET_TRY_CLI_TELEMETRY_OPTOUT=false

# Set working directory to notebooks
WORKDIR ${HOME}/WindowsPowerShell/
