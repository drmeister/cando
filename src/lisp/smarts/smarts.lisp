(in-package :smarts)

;;(defstruct chain-holder contents)
(defstruct chain
  head
  tail)

(defstruct labeled value)

(defun make-chem-info (&key tests smarts)
  (let ((ci (core:make-cxx-object 'chem:chem-info)))
    (chem:compile-smarts ci smarts)
    (if tests
        (chem:define-tests ci tests))
    ci))

(defmethod architecture.builder-protocol:make-node :around ((builder (eql :cando))
                                                            head
                                                            &rest args
                                                            &key bounds)
  (let ((result (call-next-method)))
    (typecase result
      (cons
       (cond
         ((symbolp (car result)) #| do nothing |#)
         (t (when (car result)
              (chem:setf-bounds (car result) bounds))
            (when (cdr result)
              (chem:setf-bounds (cdr result) bounds)))))
      (chem:chem-info-node
       (chem:setf-bounds result bounds))
      (otherwise (warn "What the heck is this -> ~s and how do we set its bounds" result)))
    result))

(defmethod architecture.builder-protocol:make-node ((builder (eql :cando))
                                                    (head (eql :atom))
                                                    &rest args
                                                    &key kind symbol
                                                      atomic-number
                                                      ring-bond-count
                                                      (total-hydrogen-count nil 
                                                                            total-hydrogen-count-supplied-p)
                                                      implicit-hydrogen-count
                                                      smallest-ring-size
                                                      valence
                                                      degree
                                                      connectivity
                                                      lisp-function
                                                      bounds)
;;;  (format t ":atom make-node head: ~s args: ~s~%" head args)
  (if (and total-hydrogen-count-supplied-p
           (not total-hydrogen-count))
      (setf total-hydrogen-count 1))
  (let ((sym (intern (string-upcase symbol) :keyword))
        result)
    (when kind
        (ecase kind
          (:organic
           (setf result (chem:create-sapelement (string sym)))
           #+(or)(core:make-cxx-object 'chem:atom-test :sym sym :test :sapelement)
           )
          (:aromatic
           (setf result (chem:create-saparomatic-element (string sym)))
           #+(or)(core:make-cxx-object 'chem:atom-test :sym sym :test :saparomatic-element))
          (:inorganic
           (setf result (chem:create-sapelement (string sym))))
          (:aliphatic
           (setf result (chem:create-sapaliphatic)))
          (:wildcard
           (setf result (chem:create-sapwild-card)))))
    (when lisp-function
      (setf result (chem:create-sappredicate-name lisp-function)))
    (when atomic-number
      (setf result (chem:create-sapatomic-number atomic-number)))
    (when total-hydrogen-count
      (setf result (chem:create-saptotal-hcount total-hydrogen-count)))
    (when implicit-hydrogen-count
      (setf result (chem:create-sapimplicit-hcount implicit-hydrogen-count)))
    (when ring-bond-count
      (setf result (chem:create-sapring-membership-count ring-bond-count)))
    (when smallest-ring-size
      (setf result (chem:create-sapring-size smallest-ring-size)))
    (when valence
      (setf result (chem:create-sapvalence valence)))
    (when degree
      (setf result (chem:create-sapdegree degree)))
    (when connectivity
      (setf result (chem:create-sapconnectivity connectivity)))
;;;    (format t "Made ~s~%" result)
    result))


(defmethod architecture.builder-protocol:make-node ((builder (eql :cando)) (kind (eql :chain))
                                                    &rest args
                                                    &key)
  (cons nil nil))

(defmethod architecture.builder-protocol:make-node ((builder (eql :cando))
                                                    (head (eql :atom-map-class))
                                                    &rest args
                                                    &key class bounds)
;;;  (format t ":atom-map-class make-node head: ~s args: ~s~%" head args)
  (let ((result (chem:create-sapatom-map class)))
    result)
 )

(defmethod architecture.builder-protocol:make-node ((builder (eql :cando))
                                                    (head (eql :bond))
                                                    &rest args
                                                    &key kind bounds)
;;;  (format t ":bond make-node head: ~s args: ~s~%" head args)
  (let (result)
    (ecase kind
      (:none
       (setf result (chem:create-sabno-bond nil)))
      (:single
       (setf result (chem:create-sabsingle-or-aromatic-bond nil)))
      (:double
       (setf result (chem:create-sabdouble-bond nil)))
      (:triple
       (setf result (chem:create-sabtriple-bond nil)))
      (:wildcard
       (setf result (chem:create-sabany-bond nil)))
      (:up-or-unspecified
       (setf result (chem:create-sabdirectional-single-up-or-unspecified nil)))
      (:down-or-unspecified
       (setf result (chem:create-sabdirectional-single-down-or-unspecified nil)))
      (:up
       (setf result (chem:create-sabdirectional-single-up nil)))
      (:down
       (setf result (chem:create-sabdirectional-single-down nil))))
;;;    (format t "Made ~s~%" result)
    result))

(defmethod architecture.builder-protocol:make-node ((builder (eql :cando))
                                                    (head (eql :bracketed-expression))
                                                    &rest args
                                                    &key expression)
;;;  (format t ":bracketed-expression make-node head: ~s args: ~s~%" head args)
  (let (result)
    (setf result (chem:create-log-identity nil))
    result))


(defmethod architecture.builder-protocol:make-node ((builder (eql :cando))
                                                    (head (eql :labeled))
                                                    &rest args
                                                    &key  label bounds)
;;;  (format t ":labeled make-node head: ~s args: ~s~%" head args)
  (make-labeled :value label))
#|
  (let (result)
    (setf result (chem:create-sapring-tag-test label))
    result))
|#
(defmethod architecture.builder-protocol:make-node ((builder (eql :cando))
                                                    (head (eql :binary-operator))
                                                    &rest args
                                                    &key operator bounds)
;;;  (format t ":binary-operator make-node head: ~s args: ~s~%" head args)
  (let (result)
    (ecase operator
      (:or
       (setf result (chem:create-log-or nil nil)))
      ((:strong-and :implicit-and)
       (setf result (chem:create-log-high-precedence-and nil nil)))
      (:weak-and
       (setf result (chem:create-log-low-precedence-and nil nil))))
;;;    (format t "Made ~s~%" result)
    result))


(defmethod architecture.builder-protocol:make-node ((builder (eql :cando))
                                                    (head (eql :unary-operator))
                                                    &rest args
                                                    &key operator bounds)
;;;  (format t ":recursive make-node head: ~s args: ~s~%" head args)
  (let (result)
    (ecase operator
      (:not
       (setf result (chem:create-log-not nil))))
;;;    (format t "Made ~s~%" result)
    result))


(defmethod architecture.builder-protocol:make-node ((builder (eql :cando))
                                                    (head (eql :chirality))
                                                    &rest args
                                                    &key class count bounds)
;;;  (format t ":chirality make-node head: ~s args: ~s~%" head args)
  (let (result)
    (ecase count
      (1
       (setf result (chem:create-sapchirality-clockwise)))
      (2
        (setf result (chem:create-sapchirality-anti-clockwise))))
;;;    (format t "Made ~s~%" result)
    result))


(defmethod architecture.builder-protocol:make-node ((builder (eql :cando))
                                                    (head (eql :charge))
                                                    &rest args
                                                    &key which value bounds)
;;;  (format t ":charge make-node head: ~s args: ~s~%" head args)
  (let (result)
    (ecase which
      (:positive
       (setf result (chem:create-sappositive-charge value)))
      (:negative
       (setf result (chem:create-sapnegative-charge value))))
;;;    (format t "Made ~s~%" result)
    result))


(defmethod architecture.builder-protocol:make-node ((builder (eql :cando))
                                                    (head (eql :recursive))
                                                    &rest args
                                                    &key pattern)
  (format t ":recursive make-node head: ~s args: ~s~%" head args)
  )


#+(or)
(defmethod architecture.builder-protocol:relate ((builder (eql :cando))
                                                 (head (eql :atom))
                                                 (left chem:atom-test)
                                                 (right labeled)
                                                 &key key)
  (chem:set-ring-test left :sarring-test)
  (chem:set-ring-id left (labeled-value right))
  left)
#+(or)
(defmethod architecture.builder-protocol:relate ((builder (eql :cando))
                                                 (head (eql :atom))
                                                 (left labeled)
                                                 (right chem:atom-test)
                                                 &key key)
  (chem:set-ring-test right :sarring-test)
  (chem:set-ring-id right (labeled-value left))
  right)
(defmethod architecture.builder-protocol:relate ((builder (eql :cando))
                                                 (head (eql :atom))
                                                 (left labeled)
                                                 (right chem:atom-or-bond-match-node)
                                                 &key key)
;;;  (format t "(:atom labeled chem:logical) relate head: ~s left: ~s right:~s~%" head left right)
  (chem:set-ring-test right :sarring-test)
  (chem:set-ring-id right (labeled-value left))
  right)
(defmethod architecture.builder-protocol:relate ((builder (eql :cando))
                                                 (head (eql :atom))
                                                 (left chem:atom-or-bond-match-node)
                                                 (right labeled)
                                                 &key key)
;;;  (format t "(:atom chem:logical labeled) relate head: ~s left: ~s right:~s~%" head left right)
  (chem:set-ring-test left :sarring-test)
  (chem:set-ring-id left (labeled-value right))
  left)
#+(or)(defmethod architecture.builder-protocol:relate ((builder (eql :cando))
                                                 (head (eql :atom))
                                                 (left labeled)
                                                 (right chem:atom-test)
                                                 &key key)
  (format t "(:atom labeled t) relate head: ~s left: ~s right:~s~%" head left right)
  (break "left: ~s right: ~s" left right)
  (chem:set-atom-test left right)
  left)
#+(or)
(defmethod architecture.builder-protocol:relate ((builder (eql :cando))
                                                 (head (eql :atom))
                                                 (left t)
                                                 (right labeled)
                                                 &key key)
  (format t "(:atom t labeled) relate head: ~s left: ~s right:~s~%" head left right)
  (break "left: ~s right: ~s" left right)
  (chem:set-atom-test left right)
  left)

#+(or)
(defmethod architecture.builder-protocol:relate ((builder (eql :cando))
                                                 (head (eql :atom))
                                                 (left chem:tag-set)
                                                 (right chem:atom-or-bond-match-node)
                                                 &key key)
  (chem:set-atom-test left right)
  (format t ":atom relate head: ~s left: ~s right:~s~%" head left right)
  left)

(defmethod architecture.builder-protocol:relate ((builder (eql :cando))
                                                 (head (eql :atom))
                                                 (left chem:bond-test)
                                                 (right chem:atom-test)
                                                 &key key)
;;  (format t "(:atom bond-test atom-test) relate head: ~s left: ~s right:~s~%" head left right)
  (chem:set-atom-test left right)
  left)

(defmethod architecture.builder-protocol:relate ((builder (eql :cando))
                                                 (head (eql :atom))
                                                 left
                                                 right
                                                 &key key)
  (format t "(:atom t t) relate head: ~s left: ~s right:~s~%" head left right)
  left)

(defmethod architecture.builder-protocol:relate ((builder (eql :cando))
                                                 (head (eql :expression))
                                                 left
                                                 right
                                                 &key key)
  (format t ":expression relate head: ~s left: ~s right:~s~%" head left right)
  (format nil "relate :expression left: ~s right: ~s~%" left right)
  left)

(defmethod architecture.builder-protocol:relate ((builder (eql :cando))
                                                 (head (eql :expression))
                                                 (left chem:logical)
                                                 (right integer)
                                                 &key key)
;;;  (format t ":expression relate head: ~s left: ~s right:~s~%" head left right)
    (let (result)
      (if (>= right 0)
          (setf result (chem:create-sappositive-charge right))
          (setf result (chem:create-sapnegative-charge right)))
;;;      (format t "Made ~s~%" result)
      (if (chem:get-left left)
          (progn
;;;            (format t "left ~a~%" (chem:get-left left))
            (chem:set-right left result))
          (progn
;;;            (format t "no left~%")
            (chem:set-left left result))))
  left)

(defmethod architecture.builder-protocol:relate ((builder (eql :cando))
                                                 (head (eql :expression))
                                                 (left chem:logical)
                                                 (right t)
                                                 &key key)
;;;  (format t ":expression relate  head: ~s left: ~s right:~s~%" head left right)
  (if (chem:get-left left)
      (progn
;;;        (format t "left ~a~%" (chem:get-left left))
        (chem:set-right left right))
      (progn
;;;        (format t "no left~%")
        (chem:set-left left right)))
  left)

(defmethod architecture.builder-protocol:relate ((builder (eql :cando))
                                                 (head (eql :operand))
                                                 left
                                                 right
                                                 &key key)
  (format t ":operand relate b head: ~s left: ~s right:~s~%" head left right)
  left)

(defmethod architecture.builder-protocol:relate ((builder (eql :cando))
                                                 (head (eql :operand))
                                                 (left chem:logical)
                                                 (right integer)
                                                 &key key)
;;;  (format t ":operand relate a head: ~s left: ~s right:~s~%" head left right)
  (let (result)
    (if (>= right)
        (setf result (chem:create-sapatomic-mass right))
        (error "mass must be positive"))
;;;    (format t "Made ~s~%" result)
    (if (chem:get-left left)
        (progn
;;;          (format t "left ~a~%" (chem:get-left left))
          (chem:set-right left result))
        (progn
;;;          (format t "no left~%")
          (chem:set-left left result)))
    ;; for [2H]
    #+(or)(if (chem:get-right left)
              (format t "type ~a~%" (chem:my-type (chem:get-right left))))
    #+(or)(if (and (chem:get-right left)
                   (eql (chem:my-type (chem:get-right left)) :saptotal-hcount))
              (chem:set-right left (chem:create-sappositive-charge right))))
  left)

