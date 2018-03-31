
(require :asdf)
(load "~/quicklisp/setup.lisp")
(asdf:load-asd (merge-pathnames #P"amber/amber.asd" *load-pathname*))
(asdf:load-asd (merge-pathnames #P"cando/candoview/candoview.asd" *load-pathname*))
(asdf:load-asd (merge-pathnames #P"cando/candoview/molview.asd" *load-pathname*))
(asdf:load-asd (merge-pathnames #P"cando/geometry/geometry.asd" *load-pathname*))
(asdf:load-asd (merge-pathnames #P"cando/inet/inet.asd" *load-pathname*))
(asdf:load-asd (merge-pathnames #P"cando/charges/charges.asd" *load-pathname*))
(asdf:load-asd (merge-pathnames #P"cando/aromaticity/aromaticity.asd" *load-pathname*))
(asdf:load-asd (merge-pathnames #P"cando/smarts/smarts.asd" *load-pathname*))
(asdf:load-asd (merge-pathnames #P"cando/modelling/modelling.asd" *load-pathname*))
(asdf:load-asd (merge-pathnames #P"cando/utility/utility.asd" *load-pathname*))
(asdf:load-asd (merge-pathnames #P"cando/cando.asd" *load-pathname*))
(asdf:load-asd (merge-pathnames #P"leap/leap.asd" *load-pathname*))
(asdf:load-asd (merge-pathnames #P"cando-user/cando-user.asd" *load-pathname*))
(asdf:load-asd (merge-pathnames #P"build-cando.asd" *load-pathname*))
(ql:quickload "build-cando" :verbose t)
