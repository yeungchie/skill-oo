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


; ---------- macro ----------

(defmacro ycWith (s_name g_expr \@rest l_body)
    ; 在 with 作用域内执行代码：绑定进入钩子的返回值，退出时调用退出钩子。
    ;
    ; quasiquote 里的 let 绑定列表不带初值，初值在体内赋值；
    ; 直接写初值会被读取器拆错（let: illegal binding form）。
    ;
    ; **参数**
    ;   s_name  (sym)  - 绑定变量名（不求值）
    ;   g_expr  (form) - 求值一次的对象表达式（不求值，交给宏展开）
    ;   l_body  (list) - 作用域内的表达式
    ;
    ; **返回**
    ;   (any) - 体内最后一个表达式的值；缺钩子或表达式为 nil 时 error()
    `let((__ycWithObj__)
        __ycWithObj__ = ,g_expr
        unless(__ycWithObj__
            error("ycWith: expression evaluated to nil")
        )
        unless(ycLang::_ycWithHas(__ycWithObj__ '__ycWithEnter__)
            error("ycWith: %A does not implement __ycWithEnter__"
                className(__ycWithObj__)
            )
        )
        unless(ycLang::_ycWithHas(__ycWithObj__ '__ycWithExit__)
            error("ycWith: %A does not implement __ycWithExit__"
                className(__ycWithObj__)
            )
        )
        let((,s_name)
            ,s_name = __ycWithEnter__(__ycWithObj__)
            unwindProtect(
                { ,@l_body }
                __ycWithExit__(__ycWithObj__)
            )
        )
    )
)


unuseNamespace("ycLang")

; END
