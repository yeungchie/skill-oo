useNamespace("ycYaml")

; ---------- 标量解析 ----------

procedure(_hexVal(n_c "x")  ; -> int | nil
    ; 将单个十六进制字符码转为数值。
    ;
    ; **参数**
    ;   n_c  (int) - 字符码
    ;
    ; **返回**
    ;   (int|nil) - 0..15；非十六进制为 nil
    cond(
        (n_c >= 48 && n_c <= 57 n_c - 48)
        (n_c >= 97 && n_c <= 102 n_c - 87)
        (n_c >= 65 && n_c <= 70 n_c - 55)
        (t nil)
    )
)

procedure(_parseQuoted(t_s n_i n_line "txn")  ; -> list
    ; 解析单引号或双引号标量，返回 (值 下一位置)。
    ;
    ; **参数**
    ;   t_s    (str) - 当前行文本
    ;   n_i    (int) - 引号位置
    ;   n_line (int) - 行号（错误消息）
    ;
    ; **返回**
    ;   (list) - (字符串值 闭引号后一位置)
    let((n_len n_q n_pos n_seg n_c n_esc n_d n_k n_cp l_p g_done)
        n_len = length(t_s)
        n_q = _code(t_s n_i)
        n_pos = n_i + 1
        n_seg = n_pos
        g_done = nil
        while(!g_done
            when(n_pos > n_len
                _errorLine("unterminated quoted scalar" n_line n_i)
            )
            n_c = _code(t_s n_pos)
            cond(
                (n_q == 39
                    cond(
                        (n_c == 39
                            cond(
                                (_code(t_s n_pos + 1) == 39
                                    l_p = tconc(l_p substring(t_s n_seg n_pos - n_seg))
                                    l_p = tconc(l_p "'")
                                    n_pos = n_pos + 2
                                    n_seg = n_pos
                                )
                                (t
                                    l_p = tconc(l_p substring(t_s n_seg n_pos - n_seg))
                                    g_done = t
                                    n_pos = n_pos + 1
                                )
                            )
                        )
                        (t
                            n_pos = n_pos + 1
                        )
                    )
                )
                (t
                    cond(
                        (n_c == 34
                            l_p = tconc(l_p substring(t_s n_seg n_pos - n_seg))
                            g_done = t
                            n_pos = n_pos + 1
                        )
                        (n_c == 92
                            l_p = tconc(l_p substring(t_s n_seg n_pos - n_seg))
                            n_esc = n_pos
                            n_pos = n_pos + 1
                            when(n_pos > n_len
                                _errorLine("unterminated escape" n_line n_esc)
                            )
                            n_cp = _code(t_s n_pos)
                            case(n_cp
                                (48 l_p = tconc(l_p _utf8Str(0)))
                                (97 l_p = tconc(l_p _utf8Str(7)))
                                (98 l_p = tconc(l_p _utf8Str(8)))
                                (116 l_p = tconc(l_p _utf8Str(9)))
                                (110 l_p = tconc(l_p _utf8Str(10)))
                                (118 l_p = tconc(l_p _utf8Str(11)))
                                (102 l_p = tconc(l_p _utf8Str(12)))
                                (114 l_p = tconc(l_p _utf8Str(13)))
                                (101 l_p = tconc(l_p _utf8Str(27)))
                                (32 l_p = tconc(l_p " "))
                                (34 l_p = tconc(l_p "\""))
                                (47 l_p = tconc(l_p "/"))
                                (92 l_p = tconc(l_p "\\"))
                                (78 l_p = tconc(l_p _utf8Str(133)))
                                (95 l_p = tconc(l_p _utf8Str(160)))
                                (76 l_p = tconc(l_p _utf8Str(8232)))
                                (80 l_p = tconc(l_p _utf8Str(8233)))
                                (120
                                    n_d = 0
                                    for(n_k 1 2
                                        n_cp = _hexVal(_code(t_s n_pos + n_k))
                                        unless(n_cp
                                            _errorLine("invalid hex escape" n_line n_esc)
                                        )
                                        n_d = n_d * 16 + n_cp
                                    )
                                    l_p = tconc(l_p _utf8Str(n_d))
                                    n_pos = n_pos + 2
                                )
                                (117
                                    n_d = 0
                                    for(n_k 1 4
                                        n_cp = _hexVal(_code(t_s n_pos + n_k))
                                        unless(n_cp
                                            _errorLine("invalid unicode escape" n_line n_esc)
                                        )
                                        n_d = n_d * 16 + n_cp
                                    )
                                    l_p = tconc(l_p _utf8Str(n_d))
                                    n_pos = n_pos + 4
                                )
                                (85
                                    n_d = 0
                                    for(n_k 1 8
                                        n_cp = _hexVal(_code(t_s n_pos + n_k))
                                        unless(n_cp
                                            _errorLine("invalid unicode escape" n_line n_esc)
                                        )
                                        n_d = n_d * 16 + n_cp
                                    )
                                    l_p = tconc(l_p _utf8Str(n_d))
                                    n_pos = n_pos + 8
                                )
                                (t
                                    _errorLine("invalid escape" n_line n_esc)
                                )
                            )
                            n_pos = n_pos + 1
                            n_seg = n_pos
                        )
                        (t
                            n_pos = n_pos + 1
                        )
                    )
                )
            )
        )
        list(_build(l_p) n_pos)
    )
)

