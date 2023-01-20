{ lib }:
rec {
  # checks if given listener configuration has type as a resource
  isListenerType = type: l: lib.any (r: lib.any (n: n == type) r.names) l.resources;
  # Get the first listener that includes the given resource from worker
  firstListenerOfType = type: ls: lib.lists.findFirst (isListenerType type)
    (lib.throw "No listener with resource: ${type} configured")
    ls;
  # Get an attrset of the host and port from a listener 
  connectionInfo = l: {
    host = lib.head l.bind_addresses;
    port = l.port;
  };

  # Get an attrset of the host and port from a worker given a type
  workerConnectionResource = r: w: let
    l = firstListenerOfType r w.settings.worker_listeners;
  in connectionInfo l;

}
