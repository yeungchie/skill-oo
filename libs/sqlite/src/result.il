useNamespace("ycSQLite")


defclass(_ResultData () (
    ; _ResultData 数据桶：列名、行、影响行数与最近插入 rowid。
    columns(
        \@initarg columns
        \@initform nil
    )
    rows(
        \@initarg rows
        \@initform nil
    )
    changes(
        \@initarg changes
        \@initform 0
    )
    lastInsertRowid(
        \@initarg lastInsertRowid
        \@initform nil
    )
))

defclass(Result () (
    ; Result 不可变结果集：查询行或 DML 的 changes / lastInsertRowid。
    _data(
        \@initarg _data
        \@initform nil
    )
    columns()
    rows()
    rowCount()
    isEmpty()
    changes()
    lastInsertRowid()
    toList()
))


defmethod(printself (self(Result))  ; -> str
    ; 返回结果集的打印描述串。
    ;
    ; **返回**
    ;   (str) - <ycSQLite::Result rows=N changes=M>
    lsprintf("<%A rows=%d changes=%d>" className(self)
        self->rowCount() self->changes())
)


inScheme(
procedure(_InstallResult(self "g")  ; -> t
    ; 安装 Result 的全部方法。
    ;
    ; **返回**
    ;   (t) - 安装完成
    self->columns = lambda(()  ; -> list[str] | nil
        ; 返回列名列表。
        ;
        ; **返回**
        ;   (list[str]|nil) - 列名；无列信息时为 nil
        when(self->_data->columns
            copy(self->_data->columns)
        )
    )
    self->rows = lambda(()  ; -> list[Row]
        ; 返回结果行列表浅拷贝。
        ;
        ; **返回**
        ;   (list[Row]) - 行对象列表
        when(self->_data->rows copy(self->_data->rows))
    )
    self->rowCount = lambda(()  ; -> int
        ; 返回数据行数。
        ;
        ; **返回**
        ;   (int) - 行数
        length(self->_data->rows)
    )
    self->isEmpty = lambda(()  ; -> t | nil
        ; 查询是否没有数据行。
        ;
        ; **返回**
        ;   (t|nil) - 无行时为 t
        !self->_data->rows
    )
    self->changes = lambda(()  ; -> int
        ; 返回最近一次 DML 影响行数。
        ;
        ; **返回**
        ;   (int) - 影响行数
        self->_data->changes
    )
    self->lastInsertRowid = lambda(()  ; -> int | str | nil
        ; 返回最近插入 rowid。
        ;
        ; **返回**
        ;   (int|str|nil) - 无法用 32 位 fixnum 表示时为十进制字符串
        self->_data->lastInsertRowid
    )
    self->toList = lambda(()  ; -> list[list]
        ; 返回行值列表。
        ;
        ; **返回**
        ;   (list[list]) - 每行的值列表
        let((res)
            foreach(row self->_data->rows
                res = tconc(res row->toList())
            )
            car(res)
        )
    )
    t
)
)


procedure(_CheckResultParts(l_columns l_rows n_changes "lln")  ; -> t
    ; 校验结果集构造参数。
    ;
    ; **参数**
    ;   l_columns  (list[str]|nil) - 列名
    ;   l_rows     (list[Row]|nil) - 行
    ;   n_changes  (int) - 影响行数
    ;
    ; **返回**
    ;   (t) - 合法；否则 error() 中断
    when(l_columns
        unless(listp(l_columns)
            error("ycSQLite::Result: columns must be a list or nil, got %A"
                l_columns)
        )
        for(i 1 length(l_columns)
            unless(stringp(nth(i - 1 l_columns))
                error("ycSQLite::Result: column %d must be a string, got %A"
                    i nth(i - 1 l_columns))
            )
        )
    )
    when(l_rows
        unless(listp(l_rows)
            error("ycSQLite::Result: rows must be a list or nil, got %A" l_rows)
        )
        for(i 1 length(l_rows)
            unless(className(nth(i - 1 l_rows)) == 'ycSQLite::Row
                error("ycSQLite::Result: row %d must be ycSQLite::Row, got %A"
                    i nth(i - 1 l_rows))
            )
        )
    )
    unless(fixp(n_changes) && n_changes >= 0
        error("ycSQLite::Result: changes must be a non-negative integer, got %A"
            n_changes)
    )
    t
)


procedure(Result(\@key (columns nil) (rows nil) (changes 0) (lastInsertRowid nil) "gggg")  ; -> Result
    ; 构造不可变结果集。
    ;
    ; **参数**
    ;   ?columns          (list[str]|nil) - 列名
    ;   ?rows             (list[Row]|nil) - 数据行
    ;   ?changes          (int) - 最近 DML 影响行数，默认 0
    ;   ?lastInsertRowid  (int|str|nil) - 最近插入 rowid
    ;
    ; **返回**
    ;   (Result) - 新结果集；类型非法时 error() 中断
    _CheckResultParts(columns rows changes)
    makeInstance('Result ?_data makeInstance('_ResultData
        ?columns if(columns copy(columns) nil)
        ?rows if(rows copy(rows) nil)
        ?changes changes
        ?lastInsertRowid lastInsertRowid
    ))
)


inScheme(
defmethod(initializeInstance (self(Result) \@rest _args)
    ; 构造 Result 实例时安装全部方法。
    ;
    ; **参数**
    ;   _args  (list) - 附加参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成
    _InstallResult(self)
    t
)
)

unuseNamespace("ycSQLite")

; END
