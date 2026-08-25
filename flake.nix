{
  description = "Common Lisp bindings for the Vulkan graphics and compute API";

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
        description = "Common Lisp bindings for the Vulkan graphics and compute API";
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

      # The Vulkan loader is a native library, not a Lisp system, so it goes
      # through `nativeLibraries` (which wires LD_LIBRARY_PATH/
      # DYLD_LIBRARY_PATH transitively for packages/checks/devShells alike --
      # see lib/core/asdf-derivation.nix in cl-nix-forge) rather than
      # `lispDependencies`. No new flake input and no `:depends-on` entry:
      # SB-ALIEN (SBCL's built-in FFI) is what src/foreign-library.lisp
      # dlopens it with.
      #
      # VK_ICD_FILENAMES points every check/devShell at a real, working
      # Vulkan implementation without a GPU: mesa's llvmpipe software ICD
      # ("lavapipe") on x86_64-linux, which is why `checks.default`'s
      # :vulkan-icd-tagged tests exercise real vkCreateInstance/
      # vkEnumeratePhysicalDevices calls in CI rather than only compiling
      # them. aarch64-darwin has no lavapipe equivalent in nixpkgs; MoltenVK
      # (Metal-backed, needs a real GPU) is wired there instead, for
      # `nix develop`/`nix build` on the maintainer's actual machine.
      packageArgs =
        ctx:
        {
          nativeLibraries = [ ctx.pkgs.vulkan-loader ];
        }
        // (
          if ctx.system == "x86_64-linux" then
            {
              env.VK_ICD_FILENAMES = "${ctx.pkgs.mesa}/share/vulkan/icd.d/lvp_icd.x86_64.json";
            }
          else
            {
              env.VK_ICD_FILENAMES = "${ctx.pkgs.moltenvk.out}/share/vulkan/icd.d/MoltenVK_icd.json";
            }
        );

      docs.root = ./docs;

      treefmt.evalModule = treefmt-nix.lib.evalModule;
    };
}
