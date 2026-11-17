{
  description = "Reproducible CRD schemas for Portfolio V3 manifests";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      environments = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          schemas = pkgs.callPackage ./crd-schemas.nix { };
          setup = pkgs.writeShellApplication {
            name = "setup-crd";
            runtimeInputs = [ pkgs.coreutils ];
            text = ''
              export CRD_SCHEMAS=${schemas}
              ${builtins.readFile ./setup-crd.sh}
            '';
          };
        in
        {
          inherit pkgs schemas setup;
        }
      );
    in
    {
      packages = forAllSystems (system: {
        crd-schemas = environments.${system}.schemas;
        setup-crd = environments.${system}.setup;
      });

      apps = forAllSystems (system: {
        setup-crd = {
          type = "app";
          program = "${environments.${system}.setup}/bin/setup-crd";
        };
      });

      devShells = forAllSystems (
        system:
        let
          env = environments.${system};
        in
        {
          default = env.pkgs.mkShell {
            packages = [ env.setup ];
            shellHook = ''
              if [[ -f kustomization.yaml || -f kustomization.yml || -f Kustomization ]]; then
                setup-crd .
              else
                printf 'Run setup-crd /path/to/manifest to install the CRD schemas.\n'
              fi
            '';
          };
        }
      );

      checks = forAllSystems (
        system:
        let
          env = environments.${system};
        in
        {
          crd-schemas = env.schemas;
          setup-crd = env.pkgs.runCommand "portfolio-crd-setup-check" {
            nativeBuildInputs = [ env.setup ];
          } ''
            mkdir -p 'manifest fixture'
            touch 'manifest fixture/kustomization.yaml'
            setup-crd 'manifest fixture'
            cmp ${env.schemas}/traefik.io-ingressroute-v1alpha1.json \
              'manifest fixture/.crd/traefik.io-ingressroute-v1alpha1.json'

            touch 'manifest fixture/.crd/preserved.json'
            setup-crd 'manifest fixture'
            test -f 'manifest fixture/.crd/preserved.json'

            if setup-crd missing-directory; then
              echo 'setup-crd must reject a directory without a Kustomization' >&2
              exit 1
            fi
            touch "$out"
          '';
        }
      );
    };
}
