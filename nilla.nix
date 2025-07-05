# SPDX-FileCopyrightText: 2025 Skyler Grey <sky@a.starrysky.fyi>
# SPDX-FileCopyrightText: 2025 FreshlyBakedCake
#
# SPDX-License-Identifier: MIT

let
  pins = import ./npins;

  nilla = import pins.nilla;

  settings = {
    nixpkgs.configuration.allowUnfreePredicate = (
      x: (x ? meta.license) && (x.meta.license.shortName == "unfreeRedistributable")
    ); # As we push to a public cachix, we can't use non-redistributable unfree software
    nixpkgs.configuration.permittedInsecurePackages = [
      "python3.13-youtube-dl-2021.12.17"
    ];
  };

  sources = builtins.fromJSON (builtins.readFile ./npins/sources.json);
in
nilla.create (
  { config }:
  {
    config = {
      inputs = builtins.mapAttrs (name: value: {
        src = value;
        settings = settings.${name} or config.lib.constants.undefined;
      }) pins;

      lib.constants.undefined = config.lib.modules.when false { };

      shells.default = {
        systems = [ "x86_64-linux" ];

        shell =
          {
            cargo,
            mkShell,
            rust-analyzer,
            rustc,
            ...
          }:
          mkShell {
            packages = [
              cargo
              rust-analyzer
              rustc
            ];
          };
      };
    };
  }
)
