;--------------------------
; Program  : ycIO(port.il)
; Language : Cadence Skill
;--------------------------

useNamespace("ycIO")


; ---------- class definitions ----------

defclass(_PortData () (
    ; _PortData 数据桶：Port 持有的原生 port、来源路径、打开模式与关闭标志；
    ; 构造后禁写 self->_data 及其字段（纪律非语言强制）。
    port(
        \@initarg port
        \@initform nil
    )
    path(
        \@initarg path
        \@initform ""
    )
    mode(
        \@initarg mode
        \@initform "r"
    )
    closed(
        \@initarg closed
        \@initform nil
    )
))

defclass(Port () (
    ; Port 实例：包装一个原生 file port，提供方法式读写与幂等关闭。
    _data(
        \@initarg _data
        \@initform nil
    )
    readLine()
    readAll()
    fscanf()
    write()
    flush()
    seek()
    tell()
    close()
    isClosed()
    port()
))


defmethod(printself (self(Port))  ; -> str
    ; 返回端口的打印描述串。
    ;
    ; **返回**
    ;   (str) - <ycIO::Port path="..." mode="r" closed=nil>
    lsprintf("<%A path=%A mode=%A closed=%A>" className(self)
        self->_data->path self->_data->mode self->_data->closed)
)

defmethod(__ycWithEnter__ (self(Port))  ; -> Port
    ; with 协议：进入作用域时返回端口自身。
    ;
    ; **返回**
    ;   (Port) - self
    self
)

defmethod(__ycWithExit__ (self(Port))  ; -> t
    ; with 协议：退出作用域时关闭端口。
    ;
    ; **返回**
    ;   (t) - close() 的返回值
    self->close()
)


; ---------- helpers ----------

procedure(_PortName(t_path "t")  ; -> str
    ; 把路径串规整为原生 port 函数可接受的形式。
    ;
    ; **参数**
    ;   t_path  (str) - 原始路径串
    ;
    ; **返回**
    ;   (str) - 以 "/"、"~"、"./" 或 "../" 开头的路径原样返回，相对路径补 "./" 前缀
    if(pcreMatchp("^[~/]|^\\.{1,2}/" t_path)
        t_path
        strcat("./" t_path)
    )
)


procedure(_ErrText(g_err "g")  ; -> str
    ; 从 errset.errset 提取错误消息。
    ;
    ; **参数**
    ;   g_err  (list|nil) - errset.errset
    ;
    ; **返回**
    ;   (str) - 错误消息；无法提取时返回通用说明
    if(g_err && 4 <= length(g_err) && car(car(cdr(cdr(cdr(cdr(g_err))))))
    then
        car(car(cdr(cdr(cdr(cdr(g_err))))))
    else
        "unknown port error"
    )
)


