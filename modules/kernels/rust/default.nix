{
  self,
  system,
  config,
  lib,
  mkKernel,
  ...
}: let
  inherit (lib) types;

  kernelName = "rust";

  # Helper function to coerce overlays into a list with validation
  mkOverlays = overlays: let
    validateOverlay = overlay:
      if builtins.isFunction overlay
      then overlay
      else throw "Expected function, got ${builtins.typeOf overlay}";
  in
    if builtins.isFunction overlays
    then [overlays]
    else if builtins.isList overlays
    then map validateOverlay overlays
    else throw "Expected a function or list of functions for overlays";

  kernelOptions = {
    config,
    name,
    ...
  }: let
    # Create the custom pkgs with overlays applied first
    pkgs = let
      allOverlays = config.overlays ++ config.nixpkgs.extraOverlays;
    in
      import config.nixpkgs.path {
        inherit system;
        overlays = allOverlays;
      };

    requiredRuntimePackages = [
      pkgs.cargo
      pkgs.gcc
      pkgs.binutils-unwrapped
    ];
    args = {inherit self system lib config name kernelName requiredRuntimePackages;};
    kernelModule = import ./../../kernel.nix args;
    kernelFunc = {
      self,
      system,
      # custom arguments
      pkgs,
      name ? "rust",
      displayName ? "Rust",
      requiredRuntimePackages ? with pkgs; [cargo gcc binutils-unwrapped],
      runtimePackages ? [],
      extraKernelSpc,
      evcxr ? pkgs.evcxr,
    }: let
      /*
      rust-overlay recommends using `default` over `rust`.
      Pre-aggregated package `rust` is not encouraged for stable channel since it
      contains almost all and uncertain components.
      https://github.com/oxalica/rust-overlay/blob/1558464ab660ddcb45a4a4a691f0004fdb06a5ee/rust-overlay.nix#L331
      */
      rust = pkgs.rust-bin.stable.latest.default.override {
        extensions = ["rust-src"];
      };

      allRuntimePackages = requiredRuntimePackages ++ runtimePackages ++ [rust];

      env = evcxr;
      wrappedEnv =
        pkgs.runCommand "wrapper-${env.name}"
        {nativeBuildInputs = [pkgs.makeWrapper];}
        ''
          mkdir -p $out/bin
          for i in ${env}/bin/*; do
            filename=$(basename $i)
            ln -s ${env}/bin/$filename $out/bin/$filename
            wrapProgram $out/bin/$filename \
              --set PATH "${pkgs.lib.makeSearchPath "bin" allRuntimePackages}" \
              --set RUST_SRC_PATH "${rust}/lib/rustlib/src/rust/library"
          done
        '';
    in
      {
        inherit name displayName;
        language = "rust";
        argv = [
          "${wrappedEnv}/bin/evcxr_jupyter"
          "--control_file"
          "{connection_file}"
        ];
        codemirrorMode = "rust";
        logo64 = ./logo-64x64.png;
        logo32 = ./logo32.png;
      }
      // extraKernelSpc;
  in {
    options =
      {
        evcxr = lib.mkOption {
          type = types.package;
          default = pkgs.evcxr;
          example = lib.literalExpression "pkgs.evcxr";
          description = ''
            An evaluation context for Rust.
          '';
        };

        # Allow users to pass one or more overlay functions directly
        overlays = lib.mkOption {
          type = types.listOf (types.functionTo (types.functionTo types.attrs));
          default = [self.inputs.rust-overlay.overlays.default];
          defaultText = lib.literalExpression "[ self.inputs.rust-overlay.overlays.default ]";
          example = lib.literalExpression "[ myCustomOverlay ]";
          description = ''
            A list of nixpkgs overlay functions to apply when building the Rust kernel.
            Each overlay should have the form: `final: prev: { … }`.
          '';
        };

        # Allow users to pin or replace the nixpkgs they want
        nixpkgs = lib.mkOption {
          type = types.submodule {
            options = {
              path = lib.mkOption {
                type = types.path;
                default = self.inputs.nixpkgs;
                defaultText = lib.literalExpression "self.inputs.nixpkgs";
                example = lib.literalExpression "self.inputs.nixpkgs";
                description = "Path (or flake URL) of the nixpkgs to use for Rust.";
              };
              extraOverlays = lib.mkOption {
                type = types.listOf (types.functionTo (types.functionTo types.attrs));
                default = [];
                example = lib.literalExpression "[ (import ./my-overlay.nix) ]";
                description = "Additional overlay functions to merge with `overlays`.";
              };
            };
          };
          default = {
            path = self.inputs.nixpkgs;
            extraOverlays = [];
          };
          description = "Configuration for the nixpkgs instance used by the Rust kernel.";
        };
      }
      // kernelModule.options;

    config = lib.mkIf config.enable {
      build = mkKernel (kernelFunc config.kernelArgs);
      kernelArgs =
        kernelModule.kernelArgs
        // {
          inherit (config) evcxr;
          inherit pkgs;
        };
    };
  };
in {
  options.kernel.${kernelName} = lib.mkOption {
    type = types.attrsOf (types.submodule kernelOptions);
    default = {};
    example = lib.literalExpression ''
      {
        kernel.${kernelName}."example" = {
          enable = true;
          overlays = [ myCustomOverlay ];
          nixpkgs = {
            path = self.inputs.nixpkgs-stable;
            extraOverlays = [ (import ./another-overlay.nix) ];
          };
        };
      }
    '';
    description = ''
      A ${kernelName} kernel for IPython with flexible overlay and nixpkgs configuration.
    '';
  };
}
