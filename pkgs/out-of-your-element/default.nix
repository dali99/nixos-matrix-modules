{ lib
, buildNpmPackage
, fetchFromGitea
, git
}:

buildNpmPackage rec {
  pname = "out-of-your-element";
  version = "1.2";

  src = fetchFromGitea {
    domain = "gitdab.com";
    owner = "cadence";
    repo = "out-of-your-element";
    rev = "v1.2";
    hash = "sha256-rlp6Eens5gV0dwLpICjKaVhxNXXeb/S7l628eXYvZaY=";
  };

  npmDepsHash = "sha256-ComQ8ua7k8zg0Dzih+MVgjnySpSlLJmLqnwxADCUv7M=";

  dontNpmBuild = true;

  makeCacheWritable = true;
  npmFlags = [ "--loglevel=verbose" ]; #"--legacy-peer-deps" ];

}
