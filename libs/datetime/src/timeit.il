useNamespace("ycDateTime")

; 计时宏是全局符号：SKILL 的 defmacro 只能定义全局宏 —— 把名字登记进命名空间会把宏绑定
; 重绑成普通符号、宏随即失效（实测），因此用 yc 前缀避免与使用者宏重名。
defmacro(ycTimeIt (\@rest l_body)
    ; 测量被包裹代码的运行耗时，返回表示该时长的 DateTime（以 epoch 0 起算）。
    ;
    ; quasiquote 里的 let 绑定列表带初值会被读取器拆错，因此初值在体内赋值；
    ; 隐藏符号用 gensym() 生成，避免与体内同名变量互相捕获。
    ;
    ; **参数**
    ;   l_body  (list) - 被计时的表达式，按顺序求值一次；可为空（空时测一次 nil，耗时约 0）
    ;
    ; **返回**
    ;   (ycDateTime::DateTime) - 耗时（秒 + 纳秒）；表达式的值被丢弃，需要时在体内赋值
    let((perf forms)
        perf = gensym()
        forms = if(l_body l_body list(nil))
        `let((,perf)
            ,perf = measureTime(,@forms)
            ycDateTime::DateTime(caddr(,perf))
        )
    )
)

unuseNamespace("ycDateTime")

; END
