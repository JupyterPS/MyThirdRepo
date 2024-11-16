# Start with the base Jupyter image
FROM jupyter/base-notebook:latest

# Upgrade pip and install necessary Python packages
RUN python -m pip install --upgrade pip
COPY requirements.txt ./requirements.txt
RUN python -m pip install -r requirements.txt
RUN python -m pip install --upgrade --no-deps --force-reinstall notebook
RUN python -m pip install --user numpy spotipy scipy matplotlib ipython jupyter pandas sympy nose
RUN python -m pip install jupyter_contrib_nbextensions ipywidgets jupyterthemes

# Build JupyterLab extensions and configure settings
RUN jupyter lab build 
RUN echo "c.LabBuildApp.minimize = False" >> /etc/jupyter/jupyter_config.py
RUN echo "c.LabBuildApp.dev_build = False" >> /etc/jupyter/jupyter_config.py

# Working directory
WORKDIR $HOME

# Set user and environment variables
ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}

# Switch to root user for apt-get operations
USER root

# Install necessary system packages (curl and ICU dependencies)
RUN apt-get update && apt-get install -y curl libicu-dev

# Install .NET SDK and tools
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

# Install nteract for Jupyter
RUN pip install nteract_on_jupyter

# Install the .NET Interactive tool
RUN dotnet tool install --global Microsoft.dotnet-interactive --version 1.0.155302 --add-source "https://dotnet.myget.org/F/dotnet-try/api/v3/index.json"

# Install kernel specs for .NET Interactive
RUN dotnet interactive jupyter install

# Set environment for .NET to be used in container
ENV DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    NUGET_XMLDOC_MODE=skip \
    DOTNET_TRY_CLI_TELEMETRY_OPTOUT=true

# Enable telemetry once Jupyter and .NET SDK are installed
ENV DOTNET_TRY_CLI_TELEMETRY_OPTOUT=false

# Copy your Jupyter configuration files and PowerShell scripts
COPY ./config ${HOME}/.jupyter/
COPY ./ ${HOME}/WindowsPowerShell/

# Copy NuGet.config for custom package sources
COPY ./NuGet.config ${HOME}/nuget.config

# Change ownership of the home directory to the non-root user
RUN chown -R ${NB_UID} ${HOME}

# Set back to the regular user
USER ${USER}

# Set the working directory to PowerShell scripts
WORKDIR ${HOME}/WindowsPowerShell/

# Expose the necessary ports (default Jupyter port)
EXPOSE 8888

# Define the entry point for the container (Binder will take care of this part)
CMD ["start-notebook.sh"]

ENV DOTNET_TRY_CLI_TELEMETRY_OPTOUT=false

# Set root to Notebooks
WORKDIR ${HOME}/WindowsPowerShell/
