FROM 'amazonlinux:2'

ENV PYENV_ROOT="/usr/local/pyenv"
ENV XDG_CONFIG_HOME="/usr/local"
ENV NVM_DIR="/usr/local/nvm"
ENV PATH="/usr/local/pyenv/bin:/usr/local/bin:/usr/bin/:/bin:/opt/bin:/usr/sbin"

SHELL ["/bin/bash", "-l", "-c"]

RUN yum update -y
RUN yum install -y git \
                   which \
                   shadow-utils \
                   sudo \
                   tar \
                   gzip \
                   unzip \
                   zip \
                   curl \
                   procps-ng

# Pyenv
RUN yum install -y gcc \
                   zlib-devel \
                   bzip2 \
                   bzip2-devel \
                   readline-devel \
                   sqlite \
                   sqlite-devel \
                   openssl-devel \
                   tk-devel \
                   libffi-devel

WORKDIR /tmp

# AWS CLI
RUN curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install

RUN useradd -m -d /home/playground \
               -s /bin/bash \
               -c "Lambda Playground" playground \
    && mkdir -p /home/playground/.ssh \
                /home/playground/.config \
                /home/playground/bin \
                /home/playground/workdir \
                /home/playground/.bundle \
    && mkdir -p /root/.bundle

# Runtimes supported:
#
# We currently support Ruby, Python and NodeJS. For each runtime, we're installing
# the official SDKs. More details here: https://amzn.to/33n9HQI

# RVM
RUN curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
RUN curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
RUN curl -sSL https://get.rvm.io | bash -s stable

# Do docs
RUN echo 'gem: --no-document' | tee -a /root/.gemrc
RUN echo 'gem: --no-document' | tee -a /home/playground/.gemrc

WORKDIR /usr/local

RUN source rvm/scripts/rvm \
    && rvm install 2.5 \
    && rvm use 2.5 \
    && gem install bundler \
    \
    && rvm install 2.7 \
    && rvm use 2.7 \
    && gem install bundler

RUN python -c 'print("---\nBUNDLE_PATH: \"/root/workdir\"")' | tee -a /root/.bundle/config
RUN python -c 'print("---\nBUNDLE_PATH: \"/home/playground/workdir\"")' | tee -a /home/playground/.bundle/config

RUN source rvm/scripts/rvm \
    && rvm use 2.5 \
    && gem install aws-sdk --version '3.0.1' \
    && rvm use 2.7 \
    && gem install aws-sdk --version '3.0.1'

RUN curl -s https://pyenv.run | bash \
    && eval "$(./pyenv/bin/pyenv init -)" \
    && eval "$(./pyenv/bin/pyenv virtualenv-init -)" \
    && pyenv install 2.7.18 \
    && pyenv install 3.7.9 \
    && pyenv install 3.8.6 \
    && pyenv install 3.9.0

RUN eval "$(./pyenv/bin/pyenv init -)" \
    && eval "$(./pyenv/bin/pyenv virtualenv-init -)" \
    && pyenv global 2.7.18 \
    && pip install --upgrade pip \
    && pip install botocore==1.18.16 \
    && pip install boto3==1.15.16 \
    \
    && pyenv global 3.7.9 \
    && pip install --upgrade pip \
    && pip install botocore==1.18.16 \
    && pip install boto3==1.15.16 \
    \
    && pyenv global 3.8.6 \
    && pip install --upgrade pip \
    && pip install botocore==1.18.16 \
    && pip install boto3==1.15.16 \
    \
    && pyenv global 3.9.0 \
    && pip install --upgrade pip \
    && pip install botocore==1.18.16 \
    && pip install boto3==1.15.16

# NVM
RUN curl -s -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.1/install.sh | bash \
    && source ./nvm/nvm.sh \
    && nvm install 10 \
    && nvm install 12

RUN source ./nvm/nvm.sh \
    && nvm use 10 \
    && npm install -g aws-sdk@2.771.0 \
    && nvm use 12 \
    && npm install -g aws-sdk@2.771.0

RUN chown -R playground:playground /home/playground

WORKDIR /home/playground/workdir

RUN yum remove -y sudo \
    && yum clean all \
    && rm -rf /tmp/* \
              /var/cache/yum \
              /root/.cache \
              /root/.gem \
              /root/.npm \
              /root/.gnupg
