;--------------------------
; Program  : ycString(src/escape.il)
; Language : Cadence Skill
;--------------------------

useNamespace("ycString")

procedure(Escape(t_s \@key (quote nil) "tg")  ; -> str
    ; 转义字符串（反斜杠、双引号、换行、制表、回车）。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   ?quote (any) - 非 nil 时包裹双引号
    ;
    ; **返回**
    ;   (str) - 转义后的串；?quote 时可直接 evalstring 回读
    let((l_p n_len t_ch t_out)
        n_len = length(t_s)
        when(n_len > 0
            for(n_i 1 n_len
                t_ch = substring(t_s n_i 1)
                t_out = cond(
                    (t_ch == "\\" "\\\\")
                    (t_ch == "\"" "\\\"")
                    (t_ch == "\n" "\\n")
                    (t_ch == "\t" "\\t")
                    (t_ch == "\r" "\\r")
                    (t t_ch)
                )
                l_p = tconc(l_p t_out)
            )
        )
        t_out = if(l_p
            apply('strcat car(l_p))
            ""
        )
        if(quote
            strcat("\"" t_out "\"")
            t_out
        )
    )
)

procedure(Unescape(t_s \@key (strict nil) "tg")  ; -> str
    ; 还原 escape 的转义序列。
    ;
    ; **参数**
    ;   t_s     (str) - 输入串
    ;   ?strict (any) - 非 nil 时未知转义与悬尾反斜杠报错；默认原样保留
    ;
    ; **返回**
    ;   (str) - 还原后的串
    let((l_p n_i n_len t_ch t_nx)
        n_len = length(t_s)
        n_i = 1
        while(n_i <= n_len
            t_ch = substring(t_s n_i 1)
            if(t_ch == "\\" && n_i < n_len
                {
                t_nx = substring(t_s n_i + 1 1)
                cond(
                    (t_nx == "\\" l_p = tconc(l_p "\\"))
                    (t_nx == "\"" l_p = tconc(l_p "\""))
                    (t_nx == "n" l_p = tconc(l_p "\n"))
                    (t_nx == "t" l_p = tconc(l_p "\t"))
                    (t_nx == "r" l_p = tconc(l_p "\r"))
                    (strict error("ycString::Unescape: unknown escape \\%s" t_nx))
                    (t l_p = tconc(l_p strcat("\\" t_nx)))
                )
                n_i = n_i + 2
                }
                {
                when(t_ch == "\\"
                    if(strict
                        error("ycString::Unescape: trailing backslash")
                        l_p = tconc(l_p "\\")
                    )
                )
                unless(t_ch == "\\"
                    l_p = tconc(l_p t_ch)
                )
                n_i = n_i + 1
                }
            )
        )
        if(l_p
            apply('strcat car(l_p))
            ""
        )
    )
)

unuseNamespace("ycString")

; END
