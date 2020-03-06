FROM alpine:3.11

ENV BUILD_PACKAGES curl curl-dev ruby-dev build-base openssh
ENV RUBY_PACKAGES ruby ruby-io-console ruby-bundler ruby-irb

# Update and install all of the required packages.
# At the end, remove the apk cache
RUN apk update && \
    apk upgrade && \
    apk add $BUILD_PACKAGES && \
    apk add $RUBY_PACKAGES && \
    apk add git && \
    rm -rf /var/cache/apk/*

RUN mkdir /usr/app
WORKDIR /usr/app

RUN git clone https://github.com/puppetlabs/facter-ng.git facter-ng && \
    git clone https://github.com/puppetlabs/facter-statistax.git facter-statistax && \
    cd facter-statistax && \
    git fetch --all && \
    git reset --hard origin/log_to_spreadsheet

RUN cd ./facter-statistax/acceptance && \
    bundle install

RUN mkdir ~/.ssh

RUN echo $'-----BEGIN RSA PRIVATE KEY-----\n'\
$'------  Insert ------\n'\
$'------  your   ------\n'\
$'------  own    ------\n'\
$'------ rsa key ------\n'\
$'-----END RSA PRIVATE KEY-----' > ~/.ssh/id_rsa-acceptance

RUN chmod 600 ~/.ssh/id_rsa-acceptance

RUN echo $'# For vmpooler VMs.\n'\
$'------  Insert ------\n'\
$'------  your   ------\n'\
$'------  own    ------\n'\
$'------ config  ------\n' > ~/.ssh/config

RUN gem install vmfloaty

COPY google_sheets_credentials.json /usr/app/

ENTRYPOINT ruby /usr/app/facter-statistax/acceptance/log_performance/execute_beaker_tests/test_all_platforms.rb
