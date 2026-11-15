useNamespace("ycSQLite")


defclass(_RowData () (
    ; _RowData 数据桶：行值、列名与列名到索引的映射。
    values(
        \@initarg values
        \@initform nil
    )
    columns(
        \@initarg columns
        \@initform nil
    )
    index(
        \@initarg index
        \@initform nil
    )
))

defclass(Row () (
    ; Row 不可变结果行：按列顺序保存值，并可按 0-based 索引或列名读取。
    _data(
        \@initarg _data
        \@initform nil
    )
    size()
    get()
    has()
    toList()
    toAlist()
))


procedure(_CheckRowParts(l_values l_columns "ll")  ; -> t
    ; 校验行值与列名列表。
    ;
    ; **参数**
    ;   l_values   (list) - 行值
    ;   l_columns  (list[str]) - 列名
    ;
    ; **返回**
    ;   (t) - 合法；类型或宽度不匹配时 error() 中断
    unless(listp(l_values)
        error("ycSQLite::Row: values must be a list, got %A" l_values)
    )
    unless(listp(l_columns)
        error("ycSQLite::Row: columns must be a list, got %A" l_columns)
    )
    unless(length(l_values) == length(l_columns)
        error("ycSQLite::Row: values and columns differ in size (%d vs %d)"
            length(l_values) length(l_columns))
    )
    for(i 1 length(l_columns)
        unless(stringp(nth(i - 1 l_columns))
            error("ycSQLite::Row: column %d must be a string, got %A"
                i nth(i - 1 l_columns))
        )
    )
    t
)


defmethod(printself (self(Row))  ; -> str
    ; 返回行的打印描述串。
    ;
    ; **返回**
    ;   (str) - <ycSQLite::Row columns=N>
    lsprintf("<%A columns=%d>" className(self) self->size())
)


inScheme(
procedure(_InstallRow(self "g")  ; -> t
    ; 安装 Row 的全部方法。
    ;
    ; **返回**
    ;   (t) - 安装完成
    self->size = lambda(()  ; -> int
        ; 返回列数。
        ;
        ; **返回**
        ;   (int) - 列数
        length(self->_data->values)
    )
    self->get = lambda((g_key "g")  ; -> any
        ; 按 0-based 索引或列名读取值。
        ;
        ; **参数**
        ;   g_key  (int|str) - 索引或列名
        ;
        ; **返回**
        ;   (any) - 对应值；索引/列名不存在时 error() 中断
        cond(
            (fixp(g_key)
                when(g_key < 0 || g_key >= length(self->_data->values)
                    error("%A->get: index %d out of range (size %d)"
                        className(self) g_key length(self->_data->values))
                )
                nth(g_key self->_data->values)
            )
            (stringp(g_key)
                let((idx)
                    idx = self->_data->index[g_key]
                    when(idx == nil
                        error("%A->get: unknown column name %A" className(self) g_key)
                    )
                    nth(idx self->_data->values)
                )
            )
            (t
                error("%A->get: key must be an integer or string, got %A"
                    className(self) g_key)
            )
        )
    )
    self->has = lambda((g_key "g")  ; -> t | nil
        ; 查询索引或列名是否存在。
        ;
        ; **参数**
        ;   g_key  (int|str) - 索引或列名
        ;
        ; **返回**
        ;   (t|nil) - 存在为 t
        cond(
            (fixp(g_key)
                0 <= g_key && g_key < length(self->_data->values)
            )
            (stringp(g_key)
                self->_data->index[g_key] != nil
            )
            (t nil)
        )
    )
    self->toList = lambda(()  ; -> list
        ; 返回按列顺序排列的值浅拷贝。
        ;
        ; **返回**
        ;   (list) - 值列表
        when(self->_data->values copy(self->_data->values))
    )
    self->toAlist = lambda(()  ; -> list
        ; 返回 (("column" value) ...) 形式的关联列表。
        ;
        ; **返回**
        ;   (list) - 列名与值的二元列表
        let((res column value)
            for(i 1 length(self->_data->columns)
                column = nth(i - 1 self->_data->columns)
                value = nth(i - 1 self->_data->values)
                res = tconc(res list(column value))
            )
            car(res)
        )
    )
    t
)
)


procedure(Row(l_values l_columns "ll")  ; -> Row
    ; 构造不可变结果行。
    ;
    ; **参数**
    ;   l_values   (list) - 行值
    ;   l_columns  (list[str]) - 列名
    ;
    ; **返回**
    ;   (Row) - 新行对象；类型或宽度不匹配时 error() 中断
    let((index)
        _CheckRowParts(l_values l_columns)
        index = makeTable("ycSQLiteRow" nil)
        for(i 1 length(l_columns)
            index[nth(i - 1 l_columns)] = i - 1
        )
        makeInstance('Row ?_data makeInstance('_RowData
            ?values copy(l_values)
            ?columns copy(l_columns)
            ?index index
        ))
    )
)


inScheme(
defmethod(initializeInstance (self(Row) \@rest _args)
    ; 构造 Row 实例时安装全部方法。
    ;
    ; **参数**
    ;   _args  (list) - 附加参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成
    _InstallRow(self)
    t
)
)

unuseNamespace("ycSQLite")

; END
