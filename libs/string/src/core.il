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
    let((len start end)
        len = ycUtf8:::CharCount(t_s)
        start = 1
        end = len
        when(g_left
            while(start <= end && index(t_chars ycUtf8:::Slice(t_s start 1))
                start++
            )
        )
        when(g_right
            while(end >= start && index(t_chars ycUtf8:::Slice(t_s end 1))
                end--
            )
        )
        if(start > end
            ""
            ycUtf8:::Slice(t_s start end - start + 1)
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
    unless(ambiguous == 1 || ambiguous == 2
        error("ycString::Width: ambiguous must be 1 or 2")
    )
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
    let((res)
        res = ""
        when(n_times > 0
            for(i 1 n_times
                res = strcat(res t_fill)
            )
        )
        res
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
    unless(ambiguous == 1 || ambiguous == 2
        error("ycString::Pad: ambiguous must be 1 or 2")
    )
    when(unit == "display" && ycUtf8:::Width(fill ?ambiguous ambiguous) != 1
        error("ycString::Pad: fill must be single width in display mode (%A)" fill)
    )
    let((have)
        have = if(unit == "char"
            ycUtf8:::CharCount(t_s)
            ycUtf8:::Width(t_s ?ambiguous ambiguous)
        )
        if(n_width <= have
            t_s
            let((pad)
                pad = _Repeat(fill n_width - have)
                if(side == "start"
                    strcat(pad t_s)
                    strcat(t_s pad)
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
    let((p i j len)
        len = length(t_s)
        i = 1
        while(i <= len
            while(i <= len && _IsWhitespace(substring(t_s i 1))
                i++
            )
            j = i
            while(j <= len && !_IsWhitespace(substring(t_s j 1))
                j++
            )
            when(j > i
                p = tconc(p substring(t_s i j - i))
            )
            i = j
        )
        car(p)
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
    let((p rest cut pos len sep2 done)
        rest = t_s
        sep2 = length(t_sep)
        while(!done
            cut = index(rest t_sep)
            if(cut
            then
                len = length(rest)
                pos = len - length(cut) + 1
                p = tconc(p if(pos > 1 substring(rest 1 pos - 1) ""))
                rest = if(pos + sep2 > len
                    ""
                    substring(rest pos + sep2 len - pos - sep2 + 1)
                )
            else
                p = tconc(p rest)
                done = t
            )
        )
        car(p)
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
    let((p)
        foreach(item l_items
            unless(item == ""
                p = tconc(p item)
            )
        )
        car(p)
    )
)

procedure(Split(t_s \@key (sep nil) (regex nil) (keepEmpty t) "tggg")  ; -> list[str]
    ; 切分字符串：默认按空白符；字面分隔保留空段；?regex 委托正则切分。
    ;
    ; **参数**
    ;   t_s        (str)     - 输入串
    ;   ?sep       (str|nil) - 分隔符或正则模式；缺省时按空白符切分
    ;   ?regex     (any)     - 非 nil 时 ?sep 按正则模式解释；默认 nil
    ;   ?keepEmpty (any)     - 非 nil 时保留空段；默认 t
    ;
    ; **返回**
    ;   (list[str]) - 切分段列表
    let((parts)
        cond(
            (regex
                unless(stringp(sep) && sep != ""
                    error("ycString::Split: regex mode needs a non-empty pattern (%A)" sep)
                )
                parts = ycRegEx:::Split(sep t_s)
            )
            (sep
                unless(stringp(sep)
                    error("ycString::Split: separator must be a string (%A)" sep)
                )
                unless(sep != ""
                    error("ycString::Split: separator must not be empty")
                )
                parts = _SplitLiteral(t_s sep)
            )
            (t
                parts = _SplitWhitespace(t_s)
            )
        )
        if(keepEmpty
            parts
            _KeepNonEmpty(parts)
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
    let((p i)
        i = 0
        foreach(item l_items
            i++
            unless(stringp(item)
                error("ycString::Join: item #%d is not a string (%A)" i item)
            )
            unless(i == 1
                p = tconc(p sep)
            )
            p = tconc(p item)
        )
        if(p
            apply('strcat car(p))
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
    let((lp ls)
        lp = length(t_prefix)
        ls = length(t_s)
        if(lp == 0
            t
            lp <= ls && substring(t_s 1 lp) == t_prefix
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
    let((lx ls)
        lx = length(t_suffix)
        ls = length(t_s)
        cond(
            (lx == 0 t)
            (lx > ls nil)
            (t substring(t_s ls - lx + 1 lx) == t_suffix)
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
    ;   ?regex (any) - 非 nil 时 t_old 按正则模式解释；默认 nil
    ;
    ; **返回**
    ;   (str) - 替换后的串；无匹配原样返回
    cond(
        (regex
            when(t_old == ""
                error("ycString::Replace: pattern must not be empty")
            )
            ycRegEx:::Sub(t_old t_new t_s)
        )
        (t
            when(t_old == ""
                error("ycString::Replace: search string must not be empty")
            )
            let((p rest cut pos len old done)
                rest = t_s
                old = length(t_old)
                while(!done
                    cut = index(rest t_old)
                    if(cut
                    then
                        len = length(rest)
                        pos = len - length(cut) + 1
                        p = tconc(p if(pos > 1 substring(rest 1 pos - 1) ""))
                        p = tconc(p t_new)
                        rest = if(pos + old > len
                            ""
                            substring(rest pos + old len - pos - old + 1)
                        )
                    else
                        p = tconc(p rest)
                        done = t
                    )
                )
                apply('strcat car(p))
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
    ;   ?regex (any) - 非 nil 时 t_sub 按正则模式解释；默认 nil
    ;
    ; **返回**
    ;   (int) - 出现次数
    cond(
        (regex
            when(t_sub == ""
                error("ycString::Count: pattern must not be empty")
            )
            length(ycRegEx:::Findall(t_sub t_s))
        )
        (t
            when(t_sub == ""
                error("ycString::Count: search string must not be empty")
            )
            let((n rest cut pos len sub done)
                n = 0
                rest = t_s
                sub = length(t_sub)
                while(!done
                    cut = index(rest t_sub)
                    if(cut
                    then
                        n++
                        len = length(rest)
                        pos = len - length(cut) + 1
                        rest = if(pos + sub > len
                            ""
                            substring(rest pos + sub len - pos - sub + 1)
                        )
                    else
                        done = t
                    )
                )
                n
            )
        )
    )
)

unuseNamespace("ycString")

; END
