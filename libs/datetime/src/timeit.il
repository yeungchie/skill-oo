useNamespace("ycDateTime")

; 计时宏是全局符号：SKILL 的 defmacro 只能定义全局宏 —— 把名字登记进命名空间会把宏绑定
; 重绑成普通符号、宏随即失效（实测），因此用 yc 前缀避免与使用者宏重名。
(defmacro ycTimeIt (g_expr \@rest l_body)
    ; 测量被包裹代码的运行耗时，返回表示该时长的 DateTime（以 epoch 0 起算）。
    ;
    ; **参数**
    ;   g_expr  (form) - 被计时的第一个表达式（不求值，交给宏展开）
    ;   l_body  (list) - 其余表达式
    ;
    ; **返回**
    ;   (ycDateTime::DateTime) - 耗时（秒 + 纳秒）；表达式的值被丢弃，需要时在体内赋值
    (list 'let
        (list
            (list '_ycTimeItPerf
                (cons 'measureTime (cons g_expr l_body))
            )
        )
        (list 'ycDateTime::DateTime
            (list 'caddr '_ycTimeItPerf)
        )
    )
)

unuseNamespace("ycDateTime")

; END
