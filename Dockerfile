FROM lts-alpine

COPY sk8s-push.sh /sk8s-push.sh

ENTRYPOINT ["/sk8s-push.sh"]