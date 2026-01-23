FROM eclipse-temurin:21-jdk

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    wget \
    tigervnc-standalone-server \
    tigervnc-common \
    tigervnc-tools \
    fluxbox \
    libxtst6 \
    libxrender1 \
    libxi6 \
    libxrandr2 \
    libasound2t64 \
    openssl \
    dos2unix \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r burp && useradd -r -g burp -d /home/burp -m burp && \
    mkdir -p /home/burp/.vnc /app/burp_data && \
    chown -R burp:burp /home/burp /app/burp_data

WORKDIR /app

COPY loader.jar /app/loader.jar
RUN jar tf /app/loader.jar > /dev/null 2>&1 || (echo "ERROR: loader.jar is invalid!" && exit 1)

ENV JAVA_OPTS="--add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED -javaagent:/app/loader.jar"

EXPOSE 5901

RUN echo -e '#!/bin/bash\nfluxbox &\nwhile true; do sleep 30; done' > /home/burp/.vnc/xstartup && \
    chmod +x /home/burp/.vnc/xstartup && \
    chown -R burp:burp /home/burp/.vnc

COPY start.sh /app/start.sh
RUN dos2unix /app/start.sh && \
    chmod +x /app/start.sh && \
    chown burp:burp /app/start.sh /app/loader.jar

USER burp

CMD ["/app/start.sh"]
