FROM ubuntu:16.04

RUN /usr/bin/apt-get update -q && \
    /usr/bin/apt-get install -qqy build-essential git && \
    /usr/bin/apt-get install -qqy python python-dev python-distribute python-pip && \
    /usr/bin/apt-get install -qqy uwsgi uwsgi-plugin-python && \
    /usr/bin/apt-get clean && \
    /bin/rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY /web/web-app.ini /etc/uwsgi/apps-enabled/

ARG BRANCH
RUN /bin/mkdir /opt/web-app && \
    cd /opt/web-app && \
    /usr/bin/git clone -b ${BRANCH} https://github.com/jamfit/Casper-HC.git /opt/web-app && \
    /usr/bin/pip install -r requirements.txt && \
    /bin/chown -R www-data:www-data /opt/web-app

ARG FLASK_CONFIG_FILE
ENV FLASK_CONFIG_FILE ${FLASK_CONFIG_FILE}
COPY /${FLASK_CONFIG_FILE} /opt/web-app/casper

CMD ["uwsgi", "--ini", "/etc/uwsgi/apps-enabled/web-app.ini"]
