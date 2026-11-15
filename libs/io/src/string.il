;--------------------------
; Program  : ycIO(string.il)
; Language : Cadence Skill
;--------------------------

useNamespace("ycIO")


defclass(_StringPortData () (
    ; _StringPortData 数据桶：内部 Port、方向与关闭时捕获的文本。
    port(
        \@initarg port
        \@initform nil
    )
    mode(
        \@initarg mode
        \@initform "r"
    )
    value(
        \@initarg value
        \@initform nil
    )
    text(
        \@initarg text
        \@initform nil
    )
    length(
        \@initarg length
        \@initform 0
    )
))


defclass(StringPort () (
    ; StringPort 字符串端口：读取由 FromString 构造，写入由 ToString 构造。
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
    text()
    close()
    isClosed()
    port()
))


defmethod(printself (self(StringPort))  ; -> str
    ; 返回字符串端口的打印描述串。
    ;
    ; **返回**
    ;   (str) - <ycIO::StringPort mode="r" closed=nil>
    lsprintf("<%A mode=%A closed=%A>" className(self)
        self->_data->mode self->_data->port->isClosed())
)


defmethod(__ycWithEnter__ (self(StringPort))  ; -> StringPort
    ; with 协议：进入作用域时返回字符串端口自身。
    ;
    ; **返回**
    ;   (StringPort) - self
    self
)


defmethod(__ycWithExit__ (self(StringPort))  ; -> t
    ; with 协议：退出作用域时关闭字符串端口。
    ;
    ; **返回**
    ;   (t) - close() 的返回值
    self->close()
)


procedure(_CheckStringPort(g_obj t_method g_need "gtg")  ; -> t
    ; 校验字符串端口未关闭且方向符合要求。
    ;
    ; **参数**
    ;   g_obj     (StringPort) - 字符串端口
    ;   t_method  (str) - 方法名
    ;   g_need    (str|nil) - "r" 读、"w" 写；nil 只检查关闭
    ;
    ; **返回**
    ;   (t) - 通过校验；否则 error() 中断
    when(g_obj->_data->port->isClosed()
        _PortError(g_obj t_method "port is closed")
    )
    when(g_need == "r"
        unless(g_obj->_data->mode == "r"
            _PortError(g_obj t_method "string port is not readable")
        )
    )
    when(g_need == "w"
        unless(g_obj->_data->mode == "w"
            _PortError(g_obj t_method "string port is not writable")
        )
    )
    t
)


procedure(_MakeStringInputPort(t_text "t")  ; -> Port
    ; 用字符串创建内部只读 Port。
    ;
    ; **参数**
    ;   t_text  (str) - 输入字符串
    ;
    ; **返回**
    ;   (Port) - 只读 Port；无法创建时 error() 中断
    let((port2)
        port2 = instring(t_text)
        unless(port2
            error("ycIO::StringPort: cannot open string input port")
        )
        makeInstance('Port ?_data makeInstance('_PortData
            ?port port2
            ?path "*string*"
            ?mode "r"
            ?closed nil))
    )
)


procedure(_MakeStringOutputPort()  ; -> Port
    ; 创建内部只写 Port。
    ;
    ; **返回**
    ;   (Port) - 只写 Port；无法创建时 error() 中断
    let((port2)
        port2 = outstring()
        unless(port2
            error("ycIO::StringPort: cannot open string output port")
        )
        makeInstance('Port ?_data makeInstance('_PortData
            ?port port2
            ?path "*string*"
            ?mode "w"
            ?closed nil))
    )
)


