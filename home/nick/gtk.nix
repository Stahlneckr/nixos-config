{ ... }:

let
  # Preserve the existing GTK appearance while dropping Plasma's retained
  # 170% font DPI. Hyprland supplies the monitor scaling itself.
  commonSettings = {
    gtk-application-prefer-dark-theme = false;
    gtk-cursor-blink = true;
    gtk-cursor-blink-time = 1000;
    gtk-cursor-theme-name = "breeze_cursors";
    gtk-cursor-theme-size = 24;
    gtk-decoration-layout = "icon:minimize,maximize,close";
    gtk-enable-animations = true;
    gtk-font-name = "Noto Sans,  10";
    gtk-icon-theme-name = "breeze";
    gtk-primary-button-warps-slider = true;
    gtk-sound-theme-name = "ocean";
    # GTK stores this in units of 1/1024 DPI: 96 * 1024.
    gtk-xft-dpi = 98304;
  };
in
{
  gtk = {
    enable = true;
    gtk2.enable = false;
    gtk3.extraConfig = commonSettings // {
      gtk-button-images = true;
      gtk-menu-images = true;
      gtk-modules = "colorreload-gtk-module";
      gtk-toolbar-style = 3;
    };
    gtk4.extraConfig = commonSettings;
  };
}
