{ nixpkgs, pkgs, matrix-lib, ... }:
{
  nginx-pipeline = pkgs.callPackage ./nginx-pipeline { inherit nixpkgs matrix-lib; };
}
