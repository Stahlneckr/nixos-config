{ config, pkgs, ... }:

let
  # This pinned nixpkgs has the package, but not its newer NixOS module.
  # Use greetd directly without adding another flake input or upgrading it.
  greeter = pkgs.noctalia-greeter;
  greeterConfig = (pkgs.formats.toml { }).generate "noctalia-greeter.toml" {
    user.default = "nick";
    session.default = "Hyprland (uwsm-managed)";
    keyboard.layout = "us";
  };

  # UWSM still resolves hyprland.desktop internally. NoDisplay hides it from
  # Noctalia's picker without disabling the entry (Hidden would break UWSM).
  hidePlainHyprland = ''
    entry="$out/share/wayland-sessions/hyprland.desktop"
    if test -e "$entry"; then
      chmod u+w "$out/share/wayland-sessions"
      cp "$entry" "$entry.tmp"
      chmod u+w "$entry.tmp"
      printf '\nNoDisplay=true\n' >> "$entry.tmp"
      mv -f "$entry.tmp" "$entry"
    fi
  '';

  loginSessions = pkgs.runCommand "noctalia-login-sessions" { } ''
    mkdir -p "$out/share"
    cp -rs ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions "$out/share/"
    cp -rs ${config.services.displayManager.sessionData.desktops}/share/xsessions "$out/share/"
    ${hidePlainHyprland}
  '';
in
{
  services.displayManager.sddm.enable = false;

  services.greetd = {
    enable = true;
    settings.default_session = {
      user = "greeter";
      command = "${greeter}/bin/noctalia-greeter-session";
    };
  };

  # Noctalia scans both the system profile and XDG_DATA_DIRS. Hide the direct
  # entry in both locations while retaining every other installed session.
  environment.extraSetup = hidePlainHyprland;
  systemd.services.greetd = {
    environment.XDG_DATA_DIRS = "${loginSessions}/share:${config.system.path}/share";
    path = [ pkgs.dbus ];
  };

  environment.systemPackages = [ greeter ];
  services.accounts-daemon.enable = true;
  security.polkit.enable = true;

  # The privileged login account owns only the greeter's state. Declarative
  # defaults stay read-only; appearance and picker choices use sync.toml.
  systemd.tmpfiles.rules = [
    "d /var/lib/noctalia-greeter 0750 greeter greeter -"
    "L+ /var/lib/noctalia-greeter/greeter.toml - greeter greeter - ${greeterConfig}"
  ];
}
