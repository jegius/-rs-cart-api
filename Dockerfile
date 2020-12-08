# base
FROM node:12.20.0-alpine3.11 as base

# couchbase sdk requirements
RUN apk update && apk add curl bash python g++ make && rm -rf /var/cache/apk/*

# install node-prune (https://github.com/tj/node-prune)
RUN curl -sfL https://install.goreleaser.com/github.com/tj/node-prune.sh | bash -s -- -b /usr/local/bin

WORKDIR /app

# install dependencies
COPY package*.json ./
RUN npm ci --from-lock-file && npm cache clean --force

# build
COPY . .
RUN npm run build

# remove development dependencies
RUN npm prune --production

# run node prune
RUN /usr/local/bin/node-prune

FROM node:12.20.0-alpine3.11
WORKDIR /app

# copy from base image
COPY --from=base /app/dist ./dist
COPY --from=base /app/node_modules ./node_modules

# application
USER node
ENV PORT=8080
EXPOSE 8080

CMD ["node", "dist/main.js"]