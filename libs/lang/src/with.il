;--------------------------
; Program  : ycLang(with.il)
; Language : Cadence Skill
;--------------------------

useNamespace("ycLang")


; ---------- with protocol ----------

; 协议钩子是全局通用函数；默认方法挂在根类 t 上，只作直接调用的兜底。
; 类通过 defmethod(__ycWithEnter__ (self(Class)) ...) 接入。
defmethod(__ycWithEnter__ (self(t))
    ; 默认进入钩子：提示类未接入 with 协议。
    ;
    ; **参数**
    ;   self  (t) - 任意对象
    ;
    ; **返回**
    ;   (never) - 总是 error() 中断
    error("ycWith: %A does not implement __ycWithEnter__" className(self))
)

defmethod(__ycWithExit__ (self(t))
    ; 默认退出钩子：提示类未接入 with 协议。
    ;
    ; **参数**
    ;   self  (t) - 任意对象
    ;
    ; **返回**
    ;   (never) - 总是 error() 中断
    error("ycWith: %A does not implement __ycWithExit__" className(self))
)


; ---------- helpers ----------

procedure(_ycWithHas(g_obj s_gf "gs")  ; -> t | nil
    ; 沿继承链判断对象是否有某个 with 钩子的具体方法（内部实现）。
    ;
    ; getGFbyClass() 只返回直接定义在该类上的通用函数，因此遍历
    ; superclassesOf() 的线性化父类表；根类 t 上的默认方法不计入。
    ;
    ; **参数**
    ;   g_obj  (any) - 对象
    ;   s_gf   (sym) - 通用函数名
    ;
    ; **返回**
    ;   (t|nil) - 自身或父类上有具体方法为 t
    let((ok)
        when(g_obj
            foreach(cls superclassesOf(classOf(g_obj))
                when(!ok && className(cls) != 't
                    when(member(s_gf getGFbyClass(className(cls)))
                        ok = t
                    )
                )
            )
        )
        ok
    )
)

procedure(_ycWithExpand(s_name g_expr l_body "sgl")  ; -> list
    ; 构造 ycWith 的宏展开式（内部实现）。
    ;
    ; 宏体直接构造展开式；gensym 隐藏原对象，body 以 progn 包裹。
    ;
    ; **参数**
    ;   s_name  (sym)  - 绑定变量名
    ;   g_expr  (form) - 对象表达式
    ;   l_body  (list) - 体内表达式
    ;
    ; **返回**
    ;   (list) - 宏展开式
    let((s_obj)
        s_obj = gensym()
        list('let
            list(list(s_obj g_expr))
            list('progn
                list('unless s_obj
                    list('error "ycWith: expression evaluated to nil")
                )
                list('unless
                    list('ycLang::_ycWithHas s_obj list('quote '__ycWithEnter__))
                    list('error "ycWith: %A does not implement __ycWithEnter__"
                        list('className s_obj))
                )
                list('unless
                    list('ycLang::_ycWithHas s_obj list('quote '__ycWithExit__))
                    list('error "ycWith: %A does not implement __ycWithExit__"
                        list('className s_obj))
                )
                list('let
                    list(list(s_name list('__ycWithEnter__ s_obj)))
                    list('unwindProtect
                        cons('progn l_body)
                        list('__ycWithExit__ s_obj)
                    )
                )
            )
        )
    )
)


; ---------- macro ----------

(defmacro ycWith (s_name g_expr \@rest l_body)
    ; 在 with 作用域内执行代码：绑定进入钩子的返回值，退出时调用退出钩子。
    ;
    ; **参数**
    ;   s_name  (sym)  - 绑定变量名（不求值）
    ;   g_expr  (form) - 求值一次的对象表达式（不求值，交给宏展开）
    ;   l_body  (list) - 作用域内的表达式
    ;
    ; **返回**
    ;   (any) - 体内最后一个表达式的值；缺钩子或表达式为 nil 时 error()
    _ycWithExpand(s_name g_expr l_body)
)


unuseNamespace("ycLang")

; END
