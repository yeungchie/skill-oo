ycNamespace:::Require("ycCodec" "ycTabulate")

useNamespace("ycCsv")

; ---------- 共享值 ----------

procedure(_Missing()  ; -> any
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
    render()
    print()
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
    ; 构造 Table 实例时安装方法集：rowCount/columnCount/header/rows/row/cell/columnAt/value/render/print。
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
            _MaxWidth(self->_data->rows)
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
                _Missing()
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
                        _Missing()
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

    _InstallRender(self)

    t
)
)

inScheme(
procedure(_InstallRender(self "g")  ; -> t
    ; 安装 render/print 方法（内部实现；供 initializeInstance 与 Table 构造器调用）。
    ;
    ; **参数**
    ;   self    (Table) - 目标实例
    ;
    ; **返回**
    ;   (t) - 安装完成
    self->render = lambda((\@key (format "simple") (align "left") (missingVal "") (maxColWidth nil) (unit "display") (ambiguous 1) "tgtgtx")  ; -> str
        ; 渲染美化表格文本；表头自动取自 Table，短行/Missing 填 missingVal。
        ;
        ; **参数**
        ;   ?format      (str) - 输出格式：plain/simple/grid/pipe；默认 "simple"
        ;   ?align       (str|list) - 对齐方式；默认 "left"
        ;   ?missingVal  (str) - 缺失单元格替代文本；默认 ""
        ;   ?maxColWidth (int|nil) - 单元格折行宽度；默认 nil
        ;   ?unit        (str) - 宽度单位；默认 "display"
        ;   ?ambiguous   (int) - East Asian Ambiguous 宽度；默认 1
        ;
        ; **返回**
        ;   (str) - ycTabulate::Render 生成的文本
        unless(fboundp('ycTabulate:::Render)
            error("%A->render: ycTabulate is not loaded - load it first" className(self))
        )
        apply('ycTabulate:::Render
            list(
                _RenderRows(self missingVal)
                '?headers self->header()
                '?format format
                '?align align
                '?missingVal missingVal
                '?maxColWidth maxColWidth
                '?unit unit
                '?ambiguous ambiguous
            )
        )
    )

    self->print = lambda((\@rest l_args "g")  ; -> t
        ; 打印美化表格文本并返回 t；参数原样透传给 render，空表不输出。
        ;
        ; **参数**
        ;   l_args  (list) - 原样透传给 render 的实参（?format、?align、?missingVal、?maxColWidth、?unit、?ambiguous；可全部省略）
        ;
        ; **返回**
        ;   (t) - 打印成功；ycTabulate 未加载或渲染失败时报错
        let((t_text)
            t_text = apply(self->render l_args)
            when(t_text != ""
                printf("%s\n" t_text)
            )
            t
        )
    )

    t
)
)

procedure(_RenderRows(g_self t_missing "gt")  ; -> list
    ; 将 CSV 行补齐为等宽单元格，并把 Missing 替换为 t_missing（内部实现）。
    ;
    ; **参数**
    ;   g_self    (Table) - 待渲染表格
    ;   t_missing (str) - 缺失单元格替代文本
    ;
    ; **返回**
    ;   (list) - 等宽行列表
    let((n_cols l_res l_row l_cells n_i g_cell)
        n_cols = g_self->columnCount()
        foreach(l_row g_self->rows()
            l_cells = nil
            for(n_i 1 n_cols
                g_cell = if(n_i <= length(l_row) nth(n_i - 1 l_row) _Missing())
                when(g_cell == _Missing()
                    g_cell = t_missing
                )
                l_cells = tconc(l_cells g_cell)
            )
            l_res = tconc(l_res car(l_cells))
        )
        car(l_res)
    )
)

; ---------- 构造 ----------


procedure(_MaxWidth(l_rows "l")  ; -> int
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

procedure(Table(l_rows \@key (header nil) "lg")  ; -> Table
    ; 构造不可变 CSV 表格：校验行/表头并拷贝输入。
    ;
    ; **参数**
    ;   l_rows   (list[list[str]]) - 数据行；每行至少一个字符串字段
    ;   ?header  (list[str]|nil) - 可选表头列名，须唯一；默认 nil
    ;
    ; **返回**
    ;   (Table) - 新实例；行/表头类型非法、空行、重复列名或行宽超过表头时报错
    let((l_names l_index n_width t_obj)
        l_names = _CheckHeader(header "ycCsv::Table")
        l_rows = _CopyRows(_CheckRows(l_rows "ycCsv::Table"))
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
        t_obj = makeInstance('Table ?_data
            makeInstance('TableData ?header l_names ?rows l_rows ?index l_index)
        )
        _InstallRender(t_obj)
        t_obj
    )
)

unuseNamespace("ycCsv")

; END
