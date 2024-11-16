# Use the Jupyter base notebook image
FROM jupyter/base-notebook:latest

# Set environment variables for user and home directory
ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}

# Install necessary system dependencies (curl, libssl, libicu, etc.)
USER root
RUN apt-get update && apt-get install -y \
    curl \
    libssl-dev \
    libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# Install .NET SDK
RUN dotnet_sdk_version=3.1.301 \
    && curl -SL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/$dotnet_sdk_version/dotnet-sdk-$dotnet_sdk_version-linux-x64.tar.gz \
    && dotnet_sha512='dd39931df438b8c1561f9a3bdb50f72372e29e5706d3fb4c490692f04a3d55f5acc0b46b8049bc7ea34dedba63c71b4c64c57032740cbea81eef1dce41929b4e' \
    && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -ozxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
    && dotnet --info

# Install necessary Python packages (numpy, pandas, etc.)
RUN python -m pip install --upgrade pip \
    && python -m pip install numpy pandas matplotlib scipy ipywidgets \
    && python -m pip install jupyter_contrib_nbextensions jupyterthemes spotipy \
    && python -m pip install notebook  # Install the notebook package to enable nbextensions

# Install nteract for Jupyter (interactive notebooks)
RUN pip install nteract_on_jupyter

# Install JupyterLab extensions and build JupyterLab
RUN jupyter labextension install @jupyterlab/plotly-extension jupyterlab-chart-editor

# Install .NET interactive for Jupyter
RUN dotnet tool install --global Microsoft.dotnet-interactive --version 1.0.155302 --add-source "https://dotnet.myget.org/F/dotnet-try/api/v3/index.json"

# Configure PATH for .NET tools
ENV PATH="${PATH}:${HOME}/.dotnet/tools"

# Install .NET interactive Jupyter kernel
RUN dotnet interactive jupyter install

# Clean up (reduce image size by removing unnecessary files)
RUN rm -rf /root/.cache

# Switch to jovyan user (default for Jupyter)
USER ${NB_USER}

# Expose the default Jupyter port
EXPOSE 8888

# Set the working directory to the user's home
WORKDIR ${HOME}

# Default command to start JupyterLab
CMD ["start.sh", "jupyter", "lab"]

WORKDIR ${HOME}

# Default command to start JupyterLab
CMD ["start.sh", "jupyter", "lab"]