procedure(_parseIntText(t_s "t")  ; -> any
    ; 解析 YAML 整数文本；超出 fixnum 范围回 flonum。
    ;
    ; **参数**
    ;   t_s  (str) - 去下划线后的整数文本
    ;
    ; **返回**
    ;   (int|float) - 解析结果；非法时 nil
    let((t_clean t_digits n_base n_i n_len n_sign n_v n_d n_c n_digit g_bad)
        t_clean = pcreReplace(pcreCompile("_") t_s "" 0)
        n_sign = 1
        n_i = 1
        n_len = length(t_clean)
        when(n_i <= n_len && (_code(t_clean n_i) == 43 || _code(t_clean n_i) == 45)
            when(_code(t_clean n_i) == 45
                n_sign = -1
            )
            n_i = n_i + 1
        )
        n_base = 10
        when(n_i + 1 <= n_len && _code(t_clean n_i) == 48
            case(_code(t_clean n_i + 1)
                (120 n_base = 16 n_i = n_i + 2)
                (111 n_base = 8 n_i = n_i + 2)
                (98 n_base = 2 n_i = n_i + 2)
            )
        )
        n_v = 0
        g_bad = nil
        while(n_i <= n_len && !g_bad
            n_c = _code(t_clean n_i)
            n_digit = cond(
                (n_c >= 48 && n_c <= 57 n_c - 48)
                (n_c >= 97 && n_c <= 102 n_c - 87)
                (n_c >= 65 && n_c <= 70 n_c - 55)
            )
            if(n_digit == nil || n_digit >= n_base
                g_bad = t
                n_v = n_v * n_base + n_digit
            )
            n_i = n_i + 1
        )
        unless(g_bad
            when(n_sign < 0 n_v = -n_v)
            n_v
        )
    )
)

procedure(_resolvePlain(t_s "t")  ; -> any
    ; 按 YAML 1.2 core 规则解析未加引号的标量。
    ;
    ; **参数**
    ;   t_s  (str) - 去首尾空白后的标量文本
    ;
    ; **返回**
    ;   (any) - YamlNull/布尔哨兵/数字/字符串
    prog((t_low t_clean n_v)
        when(t_s == "" || t_s == "~" || pcreMatchp("(?i)^null\\z" t_s)
            return(YamlNull)
        )
        when(pcreMatchp("(?i)^true\\z" t_s)
            return(YamlTrue)
        )
        when(pcreMatchp("(?i)^false\\z" t_s)
            return(YamlFalse)
        )
        when(pcreMatchp("(?i)^[+-]?\\.inf\\z" t_s)
            return(if(_code(t_s 1) == 45 -atof("1e999") atof("1e999")))
        )
        when(pcreMatchp("(?i)^\\.nan\\z" t_s)
            return(atof("nan"))
        )
        t_clean = pcreReplace(pcreCompile("_") t_s "" 0)
        when(pcreMatchp("^[+-]?(0[xX][0-9a-fA-F]+|0[oO][0-7]+|0[bB][01]+|[0-9]+)\\z" t_clean)
            n_v = _parseIntText(t_clean)
            when(n_v != nil
                return(n_v)
            )
        )
        when(pcreMatchp("^[+-]?([0-9]+\\.[0-9]*|\\.[0-9]+|[0-9]+[eE][+-]?[0-9]+|[0-9]+\\.[0-9]*[eE][+-]?[0-9]+)\\z" t_clean)
            return(atof(t_clean))
        )
        return(t_s)
    )
)

