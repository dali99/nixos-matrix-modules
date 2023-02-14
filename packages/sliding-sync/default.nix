{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "sliding-sync";
  version = "0.99.0";

  src = fetchFromGitHub {
    owner = "matrix-org";
    repo = "sliding-sync";
    rev = "v${version}";
    hash = "sha256-nzU/6uEUuBQEyGNLJyGdWt2C+58LTaxHHbnCtVBPKns=";
  };

  vendorHash = "sha256-t7FxgFwmB6N+cPmLnNLo5dI0H2+ldWaZn2Qskkm/bRQ=";
  proxyVendor = true; # It seems to complain about "inconsistent vendoring"

  subPackages = [ "cmd/syncv3" ];

  meta = with lib; {
    description = "a sliding sync proxy";
    homepage = "https://github.com/matrix-org/sliding-sync";
    license = licenses.asl20;
    maintainers = with maintainers; [ dandellion ];
  };
}
