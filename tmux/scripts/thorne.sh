#!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $current_dir/utils.sh
source $current_dir/colors.sh
source $current_dir/theme.sh

main() {
  tmux bind-key -r T run-shell "#{@thorne-root}/menu_items/main.sh"

  # set theme
  theme=$(get_tmux_option "@thorne-theme" "")
  ignore_window_colors=$(get_tmux_option "@thorne-ignore-window-colors" false)

  set_theme $theme

  # set configuration option variables
  show_kubernetes_context_label=$(get_tmux_option "@thorne-kubernetes-context-label" "")
  eks_hide_arn=$(get_tmux_option "@thorne-kubernetes-eks-hide-arn" false)
  eks_extract_account=$(get_tmux_option "@thorne-kubernetes-eks-extract-account" false)
  hide_kubernetes_user=$(get_tmux_option "@thorne-kubernetes-hide-user" false)
  terraform_label=$(get_tmux_option "@thorne-terraform-label" "")
  show_fahrenheit=$(get_tmux_option "@thorne-show-fahrenheit" false)
  show_location=$(get_tmux_option "@thorne-show-location" true)
  fixed_location=$(get_tmux_option "@thorne-fixed-location")
  show_powerline=$(get_tmux_option "@thorne-show-powerline" false)
  show_flags=$(get_tmux_option "@thorne-show-flags" false)
  status_bg=$(get_tmux_option "@thorne-status-bg" gray)

  # left icon area
  left_icon=$(get_tmux_option "@thorne-left-icon" session)
  left_icon_bg=$(get_tmux_option "@thorne-left-icon-bg" green)
  left_icon_fg=$(get_tmux_option "@thorne-left-icon-fg" dark_gray)
  left_icon_prefix_bg=$(get_tmux_option "@thorne-left-icon-prefix-on-bg" yellow)
  left_icon_prefix_fg=$(get_tmux_option "@thorne-left-icon-prefix-on-fg" dark_gray)
  left_icon_padding_left=$(get_tmux_option "@thorne-left-icon-padding-left" 1)
  left_icon_padding_right=$(get_tmux_option "@thorne-left-icon-padding-right" 1)
  left_icon_margin_right=$(get_tmux_option "@thorne-left-icon-margin-right" 1)
  show_left_icon_padding=$(get_tmux_option "@thorne-left-icon-padding" 1)
  show_military=$(get_tmux_option "@thorne-military-time" false)
  timezone=$(get_tmux_option "@thorne-set-timezone" "")
  show_timezone=$(get_tmux_option "@thorne-show-timezone" true)
  show_left_sep=$(get_tmux_option "@thorne-show-left-sep" )
  show_right_sep=$(get_tmux_option "@thorne-show-right-sep" )
  show_border_contrast=$(get_tmux_option "@thorne-border-contrast" false)
  show_day_month=$(get_tmux_option "@thorne-day-month" false)
  show_refresh=$(get_tmux_option "@thorne-refresh-rate" 5)
  show_synchronize_panes_label=$(get_tmux_option "@thorne-synchronize-panes-label" "Sync")
  time_format=$(get_tmux_option "@thorne-time-format" "")
  show_ssh_session_port=$(get_tmux_option "@thorne-show-ssh-session-port" false)
  IFS=' ' read -r -a plugins <<<$(get_tmux_option "@thorne-plugins" "battery network weather")
  show_empty_plugins=$(get_tmux_option "@thorne-show-empty-plugins" false)

  # Handle left icon configuration
  case $left_icon in
  smiley)
    left_icon_content="☺"
    ;;
  session)
    left_icon_content="#S"
    ;;
  window)
    left_icon_content="#W"
    ;;
  hostname)
    left_icon_content="#H"
    ;;
  username)
    left_icon=$(whoami)
    ;;
  shortname)
    left_icon_content="#h"
    ;;
  *)
    left_icon_content=$left_icon
    ;;
  esac

  icon_pd_l=""
  if [ "$left_icon_padding_left" -gt "0" ]; then
    icon_pd_l="$(printf '%*s' $left_icon_padding_left)"
  fi
  icon_pd_r=""
  if [ "$left_icon_padding_right" -gt "0" ]; then
    icon_pd_r="$(printf '%*s' $left_icon_padding_right)"
  fi

  # Handle powerline option
  if $show_powerline; then
    left_sep="$show_left_sep"
    right_sep="$show_right_sep"
  else # if disable powerline mark, equal to '', unify the logic of string.
    left_sep=''
    right_sep=''
    window_left_sep=''
    window_right_sep=''
  fi

  # Left icon, with prefix status
  tmux set-option -g status-left "#[fg=cyan]#[fg=black]#[bg=cyan]#I #[bg=brightblack]#[fg=white] #W#[fg=brightblack]#[bg=default]"
  powerbg=default

  # Set timezone unless hidden by configuration
  if [[ -z "$timezone" ]]; then
    case $show_timezone in
    false)
      timezone=""
      ;;
    true)
      timezone="#(date +%Z)"
      ;;
    esac
  fi

  case $show_flags in
  false)
    flags=""
    current_flags=""
    ;;
  true)
    flags="#{?window_flags,#[fg=${dark_purple}]#{window_flags},}"
    current_flags="#{?window_flags,#[fg=${light_purple}]#{window_flags},}"
    ;;
  esac

  # sets refresh interval to every 5 seconds
  tmux set-option -g status-interval $show_refresh

  # set the prefix + t time format
  if $show_military; then
    tmux set-option -g clock-mode-style 24
  else
    tmux set-option -g clock-mode-style 12
  fi

  # set length
  tmux set-option -g status-left-length 100
  tmux set-option -g status-right-length 100

  # pane border styling
  if $show_border_contrast; then
    tmux set-option -g pane-active-border-style "fg=${light_purple}"
  else
    tmux set-option -g pane-active-border-style "fg=${dark_purple}"
  fi
  tmux set-option -g pane-border-style "fg=${gray}"

  # message styling
  tmux set-option -g message-style "bg=${gray},fg=${white}"

  # status bar
  tmux set-option -g status-style "bg=${!status_bg},fg=${white}"

  # Handle left icon margin
  icon_mg_r=""
  if [ "$left_icon_margin_right" -gt "0" ]; then
    icon_mg_r="$(printf '%*s' $left_icon_margin_right)"
  fi

  # Status right
  tmux set-option -g status-right ""

  for plugin in "${plugins[@]}"; do

    if case $plugin in custom:*) true ;; *) false ;; esac then
      script=${plugin#"custom:"}
      if [[ -x "${current_dir}/${script}" ]]; then
        IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-custom-plugin-colors" "cyan dark_gray")
        script="#($current_dir/${script})"
      else
        colors[0]="red"
        colors[1]="dark_gray"
        script="${script} not found!"
      fi

    elif [ $plugin = "cwd" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-cwd-colors" "dark_gray white")
      tmux set-option -g status-right-length 250
      script="#($current_dir/cwd.sh)"

    elif [ $plugin = "fossil" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-fossil-colors" "green dark_gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/fossil.sh)"

    elif [ $plugin = "git" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-git-colors" "green dark_gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/git.sh)"

    elif [ $plugin = "hg" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-hg-colors" "green dark_gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/hg.sh)"

    elif [ $plugin = "battery" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-battery-colors" "pink dark_gray")
      script="#($current_dir/battery.sh)"

    elif [ $plugin = "gpu-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-gpu-usage-colors" "pink dark_gray")
      script="#($current_dir/gpu_usage.sh)"

    elif [ $plugin = "gpu-ram-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-gpu-ram-usage-colors" "cyan dark_gray")
      script="#($current_dir/gpu_ram_info.sh)"

    elif [ $plugin = "gpu-power-draw" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-gpu-power-draw-colors" "green dark_gray")
      script="#($current_dir/gpu_power.sh)"

    elif [ $plugin = "cpu-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-cpu-usage-colors" "orange dark_gray")
      script="#($current_dir/cpu_info.sh)"

    elif [ $plugin = "ram-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-ram-usage-colors" "cyan dark_gray")
      script="#($current_dir/ram_info.sh)"

    elif [ $plugin = "tmux-ram-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-tmux-ram-usage-colors" "cyan dark_gray")
      script="#($current_dir/tmux_ram_info.sh)"

    elif [ $plugin = "network" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-network-colors" "cyan dark_gray")
      script="#($current_dir/network.sh)"

    elif [ $plugin = "network-bandwidth" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-network-bandwidth-colors" "cyan dark_gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/network_bandwidth.sh)"

    elif [ $plugin = "network-ping" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-network-ping-colors" "cyan dark_gray")
      script="#($current_dir/network_ping.sh)"

    elif [ $plugin = "network-vpn" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-network-vpn-colors" "cyan dark_gray")
      script="#($current_dir/network_vpn.sh)"

    elif [ $plugin = "attached-clients" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-attached-clients-colors" "cyan dark_gray")
      script="#($current_dir/attached_clients.sh)"

    elif [ $plugin = "mpc" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-mpc-colors" "green dark_gray")
      script="#($current_dir/mpc.sh)"

    elif [ $plugin = "spotify-tui" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-spotify-tui-colors" "green dark_gray")
      script="#($current_dir/spotify-tui.sh)"

    elif [ $plugin = "playerctl" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-playerctl-colors" "green dark_gray")
      script="#($current_dir/playerctl.sh)"

    elif [ $plugin = "kubernetes-context" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-kubernetes-context-colors" "cyan dark_gray")
      script="#($current_dir/kubernetes_context.sh $eks_hide_arn $eks_extract_account $hide_kubernetes_user $show_kubernetes_context_label)"

    elif [ $plugin = "terraform" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-terraform-colors" "light_purple dark_gray")
      script="#($current_dir/terraform.sh $terraform_label)"

    elif [ $plugin = "continuum" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-continuum-colors" "cyan dark_gray")
      script="#($current_dir/continuum.sh)"

    elif [ $plugin = "weather" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-weather-colors" "orange dark_gray")
      script="#($current_dir/weather_wrapper.sh $show_fahrenheit $show_location '$fixed_location')"

    elif [ $plugin = "time" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-time-colors" "dark_purple white")
      if [ -n "$time_format" ]; then
        script=${time_format}
      else
        if $show_day_month && $show_military; then # military time and dd/mm
          script="%a %d/%m %R ${timezone}"
        elif $show_military; then # only military time
          script="%a %m/%d %R ${timezone}"
        elif $show_day_month; then # only dd/mm
          script="%a %d/%m %I:%M %p ${timezone}"
        else
          script="%a %m/%d %I:%M %p ${timezone}"
        fi
      fi
    elif [ $plugin = "synchronize-panes" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-synchronize-panes-colors" "cyan dark_gray")
      script="#($current_dir/synchronize_panes.sh $show_synchronize_panes_label)"

    elif [ $plugin = "ssh-session" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@thorne-ssh-session-colors" "green dark_gray")
      script="#($current_dir/ssh_session.sh $show_ssh_session_port)"

    else
      continue
    fi

    if $show_powerline; then
      if $show_empty_plugins; then
        tmux set-option -ga status-right "#[fg=${!colors[0]},bg=${powerbg},nobold,nounderscore,noitalics]${right_sep}#[fg=${!colors[1]},bg=${!colors[0]}] $script "
      else
        # tmux set-option -ga status-right "#{?#{==:$script,},,#[fg=${!colors[0]},nobold,nounderscore,noitalics]${right_sep}#[fg=${!colors[1]},bg=${!colors[0]}] $script  }"
        tmux set-option -ga status-right "#{?#{==:$script,},,#[fg=${!colors[0]},nobold,nounderscore,noitalics]${left_sep}#[fg=${!colors[1]},bg=${!colors[0]}]$script#[fg=${!colors[0]},bg=default]${right_sep} }"
      fi
      powerbg=default
    else
      if $show_empty_plugins; then
        tmux set-option -ga status-right "#[fg=${!colors[1]},bg=${!colors[0]}] $script "
      else
        # tmux set-option -ga status-right "#{?#{==:$script,},,#[fg=${!colors[1]},bg=${!colors[0]}] $script }"
        # tmux set-option -ga status-right "#{?#{==:$script,},,#[fg=${!colors[0]},nobold,nounderscore,noitalics]${right_sep}#[fg=${!colors[1]},bg=${!colors[0]}]$script#[fg=${!colors[0]},bg=default]${left_sep} }"
        tmux set-option -ga status-right "#{?#{==:$script,},,#[fg=${!colors[0]},nobold,nounderscore,noitalics]${right_sep}#[fg=${!colors[1]},bg=${!colors[0]}]$script#[fg=${!colors[0]},bg=default]${left_sep} }"
      fi
    fi
  done

  # Window option
  if $show_powerline; then
    tmux set-window-option -g window-status-current-format "#[fg=${white},bg=default] "
  else
    tmux set-window-option -g window-status-current-format " ${current_flags} "
  fi

  if ! $ignore_window_colors; then
    tmux set-window-option -g window-style "fg=${white},bg=${dark_gray}"
  fi

  tmux set-window-option -g window-status-format "#[fg=${white}]#[bg=${gray}] #I #W${flags}"
  tmux set-window-option -g window-status-activity-style "bold"
  tmux set-window-option -g window-status-bell-style "bold"
  tmux set-option -g status-style "fg=white,bg=default"
  tmux set-option -ga status-left ""
  tmux set-option -ga status-right ""
  tmux set-option -g status-justify centre
  tmux set-option -g status-position bottom
  tmux set-option -g pane-active-border-style "bg=default,fg=default"
  tmux set-option -g pane-border-style "fg=default"
}

# run main function
main
