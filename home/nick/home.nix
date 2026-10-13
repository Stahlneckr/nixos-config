{ config, lib, ... }:

let
  dotfiles = "${config.home.homeDirectory}/Documents/dotfiles";
  appConfigs = [ "ghostty" "nvim" "zed" "hypr" "waybar" "fuzzel" "mako" "noctalia" "cliamp" "herdr" ];
in
{
  imports = [ ./hyprland.nix ./gtk.nix ./noctalia.nix ];

  home.username = "nick";
  home.homeDirectory = "/home/nick";

  # Compatibility baseline for this first Home Manager installation.
  # Keep this value when upgrading Home Manager.
  home.stateVersion = "26.05";

  xdg.enable = true;
  xdg.configFile = lib.genAttrs appConfigs (app: {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${app}";
    # Adopt the existing directory symlinks. The activation guard below
    # only allows links resolving to these exact dotfiles directories.
    force = true;
  });

  home.activation.checkDotfilesLinks = lib.hm.dag.entryBefore [ "checkLinkTargets" ] (
    lib.concatMapStringsSep "\n" (app: ''
      target=${lib.escapeShellArg "${config.xdg.configHome}/${app}"}
      expected=${lib.escapeShellArg "${dotfiles}/${app}"}
      if [[ ! -d "$expected" ]]; then
        echo "Missing dotfiles directory: $expected" >&2
        exit 1
      fi
      if [[ -e "$target" || -L "$target" ]]; then
        if [[ ! -L "$target" ]] || [[ "$(readlink -f "$target")" != "$(readlink -f "$expected")" ]]; then
          echo "Refusing to replace $target: expected a symlink to $expected" >&2
          exit 1
        fi
      fi
    '') appConfigs
  );
}
