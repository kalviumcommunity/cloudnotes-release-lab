# --- Stage 1: install dependencies -----------------------------------------
FROM node:20-alpine AS deps
WORKDIR /app
COPY app/package.json ./
RUN npm install --omit=dev

# --- Stage 2: runtime --------------------------------------------------------
# Intended shape: copy only the installed node_modules + app source from the
# "deps" stage above, so the final image stays small.
FROM node:20-alpine AS runtime
WORKDIR /app

# NOTE: this should copy from the "deps" stage, not "build" (no such stage
# exists in this Dockerfile).
COPY --from=deps /app/node_modules ./node_modules
COPY app/ ./

# NOTE: secrets must never be baked into the image. This should be supplied
# at runtime via an env file or Compose secret instead.

ENV PORT=8080

EXPOSE 8080
CMD ["node", "server.js"]
