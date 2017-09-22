FROM rabbitmq:alpine

RUN wget -O "$RABBITMQ_HOME/plugins/rabbitmq_delayed_message_exchange-0.0.1.ez" https://bintray.com/rabbitmq/community-plugins/download_file?file_path=rabbitmq_delayed_message_exchange-0.0.1.ez

RUN rabbitmq-plugins enable --offline rabbitmq_delayed_message_exchange
