# Start from Jupyter base image with Python 3.11
FROM jupyter/base-notebook:python-3.11

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_ROOT=/usr/share/dotnet

# Switch to root to install system-level dependencies
USER root

# Update package lists and install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libicu-dev \
    libssl-dev \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install .NET SDK
RUN dotnet_sdk_version=3.1.301 && \
    curl -SL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/$dotnet_sdk_version/dotnet-sdk-$dotnet_sdk_version-linux-x64.tar.gz && \
    dotnet_sha512='dd39931df438b8c1561f9a3bdb50f72372e29e5706d3fb4c490692f04a3d55f5acc0b46b8049bc7ea34dedba63c71b4c64c57032740cbea81eef1dce41929b4e' && \
    echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - && \
    mkdir -p /usr/share/dotnet && \
    tar -ozxf dotnet.tar.gz -C /usr/share/dotnet && \
    rm dotnet.tar.gz && \
    ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet && \
    dotnet --list-sdks

# Switch back to non-root user
USER jovyan

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir numpy pandas matplotlib scipy ipywidgets

# Install JupyterLab extensions
RUN pip install --no-cache-dir jupyter_contrib_nbextensions jupyterthemes spotipy && \
    jupyter contrib nbextension install --user && \
    jupyter nbextension enable --py --sys-prefix widgetsnbextension

# Install JupyterLab prebuilt extensions using pip
RUN pip install --no-cache-dir \
    jupyterlab-chart-editor \
    plotly

# Install JupyterLab themes
RUN jt -t oceans16 -f roboto -fs 12 -T

# Expose the default Jupyter port
EXPOSE 8888

# Set the default command to start JupyterLab
CMD ["start-notebook.sh"]