procedure(_parseScalarText(t_text "t")  ; -> any
    ; 解析已去注释的单行标量文本。
    ;
    ; **参数**
    ;   t_text  (str) - 行内标量文本
    ;
    ; **返回**
    ;   (any) - 标量值；引号未闭合或非法转义报错
    prog((n_len n_i l_q)
        t_text = _rtrim(t_text)
        n_len = length(t_text)
        n_i = 1
        while(n_i <= n_len && _code(t_text n_i) == 32
            n_i = n_i + 1
        )
        when(n_i > n_len
            return(YamlNull)
        )
        if(_code(t_text n_i) == 34 || _code(t_text n_i) == 39
            progn(
                l_q = _parseQuoted(t_text n_i 1)
                when(_rtrim(_tail(t_text cadr(l_q))) != ""
                    _errorLine("unexpected characters after quoted scalar" 1 cadr(l_q))
                )
                return(car(l_q))
            )
            return(_resolvePlain(_rtrim(substring(t_text n_i n_len - n_i + 1))))
        )
    )
)

procedure(_scalarText(g_val "g")  ; -> str
    ; 将标量转为标签强制转换用的文本形式。
    ;
    ; **参数**
    ;   g_val  (any) - 标量
    ;
    ; **返回**
    ;   (str) - 文本；无法转换时报错
    cond(
        (stringp(g_val) g_val)
        (fixp(g_val) sprintf(nil "%d" g_val))
        (floatp(g_val) sprintf(nil "%.17g" g_val))
        (g_val == t "true")
        (g_val == YamlTrue "true")
        (g_val == YamlFalse "false")
        (g_val == YamlNull "null")
        (t
            error("ycYaml::decode: cannot convert value to string")
        )
    )
)

procedure(_tagValue(g_val t_tag "gt")  ; -> any
    ; 应用 YAML 核心标签（!!str/!!int/!!float/!!bool/!!null/!!seq/!!map）。
    ;
    ; **参数**
    ;   g_val  (any) - 原始值
    ;   t_tag  (str) - 标签文本（含 !! 或完整 tag URI）
    ;
    ; **返回**
    ;   (any) - 转换后的值；未知标签或类型不符报错
    let((t_name t_s)
        t_name = t_tag
        when(pcreMatchp("^tag:yaml\\.org,2002:" t_tag)
            t_name = strcat("!!" pcreReplace(pcreCompile("^tag:yaml\\.org,2002:") t_tag "" 0))
        )
        case(t_name
            ("!!str" _scalarText(g_val))
            ("!!int"
                if(fixp(g_val)
                    g_val
                    progn(
                        t_s = _scalarText(g_val)
                        unless(pcreMatchp("^[+-]?(0[xX][0-9a-fA-F_]+|0[oO][0-7_]+|0[bB][01_]+|[0-9_]+)\\z" t_s)
                            error("ycYaml::decode: !!int value is not an integer")
                        )
                        _parseIntText(t_s)
                    )
                )
            )
            ("!!float"
                if(floatp(g_val)
                    g_val
                    progn(
                        t_s = _scalarText(g_val)
                        unless(pcreMatchp("^[+-]?([0-9_]+(\\.[0-9_]*)?|\\.[0-9_]+)([eE][+-]?[0-9]+)?\\z" t_s)
                            error("ycYaml::decode: !!float value is not a number")
                        )
                        atof(pcreReplace(pcreCompile("_") t_s "" 0))
                    )
                )
            )
            ("!!bool"
                if(g_val == YamlTrue || g_val == YamlFalse
                    g_val
                    case(pcreReplace(pcreCompile("(?i)^\\s+|\\s+\\z") _scalarText(g_val) "" 0)
                        (("yes" "on" "true") YamlTrue)
                        (("no" "off" "false") YamlFalse)
                        (t error("ycYaml::decode: !!bool value is not a boolean"))
                    )
                )
            )
            ("!!null" YamlNull)
            ("!!seq"
                if(listp(g_val) || g_val == nil
                    g_val
                    error("ycYaml::decode: !!seq value is not a sequence")
                )
            )
            ("!!map"
                if(tablep(g_val)
                    g_val
                    error("ycYaml::decode: !!map value is not a mapping")
                )
            )
            (t
                error("ycYaml::decode: unsupported tag %A" t_tag)
            )
        )
    )
)

