FROM mcr.microsoft.com/dotnet/interactive

# Switch to root user to install additional dependencies
USER root

# Upgrade pip
RUN python -m pip install --upgrade pip

# Copy requirements.txt file
COPY requirements.txt ./requirements.txt

# Install Python packages
RUN python -m pip install -r requirements.txt

# Install additional Python packages
RUN python -m pip install --user numpy spotipy scipy matplotlib ipython jupyter pandas sympy nose

# Build JupyterLab
RUN jupyter lab build --minimize=False

# Set working directory
WORKDIR /home/jovyan

# Copy configuration files and notebooks
COPY ./config /home/jovyan/.jupyter/
COPY ./ /home/jovyan/WindowsPowerShell/
COPY ./NuGet.config /home/jovyan/nuget.config

# Change ownership to jovyan user
RUN chown -R jovyan:users /home/jovyan

# Switch back to jovyan user
USER jovyan

# Set path for .NET tools
ENV PATH="${PATH}:/home/jovyan/.dotnet/tools"

# Enable telemetry
ENV DOTNET_TRY_CLI_TELEMETRY_OPTOUT=false

# Final working directory
WORKDIR /home/jovyan/WindowsPowerShell/