(defmethod architecture.builder-protocol:relate ((builder (eql :cando))
                                                 (head (eql :operand))
                                                 (left chem:logical)
                                                 (right t)
                                                 &key key)
;;;  (format t ":operand relate head: ~s left: ~s right:~s~%" head left right)
  (if (chem:get-left left)
      (progn
;;;        (format t "left ~a~%" (chem:get-left left))
        (chem:set-right left right))
      (progn
;;;        (format t "no left~%")
        (chem:set-left left right)))
  left)

(defmethod architecture.builder-protocol:relate ((builder (eql :cando))
                                                 (head (eql :pattern))
                                                 left
                                                 right
                                                 &key key)
  (format t ":pattern relate head: ~s left: ~s right:~s~%" head left right)
  right)


(defmethod set-tail-or-right ((thing chem:chain) value)
  (chem:chain-set-tail thing value))

(defmethod set-tail-or-right ((thing chem:branch) value)
  (chem:branch-set-right thing value))

(defmethod architecture.builder-protocol:relate ((builder  (eql :cando))
                                                 (relation (eql :element))
                                                 (left cons)     
                                                 (right   t)
                                                 &key)
;;;  (format t ":element relate head: ~s left: ~s right:~s~%" relation left right)
  ;; scymtym's suggestion
  (let ((new (chem:make-chain.head.tail right nil)))
    (when (not (car left))
      (setf (car left) new))
    (alexandria:when-let ((last (cdr left)))
                         (set-tail-or-right last new)
                         #+(or)(setf (chain-tail last) new))
    (setf (cdr left) new))
  left)

(defmethod architecture.builder-protocol:relate ((builder  (eql :cando))
                                                 (relation (eql :element))
                                                 (left cons)     
                                                 (right chem:chain)
                                                 &key)
;;;  (format t ":element branch relate head: ~s left: ~s right:~s~%" relation left right)
  ;; scymtym's suggestion
  (let ((branch (chem:make-branch.left.right right nil))) ; (cdr left) right)))
    (alexandria:when-let ((last (cdr left)))
;;;                         (format t ":element branch relate chain-set-tail last: ~a branch: ~a~%" last branch)
                         (set-tail-or-right last branch)
                         #+(or)(setf (chain-tail last) new))
    (setf (cdr left) branch))
  left)


