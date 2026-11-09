ycNamespace:::Require("ycCodec")

useNamespace("ycYaml")

; ---------- 标量解析 ----------

procedure(_HexVal(n_c "x")  ; -> int | nil
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

procedure(_ParseQuoted(t_s n_i n_line "txn")  ; -> list
    ; 解析单引号或双引号标量，返回 (值 下一位置)。
    ;
    ; **参数**
    ;   t_s    (str) - 当前行文本
    ;   n_i    (int) - 引号位置
    ;   n_line (int) - 行号（错误消息）
    ;
    ; **返回**
    ;   (list) - (字符串值 闭引号后一位置)
    let((len q pos seg c esc d k cp p done)
        len = length(t_s)
        q = _Code(t_s n_i)
        pos = n_i + 1
        seg = pos
        done = nil
        while(!done
            when(pos > len
                _ErrorLine("unterminated quoted scalar" n_line n_i)
            )
            c = _Code(t_s pos)
            cond(
                (q == 39
                    cond(
                        (c == 39
                            cond(
                                (_Code(t_s pos + 1) == 39
                                    p = tconc(p substring(t_s seg pos - seg))
                                    p = tconc(p "'")
                                    pos = pos + 2
                                    seg = pos
                                )
                                (t
                                    p = tconc(p substring(t_s seg pos - seg))
                                    done = t
                                    pos++
                                )
                            )
                        )
                        (t
                            pos++
                        )
                    )
                )
                (t
                    cond(
                        (c == 34
                            p = tconc(p substring(t_s seg pos - seg))
                            done = t
                            pos++
                        )
                        (c == 92
                            p = tconc(p substring(t_s seg pos - seg))
                            esc = pos
                            pos++
                            when(pos > len
                                _ErrorLine("unterminated escape" n_line esc)
                            )
                            cp = _Code(t_s pos)
                            case(cp
                                (48 p = tconc(p _Utf8Str(0)))
                                (97 p = tconc(p _Utf8Str(7)))
                                (98 p = tconc(p _Utf8Str(8)))
                                (116 p = tconc(p _Utf8Str(9)))
                                (110 p = tconc(p _Utf8Str(10)))
                                (118 p = tconc(p _Utf8Str(11)))
                                (102 p = tconc(p _Utf8Str(12)))
                                (114 p = tconc(p _Utf8Str(13)))
                                (101 p = tconc(p _Utf8Str(27)))
                                (32 p = tconc(p " "))
                                (34 p = tconc(p "\""))
                                (47 p = tconc(p "/"))
                                (92 p = tconc(p "\\"))
                                (78 p = tconc(p _Utf8Str(133)))
                                (95 p = tconc(p _Utf8Str(160)))
                                (76 p = tconc(p _Utf8Str(8232)))
                                (80 p = tconc(p _Utf8Str(8233)))
                                (120
                                    d = 0
                                    for(k2 1 2
                                        cp = _HexVal(_Code(t_s pos + k2))
                                        unless(cp
                                            _ErrorLine("invalid hex escape" n_line esc)
                                        )
                                        d = d * 16 + cp
                                    )
                                    p = tconc(p _Utf8Str(d))
                                    pos = pos + 2
                                )
                                (117
                                    d = 0
                                    for(k2 1 4
                                        cp = _HexVal(_Code(t_s pos + k2))
                                        unless(cp
                                            _ErrorLine("invalid unicode escape" n_line esc)
                                        )
                                        d = d * 16 + cp
                                    )
                                    p = tconc(p _Utf8Str(d))
                                    pos = pos + 4
                                )
                                (85
                                    d = 0
                                    for(k2 1 8
                                        cp = _HexVal(_Code(t_s pos + k2))
                                        unless(cp
                                            _ErrorLine("invalid unicode escape" n_line esc)
                                        )
                                        d = d * 16 + cp
                                    )
                                    p = tconc(p _Utf8Str(d))
                                    pos = pos + 8
                                )
                                (t
                                    _ErrorLine("invalid escape" n_line esc)
                                )
                            )
                            pos++
                            seg = pos
                        )
                        (t
                            pos++
                        )
                    )
                )
            )
        )
        list(_Build(p) pos)
    )
)

procedure(_ParseIntText(t_s "t")  ; -> any
    ; 解析 YAML 整数文本；超出 fixnum 范围回 flonum。
    ;
    ; **参数**
    ;   t_s  (str) - 去下划线后的整数文本
    ;
    ; **返回**
    ;   (int|float) - 解析结果；非法时 nil
    let((clean digits base i len sign v d c digit bad f)
        clean = pcreReplace(pcreCompile("_") t_s "" 0)
        sign = 1
        i = 1
        len = length(clean)
        when(i <= len && (_Code(clean i) == 43 || _Code(clean i) == 45)
            when(_Code(clean i) == 45
                sign = -1
            )
            i++
        )
        base = 10
        when(i + 1 <= len && _Code(clean i) == 48
            case(_Code(clean i + 1)
                (120 base = 16 i = i + 2)
                (111 base = 8 i = i + 2)
                (98 base = 2 i = i + 2)
            )
        )
        v = 0
        f = 0.0
        bad = nil
        while(i <= len && !bad
            c = _Code(clean i)
            digit = cond(
                (c >= 48 && c <= 57 c - 48)
                (c >= 97 && c <= 102 c - 87)
                (c >= 65 && c <= 70 c - 55)
            )
            if(digit == nil || digit >= base
            then
                bad = t
            else
                v = v * base + digit
                f = f * base + digit
            )
            i++
        )
        unless(bad
            when(sign < 0 v = -v)
            if(f > 2147483647.0
            then
                if(sign < 0 && f == 2147483648.0
                    -2147483647 - 1
                    sign * f
                )
            else
                v
            )
        )
    )
)

procedure(_ResolvePlain(t_s "t")  ; -> any
    ; 按 YAML 1.2 core 规则解析未加引号的标量。
    ;
    ; **参数**
    ;   t_s  (str) - 去首尾空白后的标量文本
    ;
    ; **返回**
    ;   (any) - ycCodec::Null/布尔哨兵/数字/字符串
    prog((low clean v)
        when(t_s == "" || t_s == "~" || pcreMatchp("(?i)^null\\z" t_s)
            return(ycCodec:::Null)
        )
        when(pcreMatchp("(?i)^true\\z" t_s)
            return(ycCodec:::True)
        )
        when(pcreMatchp("(?i)^false\\z" t_s)
            return(ycCodec:::False)
        )
        when(pcreMatchp("(?i)^[+-]?\\.inf\\z" t_s)
            return(if(_Code(t_s 1) == 45 -atof("1e999") atof("1e999")))
        )
        when(pcreMatchp("(?i)^\\.nan\\z" t_s)
            return(atof("nan"))
        )
        clean = pcreReplace(pcreCompile("_") t_s "" 0)
        when(pcreMatchp("^[+-]?(0[xX][0-9a-fA-F]+|0[oO][0-7]+|0[bB][01]+|[0-9]+)\\z" clean)
            v = _ParseIntText(clean)
            when(v != nil
                return(v)
            )
        )
        when(pcreMatchp("^[+-]?([0-9]+\\.[0-9]*|\\.[0-9]+|[0-9]+[eE][+-]?[0-9]+|[0-9]+\\.[0-9]*[eE][+-]?[0-9]+)\\z" clean)
            return(atof(clean))
        )
        return(t_s)
    )
)

procedure(_ParseScalarText(t_text n_line "tx")  ; -> any
    ; 解析已去注释的单行标量文本。
    ;
    ; **参数**
    ;   t_text  (str) - 行内标量文本
    ;   n_line  (int) - 行号（错误消息）
    ;
    ; **返回**
    ;   (any) - 标量值；引号未闭合或非法转义报错
    prog((len i q)
        t_text = _Rtrim(t_text)
        len = length(t_text)
        i = 1
        while(i <= len && _Code(t_text i) == 32
            i++
        )
        when(i > len
            return(ycCodec:::Null)
        )
        if(_Code(t_text i) == 34 || _Code(t_text i) == 39
        then
            q = _ParseQuoted(t_text i n_line)
            when(_Rtrim(_Tail(t_text cadr(q))) != ""
                _ErrorLine("unexpected characters after quoted scalar" n_line cadr(q))
            )
            return(car(q))
        else
            return(_ResolvePlain(_Rtrim(substring(t_text i len - i + 1))))
        )
    )
)

procedure(_ScalarText(g_val "g")  ; -> str
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
        (g_val == ycCodec:::True "true")
        (g_val == ycCodec:::False "false")
        (g_val == ycCodec:::Null "null")
        (t
            error("ycYaml::Decode: cannot convert value to string")
        )
    )
)

