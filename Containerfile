FROM registry.redhat.io/ubi8/ubi-minimal

# Install build deps and utilities
RUN microdnf update -y && \
    microdnf install -y \
    bash \
    gcc \
    gcc-c++ \
    make \
    git \
    golang \
    curl \
    tar \
    unzip \
    wget \
    jq \
    ca-certificates \
    autoconf \
    automake \
    libtool \
    openssl-devel && \
    microdnf clean all

# Install k6
RUN wget https://github.com/grafana/k6/releases/download/v0.49.0/k6-v0.49.0-linux-amd64.tar.gz && \
    tar -xzf k6-v0.49.0-linux-amd64.tar.gz -C /tmp && \
    mv /tmp/k6-v0.49.0-linux-amd64/k6 /usr/local/bin/k6 && \
    rm -rf /tmp/k6-v0.49.0-linux-amd64 k6-v0.49.0-linux-amd64.tar.gz

# Install Siege (official release tarball)
RUN wget http://download.joedog.org/siege/siege-4.1.7.tar.gz && \
    tar -xzf siege-4.1.7.tar.gz && \
    cd siege-4.1.7 && \
    ./configure --with-ssl && \
    make && \
    make install && \
    cd .. && \
    rm -rf siege-4.1.7 siege-4.1.7.tar.gz



# Install Hey
RUN GOBIN=/usr/local/bin go install github.com/rakyll/hey@latest

# Set working dir
RUN mkdir -p /work && chown -R 1001:0 /work
WORKDIR /work

# Copy entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Drop privileges
USER 1001

# Default entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["help"]
