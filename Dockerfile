FROM python:3.12-alpine

LABEL maintainer="Rhino Assessment Team <cloudgoat@rhinosecuritylabs.com>"
LABEL cloudgoat.version="2.1.0"

# Install bash, necessary tools, AWS CLI, and Terraform in a single layer
RUN apk add --no-cache \
    bash \
    bash-completion \
    docker-bash-completion \
    openssh \
    curl \
    unzip \
    # Install jq to parse JSON and detect architecture
    jq \
    # Detect architecture
    && ARCH=$(uname -m) \
    && case "$ARCH" in \
        x86_64) DOWNLOAD_URL="https://releases.hashicorp.com/terraform/1.11.2/terraform_1.11.2_linux_amd64.zip" ;; \
        i686) DOWNLOAD_URL="https://releases.hashicorp.com/terraform/1.11.2/terraform_1.11.2_linux_386.zip" ;; \
        aarch64) DOWNLOAD_URL="https://releases.hashicorp.com/terraform/1.11.2/terraform_1.11.2_linux_arm64.zip" ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac \
    # Download Terraform based on architecture
    && wget -O terraform.zip $DOWNLOAD_URL \
    # Extract Terraform directly to /usr/bin
    && unzip terraform.zip -d /usr/bin/ \
    # Remove the downloaded zip file to keep the image smaller
    && rm terraform.zip \
    # Install AWS CLI without cache to reduce image size
    && pip3 install --no-cache-dir awscli==1.38.11 --upgrade

# Install CloudGoat
WORKDIR /usr/src/cloudgoat/
COPY ./ ./
RUN pip3 install --no-cache-dir .

ENTRYPOINT ["/bin/bash"]
