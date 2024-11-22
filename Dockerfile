FROM mcr.microsoft.com/dotnet/core/sdk:3.1-bionic AS dotnet

# Create a new base image from the Jupyter base-notebook
FROM jupyter/base-notebook:latest

# Switch to root user for installing dependencies
USER root

# Copy .NET SDK tools from the dotnet image
COPY --from=dotnet /usr/share/dotnet /usr/share/dotnet
COPY --from=dotnet /usr/bin/dotnet /usr/bin/dotnet

# Install .NET runtime dependencies
RUN apt-get update && apt-get install -y \
    libc6 \
    libgcc1 \
    libgssapi-krb5-2 \
    libicu-dev \
    libssl-dev \
    libstdc++6 \
    zlib1g \
    curl && \
    rm -rf /var/lib/apt/lists/*

# Install ASP.NET Core runtime
RUN curl -SL --output aspnetcore-runtime.tar.gz https://dotnetcli.blob.core.windows.net/dotnet/aspnetcore/Runtime/3.1.27/aspnetcore-runtime-3.1.27-linux-x64.tar.gz \
    && mkdir -p /usr/share/dotnet \
    && tar -xzf aspnetcore-runtime.tar.gz -C /usr/share/dotnet \
    && rm aspnetcore-runtime.tar.gz

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
RUN dotnet tool install --global Microsoft.dotnet-interactive --version 1.0.155302

# Configure PATH
ENV PATH="${PATH}:${HOME}/.dotnet/tools"

# Install kernel specs
RUN dotnet interactive jupyter install

# Re-enable telemetry
ENV DOTNET_TRY_CLI_TELEMETRY_OPTOUT=false

# Set working directory to notebooks
WORKDIR ${HOME}/WindowsPowerShell/
