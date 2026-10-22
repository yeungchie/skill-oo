;--------------------------
; Program  : codec/toml(decode.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::require("ycCodec")

useNamespace("ycToml")

; 解码默认嵌套深度上限；与其它 codec 保持一致。
_maxDecodeDepth = 800


; ---------- 值解析 ----------

procedure(_parseValue(t_s n_i n_depth n_max "txxx")  ; -> list
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
            _error(t_s n_i "nesting too deep")
        )
        n_c = _code(t_s n_i)
        cond(
            (n_c == 34
                _parseBasicString(t_s n_i nil)
            )
            (n_c == 39
                _parseLiteralString(t_s n_i nil)
            )
            (n_c == 91
                _parseArray(t_s n_i n_depth n_max)
            )
            (n_c == 123
                _parseInlineTable(t_s n_i n_depth n_max)
            )
            (n_c == 116
                if(substring(t_s n_i 4) == "true"
                    list(ycCodec:::True n_i + 4)
                    _error(t_s n_i "invalid value")
                )
            )
            (n_c == 102
                if(substring(t_s n_i 5) == "false"
                    list(ycCodec:::False n_i + 5)
                    _error(t_s n_i "invalid value")
                )
            )
            (t
                if(_looksDate(t_s n_i) || _looksTime(t_s n_i)
                    _parseDateTime(t_s n_i)
                    _parseNumber(t_s n_i)
                )
            )
        )
    )
)

procedure(_parseArray(t_s n_i n_depth n_max "txxx")  ; -> list
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
        n_i = _skipWs(t_s n_i + 1 t t)
        l_res = nil
        g_done = nil
        when(_code(t_s n_i) == 93
            g_done = t
            n_i = n_i + 1
        )
        while(!g_done
            when(n_i > n_len
                _error(t_s n_i "unterminated array")
            )
            l_r = _parseValue(t_s n_i n_depth + 1 n_max)
            l_res = tconc(l_res car(l_r))
            n_i = _skipWs(t_s cadr(l_r) t t)
            n_c = _code(t_s n_i)
            case(n_c
                (93
                    g_done = t
                    n_i = n_i + 1
                )
                (44
                    {
                    n_i = _skipWs(t_s n_i + 1 t t)
                    when(_code(t_s n_i) == 93
                        g_done = t
                        n_i = n_i + 1
                    )
                    }
                )
                (t
                    _error(t_s n_i "expected ',' or ']'")
                )
            )
        )
        list(car(l_res) n_i)
    )
)

procedure(_parseInlineTable(t_s n_i n_depth n_max "txxx")  ; -> list
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
        t_obj = _newTable()
        t_meta = _metaNew()
        n_i = _skipWs(t_s n_i + 1 nil nil)
        g_done = nil
        when(_code(t_s n_i) == 125
            g_done = t
            n_i = n_i + 1
        )
        while(!g_done
            n_key = n_i
            l_r = _parseKeyPath(t_s n_i)
            l_path = car(l_r)
            n_i = _skipWs(t_s cadr(l_r) nil nil)
            unless(_code(t_s n_i) == 61
                _error(t_s n_i "expected '='")
            )
            n_i = _skipWs(t_s n_i + 1 nil nil)
            l_v = _parseValue(t_s n_i n_depth + 1 n_max)
            _assignValue(t_s t_meta nil t_obj l_path car(l_v) n_key n_max)
            n_i = _skipWs(t_s cadr(l_v) nil nil)
            n_c = _code(t_s n_i)
            case(n_c
                (44
                    {
                    n_i = _skipWs(t_s n_i + 1 nil nil)
                    when(_code(t_s n_i) == 125
                        _error(t_s n_i "trailing comma in inline table")
                    )
                    }
                )
                (125
                    g_done = t
                    n_i = n_i + 1
                )
                (10
                    _error(t_s n_i "newline in inline table")
                )
                (t
                    _error(t_s n_i "expected ',' or '}'")
                )
            )
        )
        list(t_obj n_i)
    )
)

; ---------- 表头与文档 ----------

procedure(_parseHeader(t_s n_i n_max "txx")  ; -> list
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
        g_array = _code(t_s n_i + 1) == 91
        n_k = n_i + if(g_array 2 1)
        n_k = _skipWs(t_s n_k nil nil)
        l_r = _parseKeyPath(t_s n_k)
        l_path = car(l_r)
        n_k = _skipWs(t_s cadr(l_r) nil nil)
        if(g_array
            {
            unless(_code(t_s n_k) == 93 && _code(t_s n_k + 1) == 93
                _error(t_s n_k "expected ']]'")
            )
            n_k = n_k + 2
            }
            {
            unless(_code(t_s n_k) == 93
                _error(t_s n_k "expected ']'")
            )
            n_k = n_k + 1
            }
        )
        list(l_path _lineEnd(t_s n_k) g_array)
    )
)

procedure(_decodeText(t_s n_max "tx")  ; -> table
    ; 解析完整 TOML 文档，返回根表。
    ;
    ; **参数**
    ;   t_s    (str) - 输入文本
    ;   n_max  (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (table) - 文档根表
    let((n_i n_len t_root t_meta t_cur l_cur l_r n_key l_v l_path l_h)
        t_s = _normalize(t_s)
        n_i = 1
        n_len = length(t_s)
        t_root = _newTable()
        t_meta = _metaNew()
        t_cur = t_root
        l_cur = nil
        while(n_i <= n_len
            n_i = _skipWs(t_s n_i t t)
            when(n_i <= n_len
                if(_code(t_s n_i) == 91
                    {
                    l_h = _parseHeader(t_s n_i n_max)
                    l_r = _headerTarget(t_s t_root t_meta car(l_h) n_i cadr(cdr(l_h)) n_max)
                    t_cur = car(l_r)
                    l_cur = cadr(l_r)
                    n_i = cadr(l_h)
                    }
                    {
                    n_key = n_i
                    l_r = _parseKeyPath(t_s n_i)
                    l_path = car(l_r)
                    n_i = _skipWs(t_s cadr(l_r) nil nil)
                    unless(_code(t_s n_i) == 61
                        _error(t_s n_i "expected '='")
                    )
                    n_i = _skipWs(t_s n_i + 1 nil nil)
                    l_v = _parseValue(t_s n_i 0 n_max)
                    _assignValue(t_s t_meta l_cur t_cur l_path car(l_v) n_key n_max)
                    n_i = _lineEnd(t_s cadr(l_v))
                    }
                )
            )
        )
        t_root
    )
)

procedure(decode(t_str \@key (maxDepth nil) "tg")  ; -> table
    ; 解码 TOML 文本为根 table。
    ;
    ; **参数**
    ;   t_str     (str) - 输入文本
    ;   ?maxDepth (int) - 最大嵌套深度；默认 800
    ;
    ; **返回**
    ;   (table) - 文档根表；语法或语义错误以 error() 中断
    unless(stringp(t_str)
        error("ycToml::decode: expects a string")
    )
    when(maxDepth == nil
        maxDepth = _maxDecodeDepth
    )
    unless(fixp(maxDepth) && maxDepth >= 1
        error("ycToml::decode: ?maxDepth must be a positive fixnum")
    )
    _decodeText(t_str maxDepth)
)

unuseNamespace("ycToml")

; END
