{
  lib,
  config,
  self,
  kernelName,
}: let
  rustUtils = import ../../lib/rust-utils.nix {inherit lib;};
  overlays =
    if (lib.elem kernelName ["python" "bash" "c" "elm" "zsh" "postgres"])
    then [
      self.inputs.poetry2nix.overlays.default
    ]
    else if kernelName == "rust"
    then rustUtils.getRustOverlay self
    else [];
in
  overlays
