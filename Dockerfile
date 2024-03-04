# Auto-generated by Cloud Code AI

# Use Ubuntu as base image
FROM ubuntu:latest

# Update Ubuntu Software repository
RUN apt-get update

# Install python3 and pip
RUN apt-get install -y python3-pip

# Install ffmpeg
RUN apt-get install -y ffmpeg

# Set the working directory in the container
WORKDIR /app

# Copy the dependencies file to the working directory
COPY requirements.txt .

# Install any dependencies
RUN pip3 install -r requirements.txt

# Copy the content of the local src directory to the working directory
COPY . .

# command to run on container start
CMD [ "python3", "app.py" ]

# This container exposes port 5000 to the outside world
EXPOSE 5000