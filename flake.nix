{
  description = "NixOS modules for matrix related services";

  inputs = {
    # nixpkgs-lib.url = github:nix-community/nixpkgs.lib;
    nixpkgs.url = github:nixos/nixpkgs;
  };

  outputs = { self, nixpkgs }:
  let
    systems = [ "x86_64-linux"];
  in {
    nixosModules = {
      default = import ./module.nix;
    };
    lib = import ./lib.nix { lib = nixpkgs.lib; };
    packages = nixpkgs.lib.genAttrs systems (system: {
      out-of-your-element = nixpkgs.legacyPackages.${system}.callPackage ./pkgs/out-of-your-element {};
    });
  };
}
