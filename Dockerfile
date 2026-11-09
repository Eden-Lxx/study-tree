# 科技树 · 容器镜像（用于云服务器 / 容器平台部署）
FROM node:20-alpine

WORKDIR /app
COPY server.js index.html ./

# 容器内必须监听 0.0.0.0，对外只通过 compose 映射到 127.0.0.1 或由 Nginx 反代
ENV PORT=8080
ENV HOST=0.0.0.0
ENV TT_DATA_DIR=/data
ENV TT_PUBLIC=1
ENV NO_OPEN=1

EXPOSE 8080
VOLUME ["/data"]

# 以非 root 用户运行
RUN addgroup -S app && adduser -S app -G app && mkdir -p /data && chown -R app:app /data
USER app

HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://127.0.0.1:8080/index.html >/dev/null 2>&1 || exit 1

CMD ["node", "server.js"]
