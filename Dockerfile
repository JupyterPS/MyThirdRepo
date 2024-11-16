# Use the official Jupyter Base image with Python 3.11
FROM jupyter/base-notebook:python-3.11

# Set noninteractive frontend for apt
ENV DEBIAN_FRONTEND=noninteractive
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# Ensure apt-get permissions and state are correct
USER root
RUN rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/lib/apt/lists/partial \
    && chmod -R 755 /var/lib/apt/lists

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libicu-dev \
    libssl-dev \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Return back to the default Jupyter user
USER jovyan

# Install .NET SDK (3.1)
RUN dotnet_sdk_version=3.1.301 \
    && curl -SL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/$dotnet_sdk_version/dotnet-sdk-$dotnet_sdk_version-linux-x64.tar.gz \
    && dotnet_sha512='dd39931df438b8c1561f9a3bdb50f72372e29e5706d3fb4c490692f04a3d55f5acc0b46b8049bc7ea34dedba63c71b4c64c57032740cbea81eef1dce41929b4e' \
    && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -ozxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
    && dotnet help

# Upgrade pip and install Python libraries
RUN python -m pip install --upgrade pip \
    && python -m pip install numpy pandas matplotlib scipy ipywidgets \
    && python -m pip install jupyter_contrib_nbextensions jupyterthemes spotipy redis nteract_on_jupyter

# Configure Jupyter notebook extensions
RUN jupyter contrib nbextension install --user \
    && jupyter nbextension enable --py --sys-prefix widgetsnbextension

# Install JupyterLab extensions for Plotly and chart editing
RUN pip install jupyterlab-plotly jupyterlab-chart-editor \
    && jupyter lab build

# Set up nteract extension
RUN jupyter labextension install @nteract/jupyterlab

# Final cleanup to reduce image size
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Expose the default Jupyter port
EXPOSE 8888

# Start Jupyter Notebook
CMD ["start-notebook.sh"]


