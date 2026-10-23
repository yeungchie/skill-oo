useNamespace("ycSubProcess")


; ---------- 函数 ----------

procedure(_FormatSeconds(n_second "x")  ; -> str
    ; 将秒数换算为人类可读耗时串：0 秒为 ~0s，其余为 1s / 1m1s / 1h1m1s 风格。
    ;
    ; **参数**
    ;   n_second  (int) - 耗时秒数
    ;
    ; **返回**
    ;   (str) - 换算后的耗时串
    cond(
        (n_second == 0
            "~0s"
        )
        (n_second < 60
            lsprintf("%ds" n_second)
        )
        (n_second < 3600
            let((s)
                lsprintf("%dm%s"
                    n_second/60
                    if((s = remainder(n_second 60)) == 0
                        ""
                        lsprintf("%ds" s)
                    )
                )
            )
        )
        (t
            let((m s)
                lsprintf("%dh%s%s"
                    n_second/3600
                    if((m = remainder(n_second 3600)/60) == 0
                        ""
                        lsprintf("%dm" m)
                    )
                    if((s = remainder(n_second 60)) == 0
                        ""
                        lsprintf("%ds" s)
                    )
                )
            )
        )
    )
)


; ---------- 类定义 ----------

defclass(Elapsed () (
    ; Elapsed 时间流逝记录对象：mark() 记录起止时间，getSeconds()/humanReadable() 取耗时。
    mark()
    getStart()
    getEnd()
    getSeconds()
    humanReadable()
))

defmethod(printself (self(Elapsed))  ; -> str
    ; 返回耗时对象的打印描述串，形如 <ycSubProcess::Elapsed "1.5s">；未开始/进行中显示 "none"/"active"。
    ;
    ; **返回**
    ;   (str) - lsprintf 生成；按 getEnd()/getStart() 分支取显示值
    lsprintf("<%A %A>"
        className(self)
        cond(
            (self->getEnd()     self->humanReadable())
            (self->getStart()   "active")
            (t                  "none")
        )
    )
)


; ---------- 构造时安装全部方法 ----------

inScheme(
defmethod(initializeInstance (self(Elapsed) \@rest _args)
    ; 安装 Elapsed 全部方法：mark/getStart/getEnd/getSeconds/humanReadable。
    ;
    ; **参数**
    ;   _args  (list) - 变参：附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成后返回 t
    let((_start_ts _end_ts _second _humanReadable)
        procedure(_Error(t_method t_formatString \@rest g_args "ttg")  ; -> never
            ; 按统一格式 error() 中断：消息形如 <类名>-><方法名>: <说明>。
            ;
            ; **参数**
            ;   t_method        (str) - 出错的方法名
            ;   t_formatString  (str) - 错误说明格式串（lsprintf 格式）
            ;   g_args          (list) - 变参：格式串实参
            ;
            ; **返回**
            ;   (never) - 总是调用 error()，不返回
            error("%A->%s: %s" className(self) t_method apply('lsprintf t_formatString g_args))
        )
        self->mark = lambda(()  ; -> str | nil
            ; 记录时间点：首次调用记开始时间，再次调用记结束时间，此后无效果。
            ;
            ; **返回**
            ;   (str|nil) - 前两次调用返回当前时间串，此后返回 nil
            cond(
                (!_start_ts
                    _start_ts = getCurrentTime()
                )
                (!_end_ts
                    _end_ts = getCurrentTime()
                )
            )
        )
        self->getStart = lambda(()  ; -> str | nil
            ; 返回开始时间串；未开始返回 nil。
            ;
            ; **返回**
            ;   (str|nil) - mark() 首次调用记录的时间
            _start_ts
        )
        self->getEnd = lambda(()  ; -> str | nil
            ; 返回结束时间串；未结束返回 nil。
            ;
            ; **返回**
            ;   (str|nil) - mark() 再次调用记录的时间
            _end_ts
        )
        self->getSeconds = lambda(()  ; -> int
            ; 返回开始到结束的流逝秒数；起止未齐时 error() 中断（首次计算后缓存）。
            ;
            ; **返回**
            ;   (int) - compareTime(_end_ts _start_ts)
            unless(_second
                unless(_start_ts
                    _Error("getSeconds" "elapsed time has not been started")
                )
                unless(_end_ts
                    _Error("getSeconds" "elapsed time has not been ended")
                )
                _second = compareTime(_end_ts _start_ts)
            )
            _second
        )
        self->humanReadable = lambda(()  ; -> str
            ; 以人类可读格式返回耗时：0 秒为 ~0s，其余为 1s / 1m1s / 1h1m1s 风格。
            ;
            ; **返回**
            ;   (str) - 由 getSeconds() 换算，首次计算后缓存
            unless(_humanReadable
                _humanReadable = _FormatSeconds(self->getSeconds())
            )
            _humanReadable
        )
        t
    )
)
)


unuseNamespace("ycSubProcess")

; END
