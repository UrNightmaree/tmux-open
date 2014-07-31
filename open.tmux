#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/scripts/helpers.sh"

default_open_key="o"
open_option="@open"

default_open_editor_key="C-o"
open_editor_option="@open_editor"
open_editor_override="@open_editor_command"

command_exists() {
	local command="$1"
	type "$command" >/dev/null 2>&1
}

is_osx() {
	local platform=$(uname)
	[ "$platform" == "Darwin" ]
}

# 1. write a command to the terminal, example: 'vim -- some_file.txt'
# 2. invoke the command by pressing enter/C-m
command_generator() {
	local command_string="$1"
	echo "cat - | xargs tmux send-keys '$command_string '; tmux send-keys 'C-m'"
}

generate_open_command() {
	if is_osx; then
		echo "$(command_generator "open")"
	elif command_exists "xdg-open"; then
		echo "$(command_generator "xdg-open")"
	else
		# error command for Linux machines when 'xdg-open' not installed
		"$CURRENT_DIR/scripts/tmux_open_error_message.sh xdg-open"
	fi
}

generate_editor_command() {
	local editor=$(get_tmux_option "$open_editor_override" "$EDITOR")
	# vim freezes terminal unless there's the '--' argument. Other editors seem
	# to be fine with it (textmate [mate], light table [table]).
	echo "$(command_generator "$editor --")"
}

set_copy_mode_open_bindings() {
	local open_command="$(generate_open_command)"
	local key_bindings=$(get_tmux_option "$open_option" "$default_open_key")
	local key
	for key in $key_bindings; do
		tmux bind-key -t vi-copy    "$key" copy-pipe "$open_command"
		tmux bind-key -t emacs-copy "$key" copy-pipe "$open_command"
	done
}

set_copy_mode_open_editor_bindings() {
	local editor_command="$(generate_editor_command)"
	local key_bindings=$(get_tmux_option "$open_editor_option" "$default_open_editor_key")
	local key
	for key in $key_bindings; do
		tmux bind-key -t vi-copy    "$key" copy-pipe "$editor_command"
		tmux bind-key -t emacs-copy "$key" copy-pipe "$editor_command"
	done
}

main() {
	set_copy_mode_open_bindings
	set_copy_mode_open_editor_bindings
}
main