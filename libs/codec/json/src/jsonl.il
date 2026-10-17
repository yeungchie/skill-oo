useNamespace("ycJson")


; ---------- jsonl 切分与辅助 ----------

procedure(_lineSplit(t_s "t")  ; -> list
    ; 按 \n 切分文本为行列表（保留空行，供行号对应）。
    ;
    ; **参数**
    ;   t_s  (str) - 输入文本
    ;
    ; **返回**
    ;   (list) - 各行文本（不含 \n；行尾 \r 原样保留）
    let((l_res n_len n_start)
        l_res = nil
        n_len = length(t_s)
        when(0 < n_len
            n_start = 1
            for(n_k 1 n_len
                when(_code(t_s n_k) == 10
                    l_res = tconc(l_res substring(t_s n_start n_k - n_start))
                    n_start = n_k + 1
                )
            )
            when(n_start <= n_len
                l_res = tconc(l_res substring(t_s n_start n_len - n_start + 1))
            )
        )
        car(l_res)
    )
)

procedure(_lineBlankp(t_line "t")  ; -> t | nil
    ; 判断一行是否全为空（空格/制表/回车）。
    ;
    ; **参数**
    ;   t_line  (str) - 行文本（不含 \n）
    ;
    ; **返回**
    ;   (t|nil) - 全空白或空串时为 t
    let((n_len n_c g_blank)
        g_blank = t
        n_len = length(t_line)
        when(0 < n_len
            for(n_k 1 n_len
                unless(_code(t_line n_k) == 32 || _code(t_line n_k) == 9 || _code(t_line n_k) == 13
                    g_blank = nil
                )
            )
        )
        g_blank
    )
)

procedure(_newlines(n_n "n")  ; -> str
    ; 生成 n_n 个换行符组成的串（jsonl 错误路径的行号前缀）。
    ;
    ; **参数**
    ;   n_n  (int) - 换行个数
    ;
    ; **返回**
    ;   (str) - n_n 个 "\n" 组成的串
    let((t_s)
        t_s = ""
        when(0 < n_n
            for(n_k 1 n_n
                t_s = strcat(t_s "\n")
            )
        )
        t_s
    )
)

procedure(_decodeLines(t_str "t")  ; -> list
    ; 逐行解码 JSON Lines：空行/全空白行跳过，各非空行须为完整文档，错误带原始行号。
    ;
    ; **参数**
    ;   t_str  (str) - JSON Lines 文本
    ;
    ; **返回**
    ;   (list) - 按行序的解码产物列表；无有效行时为 nil
    let((l_lines l_res l_r t_line n_idx)
        l_lines = _lineSplit(t_str)
        l_res = nil
        n_idx = 0
        while(l_lines
            t_line = car(l_lines)
            n_idx = n_idx + 1
            unless(_lineBlankp(t_line)
                l_r = errset(_decodeText(t_line nil) nil)
                if(l_r
                    l_res = tconc(l_res car(l_r))
                    ; 行内报错：以等长换行前缀重跑，令错误行列指向原始行号
                    _decodeText(strcat(_newlines(n_idx - 1) t_line) nil)
                )
            )
            l_lines = cdr(l_lines)
        )
        car(l_res)
    )
)

unuseNamespace("ycJson")

; END
