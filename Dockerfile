FROM debian:latest

# Install Packages
RUN apt-get update -y; \
    apt-get install nano jq openssh-server lsb-release gnupg curl software-properties-common apache2-utils zip -y

# Install Packer and Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -; \
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"; \
    apt-get update; \ 
    apt-get install packer terraform

RUN useradd -m hetzner

RUN mkdir -p /home/hetzner/.ssh  /home/hetzner/terraform /home/hetzner/packer /home/hetzner/.config/packer/plugins

# Install custom Packer Plugin
RUN curl -LO https://github.com/ThorstenHeck/packer-plugin-hcloud/releases/download/v1.2.0/packer-plugin-hcloud_v1.2.0_x5.0_linux_amd64.zip; \
    unzip packer-plugin-hcloud_v1.2.0_x5.0_linux_amd64.zip -d home/hetzner/.config/packer/plugins; \
    mv home/hetzner/.config/packer/plugins/packer-plugin-hcloud_v1.2.0_x5.0_linux_amd64 home/hetzner/.config/packer/plugins/packer-plugin-hcloud


RUN echo "Host *\n\tStrictHostKeyChecking no\n" >> /home/hetzner/.ssh/config
WORKDIR /home/hetzner

RUN chown -R hetzner:hetzner /home/hetzner /tmp

USER hetzner

COPY --chown=hetzner hetzner_setup.sh /home/hetzner/hetzner_setup.sh
COPY --chown=hetzner secret.env /home/hetzner/secret.env
COPY --chown=hetzner config.template.xml /home/hetzner/config.template.xml
COPY --chown=hetzner packer /home/hetzner/packer
COPY --chown=hetzner terraform /home/hetzner/terraform
# Enable Auto-completion
RUN packer -autocomplete-install; \
    terraform -install-autocomplete

ENTRYPOINT ["bash","hetzner_setup.sh"]