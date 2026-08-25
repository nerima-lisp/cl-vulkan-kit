;;;; src/package.lisp
(defpackage #:cl-vulkan-kit
  (:use #:cl)
  (:export
   #:library-version
   #:cl-vulkan-kit-error
   #:vulkan-error
   #:vulkan-error-result
   #:load-vulkan
   #:unload-vulkan
   #:vulkan-loaded-p
   #:call-with-vulkan-loader
   #:with-vulkan-loader
   #:call-with-vulkan-instance
   #:with-vulkan-instance
   #:create-instance
   #:destroy-instance
   #:enumerate-physical-devices
   #:vulkan-version
   #:vulkan-instance
   #:physical-device))

(in-package #:cl-vulkan-kit)

(defvar *vulkan-loaded* nil)
(defconstant +vk-api-version-1-0+ #x00400000)

(defun create-instance (&key (application-name "cl-vulkan-kit")
                              (application-version 1)
                              (engine-name "cl-vulkan-kit")
                              (engine-version 1)
                              (api-version +vk-api-version-1-0+))
  (%create-instance* application-name application-version
    engine-name engine-version api-version))

(defun enumerate-physical-devices (instance &key (max-attempts 4))
  (%enumerate-physical-devices* instance max-attempts))

(defmacro with-vulkan-loader (&body body)
  `(call-with-vulkan-loader (lambda () ,@body)))

(defmacro with-vulkan-instance ((instance &rest options) &body body)
  `(call-with-vulkan-instance (lambda (,instance) ,@body) ,@options))
