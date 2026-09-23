FROM docker.io/library/node:22-alpine
RUN apk add --no-cache python3 make g++
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --omit=dev
COPY src ./src
COPY attachments ./attachments
ENV SQLITE_PATH=/data/qms.sqlite
RUN mkdir -p /data
EXPOSE 4000
CMD ["node", "src/index.js"]
