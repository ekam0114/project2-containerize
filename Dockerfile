# Stage 1: build using the full Node.js toolchain.
FROM node:24 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: serve only the generated static files.
FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
