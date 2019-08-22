FROM python:3.8.0b2-alpine3.10

LABEL maintainer="Rhino Assessment Team <cloudgoat@rhinosecuritylabs.com>"
LABEL cloudgoat.version="2.0.0"
 
RUN apk add --update bash bash-completion docker-bash-completion openssh curl

# Install Terraform and AWS CLI
RUN wget -O terraform.zip https://releases.hashicorp.com/terraform/0.12.3/terraform_0.12.3_linux_amd64.zip \
    && unzip terraform.zip \
    && rm terraform.zip \
    && mv ./terraform /usr/bin/ \
    && pip3 install awscli --upgrade

# Install CloudGoat
WORKDIR /usr/src/cloudgoat/core/python
COPY ./core/python/requirements.txt ./
RUN pip3 install -r ./requirements.txt

WORKDIR /usr/src/cloudgoat/
COPY ./ ./

ENTRYPOINT ["/bin/bash"]