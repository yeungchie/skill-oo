ycNamespace:::Require("ycCodec")

useNamespace("ycYaml")

; ---------- 流式解析 ----------

procedure(_FlowSkip(t_s n_i "tx")  ; -> int
    ; 跳过流式文本中的空白与注释。
    ;
    ; **参数**
    ;   t_s  (str) - 文本
    ;   n_i  (int) - 起始位置
    ;
    ; **返回**
    ;   (int) - 下一有效字符位置
    let((n_len n_c g_stop)
        n_len = length(t_s)
        g_stop = nil
        while(!g_stop && n_i <= n_len
            n_c = _Code(t_s n_i)
            cond(
                (n_c == 32 || n_c == 9 n_i = n_i + 1)
                (n_c == 35 n_i = n_len + 1)
                (t g_stop = t)
            )
        )
        n_i
    )
)

procedure(_FlowTokenEnd(t_s n_i "tx")  ; -> int
    ; 读取到空白或流式分隔符为止，返回终止位置。
    ;
    ; **参数**
    ;   t_s  (str) - 文本
    ;   n_i  (int) - 起始位置
    ;
    ; **返回**
    ;   (int) - 终止位置（不含）
    let((n_len n_c g_stop)
        n_len = length(t_s)
        g_stop = nil
        while(!g_stop && n_i <= n_len
            n_c = _Code(t_s n_i)
            if(n_c == 32 || n_c == 9 || n_c == 44 || n_c == 93 || n_c == 125
                g_stop = t
                n_i = n_i + 1
            )
        )
        if(g_stop n_i - 1 n_i)
    )
)

procedure(_AliasValue(t_name "t")  ; -> any
    ; 取回别名目标；未定义与循环引用报错。
    ;
    ; **参数**
    ;   t_name  (str) - 锚点名
    ;
    ; **返回**
    ;   (any) - 锚点已解析的值
    when(_ActiveAnchors[t_name]
        error("ycYaml::Decode: recursive alias %A" t_name)
    )
    unless(_Anchors[t_name]
        error("ycYaml::Decode: unknown alias %A" t_name)
    )
    _Anchors[t_name]
)

procedure(_FlowPrefix(t_s n_i l_state "txl")  ; -> list
    ; 解析流式值前的标签与锚点前缀。
    ;
    ; **参数**
    ;   t_s      (str) - 文本
    ;   n_i      (int) - 起始位置
    ;   l_state  (list) - (标签 锚点) 状态；每次返回新列表
    ;
    ; **返回**
    ;   (list) - (标签 锚点 下一位置)
    let((n_len n_c n_end t_tag t_anchor g_stop)
        n_len = length(t_s)
        t_tag = car(l_state)
        t_anchor = cadr(l_state)
        n_i = _FlowSkip(t_s n_i)
        g_stop = nil
        while(!g_stop && n_i <= n_len
            n_c = _Code(t_s n_i)
            cond(
                (n_c == 38
                    n_end = _FlowTokenEnd(t_s n_i + 1)
                    t_anchor = substring(t_s n_i + 1 n_end - n_i - 1)
                    when(t_anchor == "" error("ycYaml::Decode: empty anchor name"))
                    n_i = _FlowSkip(t_s n_end)
                )
                (n_c == 33
                    n_end = _FlowTokenEnd(t_s n_i)
                    t_tag = substring(t_s n_i n_end - n_i)
                    n_i = _FlowSkip(t_s n_end)
                )
                (t
                    g_stop = t
                )
            )
        )
        list(t_tag t_anchor n_i)
    )
)

