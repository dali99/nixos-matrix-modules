{ lib, ... }:

{
  imports = [
    ./synapse-module
    
    # TODO: Remove after 25.05
    (lib.mkRemovedOptionModule [ "services" "matrix-synapse" "sliding-sync" ] ''
      `services.matrix-synapse.sliding-sync` is no longer necessary to use sliding-sync with synapse.
      As synapse now includes this in itself, if you have a manually managed `.well-known/matrix/client` file
      remove the proxy url from it.
    '')
  ];
}
