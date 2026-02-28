# 阶段1：安装项目依赖（保留原有逻辑）
FROM docker.io/library/node:22.15.0-alpine3.21 AS mermaid-live-editor-dependencies

RUN apk --no-cache add build-base git python3 && \
    rm -rf /var/cache/apk/*

RUN corepack enable pnpm

WORKDIR /app

COPY ./package.json .
COPY ./pnpm-lock.yaml .

RUN pnpm install

# 阶段2：构建前端产物（保留原有参数和构建逻辑）
FROM mermaid-live-editor-dependencies AS mermaid-live-editor-builder

ARG MERMAID_RENDERER_URL
ARG MERMAID_KROKI_RENDERER_URL
ARG MERMAID_ANALYTICS_URL
ARG MERMAID_DOMAIN
ARG MERMAID_IS_ENABLED_MERMAID_CHART_LINKS

COPY . ./

RUN pnpm build

# 阶段3：开发环境（适配并行启动前后端的 dev 脚本）
FROM mermaid-live-editor-builder AS mermaid-dev

# 暴露开发环境端口（Vite 5173 + 后端 8081）
EXPOSE 5173 8080
ENTRYPOINT ["pnpm", "dev"]

# 阶段4：生产环境（替换原 Nginx 为 Node 后端，运行 server.js）
FROM docker.io/library/node:22.15.0-alpine3.21 AS mermaid

# 安装生产环境依赖（精简，仅保留运行时需要的）
RUN corepack enable pnpm && \
    apk --no-cache add tzdata && \
    rm -rf /var/cache/apk/*

WORKDIR /app

# 设置生产环境变量
ENV NODE_ENV=production

# 复制 package.json 和锁文件，安装生产依赖
COPY ./package.json .
COPY ./pnpm-lock.yaml .
RUN pnpm install --prod --frozen-lockfile

# 复制前端构建产物（dist 是 Vite build 输出目录，替换原 docs）
COPY --from=mermaid-live-editor-builder /app/dist ./dist

# 复制后端服务文件
COPY --from=mermaid-live-editor-builder /app/src/server.js ./src/

# 暴露后端服务端口（适配 SSH 隧道的 8081）
EXPOSE 8080

# 启动后端服务（托管前端静态文件 + CRDT/Socket.io 服务）
CMD ["node", "src/server.js"]
