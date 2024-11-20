#!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $current_dir/utils.sh

main() {
  # set configuration option variables
  show_krbtgt_label=$(get_tmux_option "@strocs-krbtgt-context-label" "")
  krbtgt_principal=$(get_tmux_option "@strocs-krbtgt-principal" "")
  show_kubernetes_context_label=$(get_tmux_option "@strocs-kubernetes-context-label" "")
  show_only_kubernetes_context=$(get_tmux_option "@strocs-show-only-kubernetes-context" "")
  eks_hide_arn=$(get_tmux_option "@strocs-kubernetes-eks-hide-arn" false)
  eks_extract_account=$(get_tmux_option "@strocs-kubernetes-eks-extract-account" false)
  hide_kubernetes_user=$(get_tmux_option "@strocs-kubernetes-hide-user" false)
  terraform_label=$(get_tmux_option "@strocs-terraform-label" "")
  show_fahrenheit=$(get_tmux_option "@strocs-show-fahrenheit" false)
  show_location=$(get_tmux_option "@strocs-show-location" true)
  fixed_location=$(get_tmux_option "@strocs-fixed-location")
  show_powerline=$(get_tmux_option "@strocs-show-powerline" true)
  transparent_powerline_bg=$(get_tmux_option "@strocs-transparent-powerline-bg" true)
  show_flags=$(get_tmux_option "@strocs-show-flags" false)
  show_left_icon=$(get_tmux_option "@strocs-show-left-icon" shortname)
  show_left_icon_padding=$(get_tmux_option "@strocs-left-icon-padding" 1)
  show_military=$(get_tmux_option "@strocs-military-time" false)
  timezone=$(get_tmux_option "@strocs-set-timezone" "")
  show_timezone=$(get_tmux_option "@strocs-show-timezone" true)
  show_left_sep=$(get_tmux_option "@strocs-show-left-sep" )
  show_right_sep=$(get_tmux_option "@strocs-show-right-sep" )
  show_border_contrast=$(get_tmux_option "@strocs-border-contrast" false)
  show_inverse_divider=$(get_tmux_option "@strocs-inverse-divider" )
  show_day_month=$(get_tmux_option "@strocs-day-month" false)
  show_refresh=$(get_tmux_option "@strocs-refresh-rate" 5)
  show_synchronize_panes_label=$(get_tmux_option "@strocs-synchronize-panes-label" "Sync")
  time_format=$(get_tmux_option "@strocs-time-format" "")
  show_ssh_session_port=$(get_tmux_option "@strocs-show-ssh-session-port" false)
  show_libreview=$(get_tmux_option "@strocs-show-libreview" false)
  IFS=' ' read -r -a plugins <<<$(get_tmux_option "@strocs-plugins" "battery network weather")
  show_empty_plugins=$(get_tmux_option "@strocs-show-empty-plugins" true)

  # Color Pallette
  white='#e3e1e4'
  black='#211f21'
  dark_0='#2d2a2e'
  dark_1='#37343a'
  dark_2='#3b383e'
  dark_3='#423f46'
  dark_4='#49464e'
  gray='#848089'
  green='#9ecd6f'
  red='#f85e84'
  yellow='#e5c463'
  plugins_colors=(dark_0 dark_1)

  # Override default colors and possibly add more
  colors="$(get_tmux_option "@strocs-colors" "")"
  if [ -n "$colors" ]; then
    eval "$colors"
  fi

  # Set transparency variables - Colors and window dividers
  if $transparent_powerline_bg; then
    bg_color="default"
    window_sep_fg=${dark_2}
    window_sep_bg=default
    window_sep="$show_inverse_divider"
  else
    bg_color=${black}
    window_sep_fg=${dark_2}
    window_sep_bg=${black}
    window_sep="$show_inverse_divider"
  fi

  # Handle left icon configuration
  case $show_left_icon in
  smiley)
    left_icon="☺"
    ;;
  session)
    left_icon="#S"
    ;;
  window)
    left_icon="#W"
    ;;
  hostname)
    left_icon="#H"
    ;;
  shortname)
    left_icon="#h"
    ;;
  *)
    left_icon=$show_left_icon
    ;;
  esac

  # Handle left icon padding
  padding=""
  if [ "$show_left_icon_padding" -gt "0" ]; then
    padding="$(printf '%*s' $show_left_icon_padding)"
  fi
  left_icon="$padding$left_icon"

  # Handle powerline option
  if $show_powerline; then
    right_sep="$show_right_sep"
    left_sep="$show_left_sep"
  fi

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
    flags="#{?window_flags,#[fg=${dark_2}]#{window_flags},}"
    current_flags="#{?window_flags,#[fg=${dark_4}]#{window_flags},}"
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
    tmux set-option -g pane-active-border-style "fg=${dark_4}"
  else
    tmux set-option -g pane-active-border-style "fg=${dark_2}"
  fi
  tmux set-option -g pane-border-style "fg=${gray}"

  # message styling
  tmux set-option -g message-style "bg=${dark_0},fg=${white}"

  # status bar
  tmux set-option -g status-style "bg=${bg_color},fg=${white}"

  # Status left
  if $show_powerline; then
    tmux set-option -g status-left "#[bg=${dark_0},fg=${white}]#{?client_prefix,#[fg=${yellow}],} ${left_icon} #[fg=${dark_0},bg=${bg_color}]#{?client_prefix,#[fg=${dark_0}],}${left_sep}"
    powerbg=${bg_color}
  else
    tmux set-option -g status-left "#[bg=${green},fg=${dark_0}]#{?client_prefix,#[bg=${yellow}],} ${left_icon}"
  fi

  # Status right
  tmux set-option -g status-right ""

  index=-1
  for plugin in "${plugins[@]}"; do
    ((index++))
    current_color=${plugins_colors[$index % 2]}

    if case $plugin in custom:*) true ;; *) false ;; esac then
      script=${plugin#"custom:"}
      if [[ -x "${current_dir}/${script}" ]]; then
        IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-custom-plugin-colors" "${current_color} gray")
        script="#($current_dir/${script})"
      else
        colors[0]="red"
        colors[1]="dark_0"
        script="${script} not found!"
      fi

    elif [ $plugin = "cwd" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-cwd-colors" "${current_color} gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/cwd.sh)"

    elif [ $plugin = "fossil" ]; then
      IIFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-cwd-colors" "${current_color} gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/fossil.sh)"

    elif [ $plugin = "git" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-git-colors" "${current_color} gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/git.sh)"

    elif [ $plugin = "hg" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-hg-colors" "${current_color} gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/hg.sh)"

    elif [ $plugin = "battery" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-battery-colors" "${current_color} gray")
      script="#($current_dir/battery.sh)"

    elif [ $plugin = "gpu-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-gpu-usage-colors" "${current_color} gray")
      script="#($current_dir/gpu_usage.sh)"

    elif [ $plugin = "gpu-ram-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-gpu-ram-usage-colors" "${current_color} gray")
      script="#($current_dir/gpu_ram_info.sh)"

    elif [ $plugin = "gpu-power-draw" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-gpu-power-draw-colors" "${current_color} gray")
      script="#($current_dir/gpu_power.sh)"

    elif [ $plugin = "cpu-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-cpu-usage-colors" "${current_color} gray")
      script="#($current_dir/cpu_info.sh)"

    elif [ $plugin = "ram-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-ram-usage-colors" "${current_color} gray")
      script="#($current_dir/ram_info.sh)"

    elif [ $plugin = "tmux-ram-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-tmux-ram-usage-colors" "${current_color} gray")
      script="#($current_dir/tmux_ram_info.sh)"

    elif [ $plugin = "network" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-network-colors" "${current_color} gray")
      script="#($current_dir/network.sh)"

    elif [ $plugin = "network-bandwidth" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-network-bandwidth-colors" "${current_color} gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/network_bandwidth.sh)"

    elif [ $plugin = "network-ping" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-network-ping-colors" "${current_color} gray")
      script="#($current_dir/network_ping.sh)"

    elif [ $plugin = "network-vpn" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-network-vpn-colors" "${current_color} gray")
      script="#($current_dir/network_vpn.sh)"

    elif [ $plugin = "attached-clients" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-attached-clients-colors" "${current_color} gray")
      script="#($current_dir/attached_clients.sh)"

    elif [ $plugin = "mpc" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-mpc-colors" "${current_color} gray")
      script="#($current_dir/mpc.sh)"

    elif [ $plugin = "spotify-tui" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-spotify-tui-colors" "${current_color} gray")
      script="#($current_dir/spotify-tui.sh)"

    elif [ $plugin = "krbtgt" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-krbtgt-colors" "${current_color} gray")
      script="#($current_dir/krbtgt.sh $krbtgt_principal $show_krbtgt_label)"

    elif [ $plugin = "playerctl" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-playerctl-colors" "${current_color} gray")
      script="#($current_dir/playerctl.sh)"

    elif [ $plugin = "kubernetes-context" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-kubernetes-context-colors" "${current_color} gray")
      script="#($current_dir/kubernetes_context.sh $eks_hide_arn $eks_extract_account $hide_kubernetes_user $show_only_kubernetes_context $show_kubernetes_context_label)"

    elif [ $plugin = "terraform" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-terraform-colors" "${current_color} gray")
      script="#($current_dir/terraform.sh $terraform_label)"

    elif [ $plugin = "continuum" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-continuum-colors" "${current_color} gray")
      script="#($current_dir/continuum.sh)"

    elif [ $plugin = "weather" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-weather-colors" "${current_color} gray")
      script="#($current_dir/weather_wrapper.sh $show_fahrenheit $show_location '$fixed_location')"

    elif [ $plugin = "time" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-time-colors" "${current_color} gray")
      if [ -n "$time_format" ]; then
        script=${time_format}
      else
        if $show_day_month && $show_military; then # military time and dd/mm
          script="%a %d/%m %R ${timezone} "
        elif $show_military; then # only military time
          script="%R ${timezone} "
        elif $show_day_month; then # only dd/mm
          script="%a %d/%m %I:%M %p ${timezone} "
        else
          script="%a %m/%d %I:%M %p ${timezone} "
        fi
      fi
    elif [ $plugin = "synchronize-panes" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-synchronize-panes-colors" "${current_color} gray")
      script="#($current_dir/synchronize_panes.sh $show_synchronize_panes_label)"

    elif [ $plugin = "libreview" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-libre-colors" "${current_color} gray")
      script="#($current_dir/libre.sh $show_libreview)"

    elif [ $plugin = "ssh-session" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-ssh-session-colors" "${current_color} gray")
      script="#($current_dir/ssh_session.sh $show_ssh_session_port)"

    else
      continue
    fi

    if [ $plugin = "sys-temp" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@strocs-sys-temp-colors" "${current_color} gray")
      script="#($current_dir/sys_temp.sh)"
    fi

    if $show_powerline; then
      if $show_empty_plugins; then
        tmux set-option -ga status-right "#[fg=${!colors[0]},bg=${powerbg},nobold,nounderscore,noitalics]${right_sep}#[fg=${!colors[1]},bg=${!colors[0]}] $script "
      else
        tmux set-option -ga status-right "#{?#{==:$script,},,#[fg=${!colors[0]},nobold,nounderscore,noitalics]${right_sep}#[fg=${!colors[1]},bg=${!colors[0]}] $script }"
      fi
      powerbg=${!colors[0]}
    else
      if $show_empty_plugins; then
        tmux set-option -ga status-right "#[fg=${!colors[1]},bg=${!colors[0]}] $script "
      else
        tmux set-option -ga status-right "#{?#{==:$script,},,#[fg=${!colors[1]},bg=${!colors[0]}] $script }"
      fi
    fi
  done

  # Window option
  if $show_powerline; then
    tmux set-window-option -g window-status-current-format "#[fg=${window_sep_fg},bg=${window_sep_bg}]${window_sep}#[fg=${white},bg=${dark_2}] #I #W${current_flags} #[fg=${dark_2},bg=${bg_color}]${left_sep}"
  else
    tmux set-window-option -g window-status-current-format "#[fg=${white},bg=${dark_2}] #I #W${current_flags} "
  fi

  tmux set-window-option -g window-status-format "#[fg=${white}]#[bg=${bg_color}] #I #W${flags}"
  tmux set-window-option -g window-status-activity-style "bold"
  tmux set-window-option -g window-status-bell-style "bold"
}

# run main function
main
