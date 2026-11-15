useNamespace("ycSQLite")


defclass(_BlobData () (
    ; _BlobData 数据桶：保存 BLOB 的十六进制文本。
    hex(
        \@initarg hex
        \@initform ""
    )
))

defclass(Blob () (
    ; Blob 不可变二进制值：内部保存十六进制文本，避免 SKILL 字符串承载任意字节。
    _data(
        \@initarg _data
        \@initform nil
    )
    hex()
    size()
    toList()
))


defmethod(printself (self(Blob))  ; -> str
    ; 返回 BLOB 的打印描述串。
    ;
    ; **返回**
    ;   (str) - <ycSQLite::Blob size=N>
    lsprintf("<%A size=%d>" className(self) self->size())
)


procedure(_CheckHex(t_hex "t")  ; -> str
    ; 校验十六进制文本并返回原串。
    ;
    ; **参数**
    ;   t_hex  (str) - 十六进制文本
    ;
    ; **返回**
    ;   (str) - 原串；奇数长度或含非十六进制字符时 error() 中断
    unless(stringp(t_hex)
        error("ycSQLite::Blob: ?hex must be a string, got %A" t_hex)
    )
    unless(remainder(length(t_hex) 2) == 0
        error("ycSQLite::Blob: hex length must be even, got %d" length(t_hex))
    )
    for(i 1 length(t_hex)
        _HexValue(substring(t_hex i 1) "ycSQLite::Blob")
    )
    t_hex
)


inScheme(
procedure(_InstallBlob(self "g")  ; -> t
    ; 安装 Blob 的全部方法。
    ;
    ; **返回**
    ;   (t) - 安装完成
    self->hex = lambda(()  ; -> str
        ; 返回十六进制文本。
        ;
        ; **返回**
        ;   (str) - 十六进制文本
        self->_data->hex
    )
    self->size = lambda(()  ; -> int
        ; 返回字节数。
        ;
        ; **返回**
        ;   (int) - 字节数
        length(self->_data->hex) / 2
    )
    self->toList = lambda(()  ; -> list[int]
        ; 返回字节值列表。
        ;
        ; **返回**
        ;   (list[int]) - 每个字节的 0..255 值
        let((res text hi lo)
            text = self->_data->hex
            for(i 1 length(text) / 2
                hi = _HexValue(substring(text i * 2 - 1 1) "ycSQLite::Blob")
                lo = _HexValue(substring(text i * 2 1) "ycSQLite::Blob")
                res = tconc(res hi * 16 + lo)
            )
            car(res)
        )
    )
    t
)
)


procedure(Blob(t_hex "t")  ; -> Blob
    ; 由十六进制文本构造不可变 BLOB。
    ;
    ; **参数**
    ;   t_hex  (str) - 十六进制文本，长度必须为偶数
    ;
    ; **返回**
    ;   (Blob) - 新的 BLOB 对象；格式非法时 error() 中断
    makeInstance('Blob ?_data makeInstance('_BlobData ?hex _CheckHex(t_hex)))
)


inScheme(
defmethod(initializeInstance (self(Blob) \@rest _args)
    ; 构造 Blob 实例时安装全部方法。
    ;
    ; **参数**
    ;   _args  (list) - 附加参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成
    _InstallBlob(self)
    t
)
)

unuseNamespace("ycSQLite")

; END
