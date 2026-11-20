;--------------------------
; Program  : ycString(src/naming.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::Require("ycUtf8")

useNamespace("ycString")

procedure(_IsDigitChar(t_ch "t")  ; -> t | nil
    ; 判断单字符是否为 ASCII 数字（内部实现）。
    ;
    ; **参数**
    ;   t_ch (str) - 单字符
    ;
    ; **返回**
    ;   (t|nil) - 命中回 t
    index("0123456789" t_ch)
)

procedure(Words(t_s "t")  ; -> list[str]
    ; 切分为词列表（标识符转换的基础）。
    ;
    ; **参数**
    ;   t_s (str) - 输入串
    ;
    ; **返回**
    ;   (list[str]) - 词列表；无词时为 nil
    let((p chars prev cp nx rest)
        prev = 0
        rest = ycUtf8:::Decode(t_s)
        while(rest
            cp = car(rest)
            nx = if(cdr(rest) car(cdr(rest)) nil)
            cond(
                (!(cp > 127 || (cp >= 65 && cp <= 90) || (cp >= 97 && cp <= 122)
                        || (cp >= 48 && cp <= 57))
                    when(chars
                        p = tconc(p ycUtf8:::Encode(car(chars)))
                        chars = nil
                    )
                )
                ((chars && cp >= 65 && cp <= 90
                        && ((prev >= 97 && prev <= 122) || (prev >= 48 && prev <= 57)))
                    p = tconc(p ycUtf8:::Encode(car(chars)))
                    chars = tconc(nil cp)
                )
                ((chars && prev >= 65 && prev <= 90 && cp >= 65 && cp <= 90
                        && nx && nx >= 97 && nx <= 122)
                    p = tconc(p ycUtf8:::Encode(car(chars)))
                    chars = tconc(nil cp)
                )
                (t
                    chars = tconc(chars cp)
                )
            )
            prev = cp
            rest = cdr(rest)
        )
        when(chars
            p = tconc(p ycUtf8:::Encode(car(chars)))
        )
        car(p)
    )
)

procedure(_CapWord(t_w "t")  ; -> str
    ; 将词首字母大写（ASCII），其余保持（内部实现）。
    ;
    ; **参数**
    ;   t_w (str) - 词
    ;
    ; **返回**
    ;   (str) - 首字母大写的结果；空词为空串
    let((n)
        n = ycUtf8:::CharCount(t_w)
        cond(
            (t_w == "" "")
            (n <= 1 upperCase(t_w))
            (t strcat(upperCase(ycUtf8:::Slice(t_w 1 1)) ycUtf8:::Slice(t_w 2 n - 1)))
        )
    )
)

procedure(JoinWords(l_words \@key (style "snake") "lt")  ; -> str
    ; 按命名风格拼接词列表。
    ;
    ; **参数**
    ;   l_words (list[str]) - 词列表
    ;   ?style  (str)       - "snake"（默认）/ "kebab" / "camel" / "pascal"
    ;
    ; **返回**
    ;   (str) - 拼接结果；空列表为空串
    unless(member(style '("snake" "kebab" "camel" "pascal"))
        error("ycString::JoinWords: unknown style %A" style)
    )
    let((p i sep w)
        sep = cond(
            (style == "snake" "_")
            (style == "kebab" "-")
            (t "")
        )
        i = 0
        foreach(item l_words
            i++
            unless(stringp(item)
                error("ycString::JoinWords: item #%d is not a string (%A)" i item)
            )
            unless(i == 1
                when(sep != ""
                    p = tconc(p sep)
                )
            )
            w = lowerCase(item)
            cond(
                (style == "camel"
                    when(i > 1
                        w = _CapWord(w)
                    )
                )
                (style == "pascal"
                    w = _CapWord(w)
                )
            )
            p = tconc(p w)
        )
        buildString(car(p) "")
    )
)

procedure(Sanitize(t_s \@key (style "snake") "tt")  ; -> str
    ; 清洗为合法标识符形态。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   ?style (str) - 目标风格（同 JoinWords）；默认 snake
    ;
    ; **返回**
    ;   (str) - 标识符；数字开头补下划线；无可用字符时报错
    let((w r)
        w = Words(t_s)
        unless(w
            error("ycString::Sanitize: no valid characters (%A)" t_s)
        )
        r = JoinWords(w ?style style)
        when(_IsDigitChar(substring(r 1 1))
            r = strcat("_" r)
        )
        r
    )
)

procedure(ToSnake(t_s "t")  ; -> str
    ; Sanitize 的 snake 风格便捷形式。
    ;
    ; **参数**
    ;   t_s (str) - 输入串
    ;
    ; **返回**
    ;   (str) - snake 形式标识符
    Sanitize(t_s ?style "snake")
)

procedure(ToKebab(t_s "t")  ; -> str
    ; Sanitize 的 kebab 风格便捷形式。
    ;
    ; **参数**
    ;   t_s (str) - 输入串
    ;
    ; **返回**
    ;   (str) - kebab 形式标识符
    Sanitize(t_s ?style "kebab")
)

procedure(ToCamel(t_s "t")  ; -> str
    ; Sanitize 的 camel 风格便捷形式。
    ;
    ; **参数**
    ;   t_s (str) - 输入串
    ;
    ; **返回**
    ;   (str) - camel 形式标识符
    Sanitize(t_s ?style "camel")
)

procedure(ToPascal(t_s "t")  ; -> str
    ; Sanitize 的 pascal 风格便捷形式。
    ;
    ; **参数**
    ;   t_s (str) - 输入串
    ;
    ; **返回**
    ;   (str) - pascal 形式标识符
    Sanitize(t_s ?style "pascal")
)

unuseNamespace("ycString")

; END
