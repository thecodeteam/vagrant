#!/bin/bash
cat << EOF > haproxy.cfg
frontend k8s-http
  bind               0.0.0.0:3000
  default_backend    rocketchat-backend
backend rocketchat-backend
  server  rocketchat   `kubectl get svc chat1-rocketchat | grep rocketchat | awk '{print $3}'`:3000
EOF
