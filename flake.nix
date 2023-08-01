{
  description = "NixOS modules for matrix related services";

  inputs = {
    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-lib }: {
    nixosModules = {
      default = import ./module.nix;
    };

    lib = import ./lib.nix { lib = nixpkgs-lib.lib; };

    packages = let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
        ${system}.tests = import ./tests {
        inherit system;
        inherit nixpkgs;
        inherit pkgs;
        nixosModule = self.outputs.nixosModules.synapse;
      };
    };
  };
}
