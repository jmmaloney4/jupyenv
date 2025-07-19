# Rust Kernel Examples

This directory contains examples demonstrating the flexible Rust kernel configuration in jupyenv.

## Features

The Rust kernel module now supports:

1. **Flexible Overlay Configuration**: Pass one or more overlay functions directly
2. **Custom Nixpkgs**: Use different nixpkgs versions or paths
3. **Extra Overlays**: Additional overlays separate from the main ones
4. **Ergonomic API**: No more wrestling with `.overlays.default`

## Examples

### Basic Usage

```nix
{
  kernel.rust.basic = {
    enable = true;
  };
}
```

### Custom Overlay

```nix
{
  kernel.rust.custom = {
    enable = true;
    overlays = [
      (final: prev: {
        rustc = prev.rustc.overrideAttrs (old: {
          version = "1.70.0";
        });
      })
    ];
  };
}
```

### Multiple Overlays

```nix
{
  kernel.rust.multiple = {
    enable = true;
    overlays = [
      overlay1
      overlay2
      overlay3
    ];
  };
}
```

### Custom Nixpkgs with Extra Overlays

```nix
{
  kernel.rust.advanced = {
    enable = true;
    overlays = [ primaryOverlay ];
    nixpkgs = {
      path = self.inputs.nixpkgs-stable;
      extraOverlays = [ extraOverlay1 extraOverlay2 ];
    };
  };
}
```

## Real-world Flake Example

```nix
{
  inputs = {
    jupyenv.url = "github:tweag/jupyenv";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";
  };

  outputs = { self, jupyenv, nixpkgs, nixpkgs-stable, ... }:
    let jupyter = jupyenv.jupyterLib.mkJupyter; in
    {
      packages.default = jupyter {
        kernel.rust = {
          enable = true;
          overlays = [
            (final: prev: {
              rustc = prev.rustc.overrideAttrs (old: {
                version = "1.70.0";
              });
            })
          ];
          nixpkgs = {
            path = self.inputs.nixpkgs-stable;
            extraOverlays = [
              (final: prev: {
                rust-analyzer = prev.rust-analyzer.overrideAttrs (old: {
                  version = "2023-07-03";
                });
              })
            ];
          };
        };
      };
    };
}
```

## Configuration Options

### `overlays`
- **Type**: `listOf function`
- **Default**: `[ self.inputs.rust-overlay.overlays.default ]`
- **Description**: List of nixpkgs overlay functions to apply

### `nixpkgs.path`
- **Type**: `path`
- **Default**: `self.inputs.nixpkgs`
- **Description**: Path to the nixpkgs to use

### `nixpkgs.extraOverlays`
- **Type**: `listOf function`
- **Default**: `[]`
- **Description**: Additional overlay functions to merge with `overlays`

## Benefits

1. **No more `.overlays.default`**: Pass overlay functions directly
2. **Flexible nixpkgs**: Use any nixpkgs version or path
3. **Multiple overlays**: Combine overlays easily
4. **Type safety**: Proper type checking for all options
5. **Backward compatibility**: Default behavior unchanged 