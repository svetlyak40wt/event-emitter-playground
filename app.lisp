(uiop:define-package #:playground/app
  (:use #:cl)
  (:import-from #:reblocks/widget
                #:widget
                #:update
                #:render
                #:defwidget)
  (:import-from #:reblocks)
  (:import-from #:reblocks/server)
  (:import-from #:reblocks/app
                #:defapp)
  (:import-from #:event-emitter
                #:event-emitter)
  (:import-from #:reblocks/session
                #:init)
  (:import-from #:reblocks-ui
                #:ui-widget)
  (:import-from #:reblocks/dependencies
                #:get-dependencies)
  (:import-from #:reblocks-lass
                #:make-dependency)
  (:import-from #:serapeum
                #:push-end))
(in-package #:playground/app)


(defclass bus (event-emitter)
  ())


(defvar *bus* (make-instance 'bus))


(defwidget form (event-emitter ui-widget)
  ())


(defwidget message ()
  ((text :initarg :text
         :reader message-text)))


(defwidget chat ()
  ((messages :initform nil
             :accessor chat-messages)))


(defwidget page ()
  ((form :initarg :form
         :reader form-widget)
   (chat :initarg :chat
         :reader chat-widget)))


(defwidget multi-pages ()
  ((pages :initarg :pages
          :reader all-pages)))


(defapp app
  :prefix "/")


(defun make-page ()
  (let* ((form (make-instance 'form))
         (chat (make-instance 'chat)))
    
    (flet ((add-message-to-the-chat (text)
             "Это обработчик новых постов в чат.
              Он добавляет новое сообщение в список и обновляет список на фронтенде."
             (push-end (make-instance 'message
                                      :text text)
                       (chat-messages chat))
             (update chat)))

      ;; Зарегистрируем обработчик, чтобы связать два виджета
      (event-emitter:on :submit *bus*
                        #'add-message-to-the-chat))
    
    (make-instance 'page
                   :form form
                   :chat chat)))


(defmethod init ((app app))
  (make-instance 'multi-pages
                 :pages (list (make-page)
                              (make-page))))


(defmethod render ((widget message))
    (reblocks/html:with-html
      (:p (message-text widget))))


(defmethod render ((widget chat))
  (reblocks/html:with-html
    (if (chat-messages widget)
        (mapcar #'render (chat-messages widget))
        (:p "В чате пока пусто."))))


(defmethod render ((widget form))
  (flet ((submit (&key message-text &allow-other-keys)
           ;; Отправим подписчикам событие о том, что пользователь ввёл какой-то текст
           (event-emitter:emit :submit *bus*
                               message-text)
           (update widget)))
    
    (reblocks-ui/form:with-html-form (:post #'submit)
      (:textarea :name "message-text")
      (:input :class "button" :type "submit" :value "Отправить"))))


(defmethod render ((widget page))
  (reblocks/html:with-html
    (render (chat-widget widget))
    (render (form-widget widget))))


(defmethod render ((widget multi-pages))
  (reblocks/html:with-html
    (mapcar #'render (all-pages widget))))


(defmethod get-dependencies ((widget page))
  (list
   (make-dependency
     '(.page
       :width 60%
       :margin 3rem auto 3rem auto) )))


(defmethod get-dependencies ((widget multi-pages))
  (list
   (make-dependency
     '(.multi-pages
       :display flex
       :lex-direction row
       :gap 3rem
       :margin-left 3rem
       :margin-right 3rem) )))


(defun start ()
  (reblocks/server:start :port 8080
                         :apps (list 'app))
  (log:config :info))
