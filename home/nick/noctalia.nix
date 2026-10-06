{ pkgs, ... }:

let
  trial = pkgs.writeShellApplication {
    name = "noctalia-trial";
    runtimeInputs = with pkgs; [ noctalia uwsm procps coreutils systemd waybar mako jq ];
    text = ''
      running() {
        pgrep -u "$UID" -x "$1|\\.$1-wrap.*" >/dev/null
      }

      stop_process() {
        pkill -u "$UID" -x "$1|\\.$1-wrap.*" || true
        for _ in {1..20}; do
          if ! running "$1"; then
            return 0
          fi
          sleep 0.1
        done
        echo "Waiting for $1 to exit failed." >&2
        return 1
      }

      require_unlocked() {
        if running hyprlock; then
          echo "Unlock the session before switching shells." >&2
          return 1
        fi
        if running noctalia; then
          # Refuse if locked OR if the lock state cannot be determined.
          if ! timeout 2 noctalia msg status | jq -e '.locked == false' >/dev/null; then
            echo "Unlock Noctalia before switching shells (or investigate an unresponsive shell)." >&2
            return 1
          fi
        fi
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
          require_unlocked
          noctalia config validate "''${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/config.toml"
          stop_process waybar
          stop_process mako
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
          require_unlocked
          stop_process noctalia
          restore_baseline
          exit 1
          ;;
        stop)
          if [[ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
            echo "Run this from your Hyprland session." >&2
            exit 1
          fi
          # Stop only the shell, not its entire UWSM unit: keep launched apps alive.
          require_unlocked
          stop_process noctalia
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
