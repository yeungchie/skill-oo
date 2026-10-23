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
    let((l_p t_cur t_prev t_ch t_nx n_len)
        t_cur = ""
        t_prev = ""
        n_len = ycUtf8:::CharCount(t_s)
        when(n_len > 0
            for(n_i 1 n_len
                t_ch = ycUtf8:::Slice(t_s n_i 1)
                t_nx = if(n_i < n_len ycUtf8:::Slice(t_s n_i + 1 1) "")
                cond(
                    (!_IsWordChar(t_ch)
                        when(t_cur != ""
                            l_p = tconc(l_p t_cur)
                            t_cur = ""
                        )
                    )
                    ((t_cur != "" && _IsUpperChar(t_ch) && (_IsLowerChar(t_prev) || _IsDigitChar(t_prev)))
                        l_p = tconc(l_p t_cur)
                        t_cur = t_ch
                    )
                    ((t_cur != "" && _IsUpperChar(t_prev) && _IsUpperChar(t_ch) && _IsLowerChar(t_nx))
                        l_p = tconc(l_p t_cur)
                        t_cur = t_ch
                    )
                    (t
                        t_cur = strcat(t_cur t_ch)
                    )
                )
                t_prev = t_ch
            )
        )
        when(t_cur != ""
            l_p = tconc(l_p t_cur)
        )
        car(l_p)
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
    let((n_n)
        n_n = ycUtf8:::CharCount(t_w)
        cond(
            (t_w == "" "")
            (n_n <= 1 upperCase(t_w))
            (t strcat(upperCase(ycUtf8:::Slice(t_w 1 1)) ycUtf8:::Slice(t_w 2 n_n - 1)))
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
    let((l_p n_i t_sep t_w)
        t_sep = cond(
            (style == "snake" "_")
            (style == "kebab" "-")
            (t "")
        )
        n_i = 0
        foreach(t_item l_words
            n_i = n_i + 1
            unless(stringp(t_item)
                error("ycString::JoinWords: item #%d is not a string (%A)" n_i t_item)
            )
            unless(n_i == 1
                when(t_sep != ""
                    l_p = tconc(l_p t_sep)
                )
            )
            t_w = lowerCase(t_item)
            cond(
                (style == "camel"
                    when(n_i > 1
                        t_w = _CapWord(t_w)
                    )
                )
                (style == "pascal"
                    t_w = _CapWord(t_w)
                )
            )
            l_p = tconc(l_p t_w)
        )
        if(l_p
            apply('strcat car(l_p))
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
    let((l_w t_r)
        l_w = Words(t_s)
        unless(l_w
            error("ycString::Sanitize: no valid characters (%A)" t_s)
        )
        t_r = JoinWords(l_w ?style style)
        when(_IsDigitChar(substring(t_r 1 1))
            t_r = strcat("_" t_r)
        )
        t_r
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
