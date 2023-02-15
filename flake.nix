{
  description = "NixOS modules for matrix related services";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11-small;
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    nixosModules = {
      synapse = import ./modules/synapse;
      sliding-sync = import ./modules/sliding-sync;
    };
    lib = import ./lib.nix { inherit (nixpkgs) lib; };
  } // 
  {
    overlays.default = (final: prev: {
      matrix-next.sliding-sync = final.callPackage ./packages/sliding-sync { };
    });
  } //
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.sliding-sync = pkgs.callPackage ./packages/sliding-sync { };
    }
  );
}
