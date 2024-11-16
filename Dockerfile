# Use the Jupyter base image with Python 3.11
FROM jupyter/base-notebook:python-3.11

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    DOTNET_CLI_TELEMETRY_OPTOUT=1

# Run as root to install system dependencies
USER root

# Update and install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libicu-dev \
    libssl-dev \
    build-essential \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Switch to jovyan user to avoid running notebook as root
USER jovyan

# Install Python packages including Jupyter extensions and themes
RUN pip install --no-cache-dir \
    numpy \
    pandas \
    matplotlib \
    scipy \
    ipywidgets \
    jupyter_contrib_nbextensions \
    jupyterthemes \
    spotipy \
    && jupyter contrib nbextension install --user \
    && jupyter nbextension enable --py --sys-prefix widgetsnbextension

# Install the notebook package to ensure compatibility with jupyter_contrib_nbextensions
RUN pip install notebook

# Install JupyterLab extensions
RUN jupyter labextension install \
    @jupyterlab/plotly-extension \
    jupyterlab-chart-editor

# Expose the default Jupyter port
EXPOSE 8888

# Start Jupyter Lab by default
CMD ["start-notebook.sh"]

CMD ["start-notebook.sh"]



