useNamespace("ycJson")


; ---------- jsonl 切分与辅助 ----------

procedure(_LineSplit(t_s "t")  ; -> list
    ; 按 \n 切分文本为行列表（保留空行，供行号对应）。
    ;
    ; **参数**
    ;   t_s  (str) - 输入文本
    ;
    ; **返回**
    ;   (list) - 各行文本（不含 \n；行尾 \r 原样保留）
    let((res len start)
        res = nil
        len = length(t_s)
        when(0 < len
            start = 1
            for(k 1 len
                when(_Code(t_s k) == 10
                    res = tconc(res substring(t_s start k - start))
                    start = k + 1
                )
            )
            when(start <= len
                res = tconc(res substring(t_s start len - start + 1))
            )
        )
        car(res)
    )
)

procedure(_LineBlankp(t_line "t")  ; -> t | nil
    ; 判断一行是否全为空（空格/制表/回车）。
    ;
    ; **参数**
    ;   t_line  (str) - 行文本（不含 \n）
    ;
    ; **返回**
    ;   (t|nil) - 全空白或空串时为 t
    let((len c blank)
        blank = t
        len = length(t_line)
        when(0 < len
            for(k 1 len
                unless(_Code(t_line k) == 32 || _Code(t_line k) == 9 || _Code(t_line k) == 13
                    blank = nil
                )
            )
        )
        blank
    )
)

procedure(_Newlines(n_n "x")  ; -> str
    ; 生成 n_n 个换行符组成的串（jsonl 错误路径的行号前缀）。
    ;
    ; **参数**
    ;   n_n  (int) - 换行个数
    ;
    ; **返回**
    ;   (str) - n_n 个 "\n" 组成的串
    let((item)
        item = ""
        when(0 < n_n
            for(k 1 n_n
                item = strcat(item "\n")
            )
        )
        item
    )
)

procedure(_DecodeLines(t_str n_max "tx")  ; -> list
    ; 逐行解码 JSON Lines：空行/全空白行跳过，各非空行须为完整文档，错误带原始行号。
    ;
    ; **参数**
    ;   t_str  (str) - JSON Lines 文本
    ;   n_max  (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (list) - 按行序的解码产物列表；无有效行时为 nil
    let((lines res r line idx)
        lines = _LineSplit(t_str)
        res = nil
        idx = 0
        while(lines
            line = car(lines)
            idx++
            unless(_LineBlankp(line)
                r = errset(_DecodeText(line nil n_max) nil)
                if(r
                    res = tconc(res car(r))
                    ; 行内报错：以等长换行前缀重跑，令错误行列指向原始行号
                    _DecodeText(strcat(_Newlines(idx - 1) line) nil n_max)
                )
            )
            lines = cdr(lines)
        )
        car(res)
    )
)

unuseNamespace("ycJson")

; END
