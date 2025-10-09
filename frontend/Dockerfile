# syntax=docker/dockerfile:1

# --- Build phase ---
FROM node:20-alpine AS build
WORKDIR /app

# Copy only the manifest first (small layer, great cache)
COPY package.json ./

# Create a lockfile from package.json (inside the image)
RUN npm install --package-lock-only

# Install exactly according to that lockfile
RUN npm ci

# Now bring in the rest of the app
COPY . .

# Vite production build (dist/)
RUN npm run build

# --- Runtime phase ---
FROM nginx:alpine
# Copy built SPA
COPY --from=build /app/dist /usr/share/nginx/html
# SPA routing + optional /api proxy
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
