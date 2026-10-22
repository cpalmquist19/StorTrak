# CommandBox runtime with Lucee 5.4 pre-installed so container starts don't download the engine.
# Lucee 5.4 is certified on Java 11, hence the jre11 base.
FROM ortussolutions/commandbox:jre11-3.23.1

ENV CFENGINE=lucee@5.4.8+2 \
    APP_DIR=/app \
    TZ=America/New_York

RUN ${BUILD_DIR}/util/warmup-server.sh
