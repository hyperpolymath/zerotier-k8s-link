; SPDX-License-Identifier: MPL-2.0
;; guix.scm — GNU Guix package definition for zerotier-k8s-link
;; Usage: guix shell -f guix.scm

(use-modules (guix packages)
             (guix build-system gnu)
             (guix licenses))

(package
  (name "zerotier-k8s-link")
  (version "0.1.0")
  (source #f)
  (build-system gnu-build-system)
  (synopsis "zerotier-k8s-link")
  (description "zerotier-k8s-link — part of the hyperpolymath ecosystem.")
  (home-page "https://github.com/hyperpolymath/zerotier-k8s-link")
  (license mpl2.0))
