# syntax=docker/dockerfile:1

############################
# deps stage (Option B)
############################
FROM node:20-alpine AS deps
WORKDIR /app

# Copy only the manifest first for better caching
COPY package.json ./

# Create lockfile from package.json inside the image
RUN --mount=type=cache,target=/root/.npm \
    npm install --package-lock-only

# Install exactly per the generated lockfile
RUN --mount=type=cache,target=/root/.npm \
    npm ci

############################
# test stage (runs your tests)
############################
FROM deps AS test
WORKDIR /app
ENV CI=true

# Bring in full source (incl. tests)
COPY . .

# Run tests exactly as requested
RUN npm test -- --run

############################
# build stage (only if tests passed)
############################
FROM deps AS build
WORKDIR /app
COPY . .

# Vite production build -> dist/
RUN npm run build

############################
# runtime stage (nginx)
############################
FROM nginx:alpine

# Copy built SPA
COPY --from=build /app/dist /usr/share/nginx/html

# Nginx config for SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
