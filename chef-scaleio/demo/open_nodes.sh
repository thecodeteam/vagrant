tmux split-window -h -t 1 "vagrant ssh centos1"
tmux select-pane -R
tmux send-keys -t 1.2 "while true; do sudo chef-client; sleep 2; done" C-m
sleep 2
tmux split-window -v -t 1.2 "vagrant ssh centos2"
tmux select-pane -D
tmux send-keys -t 1.3 "while true; do sudo chef-client; sleep 2; done" C-m
sleep 2
tmux split-window -v -t 1.3 "vagrant ssh centos3"
tmux select-pane -D
tmux send-keys -t 1.4 "while true; do sudo chef-client; sleep 2; done" C-m
