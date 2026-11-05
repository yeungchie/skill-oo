;--------------------------
; Program  : codec/toml(key.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::Require("ycCodec")

useNamespace("ycToml")

; ---------- 键 ----------

procedure(_ParseKeyPart(t_s n_i "tx")  ; -> list
    ; 解析单个键段：裸键或单行引号键。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 起始位置
    ;
    ; **返回**
    ;   (list) - (键名 下一位置)
    let((c k r)
        c = _Code(t_s n_i)
        cond(
            (c == 34
                r = _ParseBasicString(t_s n_i t)
            )
            (c == 39
                r = _ParseLiteralString(t_s n_i t)
            )
            (t
                k = n_i
                while(k <= length(t_s)
                    && ((_Code(t_s k) >= 48 && _Code(t_s k) <= 57)
                        || (_Code(t_s k) >= 65 && _Code(t_s k) <= 90)
                        || (_Code(t_s k) >= 97 && _Code(t_s k) <= 122)
                        || _Code(t_s k) == 45
                        || _Code(t_s k) == 95)
                    k++
                )
                when(k == n_i
                    _Error(t_s n_i "expected a key")
                )
                r = list(substring(t_s n_i k - n_i) k)
            )
        )
        r
    )
)

procedure(_ParseKeyPath(t_s n_i "tx")  ; -> list
    ; 解析点分键路径；点两侧允许空格与制表符。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 起始位置
    ;
    ; **返回**
    ;   (list) - (键段列表 下一位置)
    let((res r)
        r = _ParseKeyPart(t_s n_i)
        res = tconc(res car(r))
        n_i = _SkipWs(t_s cadr(r) nil nil)
        while(_Code(t_s n_i) == 46
            n_i = _SkipWs(t_s n_i + 1 nil nil)
            r = _ParseKeyPart(t_s n_i)
            res = tconc(res car(r))
            n_i = _SkipWs(t_s cadr(r) nil nil)
        )
        list(car(res) n_i)
    )
)
unuseNamespace("ycToml")

; END
