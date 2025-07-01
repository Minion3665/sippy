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
      # Add Nixpkgs as an input (match the name you used when pinning).
      inputs = builtins.mapAttrs (name: value: {
        src = value;
        settings = settings.${name} or config.lib.constants.undefined;
      }) pins;

      lib.constants.undefined = config.lib.modules.when false { };

      packages.pyVoIP = {
        systems = [ "x86_64-linux" ];

        package =
          {
            python3Packages,
          }:
          python3Packages.buildPythonPackage {
            pname = "pyVoIP";
            version = sources.pins.pyVoIP.version;

            src = config.inputs.pyVoIP.src;
          };
      };

      # With a package set defined, we can create a shell.
      shells.default = {
        # Declare what systems the shell can be used on.
        systems = [ "x86_64-linux" ];

        # Define our shell environment.
        shell =
          {
            mkShell,
            python3,
            ruff,
            system,
            ...
          }:
          mkShell {
            packages = [
              (python3.withPackages (pyPkgs: [
                config.packages.pyVoIP.result.${system}
                pyPkgs.discordpy
                pyPkgs.python-lsp-server
                pyPkgs.ruff
              ]))
            ];
          };
      };
    };
  }
)
