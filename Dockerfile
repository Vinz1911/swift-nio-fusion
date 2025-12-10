FROM swift:6.2.1-jammy
WORKDIR /root

# Copy nio server files
COPY Package.resolved ./
COPY Package.swift ./
COPY Sources ./Sources
COPY Tests ./Tests

# Build NIOFusion server
RUN swift build -c release --product NIOFusion

# Run server on exposed port
EXPOSE 7878
CMD [".build/release/NIOFusion"]
