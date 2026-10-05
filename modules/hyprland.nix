{ ... }:

{
  # Add a session to SDDM without removing the working Plasma session.
  # Keep Hyprland and its portal on the same pinned nixpkgs version.
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # Authentication for the user-installed lock screen. The NixOS hyprlock
  # module also enables hypridle globally; our helper is user/session-scoped.
  security.pam.services.hyprlock = { };
}
