;--------------------------
; Program  : codec/toml(decode.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::Require("ycCodec")

useNamespace("ycToml")

; 解码默认嵌套深度上限；与其它 codec 保持一致。
_MaxDecodeDepth = 800


; ---------- 值解析 ----------

procedure(_ParseValue(t_s n_i n_depth n_max "txxx")  ; -> list
    ; 解析任意 TOML 值，按类型派发到字符串、数组、内联表、布尔、日期时间或数字。
    ;
    ; **参数**
    ;   t_s      (str) - 输入串
    ;   n_i      (int) - 值首字符位置
    ;   n_depth  (int) - 当前嵌套深度（顶层 0）
    ;   n_max    (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (list) - (值 下一位置)
    let((n_c)
        when(n_depth > n_max
            _Error(t_s n_i "nesting too deep")
        )
        n_c = _Code(t_s n_i)
        cond(
            (n_c == 34
                _ParseBasicString(t_s n_i nil)
            )
            (n_c == 39
                _ParseLiteralString(t_s n_i nil)
            )
            (n_c == 91
                _ParseArray(t_s n_i n_depth n_max)
            )
            (n_c == 123
                _ParseInlineTable(t_s n_i n_depth n_max)
            )
            (n_c == 116
                if(substring(t_s n_i 4) == "true"
                    list(ycCodec:::True n_i + 4)
                    _Error(t_s n_i "invalid value")
                )
            )
            (n_c == 102
                if(substring(t_s n_i 5) == "false"
                    list(ycCodec:::False n_i + 5)
                    _Error(t_s n_i "invalid value")
                )
            )
            (t
                if(_LooksDate(t_s n_i) || _LooksTime(t_s n_i)
                    _ParseDateTime(t_s n_i)
                    _ParseNumber(t_s n_i)
                )
            )
        )
    )
)

procedure(_ParseArray(t_s n_i n_depth n_max "txxx")  ; -> list
    ; 解析数组；允许跨行、注释与尾逗号，空数组返回 nil。
    ;
    ; **参数**
    ;   t_s      (str) - 输入串
    ;   n_i      (int) - '[' 位置
    ;   n_depth  (int) - 当前嵌套深度
    ;   n_max    (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (list) - (列表或 nil 闭括号后一位置)
    let((n_len l_res l_r n_c g_done)
        n_len = length(t_s)
        n_i = _SkipWs(t_s n_i + 1 t t)
        l_res = nil
        g_done = nil
        when(_Code(t_s n_i) == 93
            g_done = t
            n_i++
        )
        while(!g_done
            when(n_i > n_len
                _Error(t_s n_i "unterminated array")
            )
            l_r = _ParseValue(t_s n_i n_depth + 1 n_max)
            l_res = tconc(l_res car(l_r))
            n_i = _SkipWs(t_s cadr(l_r) t t)
            n_c = _Code(t_s n_i)
            case(n_c
                (93
                    g_done = t
                    n_i++
                )
                (44
                    {
                    n_i = _SkipWs(t_s n_i + 1 t t)
                    when(_Code(t_s n_i) == 93
                        g_done = t
                        n_i++
                    )
                    }
                )
                (t
                    _Error(t_s n_i "expected ',' or ']'")
                )
            )
        )
        list(car(l_res) n_i)
    )
)

procedure(_ParseInlineTable(t_s n_i n_depth n_max "txxx")  ; -> list
    ; 解析内联表；禁止换行与尾逗号，点分键可创建嵌套表。
    ;
    ; **参数**
    ;   t_s      (str) - 输入串
    ;   n_i      (int) - '{' 位置
    ;   n_depth  (int) - 当前嵌套深度
    ;   n_max    (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (list) - (table 闭括号后一位置)
    let((t_obj t_meta l_path l_r n_c l_v g_done n_key)
        t_obj = _NewTable()
        t_meta = _MetaNew()
        n_i = _SkipWs(t_s n_i + 1 nil nil)
        g_done = nil
        when(_Code(t_s n_i) == 125
            g_done = t
            n_i++
        )
        while(!g_done
            n_key = n_i
            l_r = _ParseKeyPath(t_s n_i)
            l_path = car(l_r)
            n_i = _SkipWs(t_s cadr(l_r) nil nil)
            unless(_Code(t_s n_i) == 61
                _Error(t_s n_i "expected '='")
            )
            n_i = _SkipWs(t_s n_i + 1 nil nil)
            l_v = _ParseValue(t_s n_i n_depth + 1 n_max)
            _AssignValue(t_s t_meta nil t_obj l_path car(l_v) n_key n_max)
            n_i = _SkipWs(t_s cadr(l_v) nil nil)
            n_c = _Code(t_s n_i)
            case(n_c
                (44
                    {
                    n_i = _SkipWs(t_s n_i + 1 nil nil)
                    when(_Code(t_s n_i) == 125
                        _Error(t_s n_i "trailing comma in inline table")
                    )
                    }
                )
                (125
                    g_done = t
                    n_i++
                )
                (10
                    _Error(t_s n_i "newline in inline table")
                )
                (t
                    _Error(t_s n_i "expected ',' or '}'")
                )
            )
        )
        list(t_obj n_i)
    )
)

; ---------- 表头与文档 ----------

procedure(_ParseHeader(t_s n_i n_max "txx")  ; -> list
    ; 解析 [table] 或 [[array-of-tables]] 表头并消费行尾。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   n_i    (int) - '[' 位置
    ;   n_max  (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (list) - (键路径 下一位置 array标志)
    let((g_array n_k l_r l_path)
        g_array = _Code(t_s n_i + 1) == 91
        n_k = n_i + if(g_array 2 1)
        n_k = _SkipWs(t_s n_k nil nil)
        l_r = _ParseKeyPath(t_s n_k)
        l_path = car(l_r)
        n_k = _SkipWs(t_s cadr(l_r) nil nil)
        if(g_array
        then
            unless(_Code(t_s n_k) == 93 && _Code(t_s n_k + 1) == 93
                _Error(t_s n_k "expected ']]'")
            )
            n_k = n_k + 2
        else
            unless(_Code(t_s n_k) == 93
                _Error(t_s n_k "expected ']'")
            )
            n_k++
        )
        list(l_path _LineEnd(t_s n_k) g_array)
    )
)

procedure(_DecodeText(t_s n_max "tx")  ; -> table
    ; 解析完整 TOML 文档，返回根表。
    ;
    ; **参数**
    ;   t_s    (str) - 输入文本
    ;   n_max  (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (table) - 文档根表
    let((n_i n_len t_root t_meta t_cur l_cur l_r n_key l_v l_path l_h)
        t_s = _Normalize(t_s)
        n_i = 1
        n_len = length(t_s)
        t_root = _NewTable()
        t_meta = _MetaNew()
        t_cur = t_root
        l_cur = nil
        while(n_i <= n_len
            n_i = _SkipWs(t_s n_i t t)
            when(n_i <= n_len
                if(_Code(t_s n_i) == 91
                then
                    l_h = _ParseHeader(t_s n_i n_max)
                    l_r = _HeaderTarget(t_s t_root t_meta car(l_h) n_i cadr(cdr(l_h)) n_max)
                    t_cur = car(l_r)
                    l_cur = cadr(l_r)
                    n_i = cadr(l_h)
                else
                    n_key = n_i
                    l_r = _ParseKeyPath(t_s n_i)
                    l_path = car(l_r)
                    n_i = _SkipWs(t_s cadr(l_r) nil nil)
                    unless(_Code(t_s n_i) == 61
                        _Error(t_s n_i "expected '='")
                    )
                    n_i = _SkipWs(t_s n_i + 1 nil nil)
                    l_v = _ParseValue(t_s n_i 0 n_max)
                    _AssignValue(t_s t_meta l_cur t_cur l_path car(l_v) n_key n_max)
                    n_i = _LineEnd(t_s cadr(l_v))
                )
            )
        )
        t_root
    )
)

procedure(Decode(t_str \@key (maxDepth nil) "tg")  ; -> table
    ; 解码 TOML 文本为根 table。
    ;
    ; **参数**
    ;   t_str     (str) - 输入文本
    ;   ?maxDepth (int) - 最大嵌套深度；默认 800
    ;
    ; **返回**
    ;   (table) - 文档根表；语法或语义错误以 error() 中断
    unless(stringp(t_str)
        error("ycToml::Decode: expects a string")
    )
    unless(_ValidUtf8(t_str)
        error("ycToml::Decode: invalid UTF-8")
    )
    when(maxDepth == nil
        maxDepth = _MaxDecodeDepth
    )
    unless(fixp(maxDepth) && maxDepth >= 1
        error("ycToml::Decode: ?maxDepth must be a positive fixnum")
    )
    _DecodeText(t_str maxDepth)
)

unuseNamespace("ycToml")

; END
