# Stage 1: Build Stage
FROM node:lts-alpine AS builder

# Enable and prepare pnpm
RUN corepack enable pnpm
RUN corepack prepare pnpm@latest --activate
    
WORKDIR /app/sooperwizer
COPY . .

RUN pnpm install --frozen-lockfile
RUN pnpm build:production -F frontend-pack-station

# Stage 2: Runtime Stage
FROM node:lts-alpine

# Enable and use pnpm
RUN corepack enable pnpm && corepack prepare pnpm@latest --activate

# Set working directory
WORKDIR /app/sooperwizer

# Copy the build artifacts from the build stage
COPY --from=builder /app/sooperwizer/apps/frontend-pack-station/build ./apps/frontend-pack-station/build
COPY --from=builder /app/sooperwizer/apps/frontend-pack-station/package.json ./apps/frontend-pack-station/package.json

WORKDIR /app/sooperwizer/apps/frontend-pack-station
# Start the application
CMD ["npm", "start"]