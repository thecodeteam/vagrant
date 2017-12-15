#!/bin/sh
tmux new-session -d -s k8s 'watch -t "echo -e \"\\nNodes:\" && kubectl get nodes && echo -e \"\\nServices:\" && kubectl get svc --all-namespaces && echo -e \"\\nPods:\" && kubectl get pods --all-namespaces -o wide"'
tmux rename-window 'master'
tmux select-window -t k8s:0
tmux split-window -v
tmux -2 attach-session -t k8s
