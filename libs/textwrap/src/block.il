;--------------------------
; Program  : ycTextwrap(src/block.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::Require("ycUtf8")

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
        res = tconc(res buildString(car(line) ""))
        car(res)
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
        let((i len ch done)
            i = 1
            len = length(t_s)
            while(i <= len && !done
                ch = charToInt(getchar(t_s i))
                cond(
                    (ch == 32 || ch == 9 i = i + 1)
                    (t done = t)
                )
            )
            list(substring(t_s 1 i - 1) i > len)
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
    let((len)
        len = if(length(t_a) <= length(t_b) length(t_a) length(t_b))
        while(len > 0 && substring(t_a 1 len) != substring(t_b 1 len)
            len--
        )
        if(len == 0 "" substring(t_a 1 len))
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
    let((lines common have out)
        lines = _SplitAll(_NormalizeNewlines(t_text))
        foreach(line lines
            let((wp)
                wp = _WsPrefix(line)
                unless(cadr(wp)
                    if(have
                    then
                        common = _CommonPrefix(common car(wp))
                    else
                        common = car(wp)
                        have = t
                    )
                )
            )
        )
        unless(have common = "")
        foreach(line lines
            let((wp)
                wp = _WsPrefix(line)
                if(cadr(wp)
                    out = tconc(out "")
                    out = tconc(out substring(
                        line
                        length(common) + 1
                        length(line) - length(common)
                    ))
                )
            )
        )
        buildString(car(out) "\n")
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
    let((lines out)
        lines = _SplitAll(_NormalizeNewlines(t_text))
        foreach(line lines
            if(cadr(_WsPrefix(line))
                out = tconc(out line)
                out = tconc(out strcat(prefix line))
            )
        )
        buildString(car(out) "\n")
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
    let((cps)
        cps = _JoinWordsCps(_WordsFromCps(ycUtf8:::Decode(_NormalizeNewlines(t_text))))
        ycUtf8:::Encode(_ShortenCps(cps n_width placeholder unit ambiguous))
    )
)

unuseNamespace("ycTextwrap")

; END
