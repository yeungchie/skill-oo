useNamespace("ycJson")


; ---------- 标量解析 ----------

procedure(_literal(t_s n_i "tn")  ; -> list
    ; 在位置处匹配 true/false/null 字面量（大小写敏感）。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 字面量首字符位置
    ;
    ; **返回**
    ;   (list) - (值 下一位置)；值分别为 True、False、Null
    cond(
        (substring(t_s n_i 4) == "true"
            list(True n_i + 4)
        )
        (substring(t_s n_i 5) == "false"
            list(False n_i + 5)
        )
        (substring(t_s n_i 4) == "null"
            list(Null n_i + 4)
        )
        (t
            _error(t_s n_i "invalid literal")
        )
    )
)

procedure(_number(t_s n_i "tn")  ; -> list
    ; 按 JSON 语法扫描数字：严格校验整数/小数/指数写法，超 fixnum 范围回 flonum。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 数字首字符位置（'-' 或数字）
    ;
    ; **返回**
    ;   (list) - (数值 下一位置)；整数走 fixnum（范围内），否则 flonum
    let((n_len n_k n_c t_tok n_v g_num)
        n_len = length(t_s)
        n_k = n_i
        n_c = _code(t_s n_k)
        when(n_c == 45
            n_k = n_k + 1
            n_c = _code(t_s n_k)
        )
        cond(
            (n_c == 48
                n_k = n_k + 1
            )
            (n_c >= 49 && n_c <= 57
                n_k = n_k + 1
                while(n_k <= n_len && _digitp(_code(t_s n_k))
                    n_k = n_k + 1
                )
            )
            (t
                _error(t_s n_i "invalid number")
            )
        )
        when(n_c == 48 && _digitp(_code(t_s n_k))
            _error(t_s n_k "invalid number")
        )
        when(_code(t_s n_k) == 46
            n_k = n_k + 1
            unless(_digitp(_code(t_s n_k))
                _error(t_s n_i "invalid number")
            )
            while(n_k <= n_len && _digitp(_code(t_s n_k))
                n_k = n_k + 1
            )
        )
        n_c = _code(t_s n_k)
        when(n_c == 101 || n_c == 69
            n_k = n_k + 1
            n_c = _code(t_s n_k)
            when(n_c == 43 || n_c == 45
                n_k = n_k + 1
            )
            unless(_digitp(_code(t_s n_k))
                _error(t_s n_i "invalid number")
            )
            while(n_k <= n_len && _digitp(_code(t_s n_k))
                n_k = n_k + 1
            )
        )
        t_tok = substring(t_s n_i n_k - n_i)
        if(pcreMatchp("[.eE]" t_tok)
            list(atof(t_tok) n_k)
            {
            n_v = atof(t_tok)
            if(n_v >= (-2147483647 - 1) && n_v <= 2147483647
                g_num = atoi(t_tok)
                g_num = n_v
            )
            list(g_num n_k)
            }
        )
    )
)


unuseNamespace("ycJson")

; END
