{lib}: {
  # Helper function to check if rust-overlay is available in inputs
  hasRustOverlay = self:
    (self ? inputs) && (self.inputs ? rust-overlay);

  # Helper function to get rust-overlay default overlay if available
  getRustOverlay = self:
    lib.optionals (hasRustOverlay self) [self.inputs.rust-overlay.overlays.default];
}