procedure(_TagValue(g_val t_tag "gt")  ; -> any
    ; 应用 YAML 核心标签（!!str/!!int/!!float/!!bool/!!null/!!seq/!!map）。
    ;
    ; **参数**
    ;   g_val  (any) - 原始值
    ;   t_tag  (str) - 标签文本（含 !! 或完整 tag URI）
    ;
    ; **返回**
    ;   (any) - 转换后的值；未知标签或类型不符报错
    let((name item)
        name = t_tag
        when(pcreMatchp("^tag:yaml\\.org,2002:" t_tag)
            name = strcat("!!" pcreReplace(pcreCompile("^tag:yaml\\.org,2002:") t_tag "" 0))
        )
        case(name
            ("!!str" _ScalarText(g_val))
            ("!!int"
                if(fixp(g_val)
                then
                    g_val
                else
                    item = _ScalarText(g_val)
                    unless(pcreMatchp("^[+-]?(0[xX][0-9a-fA-F_]+|0[oO][0-7_]+|0[bB][01_]+|[0-9_]+)\\z" item)
                        error("ycYaml::Decode: !!int value is not an integer")
                    )
                    _ParseIntText(item)
                )
            )
            ("!!float"
                if(floatp(g_val)
                then
                    g_val
                else
                    item = _ScalarText(g_val)
                    unless(pcreMatchp("^[+-]?([0-9_]+(\\.[0-9_]*)?|\\.[0-9_]+)([eE][+-]?[0-9]+)?\\z" item)
                        error("ycYaml::Decode: !!float value is not a number")
                    )
                    atof(pcreReplace(pcreCompile("_") item "" 0))
                )
            )
            ("!!bool"
                if(g_val == ycCodec:::True || g_val == ycCodec:::False
                    g_val
                    case(pcreReplace(pcreCompile("(?i)^\\s+|\\s+\\z") _ScalarText(g_val) "" 0)
                        (("yes" "on" "true") ycCodec:::True)
                        (("no" "off" "false") ycCodec:::False)
                        (t error("ycYaml::Decode: !!bool value is not a boolean"))
                    )
                )
            )
            ("!!null" ycCodec:::Null)
            ("!!seq"
                if(listp(g_val) || g_val == nil
                    g_val
                    error("ycYaml::Decode: !!seq value is not a sequence")
                )
            )
            ("!!map"
                if(tablep(g_val)
                    g_val
                    error("ycYaml::Decode: !!map value is not a mapping")
                )
            )
            (t
                error("ycYaml::Decode: unsupported tag %A" t_tag)
            )
        )
    )
)

