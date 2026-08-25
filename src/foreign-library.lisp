;;;; src/foreign-library.lisp
;;;;
;;;; Loads the platform Vulkan loader. Library names are bare (no store
;;;; path baked in): flake.nix puts pkgs.vulkan-loader on
;;;; LD_LIBRARY_PATH/DYLD_LIBRARY_PATH via cl-nix-forge's `nativeLibraries`,
;;;; and SB-ALIEN:LOAD-SHARED-OBJECT resolves a bare name through that
;;;; search path exactly as a C linker would (verified locally against a
;;;; real nixpkgs vulkan-loader build).
(in-package #:cl-vulkan-kit)

(defparameter +vulkan-loader-name+
  #+linux "libvulkan.so.1"
  #+darwin "libvulkan.dylib"
  #-(or linux darwin) (error "cl-vulkan-kit supports Linux and macOS only")
  "The Vulkan loader's shared-library name on this platform.")

(defvar *vulkan-loader-loaded-p* nil
  "True once LOAD-VULKAN-LOADER has successfully loaded the Vulkan loader.")

(defun load-vulkan-loader ()
  "Load the platform Vulkan loader, once. Safe to call repeatedly."
  (unless *vulkan-loader-loaded-p*
    (sb-alien:load-shared-object +vulkan-loader-name+)
    (setf *vulkan-loader-loaded-p* t))
  (values))
