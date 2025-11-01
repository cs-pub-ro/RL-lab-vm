#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# VM user tweaks (both root & student)

# docker without sudo
usermod -aG docker student || true

# this will be ran as the `student` / `root` users
function _install_home_config() {
	set -e
	# bashrc (from rl-labs):
	mkdir -p $HOME/.config
	install -m755 "/opt/rl-labs/base/files/home/bashrc" "$HOME/.bashrc"

	# git config
    git config --global color.ui auto
    git config --global user.name 'Student VM'
    git config --global user.email 'student@stud.acs.upb.ro'

	# tmux config (for user, only):
	if [[ "$USER" != "root" ]]; then
		mkdir -p "$HOME/.config/tmux"
		rsync -ai "$RL_SRC/rl_files/home/tmux/" "$HOME/.config/tmux/"
		ln -sf "$HOME/.config/tmux/tmux.conf" "$HOME/.tmux.conf"
	fi

	# zsh config:
	mkdir -p $HOME/.config/zsh/
	rsync -ai "$RL_SRC/rl_files/home/zsh/" "$HOME/.config/zsh/"
	ln -sf "$HOME/.config/zsh/zshrc" "$HOME/.zshrc"
	# sudo chsh -s /usr/bin/zsh "$USER"
	# run zsh for user to install plugins
	zsh -i -c "source ~/.zshrc; exit 0"
}

_exported_script="$(declare -p RL_SRC); $(declare -f _install_home_config)"
for usr in student root; do
	#chsh -s /usr/bin/zsh "$usr"
	echo "$_exported_script; _install_home_config" | su -c bash "$usr"
done

