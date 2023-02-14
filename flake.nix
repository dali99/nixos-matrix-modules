{
  description = "NixOS modules for matrix related services";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11-small;
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    nixosModules = {
      synapse = import ./modules/synapse;
    };
    lib = import ./lib.nix { inherit (nixpkgs) lib; };
  } // 
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.sliding-sync = pkgs.callPackage ./packages/sliding-sync { };
    }
  );
}
