useNamespace("ycPathLib")


; ---------- fnmatch 匹配翻译（不导出） ----------

procedure(_FnmatchBracket(t_pattern n_open n_len)  ; -> (str, int)
    ; 把 pattern 中单个 "[" 字符类段编译为 pcre 字符类（fnmatch._translate 的 "[" 分支）。
    ;
    ; **参数**
    ;   t_pattern  (str) - 完整 fnmatch pattern
    ;   n_open     (int) - "[" 的 1-based 位置
    ;   n_len      (int) - t_pattern 的串长
    ;
    ; **返回**
    ;   (str, int) - 二元组 (正则串, 段后 1-based 位置)：支持 "!" 取反与段内元字符转义；
    ;                无闭合 "]" 时正则按字面 "[" 转义为 \[，位置回到 n_open + 1
    let((n_j g_stop t_stuff g_neg t_out n_k t_ch)
        n_j = n_open + 1
        when(n_j <= n_len
            when(substring(t_pattern n_j 1) == "!"
                n_j = n_j + 1
            )
        )
        when(n_j <= n_len
            when(substring(t_pattern n_j 1) == "]"
                n_j = n_j + 1
            )
        )
        while(!g_stop
            cond(
                (n_j > n_len
                    g_stop = t
                )
                (substring(t_pattern n_j 1) == "]"
                    g_stop = t
                )
                (t n_j = n_j + 1)
            )
        )
        if(n_j > n_len
            list("\\[" n_open + 1)
            let((l_res)
                t_stuff = substring(t_pattern n_open + 1 n_j - n_open - 1)
                when(substring(t_stuff 1 1) == "!"
                    g_neg = t
                    t_stuff = substring(t_stuff 2 length(t_stuff) - 1)
                )
                t_out = ""
                n_k = 1
                while(n_k <= length(t_stuff)
                    t_ch = substring(t_stuff n_k 1)
                    t_out = strcat(t_out
                        if(index("\\&~|" t_ch)
                            strcat("\\" t_ch)
                            t_ch
                        )
                    )
                    n_k = n_k + 1
                )
                unless(t_out == ""
                    when(index("^[]" substring(t_out 1 1))
                        t_out = strcat("\\" t_out)
                    )
                )
                l_res = list(
                    lsprintf("%s%s]" if(g_neg "[^" "[") t_out)
                    n_j + 1
                )
                l_res
            )
        )
    )
)

procedure(_FnmatchToPcre(t_pattern "t")  ; -> str
    ; 把 fnmatch 风格 pattern 编译为 pcre 正则串（"*" "?" 不跨 /）。
    ;
    ; **参数**
    ;   t_pattern  (str) - 含 "*"、"?"、"[seq]" 的 fnmatch pattern
    ;
    ; **返回**
    ;   (str) - 供 ^...\z 全串匹配使用的正则；其余正则元字符逐个加反斜杠转义
    let((t_res n_i n_len t_c)
        t_res = ""
        n_i = 1
        n_len = length(t_pattern)
        while(n_i <= n_len
            t_c = substring(t_pattern n_i 1)
            n_i = n_i + 1
            case(t_c
                ("*"
                    t_res = strcat(t_res "[^/]*")
                )
                ("?"
                    t_res = strcat(t_res "[^/]")
                )
                ("["
                    let((t_br)
                        t_br = _FnmatchBracket(t_pattern n_i - 1 n_len)
                        t_res = strcat(t_res car(t_br))
                        n_i = car(cdr(t_br))
                    )
                )
                (t
                    t_res = strcat(t_res
                        if(index("\\^$.+()[]{}|" t_c)
                            strcat("\\" t_c)
                            t_c
                        )
                    )
                )
            )
        )
        t_res
    )
)

procedure(_Fnmatch1(t_name t_comp "tt")  ; -> t | nil
    ; 按 fnmatch 语义判断单个名字是否匹配单段 pattern。
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
    ;   (t|nil) - 等长且逐段 _fnmatch1 全通过返回 t；长度不同或任一段不匹配返回 nil
    let((g_ok l_rest)
        g_ok = length(l_names) == length(l_comps)
        l_rest = l_names
        when(g_ok
            foreach(t_c l_comps
                when(g_ok
                    g_ok = l_rest != nil && _Fnmatch1(car(l_rest) t_c)
                    l_rest = cdr(l_rest)
                )
            )
        )
        g_ok
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
    let((n_len n_comp)
        n_len = length(l_names)
        n_comp = length(l_comps)
        unless(n_comp > n_len
            _AllMatchp(_DropFirstN(l_names n_len - n_comp) l_comps)
        )
    )
)

unuseNamespace("ycPathLib")

; END
