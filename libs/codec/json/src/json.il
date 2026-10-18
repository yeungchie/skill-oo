useNamespace("ycJson")

; ---------- Type 类型对象 ----------

defclass(TypeData () (
    ; TypeData 数据桶：收纳哨兵规范名（"True"/"False"/"Null"/"Missing"），构造后禁写。
    name(
        \@initarg name
        \@initform ""
    )
))

defclass(Type () (
    ; Type 实例：JSON 字面量哨兵对象，同规范名驻留共享同一实例。
    _data(
        \@initarg _data
        \@initform nil
    )

    toSkill()
))

defmethod(printself (self(Type))  ; -> str
    ; 返回 Type 的打印描述串，形如 ycJson::Type("True")。
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
        ;   (any) - 转换结果；有损（False 与空数组、Null/Missing 同域），仅供 SKILL 侧消费
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
            error("ycJson::Type: unknown type name %A" t_name)
        )
        t_canon = cond(
            (pcreMatchp("(?i)^true\\z" t_name) "True")
            (pcreMatchp("(?i)^false\\z" t_name) "False")
            (pcreMatchp("(?i)^null\\z" t_name) "Null")
            (pcreMatchp("(?i)^missing\\z" t_name) "Missing")
        )
        unless(t_canon
            error("ycJson::Type: unknown type name %A" t_name)
        )
        g_inst = _TypeCache[t_canon]
        unless(g_inst
            g_inst = makeInstance('Type ?_data makeInstance('TypeData ?name t_canon))
            _TypeCache[t_canon] = g_inst
        )
        g_inst
    )
)

; 哨兵：true/false/null 不坍缩为 t/nil（nil 仅表示空数组）；Missing 为对象缺键的默认标记。
; 四常量均为 Type 唯一实例，可经 ->toSkill() 转为 SKILL 原生值。
True    = Type("true")
False   = Type("false")
Null    = Type("null")
Missing = Type("missing")

; 解析与输出的默认嵌套深度上限：实测解码约 900 层触语言栈上界、编码约 1150，取 800 留安全余量；可用 ?maxDepth 调整。
_maxDepth = 800


; ---------- 基础工具 ----------

procedure(_code(t_s n_i "tn")  ; -> int | nil
    ; 取字节索引处的字符码（1-based）；索引越界返回 nil。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 1-based 字节索引
    ;
    ; **返回**
    ;   (int|nil) - 该字节的字符码；越界时为 nil
    let((g_c)
        g_c = getchar(t_s n_i)
        when(g_c
            charToInt(g_c)
        )
    )
)

procedure(_digitp(g_c "g")  ; -> t | nil
    ; 判断字符码是否为 ASCII 数字（nil 安全）。
    ;
    ; **参数**
    ;   g_c  (any) - 字符码或 nil
    ;
    ; **返回**
    ;   (t|nil) - 48..57 时为 t，否则 nil
    g_c && g_c >= 48 && g_c <= 57
)

procedure(_lineCol(t_s n_i "tn")  ; -> list
    ; 按字节索引计算行列：行/列均 1-based，列按行内字节偏移。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 1-based 字节索引
    ;
    ; **返回**
    ;   (list) - (行 列) 两元素表
    let((n_line n_last)
        n_line = 1
        n_last = 0
        when(1 < n_i
            for(n_k 1 n_i - 1
                when(_code(t_s n_k) == 10
                    n_line = n_line + 1
                    n_last = n_k
                )
            )
        )
        list(n_line n_i - n_last)
    )
)

procedure(_error(t_s n_i t_msg "tnt")  ; -> never
    ; 按统一格式 error() 中断：ycJson::decode: <说明> at line <行>, column <列>。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   n_i    (int) - 1-based 字节索引（错误位置）
    ;   t_msg  (str) - 错误说明（英文短语）
    ;
    ; **返回**
    ;   (never) - 总是调用 error()，不返回
    let((l_pos)
        l_pos = _lineCol(t_s n_i)
        error("ycJson::decode: %s at line %d, column %d" t_msg car(l_pos) cadr(l_pos))
    )
)

procedure(_build(l_p "l")  ; -> str
    ; 将 tconc 头容器（或 nil）拼接为字符串。
    ;
    ; **参数**
    ;   l_p  (list) - tconc 头容器或 nil
    ;
    ; **返回**
    ;   (str) - 各片段顺序拼接
    buildString(car(l_p) "")
)


; ---------- 解码入口 ----------

procedure(_decodeText(t_s g_relaxed n_max "tgn")  ; -> any
    ; 解析单个 JSON 文档：前导/尾随空白允许，尾随非空白字符报错。
    ;
    ; **参数**
    ;   t_s        (str) - 输入串
    ;   g_relaxed  (t|nil) - jsonc 放宽开关
    ;   n_max      (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (any) - 解析产物
    let((n_k l_r g_val)
        n_k = _skipWs(t_s 1 g_relaxed)
        l_r = _value(t_s n_k g_relaxed 0 n_max)
        g_val = car(l_r)
        n_k = _skipWs(t_s cadr(l_r) g_relaxed)
        when(n_k <= length(t_s)
            _error(t_s n_k "unexpected trailing characters")
        )
        g_val
    )
)

procedure(decode(t_str \@key (format "json") (maxDepth nil) "ttg")  ; -> any | list
    ; 解码文本：?format 选 "json"（严格单文档）、"jsonc"（注释与尾逗号放宽）或 "jsonl"（逐行）。
    ;
    ; **参数**
    ;   t_str     (str) - 输入文本
    ;   ?format   (str) - 格式；默认 "json"
    ;   ?maxDepth (int) - 最大嵌套深度；默认 1000
    ;
    ; **返回**
    ;   (any|list) - 解码产物；"jsonl" 返回按行序的列表
    unless(stringp(t_str)
        error("ycJson::decode: expects a string")
    )
    when(maxDepth == nil
        maxDepth = _maxDepth
    )
    unless(fixp(maxDepth) && maxDepth >= 1
        error("ycJson::decode: ?maxDepth must be a positive fixnum")
    )
    case(format
        ("json" _decodeText(t_str nil maxDepth))
        ("jsonc" _decodeText(t_str t maxDepth))
        ("jsonl" _decodeLines(t_str maxDepth))
        (t
            error("ycJson::decode: unknown format %A" format)
        )
    )
)

unuseNamespace("ycJson")

; END
