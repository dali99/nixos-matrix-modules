{ nixpkgs, pkgs, system ? pkgs.system, nixosModule, ... }: let
  buildSystemWithConfig = configPath: (nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      nixosModule
      configPath
      {
        boot.isContainer = true;
      }
    ];
  }).config.system.build.toplevel;
in {
  a = pkgs.writeText "hello-world" ''a'';
  base-config = buildSystemWithConfig ./base-config.nix;
  auto-workers-config = buildSystemWithConfig ./auto-workers-config.nix;
}
