{
  description = "Nick's NixOS workstation configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    {
      nixosConfigurations.nsnix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Back up existing unmanaged files when adopting them, notably
            # the GTK settings inherited from Plasma. Never force-delete them.
            home-manager.backupFileExtension = "before-home-manager";
            home-manager.users.nick = import ./home/nick/home.nix;
          }
        ];
      };
    };
}
