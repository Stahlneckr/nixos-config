{ pkgs, ... }:

let
  trial = pkgs.writeShellApplication {
    name = "noctalia-trial";
    runtimeInputs = with pkgs; [ noctalia uwsm procps coreutils systemd waybar mako ];
    text = ''
      running() {
        pgrep -u "$UID" -x "$1" >/dev/null
      }

      restore_baseline() {
        if ! running waybar; then
          uwsm app -t service -- waybar
        fi
        if ! running mako; then
          uwsm app -t service -- mako
        fi
      }

      case "''${1:-}" in
        start)
          if [[ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
            echo "Run this from your Hyprland session." >&2
            exit 1
          fi
          if running noctalia; then
            echo "Noctalia is already running."
            exit 0
          fi
          if ! systemctl --user is-active --quiet hypridle.service; then
            echo "Start hypridle first so the existing lock/suspend hooks remain active." >&2
            exit 1
          fi
          if running hyprlock; then
            echo "Unlock the session before switching shells." >&2
            exit 1
          fi
          noctalia config validate "''${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/config.toml"
          pkill -u "$UID" -x waybar || true
          pkill -u "$UID" -x mako || true
          # A background UWSM service owns the shell and its launched apps.
          if uwsm app -t service -- noctalia; then
            for _ in {1..20}; do
              if timeout 2 noctalia msg status >/dev/null 2>&1; then
                echo "Noctalia is running. Restore the baseline with: noctalia-trial stop"
                exit 0
              fi
              sleep 0.5
            done
          fi
          echo "Noctalia did not become ready; restoring Waybar and Mako." >&2
          pkill -u "$UID" -x noctalia || true
          restore_baseline
          exit 1
          ;;
        stop)
          if [[ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
            echo "Run this from your Hyprland session." >&2
            exit 1
          fi
          # Stop only the shell, not its entire UWSM unit: keep launched apps alive.
          pkill -u "$UID" -x noctalia || true
          sleep 0.5
          restore_baseline
          echo "Waybar and Mako restored."
          ;;
        *)
          echo "Usage: noctalia-trial {start|stop}" >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  # Manual trial only. Keep the existing Hyprland autostart and lock setup.
  home.packages = [ pkgs.noctalia trial ];
}
