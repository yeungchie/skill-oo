;--------------------------
; Program  : ycString(src/core.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::Require("ycRegEx" "ycUtf8")

useNamespace("ycString")

procedure(_TrimSide(t_s t_chars g_left g_right "ttgg")  ; -> str
    ; 按字面字符集剥离单端或双端字符（内部实现）。
    ;
    ; **参数**
    ;   t_s     (str)   - 输入串
    ;   t_chars (str)   - 待剥离的字面字符集
    ;   g_left  (t|nil) - 非 nil 时剥前端
    ;   g_right (t|nil) - 非 nil 时剥尾端
    ;
    ; **返回**
    ;   (str) - 剥离后的串；全部剥离时为空串
    let((n_len n_start n_end)
        n_len = ycUtf8:::CharCount(t_s)
        n_start = 1
        n_end = n_len
        when(g_left
            while(n_start <= n_end && index(t_chars ycUtf8:::Slice(t_s n_start 1))
                n_start = n_start + 1
            )
        )
        when(g_right
            while(n_end >= n_start && index(t_chars ycUtf8:::Slice(t_s n_end 1))
                n_end = n_end - 1
            )
        )
        if(n_start > n_end
            ""
            ycUtf8:::Slice(t_s n_start n_end - n_start + 1)
        )
    )
)

procedure(Trim(t_s \@key (chars " \t\r\n") "tt")  ; -> str
    ; 去除两端字符集中的字符。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   ?chars (str) - 待剥离的字面字符集（非正则）；默认空格/制表/回车/换行
    ;
    ; **返回**
    ;   (str) - 剥离后的串；全剥离时为空串
    _TrimSide(t_s chars t t)
)

procedure(TrimStart(t_s \@key (chars " \t\r\n") "tt")  ; -> str
    ; 同 Trim，仅去除前端字符。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   ?chars (str) - 待剥离的字面字符集；默认空格/制表/回车/换行
    ;
    ; **返回**
    ;   (str) - 剥离后的串
    _TrimSide(t_s chars t nil)
)

procedure(TrimEnd(t_s \@key (chars " \t\r\n") "tt")  ; -> str
    ; 同 Trim，仅去除尾端字符。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   ?chars (str) - 待剥离的字面字符集；默认空格/制表/回车/换行
    ;
    ; **返回**
    ;   (str) - 剥离后的串
    _TrimSide(t_s chars nil t)
)

procedure(Width(t_s \@key (unit "display") (ambiguous 1) "ttx")  ; -> int
    ; 计算字符串的显示列宽或码点数。
    ;
    ; **参数**
    ;   t_s        (str) - 输入串
    ;   ?unit      (str) - "display"（默认，显示列宽）或 "char"（码点数）
    ;   ?ambiguous (int) - East Asian Ambiguous 宽度（1 或 2）；默认 1
    ;
    ; **返回**
    ;   (int) - 显示列宽或码点数
    cond(
        (unit == "display" ycUtf8:::Width(t_s ?ambiguous ambiguous))
        (unit == "char" ycUtf8:::CharCount(t_s))
        (t error("ycString::Width: unknown unit %A" unit))
    )
)

procedure(_Repeat(t_fill n_times "tx")  ; -> str
    ; 重复单字符若干次（内部实现）。
    ;
    ; **参数**
    ;   t_fill  (str) - 单字符
    ;   n_times (int) - 重复次数（>= 0）
    ;
    ; **返回**
    ;   (str) - 重复结果；0 次为空串
    let((t_res)
        t_res = ""
        when(n_times > 0
            for(n_i 1 n_times
                t_res = strcat(t_res t_fill)
            )
        )
        t_res
    )
)

procedure(Pad(t_s n_width \@key (fill " ") (side "end") (unit "display") (ambiguous 1) "txtttx")  ; -> str
    ; 将字符串补足到目标宽度（永不截断）。
    ;
    ; **参数**
    ;   t_s        (str) - 输入串
    ;   n_width    (int) - 目标宽度（>= 0）
    ;   ?fill      (str) - 填充字符（单字符）；默认空格
    ;   ?side      (str) - "end" 尾补（默认）/ "start" 首补
    ;   ?unit      (str) - "display" 显示列宽（默认）/ "char" 码点数
    ;   ?ambiguous (int) - East Asian Ambiguous 宽度（1 或 2）；默认 1
    ;
    ; **返回**
    ;   (str) - 补足后的串；已足宽原样返回
    unless(fixp(n_width) && n_width >= 0
        error("ycString::Pad: width must be a non-negative integer (%A)" n_width)
    )
    unless(stringp(fill) && ycUtf8:::CharCount(fill) == 1
        error("ycString::Pad: fill must be a single character (%A)" fill)
    )
    unless(side == "end" || side == "start"
        error("ycString::Pad: unknown side %A" side)
    )
    unless(unit == "display" || unit == "char"
        error("ycString::Pad: unknown unit %A" unit)
    )
    when(unit == "display" && ycUtf8:::Width(fill ?ambiguous ambiguous) != 1
        error("ycString::Pad: fill must be single width in display mode (%A)" fill)
    )
    let((n_have)
        n_have = if(unit == "char"
            ycUtf8:::CharCount(t_s)
            ycUtf8:::Width(t_s ?ambiguous ambiguous)
        )
        if(n_width <= n_have
            t_s
            let((t_pad)
                t_pad = _Repeat(fill n_width - n_have)
                if(side == "start"
                    strcat(t_pad t_s)
                    strcat(t_s t_pad)
                )
            )
        )
    )
)

procedure(_IsWhitespace(t_ch "t")  ; -> t | nil
    ; 判断单字符是否为默认空白字符（空格/制表/回车/换行）。
    ;
    ; **参数**
    ;   t_ch (str) - 单字符
    ;
    ; **返回**
    ;   (t|nil) - 命中回 t
    index(" \t\r\n" t_ch)
)

procedure(_SplitWhitespace(t_s "t")  ; -> list[str]
    ; 按空白字符连续段切分并丢弃空段（内部实现）。
    ;
    ; **参数**
    ;   t_s (str) - 输入串
    ;
    ; **返回**
    ;   (list[str]) - 非空词列表；无词时为 nil
    let((l_p n_i n_j n_len)
        n_len = length(t_s)
        n_i = 1
        while(n_i <= n_len
            while(n_i <= n_len && _IsWhitespace(substring(t_s n_i 1))
                n_i = n_i + 1
            )
            n_j = n_i
            while(n_j <= n_len && !_IsWhitespace(substring(t_s n_j 1))
                n_j = n_j + 1
            )
            when(n_j > n_i
                l_p = tconc(l_p substring(t_s n_i n_j - n_i))
            )
            n_i = n_j
        )
        car(l_p)
    )
)

procedure(_SplitLiteral(t_s t_sep "tt")  ; -> list[str]
    ; 按字面分隔符切分并保留空段（内部实现）。
    ;
    ; **参数**
    ;   t_s   (str) - 输入串
    ;   t_sep (str) - 非空字面分隔符
    ;
    ; **返回**
    ;   (list[str]) - 切分段（含空段）
    let((l_p t_rest n_cut n_pos n_len n_sep g_done)
        t_rest = t_s
        n_sep = length(t_sep)
        while(!g_done
            n_cut = index(t_rest t_sep)
            if(n_cut
                {
                n_len = length(t_rest)
                n_pos = n_len - length(n_cut) + 1
                l_p = tconc(l_p if(n_pos > 1 substring(t_rest 1 n_pos - 1) ""))
                t_rest = if(n_pos + n_sep > n_len
                    ""
                    substring(t_rest n_pos + n_sep n_len - n_pos - n_sep + 1)
                )
                }
                {
                l_p = tconc(l_p t_rest)
                g_done = t
                }
            )
        )
        car(l_p)
    )
)

procedure(_KeepNonEmpty(l_items "l")  ; -> list[str]
    ; 过滤列表中的空串（内部实现）。
    ;
    ; **参数**
    ;   l_items (list[str]) - 待过滤列表
    ;
    ; **返回**
    ;   (list[str]) - 过滤结果；全为空串时为 nil
    let((l_p)
        foreach(t_item l_items
            unless(t_item == ""
                l_p = tconc(l_p t_item)
            )
        )
        car(l_p)
    )
)

procedure(Split(t_s \@key (sep nil) (regex nil) (keepEmpty t) "tggg")  ; -> list[str]
    ; 切分字符串：默认按空白符；字面分隔保留空段；?regex 委托正则切分。
    ;
    ; **参数**
    ;   t_s        (str)     - 输入串
    ;   ?sep       (str|nil) - 分隔符或正则模式；缺省时按空白符切分
    ;   ?regex     (any)     - 非 nil 时 ?sep 按正则模式解释
    ;   ?keepEmpty (any)     - 非 nil 时保留空段；默认 t
    ;
    ; **返回**
    ;   (list[str]) - 切分段列表
    let((l_parts)
        cond(
            (regex
                unless(stringp(sep) && sep != ""
                    error("ycString::Split: regex mode needs a non-empty pattern (%A)" sep)
                )
                l_parts = ycRegEx::Split(sep t_s ?all t)
            )
            (sep
                unless(stringp(sep)
                    error("ycString::Split: separator must be a string (%A)" sep)
                )
                unless(sep != ""
                    error("ycString::Split: separator must not be empty")
                )
                l_parts = _SplitLiteral(t_s sep)
            )
            (t
                l_parts = _SplitWhitespace(t_s)
            )
        )
        if(keepEmpty
            l_parts
            _KeepNonEmpty(l_parts)
        )
    )
)

procedure(Join(l_items \@key (sep "") "lt")  ; -> str
    ; 以分隔符连接字符串列表。
    ;
    ; **参数**
    ;   l_items (list[str]) - 待连接项（全部须为字符串）
    ;   ?sep    (str)       - 分隔符；默认空串
    ;
    ; **返回**
    ;   (str) - 连接结果；空列表为空串
    unless(stringp(sep)
        error("ycString::Join: separator must be a string (%A)" sep)
    )
    let((l_p n_i)
        n_i = 0
        foreach(g_item l_items
            n_i = n_i + 1
            unless(stringp(g_item)
                error("ycString::Join: item #%d is not a string (%A)" n_i g_item)
            )
            unless(n_i == 1
                l_p = tconc(l_p sep)
            )
            l_p = tconc(l_p g_item)
        )
        if(l_p
            apply('strcat car(l_p))
            ""
        )
    )
)

procedure(StartsWith(t_s t_prefix "tt")  ; -> t | nil
    ; 判断字符串是否以指定前缀开始。
    ;
    ; **参数**
    ;   t_s      (str) - 输入串
    ;   t_prefix (str) - 前缀
    ;
    ; **返回**
    ;   (t|nil) - 是则为 t；空前缀回 t
    let((n_lp n_ls)
        n_lp = length(t_prefix)
        n_ls = length(t_s)
        if(n_lp == 0
            t
            n_lp <= n_ls && substring(t_s 1 n_lp) == t_prefix
        )
    )
)

procedure(EndsWith(t_s t_suffix "tt")  ; -> t | nil
    ; 判断字符串是否以指定后缀结束。
    ;
    ; **参数**
    ;   t_s      (str) - 输入串
    ;   t_suffix (str) - 后缀
    ;
    ; **返回**
    ;   (t|nil) - 是则为 t；空后缀回 t
    let((n_lx n_ls)
        n_lx = length(t_suffix)
        n_ls = length(t_s)
        cond(
            (n_lx == 0 t)
            (n_lx > n_ls nil)
            (t substring(t_s n_ls - n_lx + 1 n_lx) == t_suffix)
        )
    )
)

procedure(Replace(t_s t_old t_new \@key (regex nil) "tttg")  ; -> str
    ; 替换全部出现（字面量或正则；非重叠）。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   t_old  (str) - 待替换串或正则模式
    ;   t_new  (str) - 替换串（正则模式下按 ycRegEx 的替换模板展开）
    ;   ?regex (any) - 非 nil 时 t_old 按正则模式解释
    ;
    ; **返回**
    ;   (str) - 替换后的串；无匹配原样返回
    cond(
        (regex
            when(t_old == ""
                error("ycString::Replace: pattern must not be empty")
            )
            ycRegEx::Sub(t_old t_new t_s ?all t)
        )
        (t
            when(t_old == ""
                error("ycString::Replace: search string must not be empty")
            )
            let((l_p t_rest n_cut n_pos n_len n_old g_done)
                t_rest = t_s
                n_old = length(t_old)
                while(!g_done
                    n_cut = index(t_rest t_old)
                    if(n_cut
                        {
                        n_len = length(t_rest)
                        n_pos = n_len - length(n_cut) + 1
                        l_p = tconc(l_p if(n_pos > 1 substring(t_rest 1 n_pos - 1) ""))
                        l_p = tconc(l_p t_new)
                        t_rest = if(n_pos + n_old > n_len
                            ""
                            substring(t_rest n_pos + n_old n_len - n_pos - n_old + 1)
                        )
                        }
                        {
                        l_p = tconc(l_p t_rest)
                        g_done = t
                        }
                    )
                )
                apply('strcat car(l_p))
            )
        )
    )
)

procedure(Count(t_s t_sub \@key (regex nil) "ttg")  ; -> int
    ; 统计非重叠出现次数（字面量或正则）。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   t_sub  (str) - 待计数子串或正则模式
    ;   ?regex (any) - 非 nil 时 t_sub 按正则模式解释
    ;
    ; **返回**
    ;   (int) - 出现次数
    cond(
        (regex
            when(t_sub == ""
                error("ycString::Count: pattern must not be empty")
            )
            length(ycRegEx::Findall(t_sub t_s))
        )
        (t
            when(t_sub == ""
                error("ycString::Count: search string must not be empty")
            )
            let((n_n t_rest n_cut n_pos n_len n_sub g_done)
                n_n = 0
                t_rest = t_s
                n_sub = length(t_sub)
                while(!g_done
                    n_cut = index(t_rest t_sub)
                    if(n_cut
                        {
                        n_n = n_n + 1
                        n_len = length(t_rest)
                        n_pos = n_len - length(n_cut) + 1
                        t_rest = if(n_pos + n_sub > n_len
                            ""
                            substring(t_rest n_pos + n_sub n_len - n_pos - n_sub + 1)
                        )
                        }
                        {
                        g_done = t
                        }
                    )
                )
                n_n
            )
        )
    )
)

unuseNamespace("ycString")

; END
