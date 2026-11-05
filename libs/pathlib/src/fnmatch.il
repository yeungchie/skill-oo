useNamespace("ycPathLib")


; ---------- 通配符匹配翻译（不导出） ----------

procedure(_FnmatchBracket(t_pattern n_open n_len "txx")  ; -> (str, int)
    ; 把 pattern 中单个 "[" 字符类段编译为 pcre 字符类（通配符字符类翻译的 "[" 分支）。
    ;
    ; **参数**
    ;   t_pattern  (str) - 完整通配符 pattern
    ;   n_open     (int) - "[" 的 1-based 位置
    ;   n_len      (int) - t_pattern 的串长
    ;
    ; **返回**
    ;   (str, int) - 二元组 (正则串, 段后 1-based 位置)：支持 "!" 取反与段内元字符转义；
    ;                无闭合 "]" 时正则按字面 "[" 转义为 \[，位置回到 n_open + 1
    let((j stop stuff neg out k ch)
        j = n_open + 1
        when(j <= n_len
            when(substring(t_pattern j 1) == "!"
                j++
            )
        )
        when(j <= n_len
            when(substring(t_pattern j 1) == "]"
                j++
            )
        )
        while(!stop
            cond(
                (j > n_len
                    stop = t
                )
                (substring(t_pattern j 1) == "]"
                    stop = t
                )
                (t j = j + 1)
            )
        )
        if(j > n_len
            list("\\[" n_open + 1)
            let((res)
                stuff = substring(t_pattern n_open + 1 j - n_open - 1)
                when(substring(stuff 1 1) == "!"
                    neg = t
                    stuff = substring(stuff 2 length(stuff) - 1)
                )
                out = ""
                k = 1
                while(k <= length(stuff)
                    ch = substring(stuff k 1)
                    out = strcat(out
                        if(index("\\&~|" ch)
                            strcat("\\" ch)
                            ch
                        )
                    )
                    k++
                )
                unless(out == ""
                    when(index("^[]" substring(out 1 1))
                        out = strcat("\\" out)
                    )
                )
                res = list(
                    lsprintf("%s%s]" if(neg "[^" "[") out)
                    j + 1
                )
                res
            )
        )
    )
)

procedure(_FnmatchToPcre(t_pattern "t")  ; -> str
    ; 把通配符 pattern 编译为正则串（"*" "?" 不跨 /）。
    ;
    ; **参数**
    ;   t_pattern  (str) - 含 "*"、"?"、"[seq]" 的通配符 pattern
    ;
    ; **返回**
    ;   (str) - 供 ^...\z 全串匹配使用的正则；其余正则元字符逐个加反斜杠转义
    let((res i len c)
        res = ""
        i = 1
        len = length(t_pattern)
        while(i <= len
            c = substring(t_pattern i 1)
            i++
            case(c
                ("*"
                    res = strcat(res "[^/]*")
                )
                ("?"
                    res = strcat(res "[^/]")
                )
                ("["
                    let((br)
                        br = _FnmatchBracket(t_pattern i - 1 len)
                        res = strcat(res car(br))
                        i = car(cdr(br))
                    )
                )
                (t
                    res = strcat(res
                        if(index("\\^$.+()[]{}|" c)
                            strcat("\\" c)
                            c
                        )
                    )
                )
            )
        )
        res
    )
)

procedure(_Fnmatch1(t_name t_comp "tt")  ; -> t | nil
    ; 按通配符语义判断单个名字是否匹配单段 pattern。
    ;
    ; **参数**
    ;   t_name  (str) - 被匹配的名字（路径部件）
    ;   t_comp  (str) - 单段 pattern（"*"、"?"、"[seq]" 与字面量）
    ;
    ; **返回**
    ;   (t|nil) - 匹配返回 t，否则返回 nil；pattern 为 "*" 时要求 t_name 非空
    if(t_comp == "*"
        t_name != ""
        pcreMatchp(lsprintf("^%s\\z" _FnmatchToPcre(t_comp)) t_name)
    )
)

procedure(_CanMatchEmpty(t_comp "t")  ; -> t | nil
    ; 判断 pattern 段能否匹配空名（""）。
    ;
    ; **参数**
    ;   t_comp  (str) - 单段 pattern
    ;
    ; **返回**
    ;   (t|nil) - 能匹配 "" 返回 t；"*"（以及匹配不了 "" 的段）返回 nil
    t_comp != "*" && _Fnmatch1("" t_comp)
)

procedure(_AllMatchp(l_names l_comps "ll")  ; -> t | nil
    ; 按顺序逐段判断两个串列表是否等长且每段都匹配。
    ;
    ; **参数**
    ;   l_names  (list) - 名字列表（str）
    ;   l_comps  (list) - pattern 段列表（str）
    ;
    ; **返回**
    ;   (t|nil) - 等长且逐段 _Fnmatch1 全通过返回 t；长度不同或任一段不匹配返回 nil
    let((ok rest)
        ok = length(l_names) == length(l_comps)
        rest = l_names
        when(ok
            foreach(c l_comps
                when(ok
                    ok = rest != nil && _Fnmatch1(car(rest) c)
                    rest = cdr(rest)
                )
            )
        )
        ok
    )
)

procedure(_SuffixMatchp(l_names l_comps "ll")  ; -> t | nil
    ; 判断名字列表的末段是否与 pattern 段右对齐全部匹配。
    ;
    ; **参数**
    ;   l_names  (list) - 名字列表（str）
    ;   l_comps  (list) - pattern 段列表（str）
    ;
    ; **返回**
    ;   (t|nil) - l_comps 不长于 l_names 且右对齐逐段匹配返回 t；否则返回 nil
    let((len comp)
        len = length(l_names)
        comp = length(l_comps)
        unless(comp > len
            _AllMatchp(_DropFirstN(l_names len - comp) l_comps)
        )
    )
)

unuseNamespace("ycPathLib")

; END
