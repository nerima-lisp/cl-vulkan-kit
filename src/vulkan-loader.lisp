#.(in-package #:cl-vulkan-kit)

(defun load-vulkan ()
  "Load the Vulkan loader. Returns T when the shared library is available."
  (unless *vulkan-loaded*
    (setf *vulkan-loaded* (cffi:load-foreign-library 'vulkan)))
  t)

(defun unload-vulkan ()
  "Unload the Vulkan loader when it is loaded."
  (when *vulkan-loaded*
    (cffi:close-foreign-library 'vulkan)
    (setf *vulkan-loaded* nil))
  t)

(defun vulkan-loaded-p ()
  (not (null *vulkan-loaded*)))

(defun call-with-vulkan-loader (thunk)
  (let ((owned-p (not (vulkan-loaded-p))))
    (load-vulkan)
    (unwind-protect (funcall thunk)
      (when owned-p
        (unload-vulkan)))))
