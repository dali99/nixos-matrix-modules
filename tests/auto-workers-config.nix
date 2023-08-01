{ pkgs, lib, ... }:
{
  services.matrix-synapse-next = {
    enable = true;
    settings.server_name = "matrix.example.com";

    workers = {
      enableMetrics = true;

      federationSenders = 2;
      federationReceivers = 2;
      initialSyncers = 2;
      normalSyncers = 2;
      eventPersisters = 2;
      useUserDirectoryWorker = true;
    };
  };
}
