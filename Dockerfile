# Base image: Jupyter Notebook with Python 3
FROM jupyter/base-notebook:python-3.11

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# Update system and install required system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libicu-dev \
    libssl-dev \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install .NET Core SDK
RUN dotnet_sdk_version=3.1.301 \
    && curl -SL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/$dotnet_sdk_version/dotnet-sdk-$dotnet_sdk_version-linux-x64.tar.gz \
    && mkdir -p /usr/share/dotnet \
    && tar -ozxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

# Upgrade pip and install Python packages
RUN python -m pip install --upgrade pip \
    && python -m pip install numpy pandas matplotlib scipy ipywidgets \
    && python -m pip install jupyter_contrib_nbextensions jupyterthemes spotipy \
    && python -m pip install plotly==5.15.0 jupyterlab-chart-editor redis \
    && python -m pip install nteract_on_jupyter

# Install JupyterLab extensions
RUN jupyter contrib nbextension install --user \
    && jupyter nbextension enable --py --sys-prefix widgetsnbextension

# Enable Jupyter themes
RUN jt -t chesterish

# Configure Jupyter Notebook and Lab
RUN jupyter lab build \
    && jupyter nbextensions_configurator enable --sys-prefix \
    && jupyter nbextension enable codefolding/main \
    && jupyter nbextension enable spellchecker/main

# Add notebook extensions
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager

# Set working directory
WORKDIR /home/jovyan/work

# Expose Jupyter Notebook default port
EXPOSE 8888

# Start Jupyter Notebook
CMD ["start-notebook.sh"]

