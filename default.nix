let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  compat = builtins.fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
    sha256 = lock.nodes.flake-compat.locked.narHash;
  };
  flake = (import compat { src = ./.; }).defaultNix;
in flake.legacyPackages.x86_64-linux // flake.packages.x86_64-linux
