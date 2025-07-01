# SPDX-FileCopyrightText: 2025 Skyler Grey <sky@a.starrysky.fyi>
#
# SPDX-License-Identifier: MIT

let
  pins = import ./npins;

  nilla = import pins.nilla;

  settings = {
    nixpkgs.configuration.allowUnfreePredicate = (
      x: (x ? meta.license) && (x.meta.license.shortName == "unfreeRedistributable")
    ); # As we push to a public cachix, we can't use non-redistributable unfree software
  };
in
nilla.create (
  { config }:
  {
    config = {
      # Add Nixpkgs as an input (match the name you used when pinning).
      inputs = builtins.mapAttrs (name: value: {
        src = value;
        settings = settings.${name} or config.lib.constants.undefined;
      }) pins;

      packages.pyvoip = {
        systems = [ "x86_64-linux" ];

        package =
          {
            buildPythonPackage,
          }:
          buildPythonPackage {
            pname = "pyVoIP";
            version = inputs.pyvoip.version;

            src = inputs.pyvoip.src;
          };
      };

      # With a package set defined, we can create a shell.
      shells.default = {
        # Declare what systems the shell can be used on.
        systems = [ "x86_64-linux" ];

        # Define our shell environment.
        shell =
          {
            python3,
            ...
          }:
          mkShell {
            packages = [
              (python3.withPackages (pyPkgs: [
                discordpy
                jishaku
              ]))
            ];
          };
      };
    };
  }
)
