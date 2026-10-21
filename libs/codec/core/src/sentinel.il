;--------------------------
; Program  : codec/core(sentinel.il)
; Language : Cadence Skill
;--------------------------

useNamespace("ycCodec")

; ---------- 类型 ----------

defclass(TypeData () (
    ; TypeData 数据桶：收纳规范名（"True"/"False"/"Null"/"Missing"），构造后禁写。
    name(
        \@initarg name
        \@initform ""
    )
))

defclass(Type () (
    ; Type 实例：codec 共用哨兵对象，同规范名驻留共享同一实例。
    _data(
        \@initarg _data
        \@initform nil
    )

    toSkill()
))

defmethod(printself (self(Type))  ; -> str
    ; 返回 Type 的打印描述串，形如 ycCodec::Type("True")。
    ;
    ; **返回**
    ;   (str) - lsprintf 按 %A(%A) 模板生成（类名取 className，参数为规范名）
    lsprintf("%A(%A)" className(self) self->_data->name)
)

inScheme(
defmethod(initializeInstance (self(Type) \@rest _args)
    ; 构造 Type 实例时安装方法集：toSkill。
    ;
    ; **参数**
    ;   _args  (list) - 变参：附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装 toSkill 后返回 t
    self->toSkill = lambda(()  ; -> any
        ; 转换为 SKILL 原生值：True→t、False→nil、Null/Missing→'unbound。
        ;
        ; **返回**
        ;   (any) - 转换结果；有损（False 与空容器、Null/Missing 同域），仅供 SKILL 侧消费
        case(self->_data->name
            ("True"     t)
            ("False"    nil)
            ("Null"     'unbound)
            ("Missing"  'unbound)
            (t
                error("%A->toSkill: unknown type name %A" className(self) self->_data->name)
            )
        )
    )
    t
)
)

; Type 实例驻留表：规范名 → 唯一实例（固定四键，无需容量上限）。
_TypeCache = makeTable("typeCache" nil)

procedure(Type(t_name "t")  ; -> Type
    ; 取回/构造哨兵唯一实例：大小写不敏感接受 true/false/null/missing 四名。
    ;
    ; **参数**
    ;   t_name  (str) - 类型名（任意大小写，如 "true"/"True"/"TRUE"）
    ;
    ; **返回**
    ;   (Type) - 规范名对应的唯一实例；非字符串或未知名报错
    let((t_canon g_inst)
        unless(stringp(t_name)
            error("ycCodec::Type: unknown type name %A" t_name)
        )
        t_canon = cond(
            (pcreMatchp("(?i)^true\\z" t_name) "True")
            (pcreMatchp("(?i)^false\\z" t_name) "False")
            (pcreMatchp("(?i)^null\\z" t_name) "Null")
            (pcreMatchp("(?i)^missing\\z" t_name) "Missing")
        )
        unless(t_canon
            error("ycCodec::Type: unknown type name %A" t_name)
        )
        g_inst = _TypeCache[t_canon]
        unless(g_inst
            g_inst = makeInstance('Type ?_data makeInstance('TypeData ?name t_canon))
            _TypeCache[t_canon] = g_inst
        )
        g_inst
    )
)

; 哨兵：true/false/null 不坍缩为 t/nil；Missing 为容器缺键的默认标记。
; 四常量均为 Type 唯一实例，所有 codec 共用同一组对象，可经 ->toSkill() 转为 SKILL 原生值。
True    = Type("true")
False   = Type("false")
Null    = Type("null")
Missing = Type("missing")

unuseNamespace("ycCodec")

; END
