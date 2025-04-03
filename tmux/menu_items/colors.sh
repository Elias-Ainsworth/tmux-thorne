#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"

source "$ROOT_DIR/scripts/utils.sh"

render() {
  local theme=$(get_tmux_option "@thorne-theme" "catppuccin")

  local catppuccin_title="Catppuccin"
  local kanagawa_title="Kanagawa"
  local oxocarbon_title="Oxocarbon"

  case $theme in
  catppuccin)
    catppuccin_title="Catppuccin*"
    ;;
  kanagawa)
    kanagawa_title="Kanagawa*"
    ;;
  oxocarbon)
    oxocarbon_title="Oxocarbon*"
    ;;
  esac

  tmux display-menu -T "#[align=centre fg=green]Colors" -x R -y P \
    "" \
    "" \
    "$catppuccin_title" 1 "run -b '#{@thorne-root}/scripts/actions.sh set_state_and_tmux_option theme catppuccin" \
    "$kanagawa_title" 2 "run -b '#{@thorne-root}/scripts/actions.sh set_state_and_tmux_option theme kanagawa" \
    "$oxocarbon_title" 3 "run -b '#{@thorne-root}/scripts/actions.sh set_state_and_tmux_option theme oxocarbon" \
    "" \
    "<-- Back" b "run -b 'source #{@thorne-root}/menu_items/main.sh" \
    "Close menu" q ""
}

render
