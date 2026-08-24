;;;; src/core.lisp
(in-package #:cl-vulkan-kit)

(defparameter +version+ "0.1.0"
  "Kept in sync with cl-vulkan-kit.asd's :version by hand; see release.yml,
which refuses to publish a tag that disagrees with the .asd.")

(defun library-version ()
  "Return this system's version string."
  +version+)
