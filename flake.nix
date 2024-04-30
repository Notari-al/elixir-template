{
  description = "DockYard Academy";

  nixConfig = {
    extra-substituters = [
      "https://devenv.cachix.org"
      "https://cachix.cachix.org"
      "https://nix-community.cachix.org"
      "https://dliberalesso.cachix.org"
    ];

    extra-trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "dliberalesso.cachix.org-1:7qs1S5Qd766dYFU86nVux/wRMZ8UEUbhn3Qxp/TwiOc="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-lib.url = "github:nixos/nixpkgs/nixpkgs-unstable?dir=lib";

    flake-compat.url = github:edolstra/flake-compat;
    flake-compat.flake = false;

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs-lib";

    flake-root.url = "github:srid/flake-root";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks.inputs.flake-compat.follows = "flake-compat";

    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
    devenv.inputs.flake-compat.follows = "flake-compat";
    devenv.inputs.pre-commit-hooks.follows = "pre-commit-hooks";
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.devenv.flakeModule
        inputs.flake-root.flakeModule
        inputs.treefmt-nix.flakeModule
      ];

      systems = nixpkgs.lib.systems.flakeExposed;

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.

        devenv.shells.default = {
          dotenv.enable = true;

          # enterShell = ''
          #   mix local.hex --force --if-missing
          #   mix local.rebar --force --if-missing
          #   export PATH="$HOME/.mix/escripts:$PATH"

          #   mix archive.install --force hex phx_new
          #   mix escript.install --force hex livebook
          # '';

          languages = {
            elixir.enable = true;

            javascript.enable = true;
            javascript.npm.enable = true;
            javascript.npm.install.enable = true;

            nix.enable = true;
          };

          packages = [
            pkgs.inotify-tools
          ];

          pre-commit.hooks = {
            treefmt.enable = true;
            treefmt.package = config.treefmt.build.wrapper;
          };

          services = {
            postgres = {
              enable = true;
              initialScript = ''
                CREATE ROLE postgres WITH LOGIN PASSWORD 'postgres' SUPERUSER;
              '';
            };
          };
        };

        treefmt = {
          inherit (config.flake-root) projectRootFile;
          programs = {
            alejandra.enable = true;
          };
        };
      };
    };
}
