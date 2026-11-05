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
    ;   ?quote (any) - 非 nil 时包裹双引号；默认 nil
    ;
    ; **返回**
    ;   (str) - 转义后的串；?quote 时可直接 evalstring 回读
    let((p len ch out)
        len = length(t_s)
        when(len > 0
            for(i 1 len
                ch = substring(t_s i 1)
                out = cond(
                    (ch == "\\" "\\\\")
                    (ch == "\"" "\\\"")
                    (ch == "\n" "\\n")
                    (ch == "\t" "\\t")
                    (ch == "\r" "\\r")
                    (t ch)
                )
                p = tconc(p out)
            )
        )
        out = if(p
            apply('strcat car(p))
            ""
        )
        if(quote
            lsprintf("\"%s\"" out)
            out
        )
    )
)

procedure(Unescape(t_s \@key (strict nil) "tg")  ; -> str
    ; 还原 Escape 的转义序列。
    ;
    ; **参数**
    ;   t_s     (str) - 输入串
    ;   ?strict (any) - 非 nil 时未知转义与悬尾反斜杠报错；默认 nil（原样保留）
    ;
    ; **返回**
    ;   (str) - 还原后的串
    let((p i len ch nx)
        len = length(t_s)
        i = 1
        while(i <= len
            ch = substring(t_s i 1)
            if(ch == "\\" && i < len
            then
                nx = substring(t_s i + 1 1)
                cond(
                    (nx == "\\" p = tconc(p "\\"))
                    (nx == "\"" p = tconc(p "\""))
                    (nx == "n" p = tconc(p "\n"))
                    (nx == "t" p = tconc(p "\t"))
                    (nx == "r" p = tconc(p "\r"))
                    (strict error("ycString::Unescape: unknown escape \\%s" nx))
                    (t p = tconc(p strcat("\\" nx)))
                )
                i = i + 2
            else
                when(ch == "\\"
                    if(strict
                        error("ycString::Unescape: trailing backslash")
                        p = tconc(p "\\")
                    )
                )
                unless(ch == "\\"
                    p = tconc(p ch)
                )
                i++
            )
        )
        if(p
            apply('strcat car(p))
            ""
        )
    )
)

unuseNamespace("ycString")

; END
