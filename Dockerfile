# Use a base image
FROM ubuntu:latest

# Install necessary tools and dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    unzip \
    apt-transport-https \
    ca-certificates \
    gnupg \
    software-properties-common \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install Vagrant
RUN wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update && apt-get install -y vagrant

# Install Terraform
RUN wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip \
    && unzip terraform_1.5.7_linux_amd64.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform_1.5.7_linux_amd64.zip

# Install VirtualBox
RUN wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add - \
    && add-apt-repository "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" \
    && apt-get update \
    && apt-get install -y virtualbox \
    && LATEST_VERSION=$(curl -sL https://download.virtualbox.org/virtualbox/LATEST-STABLE.TXT) \
    && EXTENSION_PACK="Oracle_VM_VirtualBox_Extension_Pack-$LATEST_VERSION.vbox-extpack" \
    && wget "https://download.virtualbox.org/virtualbox/$LATEST_VERSION/$EXTENSION_PACK" \
    && VBoxManage extpack install --replace "$EXTENSION_PACK" \
    && rm "$EXTENSION_PACK"

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install krew
RUN set -x; cd "$(mktemp -d)" \
    && OS="$(uname | tr '[:upper:]' '[:lower:]')" \
    && ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" \
    && KREW="krew-${OS}_${ARCH}" \
    && curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" \
    && tar zxvf "${KREW}.tar.gz" \
    && ./"${KREW}" install krew

# Install Minikube
RUN curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
    && install minikube-linux-amd64 /usr/local/bin/minikube \
    && rm minikube-linux-amd64

# Install Kind
RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64 \
    && chmod +x ./kind \
    && mv ./kind /usr/local/bin/

# Install kubectx and kubens
RUN git clone https://github.com/ahmetb/kubectx /opt/kubectx \
    && ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx \
    && ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# Install Google Cloud SDK
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    gnupg \
    curl \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.asc] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.asc add - \
    && apt-get update && apt-get install -y google-cloud-sdk \
    && gcloud components install gke-gcloud-auth-plugin

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Python and pip
RUN apt-get install -y python3.10-venv python3-pip

# Install pipx
RUN python3 -m pip install --user pipx \
    && python3 -m pipx ensurepath

# Install Ansible using pipx
RUN pipx install --include-deps ansible

# Set up kubectx and kubens
RUN git clone https://github.com/ahmetb/kubectx.git ~/.kubectx \
    && COMPDIR=$(pkg-config --variable=completionsdir bash-completion) \
    && ln -sf ~/.kubectx/completion/kubens.bash $COMPDIR/kubens \
    && ln -sf ~/.kubectx/completion/kubectx.bash $COMPDIR/kubectx \
    && kubectl krew install ctx \
    && kubectl krew install ns \
    && echo 'export PATH=~/.kubectx:$PATH' >> ~/.bashrc

# Install Visual Studio Code
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg \
    && install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg \
    && echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list \
    && rm packages.microsoft.gpg \
    && apt-get install -y apt-transport-https \
    && apt-get update \
    && apt-get install -y code

# Install GitHub Desktop
RUN wget https://github.com/shiftkey/desktop/releases/download/release-3.1.1-linux1/GitHubDesktop-linux-3.1.1-linux1.deb \
    && gdebi --non-interactive GitHubDesktop-linux-3.1.1-linux1.deb \
    && rm GitHubDesktop-linux-3.1.1-linux1.deb

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /
