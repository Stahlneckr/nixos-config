{ pkgs, ... }:

{
  # Configs remain editable in Documents/dotfiles, linked by home.nix.
  # These tools and services belong only to the Hyprland session.
  home.packages = with pkgs; [
    fuzzel
    waybar
    mako
    hyprlock
    hypridle
    hyprpolkitagent
    pavucontrol
  ];

  # Only respond to manual lock/suspend events: no idle timeout listeners.
  # The config stays in dotfiles/hypr/hypridle.conf via the directory link.
  services.hypridle = {
    enable = true;
    systemdTarget = "wayland-session@hyprland.desktop.target";
  };
}
