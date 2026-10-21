ycNamespace:::require("ycCodec")

useNamespace("ycCsv")

; ---------- 共享值 ----------

procedure(_missing()  ; -> any
    ; 返回 ycCodec 的缺键哨兵；供 Table 方法在 lambda 内使用。
    ;
    ; **返回**
    ;   (any) - ycCodec::Missing 唯一实例
    ycCodec:::Missing
)

; ---------- Table 类型 ----------

defclass(TableData () (
    ; TableData 数据桶：收纳表头、行列表与列名索引，构造后禁写。
    header(
        \@initarg header
        \@initform nil
    )
    rows(
        \@initarg rows
        \@initform nil
    )
    index(
        \@initarg index
        \@initform nil
    )
))

defclass(Table () (
    ; Table 实例：不可变 CSV 表格（可选表头 + 字符串行），行列均 1-based。
    ; 状态桶（TableData：header + rows + index），构造后禁写。
    _data(
        \@initarg _data
        \@initform nil
    )

    rowCount()
    columnCount()
    header()
    rows()
    row()
    cell()
    columnAt()
    value()
))

defmethod(printself (self(Table))  ; -> str
    ; 返回 Table 的打印描述串，形如 <ycCsv::Table rows=2 columns=3>。
    ;
    ; **返回**
    ;   (str) - lsprintf 按 <类名 rows=N columns=M> 模板生成
    lsprintf("<%A rows=%d columns=%d>" className(self) self->rowCount() self->columnCount())
)

inScheme(
defmethod(initializeInstance (self(Table) \@rest _args)
    ; 构造 Table 实例时安装方法集：rowCount/columnCount/header/rows/row/cell/columnAt/value。
    ;
    ; **参数**
    ;   _args  (list) - 变参：附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成后返回 t
    self->rowCount = lambda(()  ; -> int
        ; 返回数据行数。
        ;
        ; **返回**
        ;   (int) - 行数（空表为 0）
        length(self->_data->rows)
    )

    self->columnCount = lambda(()  ; -> int
        ; 返回列数：有表头时取列名数，否则取最长行宽。
        ;
        ; **返回**
        ;   (int) - 列数（空表为 0）
        if(self->_data->header
            length(self->_data->header)
            _maxWidth(self->_data->rows)
        )
    )

    self->header = lambda(()  ; -> list[str] | nil
        ; 返回表头列名列表；无表头返回 nil。
        ;
        ; **返回**
        ;   (list[str]|nil) - 内部表头列表，禁止原地修改
        self->_data->header
    )

    self->rows = lambda(()  ; -> list
        ; 返回数据行列表。
        ;
        ; **返回**
        ;   (list[list[str]]) - 内部行列表，禁止原地修改
        self->_data->rows
    )

    self->row = lambda((g_row "g")  ; -> list[str]
        ; 返回第 g_row 行（1-based）。
        ;
        ; **参数**
        ;   g_row  (int) - 行号（1-based）
        ;
        ; **返回**
        ;   (list[str]) - 该行字段列表；行号越界或非整数时报错
        unless(fixp(g_row) && 1 <= g_row && g_row <= length(self->_data->rows)
            error("%A->row: row index %A out of range" className(self) g_row)
        )
        nth(g_row - 1 self->_data->rows)
    )

    self->cell = lambda((g_row g_col "gg")  ; -> str | any
        ; 返回第 g_row 行第 g_col 列的值（1-based）。
        ;
        ; **参数**
        ;   g_row  (int) - 行号（1-based）
        ;   g_col  (int) - 列号（1-based）
        ;
        ; **返回**
        ;   (str|any) - 字段字符串；短行缺位为 ycCodec::Missing；
        ;               行/列越界或非整数时报错
        unless(fixp(g_row) && 1 <= g_row && g_row <= length(self->_data->rows)
            error("%A->cell: row index %A out of range" className(self) g_row)
        )
        unless(fixp(g_col) && 1 <= g_col && g_col <= self->columnCount()
            error("%A->cell: column index %A out of range" className(self) g_col)
        )
        let((l_row)
            l_row = nth(g_row - 1 self->_data->rows)
            if(g_col <= length(l_row)
                nth(g_col - 1 l_row)
                _missing()
            )
        )
    )

    self->columnAt = lambda((g_col "g")  ; -> list[str | any]
        ; 按列号取整列值（1-based）。
        ;
        ; **参数**
        ;   g_col  (int) - 列号（1-based）
        ;
        ; **返回**
        ;   (list) - 各行的字段值；短行缺位为 ycCodec::Missing；越界或非整数时报错
        unless(fixp(g_col) && 1 <= g_col && g_col <= self->columnCount()
            error("%A->columnAt: column index %A out of range" className(self) g_col)
        )
        let((l_res)
            foreach(l_row self->_data->rows
                l_res = tconc(l_res
                    if(g_col <= length(l_row)
                        nth(g_col - 1 l_row)
                        _missing()
                    )
                )
            )
            car(l_res)
        )
    )

    self->value = lambda((g_row g_name "gg")  ; -> str | any
        ; 按列名取第 g_row 行的值（1-based，需有表头）。
        ;
        ; **参数**
        ;   g_row   (int) - 行号（1-based）
        ;   g_name  (str) - 列名
        ;
        ; **返回**
        ;   (str|any) - 字段字符串；短行缺位为 ycCodec::Missing；
        ;               无表头、列名未知、行号越界或类型非法时报错
        unless(self->_data->header
            error("%A->value: table has no header" className(self))
        )
        unless(stringp(g_name)
            error("%A->value: column name must be a string" className(self))
        )
        let((n_col)
            n_col = self->_data->index[g_name]
            unless(n_col
                error("%A->value: unknown column name %A" className(self) g_name)
            )
            self->cell(g_row n_col)
        )
    )

    t
)
)

; ---------- 构造 ----------

procedure(_maxWidth(l_rows "l")  ; -> int
    ; 返回行列表中的最长行宽。
    ;
    ; **参数**
    ;   l_rows  (list[list[str]]) - 行列表
    ;
    ; **返回**
    ;   (int) - 最长行的字段数；空列表为 0
    let((n_max)
        n_max = 0
        foreach(l_row l_rows
            when(n_max < length(l_row)
                n_max = length(l_row)
            )
        )
        n_max
    )
)

procedure(Table(l_rows \@key (header nil) "gg")  ; -> Table
    ; 构造不可变 CSV 表格：校验行/表头并拷贝输入。
    ;
    ; **参数**
    ;   l_rows   (list[list[str]]) - 数据行；每行至少一个字符串字段
    ;   ?header  (list[str]|nil) - 可选表头列名，须唯一；默认 nil
    ;
    ; **返回**
    ;   (Table) - 新实例；行/表头类型非法、空行、重复列名或行宽超过表头时报错
    let((l_names l_index n_width)
        l_names = _checkHeader(header "ycCsv::Table")
        l_rows = _copyRows(_checkRows(l_rows "ycCsv::Table"))
        when(l_names
            n_width = length(l_names)
            for(n_i 1 length(l_rows)
                when(n_width < length(nth(n_i - 1 l_rows))
                    error("ycCsv::Table: row %d has %d fields but header has %d"
                        n_i length(nth(n_i - 1 l_rows)) n_width)
                )
            )
            l_index = makeTable("ycCsvIndex" nil)
            for(n_i 1 n_width
                l_index[nth(n_i - 1 l_names)] = n_i
            )
        )
        makeInstance('Table ?_data
            makeInstance('TableData ?header l_names ?rows l_rows ?index l_index)
        )
    )
)

unuseNamespace("ycCsv")

; END
