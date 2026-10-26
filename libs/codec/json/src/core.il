useNamespace("ycJson")

; ---------- 基础工具 ----------

procedure(_Code(t_s n_i "tx")  ; -> int | nil
    ; 取字节索引处的字符码（1-based）；索引越界返回 nil。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 1-based 字节索引
    ;
    ; **返回**
    ;   (int|nil) - 该字节的字符码；越界时为 nil
    let((g_c)
        g_c = getchar(t_s n_i)
        when(g_c
            charToInt(g_c)
        )
    )
)

procedure(_Digitp(g_c "g")  ; -> t | nil
    ; 判断字符码是否为 ASCII 数字（nil 安全）。
    ;
    ; **参数**
    ;   g_c  (any) - 字符码或 nil
    ;
    ; **返回**
    ;   (t|nil) - 48..57 时为 t，否则 nil
    g_c && g_c >= 48 && g_c <= 57
)

procedure(_LineCol(t_s n_i "tx")  ; -> list
    ; 按字节索引计算行列：行/列均 1-based，列按行内字节偏移。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 1-based 字节索引
    ;
    ; **返回**
    ;   (list) - (行 列) 两元素表
    let((n_line n_last)
        n_line = 1
        n_last = 0
        when(1 < n_i
            for(n_k 1 n_i - 1
                when(_Code(t_s n_k) == 10
                    n_line++
                    n_last = n_k
                )
            )
        )
        list(n_line n_i - n_last)
    )
)

procedure(_Error(t_s n_i t_msg "txt")  ; -> never
    ; 按统一格式 error() 中断：ycJson::Decode: <说明> at line <行>, column <列>。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   n_i    (int) - 1-based 字节索引（错误位置）
    ;   t_msg  (str) - 错误说明（英文短语）
    ;
    ; **返回**
    ;   (never) - 总是调用 error()，不返回
    let((l_pos)
        l_pos = _LineCol(t_s n_i)
        error("ycJson::Decode: %s at line %d, column %d" t_msg car(l_pos) cadr(l_pos))
    )
)

procedure(_Build(l_p "l")  ; -> str
    ; 将 tconc 头容器（或 nil）拼接为字符串。
    ;
    ; **参数**
    ;   l_p  (list) - tconc 头容器或 nil
    ;
    ; **返回**
    ;   (str) - 各片段顺序拼接
    buildString(car(l_p) "")
)


; ---------- 解码入口 ----------

unuseNamespace("ycJson")

; END
