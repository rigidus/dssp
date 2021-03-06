(define-condition operation-not-found () ())

;; Начальную  часть  адресного  пространства обычно занимает словарь (иначе
;; "кодофайл")  -  хранилище слов и данных. По мере расширения исходного набора
;; слов  словарь  растет  в  сторону  увеличения  адресов. Специальные слова из
;; обязательного  набора  позволяют  управлять  вершиной  словаря - поднимать и
;; опускать ее.

(defparameter *dict* (make-hash-table :test #'equal))

;; Наряду со стеком данных и стеком возвратов в старших адресах оперативной
;; памяти  обычно  размещается  буфер  на  64-100  байт  для  построчного ввода
;; форт-текста с терминала и буферный пул для обмена с внешней дисковой памятью
;; размером от 1 до 3 и более К байт. Доступ к этим буферам и фактический обмен
;; осуществляют специальные слова из обязательного набора.

(defparameter *buff* (make-hash-table :test #'equal))

;; Стек  данных обычно располагается в старших адресах оперативной памяти и
;; используется  для  передачи  параметров  и  результатов  между  исполняемыми
;; словами. Его элементами являются двухбайтные значения, которые в зависимости
;; от  ситуации  могут  рассматриваться  различным  образом: как целые числа со
;; знаком  в  диапазоне  от  -32768  до +32767, как адреса оперативной памяти в
;; диапазоне  от  0  до  65535  (отсюда  ограничение  64  К на размер адресного
;; пространства),  как  коды литер (диапазон зависит от принятой кодировки) для
;; обмена  с  терминалом,  как номера блоков внешней памяти в диапазоне от 0 до
;; 32767  или  просто как 16-разрядные двоичные значения. В процессе исполнения
;; слов  значения  помещаются  на  стек  и  снимаются  с  него.  Переполнение и
;; исчерпание  стека,  как  правило,  не  проверяется;  его  максимальный объем
;; устанавливается  реализацией.  Стандарт  предусматривает,  что стек растет в
;; сторону  убывания  адресов; это согласуется с аппаратной реализацией стека в
;; большинстве ЭВМ, которые ее имеют.

(defparameter *stk*  nil)
;; стек возвратов
;; ...
(defparameter *prg*  (list 2 3 "+" "prn-stk"))


(defmacro def~op (name &body body)
  `(setf (gethash ,name *dict*)
         #'(lambda ()
             ,@body)))

(def~op "prn-stk"
  (print *stk*))

(def~op "call"
  (let ((opcode (pop *stk*)))
    (let ((operation (gethash opcode *dict*)))
      (when (null operation)
        (error 'operation-not-found))
      (funcall operation))))

(def~op "+"
  (let ((a (pop *stk*))
        (b (pop *stk*)))
    (push (+ a b) *stk*)))

(defun run ()
  (tagbody
   re
     (unless (null *prg*)
       (let ((opcode (pop *prg*)))
         (if (numberp opcode)
             (push opcode *stk*)
             ;; else
              (let ((operation (gethash opcode *dict*)))
               (when (null operation)
                 (error 'operation-not-found))
               (funcall operation))))
       (go re))))

(run)
