{ pkgs, lib, ... }:
{
  services.matrix-synapse-next = {
    enable = true;
    settings.server_name = "matrix.example.com";
  };
}
