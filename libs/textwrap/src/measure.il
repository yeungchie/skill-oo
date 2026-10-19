;--------------------------
; Program  : ycTextwrap(src/measure.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::require("ycUtf8")

useNamespace("ycTextwrap")

; ---------- 基础度量 ----------

procedure(_isSpaceCp(n_cp "n")  ; -> t | nil
    ; 判断码点是否为折行语义中的空白。
    ;
    ; **参数**
    ;   n_cp  (int) - 码点
    ;
    ; **返回**
    ;   (t|nil) - 空格、制表、换行、回车、换页、垂直制表为 t
    n_cp == 32 || n_cp == 9 || n_cp == 10 || n_cp == 13 || n_cp == 12 || n_cp == 11
)

procedure(_checkUnit(t_ctx t_unit n_amb "ttn")  ; -> nil
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

procedure(_cpWidth(n_cp t_unit n_amb "ntn")  ; -> int
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
        ycUtf8:::charWidth(n_cp ?ambiguous n_amb)
    )
)

procedure(_widthText(t_s t_unit n_amb "ttn")  ; -> int
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
        ycUtf8:::charCount(t_s)
        ycUtf8:::width(t_s ?ambiguous n_amb)
    )
)

procedure(_widthCps(l_cps t_unit n_amb "ltn")  ; -> int
    ; 码点列表在指定单位下的宽度（内部实现）。
    ;
    ; **参数**
    ;   l_cps  (list[int]) - 码点列表
    ;   t_unit (str) - "display" 或 "char"
    ;   n_amb  (int) - East Asian Ambiguous 宽度
    ;
    ; **返回**
    ;   (int) - 总宽度
    let((n_sum)
        n_sum = 0
        foreach(n_cp l_cps
            n_sum = n_sum + _cpWidth(n_cp t_unit n_amb)
        )
        n_sum
    )
)

; ---------- 列表与换行 ----------

procedure(_takeCps(l_cps n_count "ln")  ; -> list[int]
    ; 取码点列表前 n 项（内部实现）。
    ;
    ; **参数**
    ;   l_cps   (list[int]) - 码点列表
    ;   n_count (int) - 项数
    ;
    ; **返回**
    ;   (list[int]) - 前 n 项；不足时取全部
    let((l_res)
        l_res = cons(nil nil)
        while(l_cps && n_count > 0
            tconc(l_res car(l_cps))
            l_cps = cdr(l_cps)
            n_count = n_count - 1
        )
        car(l_res)
    )
)

procedure(_dropCps(l_cps n_count "ln")  ; -> list[int]
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
        n_count = n_count - 1
    )
    l_cps
)

procedure(_fitCount(l_cps n_max t_unit n_amb "lntn")  ; -> int
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
    let((n_sum n_have)
        n_sum = 0
        n_have = 0
        while(l_cps && n_sum + _cpWidth(car(l_cps) t_unit n_amb) <= n_max
            n_sum = n_sum + _cpWidth(car(l_cps) t_unit n_amb)
            n_have = n_have + 1
            l_cps = cdr(l_cps)
        )
        n_have
    )
)

procedure(_cutCount(l_cps n_max t_unit n_amb "lntn")  ; -> int
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
    let((n_have)
        n_have = _fitCount(l_cps n_max t_unit n_amb)
        if(n_have == 0 && l_cps 1 n_have)
    )
)

procedure(_firstChunk(l_word n_max g_hyphen t_unit n_amb "lngtn")  ; -> list[int]
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
    let((n_count n_i n_hy)
        n_count = _cutCount(l_word n_max t_unit n_amb)
        when(g_hyphen && n_count > 1
            n_i = 1
            foreach(n_cp _takeCps(l_word n_count)
                when(n_cp == 45 n_hy = n_i)
                n_i = n_i + 1
            )
            when(n_hy n_count = n_hy)
        )
        _takeCps(l_word n_count)
    )
)

procedure(_wordsFromCps(l_cps "l")  ; -> list | nil
    ; 按空白切词并折叠连续空白（内部实现）。
    ;
    ; **参数**
    ;   l_cps  (list[int]) - 码点列表
    ;
    ; **返回**
    ;   (list[list[int]]|nil) - 词列表；全空白为 nil
    let((l_res l_acc)
        l_res = cons(nil nil)
        foreach(n_cp l_cps
            if(_isSpaceCp(n_cp)
                when(l_acc
                    tconc(l_res car(l_acc))
                    l_acc = nil
                )
                l_acc = tconc(l_acc n_cp)
            )
        )
        when(l_acc tconc(l_res car(l_acc)))
        car(l_res)
    )
)

procedure(_joinWordsCps(l_words "l")  ; -> list[int]
    ; 用单空格连接词码点（内部实现）。
    ;
    ; **参数**
    ;   l_words  (list[list[int]]) - 词列表
    ;
    ; **返回**
    ;   (list[int]) - 拼接后的码点
    let((l_res)
        l_res = cons(nil nil)
        foreach(l_word l_words
            when(car(l_res) l_res = tconc(l_res 32))
            foreach(n_cp l_word tconc(l_res n_cp))
        )
        car(l_res)
    )
)

procedure(_normalizeNewlines(t_s "t")  ; -> str
    ; 把 CRLF / CR 统一为 LF（内部实现）。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;
    ; **返回**
    ;   (str) - 统一换行后的串
    let((l_res n_i n_len n_b)
        l_res = cons(nil nil)
        n_i = 1
        n_len = length(t_s)
        while(n_i <= n_len
            n_b = charToInt(getchar(t_s n_i))
            if(n_b == 13
                progn(
                    tconc(l_res "\n")
                    when(n_i < n_len && charToInt(getchar(t_s n_i + 1)) == 10
                        n_i = n_i + 1
                    )
                )
                tconc(l_res getchar(t_s n_i))
            )
            n_i = n_i + 1
        )
        buildString(car(l_res) "")
    )
)

procedure(_logicalLines(t_s "t")  ; -> list[str]
    ; 按 LF 切行；末尾 LF 不产生额外空行（内部实现）。
    ;
    ; **参数**
    ;   t_s  (str) - 已归一换行的串
    ;
    ; **返回**
    ;   (list[str]) - 行列表；空串为 (\"\")
    let((l_res l_line n_i n_len)
        l_res = cons(nil nil)
        n_i = 1
        n_len = length(t_s)
        while(n_i <= n_len
            if(charToInt(getchar(t_s n_i)) == 10
                progn(
                    tconc(l_res buildString(car(l_line) ""))
                    l_line = nil
                )
                l_line = tconc(l_line getchar(t_s n_i))
            )
            n_i = n_i + 1
        )
        unless(t_s == "" || charToInt(getchar(t_s n_len)) == 10
            tconc(l_res buildString(car(l_line) ""))
        )
        car(l_res)
    )
)


unuseNamespace("ycTextwrap")

; END
