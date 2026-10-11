{ pkgs, ... }:

{
  # Hyprland/UWSM is the only desktop login session.
  # Keep Hyprland and its portal on the same pinned nixpkgs version.
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # Previously supplied implicitly by Plasma; keep the pieces used in Hyprland.
  environment.systemPackages = with pkgs.kdePackages; [
    dolphin
    kio-extras
    kwallet
    breeze
    breeze-icons
    ocean-sound-theme
  ];
  qt.enable = true;
  programs.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];
  xdg.icons.fallbackCursorThemes = [ "breeze_cursors" ];

  # Preserve the fonts referenced by the existing GTK and terminal settings.
  fonts.packages = [ pkgs.noto-fonts pkgs.hack-font ];
  fonts.fontconfig.defaultFonts = {
    monospace = [ "Hack" "Noto Sans Mono" ];
    sansSerif = [ "Noto Sans" ];
    serif = [ "Noto Serif" ];
  };

  # Preserve the existing wallet rather than changing browser encryption keys.
  xdg.portal.extraPortals = [ pkgs.kdePackages.kwallet ];
  security.pam.services.login.kwallet.enable = true;

  # Noctalia power controls and Dolphin removable-drive mounting.
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.udisks2.enable = true;

  # Authentication for the user-installed lock screen. The NixOS hyprlock
  # module also enables hypridle globally; our helper is user/session-scoped.
  security.pam.services.hyprlock = { };
}
