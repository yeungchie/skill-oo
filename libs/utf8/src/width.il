useNamespace("ycUtf8")

; ---------- 宽度规则 ----------

procedure(_InRanges(l_ranges n_cp "lx")  ; -> t | nil
    ; 在升序闭区间表中二分查找码点。
    ;
    ; **参数**
    ;   l_ranges  (list) - ((起始 结束) ...) 升序区间表
    ;   n_cp      (int) - 码点
    ;
    ; **返回**
    ;   (t|nil) - 命中回 t
    prog((n_lo n_hi n_mid l_r)
        n_lo = 0
        n_hi = length(l_ranges) - 1
        while(n_lo <= n_hi
            n_mid = (n_lo + n_hi) / 2
            l_r = nth(n_mid l_ranges)
            cond(
                (n_cp < car(l_r) n_hi = n_mid - 1)
                (n_cp > cadr(l_r) n_lo = n_mid + 1)
                (t return(t))
            )
        )
        nil
    )
)

procedure(_WidthOf(n_cp n_ambiguous "xx")  ; -> int
    ; 按规则计算单码点显示宽度。
    ;
    ; **参数**
    ;   n_cp        (int) - 码点
    ;   n_ambiguous (int) - Ambiguous 宽度（1 或 2）
    ;
    ; **返回**
    ;   (int) - 0 / 1 / 2
    cond(
        ((n_cp >= 0 && n_cp <= 31) || (n_cp >= 127 && n_cp <= 159) 0)
        (n_cp == 173 1)
        (_InRanges(_ZeroRanges n_cp) 0)
        (_InRanges(_WfRanges n_cp) 2)
        (_InRanges(_ARanges n_cp) n_ambiguous)
        (t 1)
    )
)

procedure(Width(t_str \@key (strict t) (ambiguous 1) "tgx")  ; -> int
    ; 计算 UTF-8 字节串的显示列宽。
    ;
    ; **参数**
    ;   t_str      (str) - UTF-8 字节串
    ;   ?strict    (any) - 非 nil 时非法序列报错；nil 时以 U+FFFD 替换；默认 t
    ;   ?ambiguous (int) - East Asian Ambiguous 的宽度（1 或 2）；默认 1
    ;
    ; **返回**
    ;   (int) - 显示列宽；空串为 0
    unless(ambiguous == 1 || ambiguous == 2
        error("ycUtf8::Width: ambiguous must be 1 or 2")
    )
    unless(stringp(t_str)
        error("ycUtf8::Width: expects a string")
    )
    let((l_res n_i n_sum)
        n_i = 1
        n_sum = 0
        while(n_i <= length(t_str)
            l_res = _Read(t_str n_i strict "ycUtf8::Width")
            n_sum = n_sum + _WidthOf(car(l_res) ambiguous)
            n_i = cadr(l_res)
        )
        n_sum
    )
)

procedure(CharWidth(n_cp \@key (ambiguous 1) "xx")  ; -> int
    ; 计算单个码点的显示宽度。
    ;
    ; **参数**
    ;   n_cp       (int) - 码点（0..0x10FFFF，非代理区）
    ;   ?ambiguous (int) - East Asian Ambiguous 的宽度（1 或 2）；默认 1
    ;
    ; **返回**
    ;   (int) - 0 / 1 / 2
    unless(ambiguous == 1 || ambiguous == 2
        error("ycUtf8::CharWidth: ambiguous must be 1 or 2")
    )
    unless(fixp(n_cp) && n_cp >= 0 && n_cp <= 1114111
        error("ycUtf8::CharWidth: invalid codepoint (%A)" n_cp)
    )
    when(n_cp >= 55296 && n_cp <= 57343
        error("ycUtf8::CharWidth: invalid codepoint (%A)" n_cp)
    )
    _WidthOf(n_cp ambiguous)
)

unuseNamespace("ycUtf8")

; END
