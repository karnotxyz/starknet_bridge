FROM node:22.10-slim AS builder

RUN apt-get update && apt-get install -y \
    git \
    curl \
    jq \
    yq \
    wget \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy only package files first
COPY pnpm-lock.yaml ./ 
COPY package.json ./ 

RUN npm i -g pnpm
# Install dependencies
RUN pnpm install --frozen-lockfile

# Install asdf
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.starkup.dev | sh -s -- --yes 
ENV HOME="/root"
ENV ASDF_DATA_DIR="/root/.asdf"
ENV PATH="${HOME}/.local/bin:${ASDF_DATA_DIR}/shims:${PATH}"

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="${HOME}/.cargo/bin:${PATH}"

COPY starkgate-contracts/scripts/setup.sh starkgate-contracts/scripts/setup.sh

# Setup starkgate-contracts
RUN ./starkgate-contracts/scripts/setup.sh

RUN ls -lah ./starkgate-contracts/.downloads/cairo/bin

# Install all tools in .tool-versions
COPY .tool-versions .tool-versions
RUN asdf install

COPY src/ ./src
COPY .tool-versions .tool-versions
COPY Scarb.* ./

# Build bridge contracts
RUN scarb build

COPY starkgate-contracts/ starkgate-contracts/
RUN cd starkgate-contracts && ./scripts/build-cairo.sh

COPY . .


# Second stage: Runner
FROM node:22.10-slim AS runner

WORKDIR /app

RUN npm i -g pnpm 
RUN apt-get update && apt-get install -y jq curl

COPY --from=builder /app/starkgate-contracts/cairo_contracts ./starkgate-contracts/cairo_contracts
COPY --from=builder /app/target ./target
COPY --from=builder /app/scripts/ ./scripts/
COPY --from=builder /app/pnpm-lock.yaml ./pnpm-lock.yaml
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules/ ./node_modules/
COPY --from=builder /app/startup.sh ./startup.sh

RUN chmod +x /app/startup.sh

ENTRYPOINT ["./startup.sh"]

CMD ["tsx", "./scripts/cli.ts"]