(defmethod architecture.builder-protocol:finish-node ((builder (eql :cando))
                                                      (kind    (eql :chain))
                                                      (node cons))
  (format t "finish element ~s~%" node)
  (car node))


(esrap:defrule chain
    (+ (alpha-char-p character))
  (:lambda (elements)
    (architecture.builder-protocol:node* (:chain)
      (* :element elements))))


(defmethod architecture.builder-protocol:finish-node ((builder (eql :cando))
                                                        (head (eql :element))
                                                        node)
  (format t "finish element ~s~%" node)
 node)

(defmethod architecture.builder-protocol:finish-node ((builder (eql :cando))
                                                        (head (eql :atom))
                                                        node)
  (format t "finish atom ~s~%" node)
  node)

(defmethod architecture.builder-protocol:finish-node ((builder (eql :cando))
                                                        (head (eql :bond))
                                                        node)
  (format t "finish bond ~s~%" node)
  node)

(defmethod architecture.builder-protocol:node-relation ((builder (eql :cando))
                                                      (head   (eql :chain))
                                                      node)
  (format t "finish element ~s~%" node)
  node)


(defgeneric build (head tree &rest args))

(defmethod build ((head (eql :atom)) tree &rest args)
  (cond
    ((consp tree)
;;;     (format t "Tree: ~s~%" (car (car tree)))
     (apply 'build (car (car tree))))
    (t (let* ((kind (getf args :kind))
              (symbol-name (getf args :symbol))
              (symbol (intern (string-upcase symbol-name) :keyword))
              (bounds (getf args :bounds)))
         (ecase kind
           (:organic
            (core:make-cxx-object 'chem:atom-test :sym symbol :test :sapelement))
           (:aromatic
            (core:make-cxx-object 'chem:atom-test :sym symbol :test :saparomatic-element))
           )))))

(defmethod build ((head (eql :atom)) (tree cons) &rest args)
     (format t "Tree: ~s~%" (car (car tree)))
  (apply 'build (car (car tree))))

(defmethod build ((head (eql :atom)) (tree null) &rest args)
  (let* ((kind (getf args :kind))
         (symbol-name (getf args :symbol))
         (symbol (intern (string-upcase symbol-name) :keyword))
         (bounds (getf args :bounds)))
    (ecase kind
      (:organic
       (core:make-cxx-object 'chem:atom-test :sym symbol :test :sapelement))
      (:aromatic
       (core:make-cxx-object 'chem:atom-test :sym symbol :test :saparomatic-element))
      )))


;;; ------------------------------------------------------------
;;;
;;; Everything that depends on SMARTS parsing is initialized now
;;;

(defvar *smarts-ring-tests*)

(defgeneric walk-smarts (parent child))

(defmethod walk-smarts (grandparent parent)
  (let ((children (chem:chem-info-node-children parent)))
    (loop for child in children
          do (walk-smarts parent child))))

(defmethod walk-smarts (parent (child chem:atom-test))
  (let ((test-type (chem:get-ring-test child)))
;;;    (format t "test-type ~s for ~s~%" test-type child)
    (when (eq test-type :sarring-test)
      (let* ((tag (chem:get-ring-id child))
             (bounds (chem:bounds child))
             (bound-start (cond
                            ((consp bounds) (car bounds))
                            ((integerp bounds) bounds)
                            (t (error "Figure out how to get bounds from ~s" bounds))))
             (info (gethash tag *smarts-ring-tests*)))
        (when (or (null info) (< bound-start (car info)))
          (setf (gethash tag *smarts-ring-tests*) (cons bound-start child)))))))

(defmethod walk-smarts (parent (child chem:logical))
  (let ((test-type (chem:get-ring-test child)))
;;;    (format t "test-type ~s for ~s~%" test-type child)
    (when (eq test-type :sarring-test)
      (let* ((tag (chem:get-ring-id child))
             (bounds (chem:bounds child))
             (bound-start (cond
                            ((consp bounds) (car bounds))
                            ((integerp bounds) bounds)
                            (t (error "Figure out how to get bounds from ~s" bounds))))
             (info (gethash tag *smarts-ring-tests*)))
        (when (or (null info) (< bound-start (car info)))
          (setf (gethash tag *smarts-ring-tests*) (cons bound-start child)))))
    ;; logicals have children
    (call-next-method)))


(defun change-nodes (ring-test-hashtable)
  (maphash (lambda (tag info)
             (let ((bound-start (car info))
                   (node (cdr info)))
               (chem:set-ring-test node :sarring-set)))
           ring-test-hashtable))

(defmacro with-top-walk (&body body)
  `(let ((*smarts-ring-tests* (make-hash-table :test 'eql)))
     (progn
       ,@body)
     (change-nodes *smarts-ring-tests*)))

(defmethod walk-smarts ((parent chem:logical) (child chem:bond-list-match-node))
  (with-top-walk
      (call-next-method)))

(defun chem:parse-smarts (code)
  (let ((result (language.smarts.parser:parse code :cando)))
    (with-top-walk
        (walk-smarts nil result))
    result))


(defun print-smarts (x) (let ((*print-readably* t)) (print-object x *standard-output*)))


(eval-when (:load-toplevel :execute)
  (chem:initialize-smarts-users))
