# Step 1: Use the official Jupyter base notebook image
FROM jupyter/base-notebook:latest

# Step 2: Install necessary system packages (including PowerShell)
USER root

# Step 3: Install necessary packages, including curl and apt dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libfreetype6-dev \
    libpng-dev \
    libblas-dev \
    liblapack-dev \
    gfortran \
    pkg-config \
    libharfbuzz-dev \
    libfribidi-dev \
    curl \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Step 4: Install PowerShell by adding the Microsoft repository
RUN curl https://packages.microsoft.com/keys/microsoft.asc | tee /etc/apt/trusted.gpg.d/microsoft.asc \
    && curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | tee /etc/apt/sources.list.d/microsoft-prod.list \
    && apt-get update && apt-get install -y powershell \
    && rm -rf /var/lib/apt/lists/*

# Step 5: Upgrade pip to the latest version
RUN python -m pip install --upgrade pip

# Step 6: Install the PowerShell Jupyter kernel
RUN pip install powershell-kernel

# Step 7: Install any additional Python dependencies (e.g., matplotlib)
RUN pip install matplotlib

# Step 8: Install requirements from a requirements.txt file (if available)
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Step 9: Setup PowerShell kernel (automatically runs when the container starts)
RUN python -m powershell_kernel.install

# Step 10: Switch back to the default Jupyter user
USER $NB_USER

# Step 11: Expose the necessary JupyterLab port
EXPOSE 8888

# Step 12: Set the entrypoint to start Jupyter Lab with PowerShell available as a kernel
CMD ["start.sh", "jupyter", "lab", "--NotebookApp.token=''"]
