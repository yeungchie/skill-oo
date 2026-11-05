;--------------------------
; Program  : ycTextwrap(src/measure.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::Require("ycUtf8")

useNamespace("ycTextwrap")

; ---------- 基础度量 ----------

procedure(_IsSpaceCp(n_cp "x")  ; -> t | nil
    ; 判断码点是否为折行语义中的空白。
    ;
    ; **参数**
    ;   n_cp  (int) - 码点
    ;
    ; **返回**
    ;   (t|nil) - 空格、制表、换行、回车、换页、垂直制表为 t
    n_cp == 32 || n_cp == 9 || n_cp == 10 || n_cp == 13 || n_cp == 12 || n_cp == 11
)

procedure(_CheckUnit(t_ctx t_unit n_amb "ttx")  ; -> nil
    ; 校验宽度单位与 ambiguous 选项（内部实现）。
    ;
    ; **参数**
    ;   t_ctx   (str) - 错误消息上下文
    ;   t_unit  (str) - "display" 或 "char"
    ;   n_amb   (int) - 1 或 2
    ;
    ; **返回**
    ;   (nil) - 合法时无返回值；非法时报错
    unless(t_unit == "display" || t_unit == "char"
        error("%s: unknown unit %A" t_ctx t_unit)
    )
    when(t_unit == "display" && !(n_amb == 1 || n_amb == 2)
        error("%s: ambiguous must be 1 or 2" t_ctx)
    )
)

procedure(_CpWidth(n_cp t_unit n_amb "xtx")  ; -> int
    ; 单个码点在指定单位下的宽度（内部实现）。
    ;
    ; **参数**
    ;   n_cp   (int) - 码点
    ;   t_unit (str) - "display" 或 "char"
    ;   n_amb  (int) - East Asian Ambiguous 宽度
    ;
    ; **返回**
    ;   (int) - 显示列宽或 1
    if(t_unit == "char"
        1
        ycUtf8:::CharWidth(n_cp ?ambiguous n_amb)
    )
)

procedure(_WidthText(t_s t_unit n_amb "ttx")  ; -> int
    ; 字符串在指定单位下的宽度（内部实现）。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   t_unit (str) - "display" 或 "char"
    ;   n_amb  (int) - East Asian Ambiguous 宽度
    ;
    ; **返回**
    ;   (int) - 显示列宽或码点数
    if(t_unit == "char"
        ycUtf8:::CharCount(t_s)
        ycUtf8:::Width(t_s ?ambiguous n_amb)
    )
)

procedure(_WidthCps(l_cps t_unit n_amb "ltx")  ; -> int
    ; 码点列表在指定单位下的宽度（内部实现）。
    ;
    ; **参数**
    ;   l_cps  (list[int]) - 码点列表
    ;   t_unit (str) - "display" 或 "char"
    ;   n_amb  (int) - East Asian Ambiguous 宽度
    ;
    ; **返回**
    ;   (int) - 总宽度
    let((sum)
        sum = 0
        foreach(cp l_cps
            sum = sum + _CpWidth(cp t_unit n_amb)
        )
        sum
    )
)

; ---------- 列表与换行 ----------

procedure(_TakeCps(l_cps n_count "lx")  ; -> list[int]
    ; 取码点列表前 n 项（内部实现）。
    ;
    ; **参数**
    ;   l_cps   (list[int]) - 码点列表
    ;   n_count (int) - 项数
    ;
    ; **返回**
    ;   (list[int]) - 前 n 项；不足时取全部
    let((res)
        while(l_cps && n_count > 0
            res = tconc(res car(l_cps))
            l_cps = cdr(l_cps)
            n_count--
        )
        car(res)
    )
)

procedure(_DropCps(l_cps n_count "lx")  ; -> list[int]
    ; 丢弃码点列表前 n 项（内部实现）。
    ;
    ; **参数**
    ;   l_cps   (list[int]) - 码点列表
    ;   n_count (int) - 项数
    ;
    ; **返回**
    ;   (list[int]) - 剩余部分
    while(l_cps && n_count > 0
        l_cps = cdr(l_cps)
        n_count--
    )
    l_cps
)

procedure(_FitCount(l_cps n_max t_unit n_amb "lxtx")  ; -> int
    ; 计算在宽度上限内可完整容纳的码点数（内部实现）。
    ;
    ; **参数**
    ;   l_cps  (list[int]) - 码点列表
    ;   n_max  (int) - 宽度上限
    ;   t_unit (str) - 单位
    ;   n_amb  (int) - Ambiguous 宽度
    ;
    ; **返回**
    ;   (int) - 可容纳码点数；首码点即超宽时为 0
    let((sum have)
        sum = 0
        have = 0
        while(l_cps && sum + _CpWidth(car(l_cps) t_unit n_amb) <= n_max
            sum = sum + _CpWidth(car(l_cps) t_unit n_amb)
            have++
            l_cps = cdr(l_cps)
        )
        have
    )
)

procedure(_CutCount(l_cps n_max t_unit n_amb "lxtx")  ; -> int
    ; 计算硬切码点数，至少前进一个码点（内部实现）。
    ;
    ; **参数**
    ;   l_cps  (list[int]) - 码点列表
    ;   n_max  (int) - 宽度上限
    ;   t_unit (str) - 单位
    ;   n_amb  (int) - Ambiguous 宽度
    ;
    ; **返回**
    ;   (int) - 至少为 1
    let((have)
        have = _FitCount(l_cps n_max t_unit n_amb)
        if(have == 0 && l_cps 1 have)
    )
)

procedure(_FirstChunk(l_word n_max g_hyphen t_unit n_amb "lxgtx")  ; -> list[int]
    ; 从超宽词中切出首个可容纳片段（内部实现）。
    ;
    ; **参数**
    ;   l_word   (list[int]) - 词码点
    ;   n_max    (int) - 宽度上限
    ;   g_hyphen (t|nil) - 非 nil 时优先在连字符后断
    ;   t_unit   (str) - 单位
    ;   n_amb    (int) - Ambiguous 宽度
    ;
    ; **返回**
    ;   (list[int]) - 片段码点
    let((count i hy)
        count = _CutCount(l_word n_max t_unit n_amb)
        when(g_hyphen && count > 1
            i = 1
            foreach(cp _TakeCps(l_word count)
                when(cp == 45 hy = i)
                i++
            )
            when(hy count = hy)
        )
        _TakeCps(l_word count)
    )
)

procedure(_WordsFromCps(l_cps "l")  ; -> list | nil
    ; 按空白切词并折叠连续空白（内部实现）。
    ;
    ; **参数**
    ;   l_cps  (list[int]) - 码点列表
    ;
    ; **返回**
    ;   (list[list[int]]|nil) - 词列表；全空白为 nil
    let((res acc)
        foreach(cp l_cps
            if(_IsSpaceCp(cp)
                when(acc
                    res = tconc(res car(acc))
                    acc = nil
                )
                acc = tconc(acc cp)
            )
        )
        when(acc res = tconc(res car(acc)))
        car(res)
    )
)

procedure(_JoinWordsCps(l_words "l")  ; -> list[int]
    ; 用单空格连接词码点（内部实现）。
    ;
    ; **参数**
    ;   l_words  (list[list[int]]) - 词列表
    ;
    ; **返回**
    ;   (list[int]) - 拼接后的码点
    let((res)
        foreach(word l_words
            when(car(res) res = tconc(res 32))
            foreach(cp word res = tconc(res cp))
        )
        car(res)
    )
)

procedure(_NormalizeNewlines(t_s "t")  ; -> str
    ; 把 CRLF / CR 统一为 LF（内部实现）。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;
    ; **返回**
    ;   (str) - 统一换行后的串
    let((res i len b)
        i = 1
        len = length(t_s)
        while(i <= len
            b = charToInt(getchar(t_s i))
            if(b == 13
            then
                res = tconc(res "\n")
                when(i < len && charToInt(getchar(t_s i + 1)) == 10
                    i++
                )
            else
                res = tconc(res getchar(t_s i))
            )
            i++
        )
        buildString(car(res) "")
    )
)

procedure(_LogicalLines(t_s "t")  ; -> list[str]
    ; 按 LF 切行；末尾 LF 不产生额外空行（内部实现）。
    ;
    ; **参数**
    ;   t_s  (str) - 已归一换行的串
    ;
    ; **返回**
    ;   (list[str]) - 行列表；空串为 nil
    let((res line i len)
        i = 1
        len = length(t_s)
        while(i <= len
            if(charToInt(getchar(t_s i)) == 10
            then
                res = tconc(res buildString(car(line) ""))
                line = nil
            else
                line = tconc(line getchar(t_s i))
            )
            i++
        )
        unless(t_s == "" || charToInt(getchar(t_s len)) == 10
            res = tconc(res buildString(car(line) ""))
        )
        car(res)
    )
)


unuseNamespace("ycTextwrap")

; END
