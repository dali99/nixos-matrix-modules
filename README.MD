For support and requests feel free to join [#nixos-matrix-modules:dodsorf.as](https://matrix.to/#/#nixos-matrix-modules:dodsorf.as), [uri](matrix:r/nixos-matrix-modules:dodsorf.as)

With matrix.YOURDOMAIN pointing at the server:

```
{
  imports = [ ./synapse-module ];

  services.matrix-synapse-next = {
    enable = true;

    workers.federationSenders = 1;
    workers.federationReceivers = 1;
    workers.initialSyncers = 1;
    workers.normalSyncers = 1;
    workers.eventPersisters = 2;
    workers.useUserDirectoryWorker = true;

    enableNginx = true;

    settings = {
      server_name = "YOURDOMAIN";
      
      database = {
        name = "psycopg2";
        args = {
          host = "localhost";
          user = "synapse";
          password = "synapse";
          dbname = "synapse";
        };
      };
    };
  };
  
  services.redis.servers."".enable = true;
}
```

is ~enough to get a functional matrix-server running with some workers