procedure(_ParseBlockScalar(l_lines n_pos n_parentIndent t_header n_line n_col "lxntnn")  ; -> list
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
    prog((len i c style chomp hint indent last raw line ind content count tail body p stop prevBlank prevMore)
        len = length(t_header)
        style = _Code(t_header 1)
        chomp = 0
        hint = 0
        i = 2
        while(i <= len
            c = _Code(t_header i)
            cond(
                (c == 43 chomp = 1)
                (c == 45 chomp = -1)
                (c >= 49 && c <= 57 hint = c - 48)
                (c == 32 || c == 9
                    when(_Rtrim(substring(t_header i + 1 length(t_header) - i)) != ""
                        _ErrorLine("unexpected characters after block scalar header" n_line n_col)
                    )
                    i = len + 1
                )
                (t _ErrorLine("invalid block scalar header" n_line n_col))
            )
            i++
        )
        last = n_pos
        raw = nil
        content = nil
        stop = nil
        while(!stop && last <= length(l_lines)
            line = _Nth1(last l_lines)
            ind = 0
            while(ind < length(line) && _Code(line ind + 1) == 32
                ind++
            )
            when(_Rtrim(line) == ""
                raw = tconc(raw "")
                last++
            )
            unless(stop || _Rtrim(line) == ""
                when(content == nil
                    when(hint == 0 && ind == 0 && _Code(line 1) == 9
                        _ErrorLine("tab character in indentation" last 1)
                    )
                    content = if(hint > 0 n_parentIndent + hint ind)
                )
                cond(
                    (ind < content
                        when(_Code(line ind + 1) == 9
                            _ErrorLine("tab character in indentation" last ind + 1)
                        )
                        stop = t
                    )
                    (t
                        raw = tconc(raw substring(line content + 1 length(line) - content))
                        last++
                    )
                )
            )
        )
        raw = car(raw)
        count = length(raw)
        while(count > 0 && _Nth1(count raw) == ""
            count--
        )
        cond(
            (style == 62
                body = ""
                prevBlank = t
                for(i2 1 length(raw)
                    line = _Nth1(i2 raw)
                    let((more sep)
                        more = length(line) > 0 && (_Code(line 1) == 32 || _Code(line 1) == 9)
                        if(i2 == 1
                        then
                            body = line
                        else
                            sep = cond(
                                (line == "" && !prevMore && !prevBlank "")
                                (line == "" || prevBlank || more || prevMore "\n")
                                (t " ")
                            )
                            body = strcat(body sep line)
                        )
                        prevBlank = line == ""
                        prevMore = more
                    )
                )
                body = strcat(body intToChar(10))
            )
            (t
                p = nil
                foreach(line2 raw
                    p = tconc(p line2)
                )
                body = strcat(_JoinBuild(p "\n") "\n")
            )
        )
        cond(
            (chomp == -1
                while(length(body) > 0 && _Code(body length(body)) == 10
                    body = substring(body 1 length(body) - 1)
                )
            )
            (chomp == 0
                while(length(body) > 0 && _Code(body length(body)) == 10
                    body = substring(body 1 length(body) - 1)
                )
                when(length(body) > 0
                    body = strcat(body intToChar(10))
                )
            )
        )
        return(list(body last))
    )
)

unuseNamespace("ycYaml")

; END
