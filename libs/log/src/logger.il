;--------------------------
; Program  : ycLog(logger.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::Require("ycDateTime")

useNamespace("ycLog")


; ---------- class definitions ----------

; 数据桶：Logger 的名称、级别与输出目标；构造后由 Logger 方法维护。
defclass(_LoggerData () (
    ; _LoggerData 数据桶：收纳 Logger 的名称、级别与输出目标，构造后由 Logger 方法维护。
    name(
        \@initarg name
        \@initform ""
    )
    level(
        \@initarg level
        \@initform 'info
    )
    file(
        \@initarg file
        \@initform nil
    )
    port(
        \@initarg port
        \@initform nil
    )
    console(
        \@initarg console
        \@initform t
    )
    flush(
        \@initarg flush
        \@initform t
    )
    timeFormat(
        \@initarg timeFormat
        \@initform "[%F %T]"
    )
))

defclass(Logger () (
    ; Logger 实例：分级日志器；状态收在 _LoggerData 中，级别与文件端口可由方法修改。
    _data(
        \@initarg _data
        \@initform nil
    )
    debug()
    info()
    warn()
    error()
    log()
    level()
    setLevel()
    flush()
    close()
))


defmethod(printself (self(Logger))  ; -> str
    ; 返回 Logger 的打印描述串。
    ;
    ; **返回**
    ;   (str) - <ycLog::Logger name="..." level=... file=...>
    lsprintf("<%A name=%A level=%A file=%A>" className(self)
        self->_data->name self->_data->level self->_data->file)
)

defmethod(__ycWithEnter__ (self(Logger))  ; -> Logger
    ; with 协议：进入作用域时返回 logger 自身。
    ;
    ; **返回**
    ;   (Logger) - self
    self
)

defmethod(__ycWithExit__ (self(Logger))  ; -> t
    ; with 协议：退出作用域时关闭文件端口。
    ;
    ; **返回**
    ;   (t) - close() 的返回值
    self->close()
)


; ---------- helpers ----------

procedure(_LevelParts(g_level "g")  ; -> list | nil
    ; 把级别映射为 (优先级 标签)；未知或非符号级别返回 nil。
    ;
    ; 形参按 any 接收：调用方可能传来错误类型的值，由本函数返回 nil 后
    ; 再用调用方的公开上下文报错，避免内部过程名出现在用户消息里。
    ;
    ; **参数**
    ;   g_level  (any) - 级别符号
    ;
    ; **返回**
    ;   (list|nil) - (int 优先级 str 标签)；未知级别 nil
    cond(
        (g_level == 'debug list(0 "DEBUG"))
        (g_level == 'info list(1 "INFO"))
        (g_level == 'warn list(2 "WARN"))
        (g_level == 'error list(3 "ERROR"))
        (t nil)
    )
)

procedure(_CheckFlag(g_value t_name t_ctx "gtt")  ; -> t | nil
    ; 校验 t/nil 开关选项。
    ;
    ; **参数**
    ;   g_value  (any) - 选项值
    ;   t_name   (str) - 选项名（不含 ?）
    ;   t_ctx    (str) - 错误上下文
    ;
    ; **返回**
    ;   (t|nil) - 原值；非 t/nil 时 error
    unless(g_value == t || g_value == nil
        error("%s: ?%s must be t or nil, got %A" t_ctx t_name g_value)
    )
    g_value
)

procedure(_LogLine(t_name s_level g_timeFormat t_msg "tsgt")  ; -> str
    ; 拼一行日志：可选时间戳、级别标签、可选名称与正文。
    ;
    ; **参数**
    ;   t_name        (str)     - 日志器名称；空串不显示名称段
    ;   s_level       (sym)     - 已校验的级别
    ;   g_timeFormat  (str|nil) - 时间戳模板；nil 不显示时间戳
    ;   t_msg         (str)     - 正文
    ;
    ; **返回**
    ;   (str) - 形如 `[时间] [INFO] [名称] 正文`
    let((tag stamp)
        tag = cadr(_LevelParts(s_level))
        stamp = if(g_timeFormat
            lsprintf("%s " ycDateTime:::Current()->format(g_timeFormat))
            "")
        lsprintf("%s[%s]%s %s" stamp tag
            if(t_name == "" "" lsprintf(" [%s]" t_name))
            t_msg)
    )
)


; ---------- method installer ----------

inScheme(
procedure(_InstallLogger(self "g")  ; -> t
    ; 把日志方法安装到 Logger 类（由 initializeInstance 调用）。
    ;
    ; **返回**
    ;   (t) - 安装完成；调用方忽略

procedure(_emit(t_method s_level t_fmt l_args)  ; -> Logger
    ; 按级别写一条记录；低于阈值时直接返回。
    ;
    ; 方法 lambda 捕获闭包变量且带 @rest 时 argstring 不生效（引擎行为），
    ; 故格式串类型在这里按方法名手工校验，保证错误消息是公开上下文。
    ;
    ; **参数**
    ;   t_method  (str)  - 方法名（用于错误上下文）
    ;   s_level   (sym)  - 级别
    ;   t_fmt     (str)  - 格式串或正文
    ;   l_args    (list) - 格式参数
    ;
    ; **返回**
    ;   (Logger) - self
    let((parts line msg)
        unless(stringp(t_fmt)
            error("%A->%s: message must be a string, got %A"
                className(self) t_method t_fmt)
        )
        parts = _LevelParts(s_level)
        unless(parts
            error("%A->%s: unknown level %A, expected debug, info, warn or error"
                className(self) t_method s_level)
        )
        when(car(parts) >= car(_LevelParts(self->_data->level))
            msg = if(l_args apply('lsprintf t_fmt l_args) t_fmt)
            line = _LogLine(self->_data->name s_level self->_data->timeFormat msg)
            when(self->_data->console
                printf("%s\n" line)
            )
            when(self->_data->port
                fprintf(self->_data->port "%s\n" line)
                when(self->_data->flush
                    drain(self->_data->port)
                )
            )
        )
        self
    )
)

self->debug = lambda((t_fmt \@rest l_args "tg")  ; -> self
    ; 写 DEBUG 级日志。
    ;
    ; **参数**
    ;   t_fmt   (str)  - 格式串或正文
    ;   l_args  (list) - 格式参数
    ;
    ; **返回**
    ;   (Logger) - self
    _emit("debug" 'debug t_fmt l_args)
)

self->info = lambda((t_fmt \@rest l_args "tg")  ; -> self
    ; 写 INFO 级日志。
    ;
    ; **参数**
    ;   t_fmt   (str)  - 格式串或正文
    ;   l_args  (list) - 格式参数
    ;
    ; **返回**
    ;   (Logger) - self
    _emit("info" 'info t_fmt l_args)
)

self->warn = lambda((t_fmt \@rest l_args "tg")  ; -> self
    ; 写 WARN 级日志。
    ;
    ; **参数**
    ;   t_fmt   (str)  - 格式串或正文
    ;   l_args  (list) - 格式参数
    ;
    ; **返回**
    ;   (Logger) - self
    _emit("warn" 'warn t_fmt l_args)
)

self->error = lambda((t_fmt \@rest l_args "tg")  ; -> self
    ; 写 ERROR 级日志。
    ;
    ; **参数**
    ;   t_fmt   (str)  - 格式串或正文
    ;   l_args  (list) - 格式参数
    ;
    ; **返回**
    ;   (Logger) - self
    _emit("error" 'error t_fmt l_args)
)

self->log = lambda((s_level t_fmt \@rest l_args "stg")  ; -> self
    ; 按运行期级别写日志。
    ;
    ; **参数**
    ;   s_level  (sym)  - 级别
    ;   t_fmt    (str)  - 格式串或正文
    ;   l_args   (list) - 格式参数
    ;
    ; **返回**
    ;   (Logger) - self；未知级别 error
    _emit("log" s_level t_fmt l_args)
)

self->level = lambda(()  ; -> sym
    ; 返回当前过滤阈值。
    ;
    ; **返回**
    ;   (sym) - debug / info / warn / error
    self->_data->level
)

self->setLevel = lambda((s_level "s")  ; -> self
    ; 修改过滤阈值。
    ;
    ; **参数**
    ;   s_level  (sym) - 新级别
    ;
    ; **返回**
    ;   (Logger) - self；未知级别 error
    unless(_LevelParts(s_level)
        error("%A->setLevel: unknown level %A, expected debug, info, warn or error"
            className(self) s_level)
    )
    self->_data->level = s_level
    self
)

self->flush = lambda(()  ; -> t
    ; 把文件缓冲落盘；未开文件时无操作。
    ;
    ; **返回**
    ;   (t) - 恒为 t
    when(self->_data->port
        drain(self->_data->port)
    )
    t
)

self->close = lambda(()  ; -> t
    ; 关闭文件端口；可重复调用，关闭后日志仍可写控制台。
    ;
    ; **返回**
    ;   (t) - 恒为 t
    when(self->_data->port
        close(self->_data->port)
        self->_data->port = nil
    )
    t
)

t
)
)


; ---------- constructor ----------

procedure(Logger(t_name \@key (level 'info) (file nil) (console t) (append t) (flush t) (timeFormat "[%F %T]") "tgggggg")  ; -> Logger
    ; 构造分级日志器。
    ;
    ; **参数**
    ;   t_name     (str)     - 日志器名称；空串不显示名称段
    ;   ?level     (sym)     - 过滤阈值；默认 'info
    ;   ?file      (str|nil) - 日志文件路径；默认 nil（不写文件）
    ;   ?console   (t|nil)   - 是否写 CIW/标准输出；默认 t
    ;   ?append    (t|nil)   - 文件以追加方式打开；默认 t
    ;   ?flush     (t|nil)   - 每条记录后立即落盘；默认 t
    ;   ?timeFormat (str|nil) - 时间戳模板；默认 "[%F %T]"，nil 关闭
    ;
    ; **返回**
    ;   (Logger) - 新日志器；参数非法或文件打不开时 error
    let((port)
        unless(_LevelParts(level)
            error("ycLog::Logger: unknown level %A, expected debug, info, warn or error" level)
        )
        _CheckFlag(console "console" "ycLog::Logger")
        _CheckFlag(append "append" "ycLog::Logger")
        _CheckFlag(flush "flush" "ycLog::Logger")
        when(file != nil && !stringp(file)
            error("ycLog::Logger: ?file must be a string or nil, got %A" file)
        )
        when(file == ""
            error("ycLog::Logger: ?file must not be empty")
        )
        when(timeFormat != nil && !stringp(timeFormat)
            error("ycLog::Logger: ?timeFormat must be a string or nil, got %A" timeFormat)
        )
        when(timeFormat == ""
            error("ycLog::Logger: ?timeFormat must not be empty; use nil to disable timestamps")
        )
        when(timeFormat
            unless(errset(ycDateTime:::Current()->format(timeFormat) nil)
                error("ycLog::Logger: invalid ?timeFormat %A" timeFormat)
            )
        )
        when(file
            port = outfile(file if(append "a" "w"))
            unless(port
                error("ycLog::Logger: cannot open log file %A" file)
            )
        )
        makeInstance('Logger ?_data makeInstance('_LoggerData
            ?name    t_name
            ?level   level
            ?file    file
            ?port    port
            ?console console
            ?flush      flush
            ?timeFormat timeFormat))
    )
)


inScheme(
defmethod(initializeInstance (self(Logger) \@rest _args)
    ; 构造 Logger 实例时调用 _InstallLogger 安装全部方法集。
    ;
    ; **参数**
    ;   _args  (list) - 变参：附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成后返回 t
    _InstallLogger(self)
    t
)
)

unuseNamespace("ycLog")

; END
