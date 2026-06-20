{
  description = "waycal — a 3-widget Google productivity suite (Calendar/Mail/Tasks) for Wayland, driven by the gog CLI and rendered with Quickshell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    quickshell = {
      url = "github:quickshell-mirror/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , quickshell
    }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in
        {
          waycal = pkgs.callPackage ./nix/package.nix {
            quickshell = quickshell.packages.${system}.default;
          };
          default = self.packages.${system}.waycal;
        });

      apps = forAllSystems (system: {
        # Debug the Python adapter directly: `nix run .#waycal-fetch -- agenda --days 7`
        waycal-fetch = {
          type = "app";
          program = "${self.packages.${system}.waycal}/bin/waycal-fetch";
        };
        default = self.apps.${system}.waycal-fetch;
      });

      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = [
              quickshell.packages.${system}.default
              pkgs.python3
              pkgs.uv
              pkgs.jq
              # `gog` is expected to be installed on the host; add it here if packaged.
              pkgs.nixpkgs-fmt
              pkgs.statix
              pkgs.deadnix
            ];

            shellHook = ''
              echo "waycal dev shell — run the adapter:  python backend/waycal_fetch.py agenda --days 7"
              echo "                    run the UI:       qs -p ./frontend"
            '';
          };
        });

      # home-manager module: imported as a flake module (NOT the home-manager CLI).
      homeManagerModules = {
        waycal = import ./modules/home-manager.nix self;
        default = self.homeManagerModules.waycal;
      };

      formatter = forAllSystems (system: (pkgsFor system).nixpkgs-fmt);
    };
}