procedure(_PortError(g_obj t_method t_format \@rest l_args "gttg")  ; -> never
    ; 按 Port/StringPort 方法上下文报错。
    ;
    ; **参数**
    ;   g_obj     (Port|StringPort) - 端口对象
    ;   t_method  (str) - 方法名
    ;   t_format  (str) - 消息格式
    ;   l_args    (list) - 格式参数
    ;
    ; **返回**
    ;   (never) - 总是 error() 中断
    error("%A->%s: %s" className(g_obj) t_method
        apply('lsprintf t_format l_args))
)


procedure(_Fscanf(g_obj g_port t_format l_vars "ggtl")  ; -> int | nil
    ; 在原生 port 上执行 fscanf，变量名以符号列表传入。
    ;
    ; **参数**
    ;   g_obj     (Port|StringPort) - 端口对象
    ;   g_port    (port) - 原生 port
    ;   t_format  (str) - 格式串
    ;   l_vars    (list[symbol]) - 接收值的变量名
    ;
    ; **返回**
    ;   (int|nil) - 成功读取的项数；EOF 返回 nil
    unless(portp(g_port)
        _PortError(g_obj "fscanf" "not a native port")
    )
    when(l_vars
        unless(listp(l_vars)
            _PortError(g_obj "fscanf" "?l_vars must be a list of symbols")
        )
        foreach(var l_vars
            unless(symbolp(var)
                _PortError(g_obj "fscanf"
                    "?l_vars element must be a symbol, got %A" var)
            )
        )
    )
    let((res)
        res = errset(
            apply('fscanf cons(g_port cons(t_format l_vars)))
            nil
        )
        unless(res
            _PortError(g_obj "fscanf" "%s" _ErrText(errset.errset))
        )
        car(res)
    )
)


procedure(_Seek(g_obj g_port x_offset x_whence "ggxx")  ; -> t | nil
    ; 在原生 port 上执行 fileSeek。
    ;
    ; **参数**
    ;   g_obj     (Port|StringPort) - 端口对象
    ;   g_port    (port) - 原生 port
    ;   x_offset  (int) - 偏移量
    ;   x_whence  (int) - 0 起始、1 当前位置、2 末尾
    ;
    ; **返回**
    ;   (t|nil) - 原生 fileSeek 的返回值
    unless(portp(g_port)
        _PortError(g_obj "seek" "not a native port")
    )
    unless(x_whence == 0 || x_whence == 1 || x_whence == 2
        _PortError(g_obj "seek" "?whence must be 0, 1 or 2")
    )
    let((res)
        res = errset(fileSeek(g_port x_offset x_whence) nil)
        unless(res
            _PortError(g_obj "seek" "%s" _ErrText(errset.errset))
        )
        car(res)
    )
)


procedure(_Tell(g_obj g_port "gg")  ; -> int
    ; 在原生 port 上执行 fileTell。
    ;
    ; **参数**
    ;   g_obj   (Port|StringPort) - 端口对象
    ;   g_port  (port) - 原生 port
    ;
    ; **返回**
    ;   (int) - 当前字节偏移
    unless(portp(g_port)
        _PortError(g_obj "tell" "not a native port")
    )
    let((res)
        res = errset(fileTell(g_port) nil)
        unless(res
            _PortError(g_obj "tell" "%s" _ErrText(errset.errset))
        )
        car(res)
    )
)


; ---------- method installer ----------

inScheme(
procedure(_InstallPort(self "g")  ; -> t
    ; 把端口方法安装到 Port 类（由 initializeInstance 调用）。
    ;
    ; **返回**
    ;   (t) - 安装完成；调用方忽略

    self->readLine = lambda(()  ; -> str | nil
        ; 读取一行；保留行尾换行，EOF 返回 nil。
        ;
        ; **返回**
        ;   (str|nil) - 一行文本；已关闭时 error() 中断
        when(self->_data->closed
            error("%A->readLine: port is closed: %s"
                className(self) self->_data->path)
        )
        unless(self->_data->mode == "r"
            error("%A->readLine: port is not readable: %s"
                className(self) self->_data->path)
        )
        let((line)
            gets(line self->_data->port)
            line
        )
    )

    self->readAll = lambda(()  ; -> str
        ; 读取到 EOF；保留换行，空文件返回空串。
        ;
        ; **返回**
        ;   (str) - 文件剩余内容的拼接；已关闭时 error() 中断
        when(self->_data->closed
            error("%A->readAll: port is closed: %s"
                className(self) self->_data->path)
        )
        unless(self->_data->mode == "r"
            error("%A->readAll: port is not readable: %s"
                className(self) self->_data->path)
        )
        let((line res)
            while(gets(line self->_data->port)
                res = tconc(res line)
            )
            if(res
                buildString(car(res) "")
                ""
            )
        )
    )

    self->write = lambda((t_text "t")  ; -> self
        ; 写入字符串。
        ;
        ; **参数**
        ;   t_text  (str) - 写入内容
        ;
        ; **返回**
        ;   (Port) - self；已关闭时 error() 中断
        when(self->_data->closed
            error("%A->write: port is closed: %s"
                className(self) self->_data->path)
        )
        when(self->_data->mode == "r"
            error("%A->write: port is not writable: %s"
                className(self) self->_data->path)
        )
        fprintf(self->_data->port "%s" t_text)
        self
    )

    self->fscanf = lambda((t_format l_vars "tl")  ; -> int | nil
        ; 从端口按格式读取，变量名以符号列表传入。
        ;
        ; **参数**
        ;   t_format  (str) - 格式串
        ;   l_vars    (list[symbol]) - 接收值的变量名
        ;
        ; **返回**
        ;   (int|nil) - 成功读取的项数；EOF 返回 nil；已关闭或非读端口时 error() 中断
        when(self->_data->closed
            error("%A->fscanf: port is closed: %s"
                className(self) self->_data->path)
        )
        unless(self->_data->mode == "r"
            error("%A->fscanf: port is not readable: %s"
                className(self) self->_data->path)
        )
        _Fscanf(self self->_data->port t_format l_vars)
    )

    self->flush = lambda(()  ; -> self
        ; 把写入缓冲刷到文件；只读端口无操作。
        ;
        ; **返回**
        ;   (Port) - self；已关闭时 error() 中断
        when(self->_data->closed
            error("%A->flush: port is closed: %s" className(self) self->_data->path)
        )
        when(self->_data->mode != "r" && self->_data->port
            drain(self->_data->port)
        )
        self
    )

    self->seek = lambda((x_offset \@key (whence 0) "xx")  ; -> t | nil
        ; 移动端口位置，目标须落在文件范围内。
        ;
        ; **参数**
        ;   x_offset  (int) - 偏移量
        ;   ?whence x_whence (int) - 0 起始、1 当前位置、2 末尾（默认 0）
        ;
        ; **返回**
        ;   (t|nil) - 成功为 t；目标小于 0 或超出文件长度时为 nil；
        ;   已关闭或 ?whence 非法时 error() 中断
        when(self->_data->closed
            error("%A->seek: port is closed: %s"
                className(self) self->_data->path)
        )
        unless(whence == 0 || whence == 1 || whence == 2
            _PortError(self "seek" "?whence must be 0, 1 or 2")
        )
        let((cur end target)
            when(self->_data->mode != "r"
                drain(self->_data->port)
            )
            cur = _Tell(self self->_data->port)
            _Seek(self self->_data->port 0 2)
            end = _Tell(self self->_data->port)
            _Seek(self self->_data->port cur 0)
            target = case(whence
                (0 x_offset)
                (1 cur + x_offset)
                (2 end + x_offset)
            )
            if(target >= 0 && target <= end
            then
                _Seek(self self->_data->port target 0)
            else
                nil
            )
        )
    )

    self->tell = lambda(()  ; -> int
        ; 返回当前字节偏移，对应 fileTell。
        ;
        ; **返回**
        ;   (int) - 当前偏移；已关闭时 error() 中断
        when(self->_data->closed
            error("%A->tell: port is closed: %s"
                className(self) self->_data->path)
        )
        _Tell(self self->_data->port)
    )

    self->close = lambda(()  ; -> t
        ; 关闭原生端口；可重复调用。
        ;
        ; **返回**
        ;   (t) - 恒为 t
        unless(self->_data->closed
            when(self->_data->port
                unwindProtect(
                    close(self->_data->port)
                    self->_data->closed = t
                )
            )
            self->_data->closed = t
        )
        t
    )

    self->isClosed = lambda(()  ; -> t | nil
        ; 查询端口是否已关闭。
        ;
        ; **返回**
        ;   (t|nil) - 已关闭为 t
        self->_data->closed
    )

    self->port = lambda(()  ; -> port
        ; 返回底层原生 port。
        ;
        ; **返回**
        ;   (port) - 原生 file port；关闭后仍返回原对象
        self->_data->port
    )

    t
)
)


; ---------- constructor ----------

procedure(Open(t_path \@key (mode "r") "tt")  ; -> Port
    ; 打开文件并返回端口包装。
    ;
    ; **参数**
    ;   t_path  (str) - 文件路径
    ;   ?mode   (str) - 打开模式："r" 读取、"w" 截断写入、"a" 追加写入（默认 "r"）
    ;
    ; **返回**
    ;   (Port) - 新的端口包装；非法模式、打开失败时 error() 中断
    let((port2 name)
        unless(mode == "r" || mode == "w" || mode == "a"
            error("ycIO::Open: invalid mode: '%s'" mode)
        )
        when(t_path == ""
            error("ycIO::Open: empty path")
        )
        name = _PortName(t_path)
        when(mode == "r"
            when(isDir(name)
                error("ycIO::Open: is a directory: %s" t_path)
            )
        )
        port2 = if(mode == "r"
            infile(name)
            outfile(name mode)
        )
        unless(port2
            error("ycIO::Open: cannot open: %s" t_path)
        )
        makeInstance('Port ?_data makeInstance('_PortData
            ?port   port2
            ?path   t_path
            ?mode   mode
            ?closed nil))
    )
)


inScheme(
defmethod(initializeInstance (self(Port) \@rest _args)
    ; 构造 Port 实例时调用 _InstallPort 安装全部方法集。
    ;
    ; **参数**
    ;   _args  (list) - 变参：附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成后返回 t
    _InstallPort(self)
    t
)
)

unuseNamespace("ycIO")

; END
