;--------------------------
; Program  : ycTextwrap(src/block.il)
; Language : Cadence Skill
;--------------------------

useNamespace("ycTextwrap")

; ---------- 行与前导空白 ----------

procedure(_SplitAll(t_s "t")  ; -> list[str]
    ; 按 LF 切行并保留末尾空行（内部实现）。
    ;
    ; **参数**
    ;   t_s  (str) - 已归一换行的串
    ;
    ; **返回**
    ;   (list[str]) - 行列表
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
        tconc(l_res buildString(car(l_line) ""))
        car(l_res)
    )
)

procedure(_WsPrefix(t_s "t")  ; -> list
    ; 返回行的前导空白前缀与是否空白行（内部实现）。
    ;
    ; **参数**
    ;   t_s  (str) - 单行文本
    ;
    ; **返回**
    ;   (list) - (前缀串 空白行标志)
    if(t_s == ""
        list("" t)
        let((n_i n_len n_ch g_done)
            n_i = 1
            n_len = length(t_s)
            while(n_i <= n_len && !g_done
                n_ch = charToInt(getchar(t_s n_i))
                cond(
                    (n_ch == 32 || n_ch == 9 n_i = n_i + 1)
                    (t g_done = t)
                )
            )
            list(substring(t_s 1 n_i - 1) n_i > n_len)
        )
    )
)

procedure(_CommonPrefix(t_a t_b "tt")  ; -> str
    ; 计算两个字符串的公共字节前缀（内部实现）。
    ;
    ; **参数**
    ;   t_a  (str) - 串一
    ;   t_b  (str) - 串二
    ;
    ; **返回**
    ;   (str) - 最长公共前缀
    let((n_len)
        n_len = if(length(t_a) <= length(t_b) length(t_a) length(t_b))
        while(n_len > 0 && substring(t_a 1 n_len) != substring(t_b 1 n_len)
            n_len = n_len - 1
        )
        if(n_len == 0 "" substring(t_a 1 n_len))
    )
)

; ---------- 公开入口 ----------

procedure(Dedent(t_text "t")  ; -> str
    ; 去除所有非空白行的公共前导空白。
    ;
    ; **参数**
    ;   t_text  (str) - 输入文本
    ;
    ; **返回**
    ;   (str) - 去除公共缩进后的文本；空白行归一为空串
    unless(stringp(t_text)
        error("ycTextwrap::Dedent: text must be a string (%A)" t_text)
    )
    let((l_lines t_common g_have l_out)
        l_lines = _SplitAll(_NormalizeNewlines(t_text))
        foreach(t_line l_lines
            let((l_wp)
                l_wp = _WsPrefix(t_line)
                unless(cadr(l_wp)
                    if(g_have
                        t_common = _CommonPrefix(t_common car(l_wp))
                        progn(
                            t_common = car(l_wp)
                            g_have = t
                        )
                    )
                )
            )
        )
        unless(g_have t_common = "")
        l_out = cons(nil nil)
        foreach(t_line l_lines
            let((l_wp)
                l_wp = _WsPrefix(t_line)
                if(cadr(l_wp)
                    tconc(l_out "")
                    tconc(l_out substring(
                        t_line
                        length(t_common) + 1
                        length(t_line) - length(t_common)
                    ))
                )
            )
        )
        buildString(car(l_out) "\n")
    )
)

procedure(Indent(t_text \@key (prefix "  ") "tt")  ; -> str
    ; 给每个非空白行加统一前缀。
    ;
    ; **参数**
    ;   t_text  (str) - 输入文本
    ;   ?prefix (str) - 行前缀；默认两个空格
    ;
    ; **返回**
    ;   (str) - 加前缀后的文本；空白行原样保留
    unless(stringp(t_text)
        error("ycTextwrap::Indent: text must be a string (%A)" t_text)
    )
    unless(stringp(prefix)
        error("ycTextwrap::Indent: prefix must be a string (%A)" prefix)
    )
    let((l_lines l_out)
        l_lines = _SplitAll(_NormalizeNewlines(t_text))
        l_out = cons(nil nil)
        foreach(t_line l_lines
            if(cadr(_WsPrefix(t_line))
                tconc(l_out t_line)
                tconc(l_out strcat(prefix t_line))
            )
        )
        buildString(car(l_out) "\n")
    )
)

procedure(Shorten(t_text n_width \@key (placeholder "...") (unit "display") (ambiguous 1) "txttx")  ; -> str
    ; 将文本截断到指定宽度并追加占位符。
    ;
    ; **参数**
    ;   t_text       (str) - 输入文本
    ;   n_width      (int) - 目标宽度（>= 1）
    ;   ?placeholder (str) - 占位符；默认 "..."
    ;   ?unit        (str) - "display"（默认）或 "char"
    ;   ?ambiguous   (int) - East Asian Ambiguous 宽度（1 或 2）；默认 1
    ;
    ; **返回**
    ;   (str) - 折叠空白后的截断文本；未超宽时不加占位符
    unless(stringp(t_text)
        error("ycTextwrap::Shorten: text must be a string (%A)" t_text)
    )
    unless(fixp(n_width) && n_width >= 1
        error("ycTextwrap::Shorten: width must be a positive integer (%A)" n_width)
    )
    unless(stringp(placeholder)
        error("ycTextwrap::Shorten: placeholder must be a string (%A)" placeholder)
    )
    _CheckUnit("ycTextwrap::Shorten" unit ambiguous)
    let((l_cps)
        l_cps = _JoinWordsCps(_WordsFromCps(ycUtf8:::Decode(_NormalizeNewlines(t_text))))
        ycUtf8:::Encode(_ShortenCps(l_cps n_width placeholder unit ambiguous))
    )
)

unuseNamespace("ycTextwrap")

; END
