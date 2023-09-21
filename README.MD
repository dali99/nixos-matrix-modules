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

## Sliding Sync (Element X)

Just add the following to your config and point `slidingsync.YOURDOMAIN` at the server

```
services.matrix-synapse-next = {
  enableSlidingSync = true;
};

matrix-synapse.sliding-sync.environmentFile = "/some/file/containing/SYNCV3_SECRET=<some secret>";

```

If using well-known delagation make sure `YOURDOMAIN/.well-known/matrix/client` matches
what's in `matrix.YOURDOMAIN/.well-known/matrix/client`
