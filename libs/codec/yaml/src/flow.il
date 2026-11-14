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
    let((len c stop)
        len = length(t_s)
        stop = nil
        while(!stop && n_i <= len
            c = _Code(t_s n_i)
            cond(
                (c == 32 || c == 9 n_i = n_i + 1)
                (c == 35 n_i = len + 1)
                (t stop = t)
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
    let((len c stop)
        len = length(t_s)
        stop = nil
        while(!stop && n_i <= len
            c = _Code(t_s n_i)
            if(c == 32 || c == 9 || c == 44 || c == 93 || c == 125
            then
                stop = t
            else
                n_i++
            )
        )
        n_i
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
    unless(_DefinedAnchors[t_name]
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
    let((len c end tag anchor stop)
        len = length(t_s)
        tag = car(l_state)
        anchor = cadr(l_state)
        n_i = _FlowSkip(t_s n_i)
        stop = nil
        while(!stop && n_i <= len
            c = _Code(t_s n_i)
            cond(
                (c == 38
                    end = _FlowTokenEnd(t_s n_i + 1)
                    anchor = substring(t_s n_i + 1 end - n_i - 1)
                    when(anchor == "" error("ycYaml::Decode: empty anchor name"))
                    n_i = _FlowSkip(t_s end)
                )
                (c == 33
                    end = _FlowTokenEnd(t_s n_i)
                    tag = substring(t_s n_i end - n_i)
                    n_i = _FlowSkip(t_s end)
                )
                (t
                    stop = t
                )
            )
        )
        list(tag anchor n_i)
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
    prog((len c end p v tag anchor val q stop)
        when(n_max < 0
            error("ycYaml::Decode: nesting too deep")
        )
        len = length(t_s)
        n_i = _FlowSkip(t_s n_i)
        when(n_i > len
            error("ycYaml::Decode: unexpected end of flow value")
        )
        c = _Code(t_s n_i)
        when(c == 42
            end = _FlowTokenEnd(t_s n_i + 1)
            v = _AliasValue(substring(t_s n_i + 1 end - n_i - 1))
            return(list(v end))
        )
        p = _FlowPrefix(t_s n_i list(nil nil))
        tag = car(p)
        anchor = cadr(p)
        n_i = caddr(p)
        when(n_i > len
            error("ycYaml::Decode: missing value after tag or anchor")
        )
        c = _Code(t_s n_i)
        when(anchor
            when(_ActiveAnchors[anchor]
                error("ycYaml::Decode: recursive anchor %A" anchor)
            )
            _ActiveAnchors[anchor] = t
        )
        cond(
            (c == 91
                n_i++
                v = _FlowSeq(t_s n_i n_max - 1)
            )
            (c == 123
                n_i++
                v = _FlowMap(t_s n_i n_max - 1)
            )
            (c == 34 || c == 39
                q = _ParseQuoted(t_s n_i 1 1)
                v = list(car(q) cadr(q))
            )
            (t
                end = n_i
                stop = nil
                while(!stop && end <= len
                    c = _Code(t_s end)
                    if(c == 44 || c == 93 || c == 125
                        || (c == 35 && (end == n_i || _Code(t_s end - 1) == 32 || _Code(t_s end - 1) == 9))
                        stop = t
                    )
                    unless(stop
                        end++
                    )
                )
                v = list(_ParseScalarText(_Rtrim(substring(t_s n_i end - n_i)) 1 n_i) end)
            )
        )
        val = car(v)
        when(tag
            val = _TagValue(val tag)
            v = list(val cadr(v))
        )
        when(anchor
            _Anchors[anchor] = val
            _DefinedAnchors[anchor] = t
            _ActiveAnchors[anchor] = nil
        )
        return(v)
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
    prog((len res v c done)
        when(n_max < 0
            error("ycYaml::Decode: nesting too deep")
        )
        len = length(t_s)
        done = nil
        n_i = _FlowSkip(t_s n_i)
        when(n_i <= len && _Code(t_s n_i) == 93
            return(list(nil n_i + 1))
        )
        while(!done
            v = _FlowValue(t_s n_i n_max)
            res = tconc(res car(v))
            n_i = _FlowSkip(t_s cadr(v))
            when(n_i > len
                error("ycYaml::Decode: unterminated flow sequence")
            )
            c = _Code(t_s n_i)
            case(c
                (44
                    n_i = _FlowSkip(t_s n_i + 1)
                    when(n_i <= len && _Code(t_s n_i) == 93
                        done = t
                        n_i++
                    )
                )
                (93
                    done = t
                    n_i++
                )
                (t
                    error("ycYaml::Decode: expected ',' or ']' in flow sequence")
                )
            )
        )
        return(list(car(res) n_i))
    )
)

procedure(_ParseKeyText(t_text n_line n_base "txn")  ; -> any
    ; 解析映射键：引号键为字符串，整数键为 fixnum，其余为字符串。
    ;
    ; **参数**
    ;   t_text  (str) - 键文本
    ;   n_line  (int) - 行号（错误消息）
    ;   n_base  (int) - 基准列号（`t_text` 首字符在行内的列号）
    ;
    ; **返回**
    ;   (any) - 键值
    prog((i len q)
        t_text = _Rtrim(t_text)
        i = 1
        len = length(t_text)
        while(i <= len && _Code(t_text i) == 32
            i++
        )
        when(i > len
            return("")
        )
        when(_Code(t_text i) == 34 || _Code(t_text i) == 39
            q = _ParseQuoted(t_text i n_line n_base + i - 1)
            return(car(q))
        )
        t_text = substring(t_text i len - i + 1)
        when(pcreMatchp("^[+-]?[0-9_]+\\z" t_text)
            let((v)
                v = _ParseIntText(pcreReplace(pcreCompile("_") t_text "" 0))
                when(fixp(v)
                    return(v)
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
    prog((len c start k sq dq esc)
        len = length(t_s)
        n_i = _FlowSkip(t_s n_i)
        start = n_i
        sq = nil
        dq = nil
        esc = nil
        k = n_i
        while(k <= len
            c = _Code(t_s k)
            cond(
                (dq
                    when(esc esc = nil)
                    when(!esc && c == 92 esc = t)
                    when(!esc && c == 34 dq = nil)
                )
                (sq
                    when(c == 39 sq = nil)
                )
                (c == 34 && _QuoteStart(t_s k t) dq = t)
                (c == 39 && _QuoteStart(t_s k t) sq = t)
                (c == 58
                    return(list(_ParseKeyText(substring(t_s start k - start) 1 start) k))
                )
                (c == 44 || c == 93 || c == 125
                    error("ycYaml::Decode: expected ':' in flow mapping")
                )
            )
            k++
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
    prog((len map k v c done key)
        when(n_max < 0
            error("ycYaml::Decode: nesting too deep")
        )
        len = length(t_s)
        map = makeTable("ycYaml" ycCodec:::Missing)
        done = nil
        n_i = _FlowSkip(t_s n_i)
        when(n_i <= len && _Code(t_s n_i) == 125
            return(list(map n_i + 1))
        )
        while(!done
            k = _FlowKey(t_s n_i)
            key = car(k)
            n_i = _FlowSkip(t_s cadr(k) + 1)
            cond(
                (n_i > len || _Code(t_s n_i) == 44 || _Code(t_s n_i) == 125
                    v = list(ycCodec:::Null n_i)
                )
                (t
                    v = _FlowValue(t_s n_i n_max)
                )
            )
            if(key == "<<" && (tablep(car(v)) || listp(car(v)))
                _MergeInto(map car(v))
            )
            unless(key == "<<" && (tablep(car(v)) || listp(car(v)))
                map[key] = car(v)
            )
            n_i = _FlowSkip(t_s cadr(v))
            when(n_i > len
                error("ycYaml::Decode: unterminated flow mapping")
            )
            c = _Code(t_s n_i)
            case(c
                (44
                    n_i = _FlowSkip(t_s n_i + 1)
                    when(n_i <= len && _Code(t_s n_i) == 125
                        done = t
                        n_i++
                    )
                )
                (125
                    done = t
                    n_i++
                )
                (t
                    error("ycYaml::Decode: expected ',' or '}' in flow mapping")
                )
            )
        )
        return(list(map n_i))
    )
)

unuseNamespace("ycYaml")

; END