procedure(_parseBlockScalar(l_lines n_pos n_parentIndent t_header n_line n_col "lxntnn")  ; -> list
    ; 解析 `|`/`>` 块标量及其后续缩进行。
    ;
    ; **参数**
    ;   l_lines       (list[str]) - 行列表
    ;   n_pos         (int) - 标题行后一行
    ;   n_parentIndent(int) - 父缩进
    ;   t_header      (str) - 以 | 或 > 开头的标题
    ;   n_line        (int) - 标题行号
    ;   n_col         (int) - 标题列号
    ;
    ; **返回**
    ;   (list) - (字符串 下一行号)
    prog((n_len n_i n_c n_style n_chomp n_hint n_indent n_last l_raw t_line n_ind n_content n_count n_tail t_body l_p g_stop g_prevBlank)
        n_len = length(t_header)
        n_style = _code(t_header 1)
        n_chomp = 0
        n_hint = 0
        n_i = 2
        while(n_i <= n_len
            n_c = _code(t_header n_i)
            cond(
                (n_c == 43 n_chomp = 1)
                (n_c == 45 n_chomp = -1)
                (n_c >= 49 && n_c <= 57 n_hint = n_c - 48)
                (n_c == 32 || n_c == 9 n_i = n_len + 1)
                (t _errorLine("invalid block scalar header" n_line n_col))
            )
            n_i = n_i + 1
        )
        n_last = n_pos
        l_raw = nil
        n_content = nil
        g_stop = nil
        while(!g_stop && n_last <= length(l_lines)
            t_line = _nth1(n_last l_lines)
            n_ind = _lineIndent(t_line)
            when(_rtrim(t_line) == ""
                l_raw = tconc(l_raw "")
                n_last = n_last + 1
            )
            unless(g_stop || _rtrim(t_line) == ""
                when(n_content == nil
                    n_content = if(n_hint > 0 n_parentIndent + n_hint n_ind)
                )
                cond(
                    (n_ind < n_content
                        g_stop = t
                    )
                    (t
                        l_raw = tconc(l_raw substring(t_line n_content + 1 length(t_line) - n_content))
                        n_last = n_last + 1
                    )
                )
            )
        )
        l_raw = car(l_raw)
        n_count = length(l_raw)
        while(n_count > 0 && _nth1(n_count l_raw) == ""
            n_count = n_count - 1
        )
        cond(
            (n_style == 62
                t_body = ""
                g_prevBlank = t
                for(n_i 1 length(l_raw)
                    t_line = _nth1(n_i l_raw)
                    cond(
                        (n_i == 1
                            t_body = t_line
                            g_prevBlank = t_line == ""
                        )
                        (t_line == ""
                            t_body = strcat(t_body intToChar(10))
                            g_prevBlank = t
                        )
                        (g_prevBlank
                            t_body = strcat(t_body t_line)
                            g_prevBlank = nil
                        )
                        (t
                            t_body = strcat(t_body " " t_line)
                        )
                    )
                )
                t_body = strcat(t_body intToChar(10))
            )
            (t
                l_p = nil
                foreach(t_line l_raw
                    l_p = tconc(l_p t_line)
                )
                t_body = strcat(_joinBuild(l_p "\n") "\n")
            )
        )
        cond(
            (n_chomp == -1
                while(length(t_body) > 0 && _code(t_body length(t_body)) == 10
                    t_body = substring(t_body 1 length(t_body) - 1)
                )
            )
            (n_chomp == 0
                while(length(t_body) > 0 && _code(t_body length(t_body)) == 10
                    t_body = substring(t_body 1 length(t_body) - 1)
                )
                when(length(t_body) > 0
                    t_body = strcat(t_body intToChar(10))
                )
            )
        )
        return(list(t_body n_last))
    )
)
; END
