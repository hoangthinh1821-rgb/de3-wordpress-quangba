FROM nginx:alpine

LABEL org.opencontainers.image.title="de3-nginx" \
      org.opencontainers.image.description="Reverse proxy + TLS cho website quang ba san pham (De 3)" \
      org.opencontainers.image.version="1.0"

# Xoá cấu hình mặc định
RUN rm -f /etc/nginx/conf.d/default.conf

# Cấu hình chính (đã tắt server_tokens, bật gzip, log format có thời gian phản hồi)
COPY nginx.conf /etc/nginx/nginx.conf

# Template được entrypoint chạy envsubst -> /etc/nginx/conf.d/default.conf
COPY templates/ /etc/nginx/templates/

EXPOSE 80 443

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD wget -q --no-check-certificate -O /dev/null https://localhost/healthz || exit 1

STOPSIGNAL SIGQUIT
CMD ["nginx", "-g", "daemon off;"]
