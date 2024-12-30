#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# VM user tweaks (both root & student)

# docker without sudo
usermod -aG docker student || true

# this will be ran as the `student` / `root` users
function _install_home_config() {
	set -e
	# bashrc:
	mkdir -p $HOME/.config
	install -m755 "$RL_SRC/rl_files/home/bashrc" "$HOME/.bashrc"

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

	# pwndbg!
	[[ -d "$HOME/pwndbg" ]] || git clone https://github.com/pwndbg/pwndbg "$HOME/pwndbg"
	(
		cd "$HOME/pwndbg";
		PWNDBG_VENV_PATH=./.venv
		# create Python virtual environment and install dependencies in it
		[[ -d "${PWNDBG_VENV_PATH}" ]] || python3 -m venv -- ${PWNDBG_VENV_PATH}
		PYTHON=${PWNDBG_VENV_PATH}/bin/python
		# upgrade pip itself
		${PYTHON} -m pip install --upgrade pip
		${PWNDBG_VENV_PATH}/bin/pip install -e .
		echo "source $PWD/gdbinit.py" > "$HOME/.gdbinit"
	)
}
echo "$(declare -f _install_home_config); _install_home_config" | su -c bash student
echo "$(declare -f _install_home_config); _install_home_config" | su -c bash root


