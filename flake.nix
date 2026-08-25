{
  description = "Common Lisp CFFI bindings for the Vulkan graphics and compute API";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    cl-nix-forge = {
      url = "github:nerima-lisp/cl-nix-forge/v0.5.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cl-weave = {
      url = "github:nerima-lisp/cl-weave/v1.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      cl-nix-forge,
      cl-weave,
      treefmt-nix,
      ...
    }:
    let
      # aarch64-darwin included alongside the CI-gated x86_64-linux so
      # `nix build`/`nix flake check` work on the aarch64-darwin dev machine
      # too -- this reverts PACKAGE_STANDARD.md's 2026-08-01 Linux-only
      # decision the same way every other current sibling repo already has
      # (cl-codec-kit, cl-nyancat, cl-prolog-kit, cl-dataflow-kit).
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
    in
    cl-nix-forge.lib.${nixpkgs.lib.head systems}.mkPackageFlake {
      inherit self systems nixpkgs;

      pname = "cl-vulkan-kit";
      asd = ./cl-vulkan-kit.asd;
      root = ./.;
      sourceInclude = [
        ./src
        ./t
        ./run-tests.lisp
      ];

      extraOutputs =
        ctx:
        let
          coverage = ctx.cl.mkCoverageReport {
            drv = ctx.package;
            name = "cl-vulkan-kit-coverage";
            timeoutSeconds = 600;
            killAfterSeconds = 30;
            entryPointText = ''
              (require "asdf")
              (asdf:load-system "cl-weave")
              (asdf:load-system "cl-vulkan-kit/test")
              (let ((report-directory
                      (merge-pathnames "cl-nix-forge-coverage-report/"
                                       (uiop:getcwd))))
                (ensure-directories-exist report-directory)
              (unless
                  (cl-weave:run-all
                   :reporter :spec
                   :max-workers 1
                   :coverage t
                   :coverage-reset t
                   :coverage-report-directory report-directory
                   :coverage-include-pathnames
                   (mapcar #'uiop:ensure-pathname
                           '("src/core.lisp"
                             "src/vulkan-device.lisp"
                             "src/vulkan-instance.lisp"
                             "src/vulkan-loader.lisp"))
                   :coverage-minimum-expression 100
                   :coverage-minimum-branch 100)
                (error "cl-vulkan-kit coverage suite failed")))
            '';
          };
        in
        {
          packages.coverage = coverage;
          checks.coverage = coverage;
        };

      meta = {
        description = "Common Lisp CFFI bindings for the Vulkan graphics and compute API";
        homepage = "https://github.com/nerima-lisp/cl-vulkan-kit";
        license = nixpkgs.lib.licenses.mit;
      };

      lispDependencies =
        ctx:
        [
          (cl-nix-forge.lib.${nixpkgs.lib.head systems}.fromDerivation {
            drv = cl-weave.packages.${ctx.system}.cl-weave;
            recursive = true;
          })
          (cl-nix-forge.lib.${nixpkgs.lib.head systems}.fromDerivation {
            drv = nixpkgs.legacyPackages.${ctx.system}.sbclPackages.cffi;
            recursive = true;
          })
        ]
        ++ map (
          drv:
          cl-nix-forge.lib.${nixpkgs.lib.head systems}.fromDerivation {
            inherit drv;
            recursive = true;
          }
        ) nixpkgs.legacyPackages.${ctx.system}.sbclPackages.cffi.propagatedBuildInputs;

      lispCheckDependencies = ctx: [
        (cl-nix-forge.lib.${nixpkgs.lib.head systems}.fromDerivation {
          drv = cl-weave.packages.${ctx.system}.cl-weave;
          recursive = true;
        })
      ];

      docs.root = ./docs;

      treefmt.evalModule = treefmt-nix.lib.evalModule;
    };
}
