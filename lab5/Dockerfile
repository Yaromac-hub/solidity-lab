# node:alpine will be our base image to create this image
FROM node:lts-alpine
# Set the /app directory as working directory
WORKDIR /app
# Install ganache-cli globally
RUN apk update && \
    apk add curl git
RUN npm init --yes && \
    npm install --save-dev hardhat 
COPY hardhat.config.js .
# Set the default command for the image
EXPOSE 8545
CMD ["npx", "hardhat", "node"]