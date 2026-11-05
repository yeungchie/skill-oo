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

defmacro(ycWith (s_name g_expr \@rest l_body)
    ; 在 with 作用域内执行代码：绑定进入钩子的返回值，退出时调用退出钩子。
    ;
    ; quasiquote 里的 let 绑定列表带初值会被读取器拆错，因此初值在体内赋值。
    ; 隐藏对象用 gensym() 生成唯一符号，避免与体内同名变量互相捕获。
    ; s_name 为 nil 时只执行两个钩子，不建立用户绑定。
    ;
    ; **参数**
    ;   s_name  (sym|nil) - 绑定变量名（不求值）；nil 表示不绑定，t 不可用
    ;   g_expr  (form)    - 求值一次的对象表达式（不求值，交给宏展开）
    ;   l_body  (list)    - 作用域内的表达式（可为空，空 body 返回 nil）
    ;
    ; **返回**
    ;   (any) - 体内最后一个表达式的值（省略 body 为 nil）；缺钩子或表达式为 nil 时 error()
    let((obj scope)
        unless((s_name == nil) || (symbolp(s_name) && s_name != 't)
            error("ycWith: binding name must be a symbol other than t, or nil")
        )
        obj = gensym()
        scope = if(s_name
            `let((,s_name)
                ,s_name = __ycWithEnter__(,obj)
                unwindProtect(
                    { nil ,@l_body }
                    __ycWithExit__(,obj)
                )
            )
            `progn(
                __ycWithEnter__(,obj)
                unwindProtect(
                    { nil ,@l_body }
                    __ycWithExit__(,obj)
                )
            )
        )
        `let((,obj)
            ,obj = ,g_expr
            unless(,obj
                error("ycWith: expression evaluated to nil")
            )
            unless(ycLang::_ycWithHas(,obj '__ycWithEnter__)
                error("ycWith: %A does not implement __ycWithEnter__"
                    className(,obj)
                )
            )
            unless(ycLang::_ycWithHas(,obj '__ycWithExit__)
                error("ycWith: %A does not implement __ycWithExit__"
                    className(,obj)
                )
            )
            ,scope
        )
    )
)


unuseNamespace("ycLang")

; END
