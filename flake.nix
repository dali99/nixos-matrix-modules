{
  description = "NixOS modules for matrix related services";

  inputs = {
    nixpkgs-lib.url = github:nix-community/nixpkgs.lib;
  };

  outputs = { self, nixpkgs-lib }: {
    nixosModules = {
      synapse = import ./synapse-module { matrix-lib = self.lib; };
    };
    lib = import ./lib.nix { lib = nixpkgs-lib.lib; };
  };
}
