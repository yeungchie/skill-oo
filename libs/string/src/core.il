;--------------------------
; Program  : ycString(src/core.il)
; Language : Cadence Skill
;--------------------------

ycRequireNamespace("ycRegEx" "ycUtf8")

useNamespace("ycString")

procedure(_trimSide(t_s t_chars g_left g_right "ttgg")  ; -> str
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
        n_len = ycUtf8:::charCount(t_s)
        n_start = 1
        n_end = n_len
        when(g_left
            while(n_start <= n_end && index(t_chars ycUtf8:::slice(t_s n_start 1))
                n_start = n_start + 1
            )
        )
        when(g_right
            while(n_end >= n_start && index(t_chars ycUtf8:::slice(t_s n_end 1))
                n_end = n_end - 1
            )
        )
        if(n_start > n_end
            ""
            ycUtf8:::slice(t_s n_start n_end - n_start + 1)
        )
    )
)

procedure(trim(t_s \@key (chars " \t\r\n") "tg")  ; -> str
    ; 去除两端字符集中的字符。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   ?chars (str) - 待剥离的字面字符集（非正则）；默认空格/制表/回车/换行
    ;
    ; **返回**
    ;   (str) - 剥离后的串；全剥离时为空串
    _trimSide(t_s chars t t)
)

procedure(trimStart(t_s \@key (chars " \t\r\n") "tg")  ; -> str
    ; 同 trim，仅去除前端字符。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   ?chars (str) - 待剥离的字面字符集；默认空格/制表/回车/换行
    ;
    ; **返回**
    ;   (str) - 剥离后的串
    _trimSide(t_s chars t nil)
)

procedure(trimEnd(t_s \@key (chars " \t\r\n") "tg")  ; -> str
    ; 同 trim，仅去除尾端字符。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   ?chars (str) - 待剥离的字面字符集；默认空格/制表/回车/换行
    ;
    ; **返回**
    ;   (str) - 剥离后的串
    _trimSide(t_s chars nil t)
)

procedure(width(t_s \@key (unit "display") (ambiguous 1) "tgg")  ; -> int
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
        (unit == "display" ycUtf8:::width(t_s ?ambiguous ambiguous))
        (unit == "char" ycUtf8:::charCount(t_s))
        (t error("ycString::width: unknown unit %A" unit))
    )
)

procedure(_repeat(t_fill n_times "tn")  ; -> str
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

procedure(pad(t_s n_width \@key (fill " ") (side "end") (unit "display") (ambiguous 1) "tngggg")  ; -> str
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
        error("ycString::pad: width must be a non-negative integer (%A)" n_width)
    )
    unless(stringp(fill) && ycUtf8:::charCount(fill) == 1
        error("ycString::pad: fill must be a single character (%A)" fill)
    )
    unless(side == "end" || side == "start"
        error("ycString::pad: unknown side %A" side)
    )
    unless(unit == "display" || unit == "char"
        error("ycString::pad: unknown unit %A" unit)
    )
    when(unit == "display" && ycUtf8:::width(fill ?ambiguous ambiguous) != 1
        error("ycString::pad: fill must be single width in display mode (%A)" fill)
    )
    let((n_have)
        n_have = if(unit == "char"
            ycUtf8:::charCount(t_s)
            ycUtf8:::width(t_s ?ambiguous ambiguous)
        )
        if(n_width <= n_have
            t_s
            let((t_pad)
                t_pad = _repeat(fill n_width - n_have)
                if(side == "start"
                    strcat(t_pad t_s)
                    strcat(t_s t_pad)
                )
            )
        )
    )
)

unuseNamespace("ycString")

; END
