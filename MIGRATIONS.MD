# Migrations

This is a best effort document descibing neccecary changes you might have to do when updating

## 0.6.1

enableSlidingSync, and setting matrix-synapse.sliding-sync.environmentFile (or any other sliding-sync setting)
is no longer needed for a sliding-sync setup. Upgrading will force relogins for all users.

## 0.5.0

* The module has been renamed from `synapse` to `default`
* The synapse module now expects a wrapper-style package. This means the module is now incompatible with nixpkgs < 23.11.


