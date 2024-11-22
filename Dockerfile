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

# Step 6: Reinstall Jupyter notebook for compatibility                           <<<<<<<<<<<<<< 1                      
#RUN python -m pip install --upgrade --no-deps --force-reinstall notebook
#RUN python -m pip install --user numpy spotipy scipy matplotlib ipython jupyter pandas sympy nose

RUN jupyter lab build 

# Install JupyterLab Git and related extensions                <<<<<<<<<<<< 2
#RUN python -m pip install jupyterlab-git jupyterlab_github
#RUN jupyter labextension install @jupyterlab/git

#Working Directory
# Install Jupyter themes and additional Python packages        <<<<<<<<<<<< 3
#RUN python -m pip install jupyterthemes numpy spotipy scipy matplotlib ipython jupyter pandas sympy nose ipywidgets

# Step 8: Set up the working directory
WORKDIR $HOME

# Step 9: Set up user and home environment variables
ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}

# Step 10: Change to root user to install system dependencies
USER root

RUN pip install --upgrade notebook
#RUN pip install --upgrade ipykernel

# Step 12: Install any additional Python dependencies (e.g., matplotlib)
RUN pip install matplotlib

# Step 8: Install requirements from a requirements.txt file (if available)            
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt    

# Install Python dependencies                                           
RUN python -m pip install --upgrade pip \
    && pip install powershell-kernel matplotlib

# Set up PowerShell kernel for Jupyter                                
RUN python -m powershell_kernel.install

# Step 8: Install requirements from a requirements.txt file (if available)
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Step 9: Setup PowerShell kernel (automatically runs when the container starts)
RUN python -m powershell_kernel.install

# Step 15: Install requirements from a requirements.txt file (if available)       
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt    

# Step 16: Switch back to the default Jupyter user
USER $NB_USER

# Step 17: Expose the necessary JupyterLab port
EXPOSE 8888

# Step 18: Set the entrypoint to start Jupyter Lab with PowerShell available as a kernel
CMD ["start.sh", "jupyter", "lab", "--NotebookApp.token=''"]
