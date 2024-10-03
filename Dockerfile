# Use a base image, e.g., Debian or any other relevant base for your app
FROM debian:bookworm

# Set environment variables (optional)
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages for your app
RUN apt-get update && apt-get install -y curl git build-essential && rm -rf /var/lib/apt/lists/*

# Copy your application files
COPY . /app
WORKDIR /app

# Install additional dependencies or build the application (if needed)
# RUN [commands to install/build]

# Set the default command to run your application
CMD ["./Jenkins-Pratice.sh"]
