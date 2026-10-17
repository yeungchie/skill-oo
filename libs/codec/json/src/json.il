useNamespace("ycJson")

; 哨兵：false/null 不坍缩为 nil（nil 仅表示空数组）；Missing 为对象缺键的默认标记。
False = 'False
Null = 'Null
Missing = 'Missing

; 解析与输出的嵌套深度上限。
_maxDepth = 1000


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
    ; 按统一格式 error() 中断：ycJson: <说明> at line <行>, column <列>。
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
        error("ycJson: %s at line %d, column %d" t_msg car(l_pos) cadr(l_pos))
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


; ---------- 严格解析入口 ----------

procedure(_decodeText(t_s g_relaxed "tg")  ; -> any
    ; 解析单个 JSON 文档：前导/尾随空白允许，尾随非空白字符报错。
    ;
    ; **参数**
    ;   t_s        (str) - 输入串
    ;   g_relaxed  (t|nil) - jsonc 放宽开关
    ;
    ; **返回**
    ;   (any) - 解析产物
    let((n_k l_r g_val)
        n_k = _skipWs(t_s 1 g_relaxed)
        l_r = _value(t_s n_k g_relaxed 0)
        g_val = car(l_r)
        n_k = _skipWs(t_s cadr(l_r) g_relaxed)
        when(n_k <= length(t_s)
            _error(t_s n_k "unexpected trailing characters")
        )
        g_val
    )
)

procedure(jsonParse(t_str "t")  ; -> any
    ; 解析严格 JSON 单文档；前导/尾随空白允许，尾随非空白字符报错。
    ;
    ; **参数**
    ;   t_str  (str) - JSON 文本
    ;
    ; **返回**
    ;   (any) - 解析产物（table/list/fixnum/flonum/字符串/t/哨兵）
    unless(stringp(t_str)
        error("ycJson: jsonParse expects a string")
    )
    _decodeText(t_str nil)
)

procedure(jsoncParse(t_str "t")  ; -> any
    ; 解析放宽 JSON 单文档：支持 // 与 /* */ 注释、数组/对象尾逗号。
    ;
    ; **参数**
    ;   t_str  (str) - JSON 文本
    ;
    ; **返回**
    ;   (any) - 解析产物（table/list/fixnum/flonum/字符串/t/哨兵）
    unless(stringp(t_str)
        error("ycJson: jsoncParse expects a string")
    )
    _decodeText(t_str t)
)

unuseNamespace("ycJson")

; END
