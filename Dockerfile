# syntax=docker/dockerfile:1
ARG JAVA_VERSION=21

FROM eclipse-temurin:${JAVA_VERSION}-jdk-alpine AS build
ARG H2_VERSION
RUN test -n "$H2_VERSION" || (echo "H2_VERSION is required" && exit 1)
WORKDIR /build
RUN BASE=https://repo1.maven.org/maven2/com/h2database/h2/${H2_VERSION}/h2-${H2_VERSION} \
 && wget -q -O h2.jar ${BASE}.jar \
 && echo "$(wget -q -O - ${BASE}.jar.sha1)  h2.jar" | sha1sum -c -
# Module list: everything H2 can use, except java.desktop (only used by the
# Swing GUIConsole, useless in a container). Test any change with scripts/build-test.sh.
RUN apk add --no-cache binutils \
 && jlink \
    --add-modules java.sql,java.naming,java.management,java.scripting,java.compiler,java.instrument,jdk.compiler,jdk.net,jdk.charsets,jdk.localedata,jdk.crypto.ec \
    --strip-debug --no-header-files --no-man-pages --compress=zip-9 --output /jre \
 && find /jre -name '*.so' -exec strip --strip-unneeded {} + \
 && find /jre/bin -type f ! -name java -delete

FROM alpine:3.22
RUN addgroup -S h2 && adduser -S -G h2 -h /data h2
COPY --from=build /jre /opt/jre
COPY --from=build /build/h2.jar /opt/h2.jar
COPY --chmod=755 bin/h2-shell bin/h2-runscript /usr/local/bin/
ENV H2_OPTS="-tcp -tcpAllowOthers -web -webAllowOthers -pg -pgAllowOthers -ifNotExists -baseDir /data" \
    JAVA_OPTS=""
USER h2
WORKDIR /data
VOLUME /data
EXPOSE 9092 8082 5435
HEALTHCHECK --interval=15s --timeout=3s --start-period=10s \
  CMD nc -z 127.0.0.1 9092 || exit 1
ENTRYPOINT ["/bin/sh","-c","exec /opt/jre/bin/java $JAVA_OPTS -cp /opt/h2.jar org.h2.tools.Server $H2_OPTS"]
