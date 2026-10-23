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
    let((n_c n_k l_r)
        n_c = _Code(t_s n_i)
        cond(
            (n_c == 34
                l_r = _ParseBasicString(t_s n_i t)
            )
            (n_c == 39
                l_r = _ParseLiteralString(t_s n_i t)
            )
            (t
                n_k = n_i
                while(n_k <= length(t_s)
                    && ((_Code(t_s n_k) >= 48 && _Code(t_s n_k) <= 57)
                        || (_Code(t_s n_k) >= 65 && _Code(t_s n_k) <= 90)
                        || (_Code(t_s n_k) >= 97 && _Code(t_s n_k) <= 122)
                        || _Code(t_s n_k) == 45
                        || _Code(t_s n_k) == 95)
                    n_k = n_k + 1
                )
                when(n_k == n_i
                    _Error(t_s n_i "expected a key")
                )
                l_r = list(substring(t_s n_i n_k - n_i) n_k)
            )
        )
        l_r
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
    let((l_res l_r)
        l_r = _ParseKeyPart(t_s n_i)
        l_res = tconc(l_res car(l_r))
        n_i = _SkipWs(t_s cadr(l_r) nil nil)
        while(_Code(t_s n_i) == 46
            n_i = _SkipWs(t_s n_i + 1 nil nil)
            l_r = _ParseKeyPart(t_s n_i)
            l_res = tconc(l_res car(l_r))
            n_i = _SkipWs(t_s cadr(l_r) nil nil)
        )
        list(car(l_res) n_i)
    )
)
unuseNamespace("ycToml")

; END
