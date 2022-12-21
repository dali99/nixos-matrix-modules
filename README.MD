With matrix.YOURDOMAIN pointing at the server:

```
{
  imports = [ ./synapse-module ];

  services.matrix-synapse-next = {
    enable = true;

    workers.federationSenders = 1;
    workers.federationReceivers = 1;

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

is ~enough to get a functional matrix-server running one federation sender and one federation receiver
