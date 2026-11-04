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
    write()
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
        let((t_line)
            gets(t_line self->_data->port)
            t_line
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
        let((t_line l_res)
            while(gets(t_line self->_data->port)
                l_res = tconc(l_res t_line)
            )
            if(l_res
                buildString(car(l_res) "")
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
        fprintf(self->_data->port "%s" t_text)
        self
    )

    self->close = lambda(()  ; -> t
        ; 关闭原生端口；可重复调用。
        ;
        ; **返回**
        ;   (t) - 恒为 t
        unless(self->_data->closed
            when(self->_data->port
                close(self->_data->port)
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
    let((g_port)
        unless(mode == "r" || mode == "w" || mode == "a"
            error("ycIO::Open: invalid mode: '%s'" mode)
        )
        g_port = if(mode == "r"
            infile(_PortName(t_path))
            outfile(_PortName(t_path) mode)
        )
        unless(g_port
            error("ycIO::Open: cannot open: %s" t_path)
        )
        makeInstance('Port ?_data makeInstance('_PortData
            ?port   g_port
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
