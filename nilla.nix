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

      packages.edge-tts = {
        systems = [ "x86_64-linux" ];

        package =
          {
            python3,
          }:
          python3.pkgs.buildPythonPackage {
            pname = "edge-tts";
            version = sources.pins.edge-tts.version;

            src = config.inputs.edge-tts.src;

            dependencies = [
              python3.pkgs.aiohttp
              python3.pkgs.certifi
              python3.pkgs.srt
              python3.pkgs.tabulate
              python3.pkgs.typing-extensions
            ];
          };
      };

      packages.PySIP =
        let
          project = config.inputs.pyproject.result.lib.project.loadPyproject {
            projectRoot = config.inputs.PySIP.src;
          };
        in
        {
          systems = [ "x86_64-linux" ];

          package =
            {
              python3,
              system,
            }:
            let
              pythonPackages = python3.pkgs // {
                edge-tts = config.packages.edge-tts.result.${system};
              };

              buildPythonPackageAttrs = project.renderers.buildPythonPackage {
                python = python3;
                inherit pythonPackages;
              };
            in
            python3.pkgs.buildPythonPackage (
              buildPythonPackageAttrs
              // {
                depedencies = (buildPythonPackageAttrs.dependencies or [ ]) ++ [ python3.pkgs.scipy ]; # scipy is mentioned in requirements.txt but not pyproject.toml
                patches = (buildPythonPackageAttrs.patches or [ ]) ++ [
                  ./patches/PySIP/invite-407.patch
                  ./patches/PySIP/ssl-fix.patch
                ];
              }
            );
        };

      # With a package set defined, we can create a shell.
      shells.default = {
        # Declare what systems the shell can be used on.
        systems = [ "x86_64-linux" ];

        # Define our shell environment.
        shell =
          {
            ffmpeg,
            mkShell,
            python3,
            ruff,
            system,
            ...
          }:
          mkShell {
            packages = [
              (python3.withPackages (pyPkgs: [
                config.packages.PySIP.result.${system}
                pyPkgs.discordpy
                pyPkgs.python-lsp-server
                pyPkgs.ruff
                pyPkgs.scipy # HACK: should be a pysip dep
              ]))
              ffmpeg
            ];
          };
      };
    };
  }
)
