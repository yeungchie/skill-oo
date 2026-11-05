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
    let((c)
        when(n_depth > n_max
            _Error(t_s n_i "nesting too deep")
        )
        c = _Code(t_s n_i)
        cond(
            (c == 34
                _ParseBasicString(t_s n_i nil)
            )
            (c == 39
                _ParseLiteralString(t_s n_i nil)
            )
            (c == 91
                _ParseArray(t_s n_i n_depth n_max)
            )
            (c == 123
                _ParseInlineTable(t_s n_i n_depth n_max)
            )
            (c == 116
                if(substring(t_s n_i 4) == "true"
                    list(ycCodec:::True n_i + 4)
                    _Error(t_s n_i "invalid value")
                )
            )
            (c == 102
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
    let((len res r c done)
        len = length(t_s)
        n_i = _SkipWs(t_s n_i + 1 t t)
        res = nil
        done = nil
        when(_Code(t_s n_i) == 93
            done = t
            n_i++
        )
        while(!done
            when(n_i > len
                _Error(t_s n_i "unterminated array")
            )
            r = _ParseValue(t_s n_i n_depth + 1 n_max)
            res = tconc(res car(r))
            n_i = _SkipWs(t_s cadr(r) t t)
            c = _Code(t_s n_i)
            case(c
                (93
                    done = t
                    n_i++
                )
                (44
                    {
                    n_i = _SkipWs(t_s n_i + 1 t t)
                    when(_Code(t_s n_i) == 93
                        done = t
                        n_i++
                    )
                    }
                )
                (t
                    _Error(t_s n_i "expected ',' or ']'")
                )
            )
        )
        list(car(res) n_i)
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
    let((obj meta path r c v done key)
        obj = _NewTable()
        meta = _MetaNew()
        n_i = _SkipWs(t_s n_i + 1 nil nil)
        done = nil
        when(_Code(t_s n_i) == 125
            done = t
            n_i++
        )
        while(!done
            key = n_i
            r = _ParseKeyPath(t_s n_i)
            path = car(r)
            n_i = _SkipWs(t_s cadr(r) nil nil)
            unless(_Code(t_s n_i) == 61
                _Error(t_s n_i "expected '='")
            )
            n_i = _SkipWs(t_s n_i + 1 nil nil)
            v = _ParseValue(t_s n_i n_depth + 1 n_max)
            _AssignValue(t_s meta nil obj path car(v) key n_max)
            n_i = _SkipWs(t_s cadr(v) nil nil)
            c = _Code(t_s n_i)
            case(c
                (44
                    {
                    n_i = _SkipWs(t_s n_i + 1 nil nil)
                    when(_Code(t_s n_i) == 125
                        _Error(t_s n_i "trailing comma in inline table")
                    )
                    }
                )
                (125
                    done = t
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
        list(obj n_i)
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
    let((array k r path)
        array = _Code(t_s n_i + 1) == 91
        k = n_i + if(array 2 1)
        k = _SkipWs(t_s k nil nil)
        r = _ParseKeyPath(t_s k)
        path = car(r)
        k = _SkipWs(t_s cadr(r) nil nil)
        if(array
        then
            unless(_Code(t_s k) == 93 && _Code(t_s k + 1) == 93
                _Error(t_s k "expected ']]'")
            )
            k = k + 2
        else
            unless(_Code(t_s k) == 93
                _Error(t_s k "expected ']'")
            )
            k++
        )
        list(path _LineEnd(t_s k) array)
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
    let((i len root meta cur cur2 r key v path h)
        t_s = _Normalize(t_s)
        i = 1
        len = length(t_s)
        root = _NewTable()
        meta = _MetaNew()
        cur = root
        cur2 = nil
        while(i <= len
            i = _SkipWs(t_s i t t)
            when(i <= len
                if(_Code(t_s i) == 91
                then
                    h = _ParseHeader(t_s i n_max)
                    r = _HeaderTarget(t_s root meta car(h) i cadr(cdr(h)) n_max)
                    cur = car(r)
                    cur2 = cadr(r)
                    i = cadr(h)
                else
                    key = i
                    r = _ParseKeyPath(t_s i)
                    path = car(r)
                    i = _SkipWs(t_s cadr(r) nil nil)
                    unless(_Code(t_s i) == 61
                        _Error(t_s i "expected '='")
                    )
                    i = _SkipWs(t_s i + 1 nil nil)
                    v = _ParseValue(t_s i 0 n_max)
                    _AssignValue(t_s meta cur2 cur path car(v) key n_max)
                    i = _LineEnd(t_s cadr(v))
                )
            )
        )
        root
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
