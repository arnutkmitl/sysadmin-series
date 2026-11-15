FROM nginx:1.30-alpine
ARG VERSION=dev
ARG COMMIT=unknown
COPY site/ /usr/share/nginx/html/
RUN sed -i "s/@VERSION@/${VERSION}/; s/@COMMIT@/${COMMIT}/" /usr/share/nginx/html/index.html \
 && printf '{"version":"%s","commit":"%s"}\n' "$VERSION" "$COMMIT" > /usr/share/nginx/html/version.json
HEALTHCHECK --interval=10s --timeout=3s CMD wget -qO- http://127.0.0.1/version.json || exit 1
