FROM codeclimate/alpine-ruby:0.0.1

WORKDIR /usr/src/app
COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/

RUN apk --update add git openssh-client build-base && \
    bundle install -j 4 && \
    apk del build-base && rm -fr /usr/share/ri

RUN wget -O /bin/docker https://get.docker.com/builds/Linux/x86_64/docker-1.6.0
RUN chmod +x /bin/docker

COPY . /usr/src/app

ENTRYPOINT ["/usr/src/app/bin/codeclimate"]
