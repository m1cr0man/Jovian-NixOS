{
  description = "NixOS on the Steam Deck";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    # Only targeting x86 since that's what the Deck is.
    system = "x86_64-linux";
    buildConfig = { configuration ? {} }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          self.nixosModules.jovian
          configuration
          ({ lib, config, ... }: {
            jovian.devices.steamdeck.enable = true;

            # Override config in installation-cd-graphical-base.nix
            hardware.pulseaudio.enable = lib.mkIf
              (config.jovian.devices.steamdeck.enableSoundSupport && config.services.pipewire.enable)
              (lib.mkForce false);
          })
        ];
      }
    ;
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        self.overlays.jovian
      ];
    };
  in
  {
    # Packages is the prefix key for "nix build .#<name>".
    # This is the simplest analog to nix-build -A <name>.
    packages."${system}" = rec {
      # Since Plasma is what Valve provides on the Deck itself,
      # it is used as the default here too.
      default = isoPlasma;
      isoMinimal = (buildConfig {
        configuration = "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix";
      }).config.system.build.isoImage;
      isoGnome = (buildConfig {
        configuration = "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix";
      }).config.system.build.isoImage;
      isoPlasma = (buildConfig {
        configuration = "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-plasma5.nix";
      }).config.system.build.isoImage;
    };

    # Minimize diff while making `nix flake check` pass
    overlays.jovian = final: prev: (import ./overlay.nix) final prev;

    nixosModules.jovian = import ./modules;

    lib.buildConfig = buildConfig;

    # legacyPackages is a nice way to re-export nixpkgs and provide
    # all the extra packages from our overlay for use.
    legacyPackages."${system}" = pkgs;
  };
}