procedure(_FlowValue(t_s n_i n_max "txn")  ; -> list
    ; 解析一个流式值（标量、序列、映射、标签或别名）。
    ;
    ; **参数**
    ;   t_s    (str) - 文本
    ;   n_i    (int) - 起始位置
    ;   n_max  (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (list) - (值 下一位置)
    prog((n_len n_c n_end l_p l_v t_tag t_anchor g_val l_q g_stop)
        when(n_max < 0
            error("ycYaml::Decode: nesting too deep")
        )
        n_len = length(t_s)
        n_i = _FlowSkip(t_s n_i)
        when(n_i > n_len
            error("ycYaml::Decode: unexpected end of flow value")
        )
        n_c = _Code(t_s n_i)
        when(n_c == 42
            n_end = _FlowTokenEnd(t_s n_i + 1)
            l_v = _AliasValue(substring(t_s n_i + 1 n_end - n_i - 1))
            return(list(l_v n_end))
        )
        l_p = _FlowPrefix(t_s n_i list(nil nil))
        t_tag = car(l_p)
        t_anchor = cadr(l_p)
        n_i = caddr(l_p)
        when(n_i > n_len
            error("ycYaml::Decode: missing value after tag or anchor")
        )
        n_c = _Code(t_s n_i)
        when(t_anchor
            when(_ActiveAnchors[t_anchor]
                error("ycYaml::Decode: recursive anchor %A" t_anchor)
            )
            _ActiveAnchors[t_anchor] = t
        )
        cond(
            (n_c == 91
                n_i = n_i + 1
                l_v = _FlowSeq(t_s n_i n_max - 1)
            )
            (n_c == 123
                n_i = n_i + 1
                l_v = _FlowMap(t_s n_i n_max - 1)
            )
            (n_c == 34 || n_c == 39
                l_q = _ParseQuoted(t_s n_i 1)
                l_v = list(car(l_q) cadr(l_q))
            )
            (t
                n_end = n_i
                g_stop = nil
                while(!g_stop && n_end <= n_len
                    n_c = _Code(t_s n_end)
                    if(n_c == 44 || n_c == 93 || n_c == 125
                        || (n_c == 35 && (n_end == n_i || _Code(t_s n_end - 1) == 32 || _Code(t_s n_end - 1) == 9))
                        g_stop = t
                    )
                    unless(g_stop
                        n_end = n_end + 1
                    )
                )
                l_v = list(_ParseScalarText(_Rtrim(substring(t_s n_i n_end - n_i))) n_end)
            )
        )
        g_val = car(l_v)
        when(t_tag
            g_val = _TagValue(g_val t_tag)
            l_v = list(g_val cadr(l_v))
        )
        when(t_anchor
            _Anchors[t_anchor] = g_val
            _ActiveAnchors[t_anchor] = nil
        )
        return(l_v)
    )
)

procedure(_FlowSeq(t_s n_i n_max "txn")  ; -> list
    ; 解析流式序列的剩余部分（`[` 已消费）。
    ;
    ; **参数**
    ;   t_s    (str) - 文本
    ;   n_i    (int) - `[` 后位置
    ;   n_max  (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (list) - (列表或 nil 下一位置)
    prog((n_len l_res l_v n_c g_done)
        when(n_max < 0
            error("ycYaml::Decode: nesting too deep")
        )
        n_len = length(t_s)
        g_done = nil
        n_i = _FlowSkip(t_s n_i)
        when(n_i <= n_len && _Code(t_s n_i) == 93
            return(list(nil n_i + 1))
        )
        while(!g_done
            l_v = _FlowValue(t_s n_i n_max)
            l_res = tconc(l_res car(l_v))
            n_i = _FlowSkip(t_s cadr(l_v))
            when(n_i > n_len
                error("ycYaml::Decode: unterminated flow sequence")
            )
            n_c = _Code(t_s n_i)
            case(n_c
                (44
                    n_i = _FlowSkip(t_s n_i + 1)
                    when(n_i <= n_len && _Code(t_s n_i) == 93
                        g_done = t
                        n_i = n_i + 1
                    )
                )
                (93
                    g_done = t
                    n_i = n_i + 1
                )
                (t
                    error("ycYaml::Decode: expected ',' or ']' in flow sequence")
                )
            )
        )
        return(list(car(l_res) n_i))
    )
)

procedure(_ParseKeyText(t_text "t")  ; -> any
    ; 解析映射键：引号键为字符串，整数键为 fixnum，其余为字符串。
    ;
    ; **参数**
    ;   t_text  (str) - 键文本
    ;
    ; **返回**
    ;   (any) - 键值
    prog((n_i n_len l_q)
        t_text = _Rtrim(t_text)
        n_i = 1
        n_len = length(t_text)
        while(n_i <= n_len && _Code(t_text n_i) == 32
            n_i = n_i + 1
        )
        when(n_i > n_len
            return("")
        )
        when(_Code(t_text n_i) == 34 || _Code(t_text n_i) == 39
            l_q = _ParseQuoted(t_text n_i 1)
            return(car(l_q))
        )
        t_text = substring(t_text n_i n_len - n_i + 1)
        when(pcreMatchp("^[+-]?[0-9_]+\\z" t_text)
            let((g_v)
                g_v = _ParseIntText(pcreReplace(pcreCompile("_") t_text "" 0))
                when(fixp(g_v)
                    return(g_v)
                )
            )
        )
        return(t_text)
    )
)

procedure(_FlowKey(t_s n_i "tx")  ; -> list
    ; 读取流式映射键，直到冒号或分隔符。
    ;
    ; **参数**
    ;   t_s  (str) - 文本
    ;   n_i  (int) - 起始位置
    ;
    ; **返回**
    ;   (list) - (键值 冒号位置)
    prog((n_len n_c n_start n_k g_sq g_dq g_esc)
        n_len = length(t_s)
        n_i = _FlowSkip(t_s n_i)
        n_start = n_i
        g_sq = nil
        g_dq = nil
        g_esc = nil
        n_k = n_i
        while(n_k <= n_len
            n_c = _Code(t_s n_k)
            cond(
                (g_dq
                    when(g_esc g_esc = nil)
                    when(!g_esc && n_c == 92 g_esc = t)
                    when(!g_esc && n_c == 34 g_dq = nil)
                )
                (g_sq
                    when(n_c == 39 g_sq = nil)
                )
                (n_c == 34 g_dq = t)
                (n_c == 39 g_sq = t)
                (n_c == 58
                    return(list(_ParseKeyText(substring(t_s n_start n_k - n_start)) n_k))
                )
                (n_c == 44 || n_c == 93 || n_c == 125
                    error("ycYaml::Decode: expected ':' in flow mapping")
                )
            )
            n_k = n_k + 1
        )
        error("ycYaml::Decode: expected ':' in flow mapping")
    )
)

procedure(_FlowMap(t_s n_i n_max "txn")  ; -> list
    ; 解析流式映射的剩余部分（`{` 已消费）。
    ;
    ; **参数**
    ;   t_s    (str) - 文本
    ;   n_i    (int) - `{` 后位置
    ;   n_max  (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (list) - (table 下一位置)
    prog((n_len t_map l_k l_v n_c g_done g_key)
        when(n_max < 0
            error("ycYaml::Decode: nesting too deep")
        )
        n_len = length(t_s)
        t_map = makeTable("ycYaml" ycCodec:::Missing)
        g_done = nil
        n_i = _FlowSkip(t_s n_i)
        when(n_i <= n_len && _Code(t_s n_i) == 125
            return(list(t_map n_i + 1))
        )
        while(!g_done
            l_k = _FlowKey(t_s n_i)
            g_key = car(l_k)
            n_i = _FlowSkip(t_s cadr(l_k) + 1)
            cond(
                (n_i > n_len || _Code(t_s n_i) == 44 || _Code(t_s n_i) == 125
                    l_v = list(ycCodec:::Null n_i)
                )
                (t
                    l_v = _FlowValue(t_s n_i n_max)
                )
            )
            if(g_key == "<<" && (tablep(car(l_v)) || listp(car(l_v)))
                _MergeInto(t_map car(l_v))
            )
            unless(g_key == "<<" && (tablep(car(l_v)) || listp(car(l_v)))
                t_map[g_key] = car(l_v)
            )
            n_i = _FlowSkip(t_s cadr(l_v))
            when(n_i > n_len
                error("ycYaml::Decode: unterminated flow mapping")
            )
            n_c = _Code(t_s n_i)
            case(n_c
                (44
                    n_i = _FlowSkip(t_s n_i + 1)
                    when(n_i <= n_len && _Code(t_s n_i) == 125
                        g_done = t
                        n_i = n_i + 1
                    )
                )
                (125
                    g_done = t
                    n_i = n_i + 1
                )
                (t
                    error("ycYaml::Decode: expected ',' or '}' in flow mapping")
                )
            )
        )
        return(list(t_map n_i))
    )
)

unuseNamespace("ycYaml")

; END
