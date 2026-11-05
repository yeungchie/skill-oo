;--------------------------
; Program  : ycString(src/naming.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::Require("ycUtf8")

useNamespace("ycString")

procedure(_IsUpperChar(t_ch "t")  ; -> t | nil
    ; 判断单字符是否为 ASCII 大写字母（内部实现）。
    ;
    ; **参数**
    ;   t_ch (str) - 单字符
    ;
    ; **返回**
    ;   (t|nil) - 命中回 t
    index("ABCDEFGHIJKLMNOPQRSTUVWXYZ" t_ch)
)

procedure(_IsLowerChar(t_ch "t")  ; -> t | nil
    ; 判断单字符是否为 ASCII 小写字母（内部实现）。
    ;
    ; **参数**
    ;   t_ch (str) - 单字符
    ;
    ; **返回**
    ;   (t|nil) - 命中回 t
    index("abcdefghijklmnopqrstuvwxyz" t_ch)
)

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

procedure(_IsWordChar(t_ch "t")  ; -> t | nil
    ; 判断单字符是否算词内字符：ASCII 字母数字或非 ASCII 码点（内部实现）。
    ;
    ; **参数**
    ;   t_ch (str) - 单字符（码点完整）
    ;
    ; **返回**
    ;   (t|nil) - 是则回 t
    if(length(t_ch) > 1
        t
        _IsUpperChar(t_ch) || _IsLowerChar(t_ch) || _IsDigitChar(t_ch)
    )
)

procedure(Words(t_s "t")  ; -> list[str]
    ; 切分为词列表（标识符转换的基础）。
    ;
    ; **参数**
    ;   t_s (str) - 输入串
    ;
    ; **返回**
    ;   (list[str]) - 词列表；无词时为 nil
    let((p cur prev ch nx len)
        cur = ""
        prev = ""
        len = ycUtf8:::CharCount(t_s)
        when(len > 0
            for(i 1 len
                ch = ycUtf8:::Slice(t_s i 1)
                nx = if(i < len ycUtf8:::Slice(t_s i + 1 1) "")
                cond(
                    (!_IsWordChar(ch)
                        when(cur != ""
                            p = tconc(p cur)
                            cur = ""
                        )
                    )
                    ((cur != "" && _IsUpperChar(ch) && (_IsLowerChar(prev) || _IsDigitChar(prev)))
                        p = tconc(p cur)
                        cur = ch
                    )
                    ((cur != "" && _IsUpperChar(prev) && _IsUpperChar(ch) && _IsLowerChar(nx))
                        p = tconc(p cur)
                        cur = ch
                    )
                    (t
                        cur = strcat(cur ch)
                    )
                )
                prev = ch
            )
        )
        when(cur != ""
            p = tconc(p cur)
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
        if(p
            apply('strcat car(p))
            ""
        )
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
