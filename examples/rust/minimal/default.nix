{pkgs, ...}: {
  kernel.rust.minimal-example = {
    enable = true;
    # Basic usage with default settings
  };

  # Example with custom overlay
  kernel.rust.custom-overlay-example = {
    enable = true;
    overlays = [
      # Custom overlay function
      (final: prev: {
        # Override rustc version
        rustc = prev.rustc.overrideAttrs (old: {
          version = "1.70.0";
        });
      })
    ];
  };

  # Example with custom nixpkgs and extra overlays
  kernel.rust.custom-nixpkgs-example = {
    enable = true;
    overlays = [
      # Primary overlay
      (final: prev: {
        # Add custom rust toolchain
        my-rust = prev.rust-bin.stable.latest.default.override {
          extensions = ["rust-src" "rust-analysis"];
        };
      })
    ];
    nixpkgs = {
      # Use a different nixpkgs version
      path = pkgs.lib.mkDefault pkgs.path; # This would be self.inputs.nixpkgs-stable in real usage
      extraOverlays = [
        # Additional overlay for extra packages
        (final: prev: {
          extra-rust-tools = prev.rust-bin.stable.latest.default.override {
            extensions = ["rustfmt" "clippy"];
          };
        })
      ];
    };
  };
}
