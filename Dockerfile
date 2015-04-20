FROM debian:wheezy

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r rabbitmq && useradd -r -d /var/lib/rabbitmq -m -g rabbitmq rabbitmq

RUN apt-get update && apt-get install -y curl ca-certificates --no-install-recommends && rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.3/gosu-$(dpkg --print-architecture)" \
	&& curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.3/gosu-$(dpkg --print-architecture).asc" \
	&& gpg --verify /usr/local/bin/gosu.asc \
	&& rm /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu

# Add the officially endorsed Erlang debian repository:
# See:
#  - http://www.erlang.org/download.html
#  - https://www.erlang-solutions.com/downloads/download-erlang-otp
RUN apt-key adv --keyserver pool.sks-keyservers.net --recv-keys 434975BD900CCBE4F7EE1B1ED208507CA14F4FCA
RUN echo 'deb http://packages.erlang-solutions.com/debian wheezy contrib' > /etc/apt/sources.list.d/erlang.list

# http://www.rabbitmq.com/install-debian.html
# "Please note that the word testing in this line refers to the state of our release of RabbitMQ, not any particular Debian distribution."
RUN apt-key adv --keyserver pool.sks-keyservers.net --recv-keys F78372A06FF50C80464FC1B4F7B8CEA6056E8E56
RUN echo 'deb http://www.rabbitmq.com/debian/ testing main' > /etc/apt/sources.list.d/rabbitmq.list

ENV RABBITMQ_VERSION 3.5.1-1

RUN apt-get update && apt-get install -y rabbitmq-server=$RABBITMQ_VERSION --no-install-recommends && rm -rf /var/lib/apt/lists/*

# /usr/sbin/rabbitmq-server has some irritating behavior, and only exists to "su - rabbitmq /usr/lib/rabbitmq/bin/rabbitmq-server ..."
ENV PATH /usr/lib/rabbitmq/bin:$PATH

# get logs to stdout (thanks to http://www.superpumpup.com/docker-rabbitmq-stdout for inspiration)
# TODO figure out what we'd need to do to add "(sasl_)?" to this sed and have it work ("{"init terminating in do_boot",{rabbit,failure_during_boot,{error,{cannot_log_to_tty,sasl_report_tty_h,not_installed}}}}")
RUN sed -E 's!^(\s*-rabbit\s+error_logger)\s+\S*!\1 tty!' /usr/lib/rabbitmq/lib/rabbitmq_server-*/sbin/rabbitmq-server > /tmp/rabbitmq-server \
	&& chmod +x /tmp/rabbitmq-server \
	&& mv /tmp/rabbitmq-server /usr/lib/rabbitmq/lib/rabbitmq_server-*/sbin/rabbitmq-server

RUN echo '[{rabbit, [{loopback_users, []}]}].' > /etc/rabbitmq/rabbitmq.config

VOLUME /var/lib/rabbitmq

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 5672
CMD ["rabbitmq-server"]
