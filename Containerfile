FROM registry.redhat.io/ubi8/ubi-minimal

RUN microdnf update -y && \
    microdnf install -y \
    gcc \
    make \
    git \
    golang \
    curl \
    unzip \
    wget && \
    microdnf clean all

# Install k6
RUN wget https://github.com/grafana/k6/releases/download/v0.49.0/k6-v0.49.0-linux-amd64.tar.gz && \
    tar -xzf k6-v0.49.0-linux-amd64.tar.gz -C /usr/local/bin && \
    rm k6-v0.49.0-linux-amd64.tar.gz

# Install Siege
RUN git clone https://github.com/JoeDog/siege.git && \
    cd siege && \
    ./configure && \
    make && \
    make install && \
    cd .. && \
    rm -rf siege

# Install Hey
RUN go install github.com/rakyll/hey@latest

# Set the working directory
WORKDIR /app

# (Optional) Copy any test scripts or configurations here
# COPY . /app

# Change user to non root random user
USER 1001

# Define a default command to run when the container starts (e.g., to see help messages)
CMD ["bash"]