inScheme(
procedure(_InstallStringPort(self "g")  ; -> t
    ; 安装 StringPort 的全部方法。
    ;
    ; **返回**
    ;   (t) - 安装完成

    self->readLine = lambda(()  ; -> str | nil
        ; 读取一行；保留行尾换行，EOF 返回 nil。
        ;
        ; **返回**
        ;   (str|nil) - 一行文本；非读端口或已关闭时 error() 中断
        _CheckStringPort(self "readLine" "r")
        self->_data->port->readLine()
    )

    self->readAll = lambda(()  ; -> str
        ; 读取到 EOF；保留换行，空串返回空串。
        ;
        ; **返回**
        ;   (str) - 剩余内容；非读端口或已关闭时 error() 中断
        _CheckStringPort(self "readAll" "r")
        self->_data->port->readAll()
    )

    self->fscanf = lambda((t_format l_vars "tl")  ; -> int | nil
        ; 从字符串按格式读取，变量名以符号列表传入。
        ;
        ; **参数**
        ;   t_format  (str) - 格式串
        ;   l_vars    (list[symbol]) - 接收值的变量名
        ;
        ; **返回**
        ;   (int|nil) - 成功读取的项数；EOF 返回 nil；非读端口时 error() 中断
        _CheckStringPort(self "fscanf" "r")
        _Fscanf(self self->_data->port->port() t_format l_vars)
    )

    self->write = lambda((t_text "t")  ; -> self
        ; 写入字符串。
        ;
        ; **参数**
        ;   t_text  (str) - 写入内容
        ;
        ; **返回**
        ;   (StringPort) - self；非写端口或已关闭时 error() 中断
        _CheckStringPort(self "write" "w")
        self->_data->port->write(t_text)
        self
    )

    self->flush = lambda(()  ; -> self
        ; 刷新写缓冲；读端口上无操作。
        ;
        ; **返回**
        ;   (StringPort) - self；已关闭时 error() 中断
        _CheckStringPort(self "flush" nil)
        self->_data->port->flush()
        self
    )

    self->seek = lambda((x_offset \@key (whence 0) "xx")  ; -> t | nil
        ; 移动字符串端口位置。
        ;
        ; **参数**
        ;   x_offset  (int) - 偏移量
        ;   ?whence x_whence (int) - 0 起始、1 当前位置、2 末尾（默认 0）
        ;
        ; **返回**
        ;   (t|nil) - 成功为 t；失败为 nil；writer 仅支持 0
        _CheckStringPort(self "seek" nil)
        unless(whence == 0 || whence == 1 || whence == 2
            _PortError(self "seek" "?whence must be 0, 1 or 2")
        )
        when(self->_data->mode == "w" && whence != 0
            _PortError(self "seek"
                "string writer only supports absolute seek (whence 0)")
        )
        if(self->_data->mode == "r"
        then
            let((pos target)
                pos = _Tell(self self->_data->port->port())
                when(pos > self->_data->length
                    pos = self->_data->length
                )
                target = case(whence
                    (0 x_offset)
                    (1 pos + x_offset)
                    (2 self->_data->length + x_offset)
                )
                if(fixp(target) && target >= 0 && target <= self->_data->length
                then
                    self->_data->port->close()
                    self->_data->port = _MakeStringInputPort(self->_data->text)
                    _Seek(self self->_data->port->port() target 0)
                else
                    nil
                )
            )
        else
            let((pos)
                pos = _Tell(self self->_data->port->port())
                if(x_offset == pos
                    t
                    _Seek(self self->_data->port->port() x_offset 0)
                )
            )
        )
    )

    self->tell = lambda(()  ; -> int
        ; 返回当前字节偏移。
        ;
        ; **返回**
        ;   (int) - 当前偏移；已关闭时 error() 中断
        _CheckStringPort(self "tell" nil)
        let((pos)
            pos = _Tell(self self->_data->port->port())
            if(self->_data->mode == "r" && pos > self->_data->length
                self->_data->length
                pos
            )
        )
    )

    self->text = lambda(()  ; -> str
        ; 返回写入的文本；关闭后返回关闭时捕获的内容。
        ;
        ; **返回**
        ;   (str) - 写入内容；非写端口时 error() 中断
        unless(self->_data->mode == "w"
            _PortError(self "text" "text() is only available on a string writer")
        )
        if(self->_data->port->isClosed()
            self->_data->value
            getOutstring(self->_data->port->port())
        )
    )

    self->close = lambda(()  ; -> t
        ; 关闭字符串端口；writer 在关闭前捕获文本。
        ;
        ; **返回**
        ;   (t) - 恒为 t
        unless(self->_data->port->isClosed()
            when(self->_data->mode == "w"
                self->_data->value = getOutstring(self->_data->port->port())
            )
            self->_data->port->close()
        )
        t
    )

    self->isClosed = lambda(()  ; -> t | nil
        ; 查询字符串端口是否已关闭。
        ;
        ; **返回**
        ;   (t|nil) - 已关闭为 t
        self->_data->port->isClosed()
    )

    self->port = lambda(()  ; -> port
        ; 返回底层原生 port。
        ;
        ; **返回**
        ;   (port) - 原生 port；关闭后仍返回原对象
        self->_data->port->port()
    )

    t
)
)


procedure(FromString(t_text "t")  ; -> StringPort
    ; 从字符串创建只读端口。
    ;
    ; **参数**
    ;   t_text  (str) - 输入字符串
    ;
    ; **返回**
    ;   (StringPort) - 只读字符串端口；无法创建时 error() 中断
    let((port2)
        port2 = _MakeStringInputPort(t_text)
        makeInstance('StringPort ?_data makeInstance('_StringPortData
            ?port port2
            ?mode "r"
            ?text t_text
            ?length (length t_text)
        ))
    )
)


procedure(ToString()  ; -> StringPort
    ; 创建只写字符串端口。
    ;
    ; **返回**
    ;   (StringPort) - 只写字符串端口；无法创建时 error() 中断
    let((port2)
        port2 = _MakeStringOutputPort()
        makeInstance('StringPort ?_data makeInstance('_StringPortData
            ?port port2
            ?mode "w"
            ?text nil
            ?length 0
        ))
    )
)


inScheme(
defmethod(initializeInstance (self(StringPort) \@rest _args)
    ; 构造 StringPort 实例时安装方法。
    ;
    ; **参数**
    ;   _args  (list) - 附加参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成
    _InstallStringPort(self)
    t
)
)

unuseNamespace("ycIO")

; END
