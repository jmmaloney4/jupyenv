{
  inputs,
  self,
  ...
}: let
  # Example custom overlay
  myRustOverlay = final: prev: {
    # Override rustc to use a specific version
    rustc = prev.rustc.overrideAttrs (old: {
      version = "1.70.0";
    });
    
    # Add custom rust toolchain
    my-rust-toolchain = prev.rust-bin.stable.latest.default.override {
      extensions = ["rust-src" "rust-analysis" "rustfmt" "clippy"];
    };
  };

  # Another overlay for additional tools
  extraToolsOverlay = final: prev: {
    # Add additional development tools
    rust-extra-tools = prev.rust-bin.stable.latest.default.override {
      extensions = ["rustfmt" "clippy" "rust-analyzer"];
    };
  };
in {
  # Basic usage with default settings
  kernel.rust.basic = {
    enable = true;
  };

  # Usage with custom overlay
  kernel.rust.custom-overlay = {
    enable = true;
    overlays = [ myRustOverlay ];
  };

  # Usage with multiple overlays
  kernel.rust.multiple-overlays = {
    enable = true;
    overlays = [ myRustOverlay extraToolsOverlay ];
  };

  # Usage with custom nixpkgs and extra overlays
  kernel.rust.custom-nixpkgs = {
    enable = true;
    overlays = [ myRustOverlay ];
    nixpkgs = {
      # Use a different nixpkgs version (e.g., stable)
      path = self.inputs.nixpkgs-stable;
      extraOverlays = [ extraToolsOverlay ];
    };
  };

  # Advanced usage with all features
  kernel.rust.advanced = {
    enable = true;
    overlays = [
      # Primary overlay
      (final: prev: {
        rustc = prev.rustc.overrideAttrs (old: {
          version = "1.70.0";
        });
      })
    ];
    nixpkgs = {
      # Use stable nixpkgs
      path = self.inputs.nixpkgs-stable;
      extraOverlays = [
        # Additional overlays
        (final: prev: {
          rust-analyzer = prev.rust-analyzer.overrideAttrs (old: {
            version = "2023-07-03";
          });
        })
        extraToolsOverlay
      ];
    };
  };
} 