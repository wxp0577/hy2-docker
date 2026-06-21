FROM tobyxdd/hysteria:latest AS builder

FROM alpine:latest
RUN apk add --no-cache openssl tzdata ca-certificates
COPY --from=builder /usr/local/bin/hysteria /usr/local/bin/hysteria
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
