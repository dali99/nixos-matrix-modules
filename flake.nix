{
  description = "NixOS modules for matrix related services";

  outputs = { self }: {
    nixosModules = {
      synapse = import ./synapse-module;
    };
  };
}
