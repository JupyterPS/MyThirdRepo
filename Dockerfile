# Step 1: Start from the official .NET SDK image
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS dotnet

# Create a new base image from the Jupyter base-notebook
# Step 2: Create a new base image from the Jupyter base-notebook
FROM jupyter/base-notebook:latest

# Switch to root user to install additional dependencies
# Step 3: Switch to root user to install additional dependencies
USER root

# Clear Docker cache
# Step 4: Clear Docker cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install required packages, n package manager, and Node.js
# Step 5: Install required packages, n package manager, and Node.js
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-dev \
    @@ -19,49 +19,104 @@ RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    libssl-dev \
    git \
    sudo \
    && curl -L https://raw.githubusercontent.com/tj/n/master/bin/n -o /usr/local/bin/n \
    && chmod +x /usr/local/bin/n \
    && n 14.17.0 \
    && python3 -m pip install --upgrade pip \
    && python3 -m pip install notebook numpy spotipy scipy matplotlib ipython jupyter pandas sympy nose

# Install JupyterLab separately to avoid memory issues
# Step 6: Install JupyterLab separately to avoid memory issues
RUN python3 -m pip install jupyterlab

# Install .NET Runtime 3.1 using the official installation script
# Step 7: Install .NET Runtime 3.1 using the official installation script
RUN curl -SL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 3.1 --install-dir /usr/share/dotnet

# Install .NET Runtime 6.0 using the official installation script
# Step 8: Install .NET Runtime 6.0 using the official installation script
RUN curl -SL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 6.0 --install-dir /usr/share/dotnet

# Install .NET Interactive tool
# Step 9: Set correct permissions and ownership for dotnet
RUN chmod -R 755 /usr/share/dotnet && chown -R jovyan:users /usr/share/dotnet
# Step 10: Create symbolic links to make dotnet commands available
RUN ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet
# Step 11: Switch to jovyan user for dotnet tool installation
USER jovyan
# Step 12: Install .NET Interactive tool
RUN /usr/share/dotnet/dotnet tool install --global Microsoft.dotnet-interactive --version 1.0.155302

# Set PATH to include .dotnet/tools
# Step 13: Add .dotnet/tools to PATH for jovyan user
ENV PATH="$PATH:/root/.dotnet/tools:/home/jovyan/.dotnet/tools"

# Ensure dotnet-interactive is installed
# Step 14: Verify dotnet and dotnet-interactive installations
RUN echo $PATH
RUN ls -la /home/jovyan/.dotnet/tools
RUN ls -la /usr/share/dotnet
RUN dotnet --info
RUN dotnet-interactive --version

# Install the .NET Interactive kernels (including PowerShell)
# Step 15: Install the .NET Interactive kernels (including PowerShell)
RUN dotnet-interactive jupyter install

# Set working directory
# Step 16: Set the working directory
WORKDIR /home/jovyan

# Copy configuration files and notebooks
COPY ./config /home/jovyan/.jupyter/
COPY ./ /home/jovyan/WindowsPowerShell/
COPY ./NuGet.config /home/jovyan/nuget.config
# Step 17: Copy configuration files and notebooks with correct ownership
COPY --chown=jovyan:users ./config /home/jovyan/.jupyter/
COPY --chown=jovyan:users ./ /home/jovyan/WindowsPowerShell/
COPY --chown=jovyan:users ./NuGet.config /home/jovyan/nuget.config

# Change ownership to jovyan user
RUN chown -R jovyan:users /home/jovyan
# Step 18: Ensure permissions for .dotnet/tools directory
RUN mkdir -p /home/jovyan/.dotnet/tools && \
    chmod -R 755 /home/jovyan/.dotnet && \
    chown -R jovyan:users /home/jovyan/.dotnet

# Switch back to jovyan user
USER jovyan
# Step 19: Install nteract for Jupyter
RUN python3 -m pip install nteract_on_jupyter

# Enable telemetry
# Step 20: Enable telemetry
ENV DOTNET_TRY_CLI_TELEMETRY_OPTOUT=false

# Final working directory
# Step 21: Install JupyterLab git extension using pip as root
USER root
RUN python3 -m pip install jupyterlab-git
# Step 22: Install JupyterLab GitHub extension using pip as root
RUN python3 -m pip install jupyterlab_github
# Step 23: Add Microsoft repository and install PowerShell
RUN wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell
# Step 24: Add jovyan to sudoers
RUN echo "jovyan ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
# Step 25: Switch back to jovyan user
USER jovyan
# Step 26: Test dotnet command
RUN sudo dotnet --info
# Step 27: Final working directory
WORKDIR /home/jovyan/WindowsPowerShell/
# Step 28: Add logging configuration and extended timeout
RUN mkdir -p /home/jovyan/.jupyter && \
    echo "c.NotebookApp.log_level = 'DEBUG'" > /home/jovyan/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.log_file = '/home/jovyan/.jupyter/jupyter.log'" >> /home/jovyan/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.ip = '0.0.0.0'" >> /home/jovyan/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.open_browser = False" >> /home/jovyan/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.shutdown_no_activity_timeout = 600" >> /home/jovyan/.jupyter/jupyter_notebook_config.py && \
    echo "c.MappingKernelManager.cull_interval = 600" >> /home/jovyan/.jupyter/jupyter_notebook_config.py && \
    echo "c.MappingKernelManager.cull_idle_timeout = 600" >> /home/jovyan/.jupyter/jupyter_notebook_config.py
# Step 29: Additional verification for dotnet tools
RUN /usr/share/dotnet/dotnet tool list --global
# Step 30: Run Jupyter Notebook
CMD jupyter notebook --allow-root --no-browser --ip=0.0.0.0 --port=8888 --NotebookApp.log_level=DEBUG
