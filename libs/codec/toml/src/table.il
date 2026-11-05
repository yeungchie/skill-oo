;--------------------------
; Program  : codec/toml(table.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::Require("ycCodec")

useNamespace("ycToml")

procedure(_AssignValue(t_s g_meta l_base g_obj l_path g_val n_pos n_max "tglglgxx")  ; -> t
    ; 将点分键值写入当前表；自动创建中间表并检测重复/冲突。
    ;
    ; **参数**
    ;   t_s      (str) - 输入串（错误定位）
    ;   g_meta   (table) - 路径元数据表
    ;   l_base   (list) - 当前表的规范路径
    ;   g_obj    (table) - 当前表
    ;   l_path   (list[str]) - 点分键路径
    ;   g_val    (any) - 待写入值
    ;   n_pos    (int) - 键起始位置
    ;   n_max    (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (t) - 写入成功
    let((cur i n key next tab kind)
        when(length(l_base) + length(l_path) > n_max
            _Error(t_s n_pos "nesting too deep")
        )
        cur = l_base
        i = 0
        n = length(l_path)
        foreach(key2 l_path
            i++
            if(i < n
            then
                if(!_HasKey(g_obj key2)
                then
                    tab = _NewTable()
                    g_obj[key2] = tab
                    _MetaSet(g_meta append1(cur key2) "dotted")
                    cur = append1(cur key2)
                    g_obj = tab
                else
                    next = g_obj[key2]
                    when(listp(next)
                        _Error(t_s n_pos "key path crosses an array")
                    )
                    unless(tablep(next)
                        _Error(t_s n_pos "key path crosses a value")
                    )
                    kind = _MetaGet(g_meta append1(cur key2))
                    when(kind == "inline"
                        _Error(t_s n_pos "cannot extend an inline table")
                    )
                    when(kind == "array"
                        _Error(t_s n_pos "key path crosses an array")
                    )
                    cur = append1(cur key2)
                    g_obj = next
                )
            else
                when(_HasKey(g_obj key2)
                    _Error(t_s n_pos "duplicate key")
                )
                g_obj[key2] = g_val
                _MarkInline(g_meta append1(cur key2) g_val)
            )
        )
        t
    )
)

procedure(_HeaderTarget(t_s g_root g_meta l_path n_pos g_array n_max "tgglxgx")  ; -> list
    ; 按表头路径定位目标表；普通表头与表数组分别处理。
    ;
    ; **参数**
    ;   t_s      (str) - 输入串
    ;   g_root   (table) - 文档根表
    ;   g_meta   (table) - 路径元数据表
    ;   l_path   (list[str]) - 表头键路径
    ;   n_pos    (int) - 表头起始位置
    ;   g_array  (t|nil) - t 时为 [[...]]
    ;   n_max    (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (list) - (目标表 规范路径)
    let((n i obj key val kind tab cur last has)
        when(length(l_path) > n_max
            _Error(t_s n_pos "nesting too deep")
        )
        n = length(l_path)
        i = 0
        obj = g_root
        cur = nil
        foreach(key2 l_path
            i++
            has = _HasKey(obj key2)
            val = obj[key2]
            if(i < n
            then
                if(!has
                then
                    tab = _NewTable()
                    obj[key2] = tab
                    _MetaSet(g_meta append1(cur key2) "implicit")
                    cur = append1(cur key2)
                    obj = tab
                else
                    if(listp(val)
                    then
                        kind = _MetaGet(g_meta append1(cur key2))
                        unless(kind == "array" && length(val) > 0
                            _Error(t_s n_pos "key path is not a table")
                        )
                        last = length(val)
                        cur = append1(append1(cur key2) last)
                        obj = nth(last - 1 val)
                    else
                        unless(tablep(val)
                            _Error(t_s n_pos "key path is not a table")
                        )
                        kind = _MetaGet(g_meta append1(cur key2))
                        when(kind == "inline"
                            _Error(t_s n_pos "cannot extend an inline table")
                        )
                        when(kind == "array"
                            _Error(t_s n_pos "key path is not a table")
                        )
                        cur = append1(cur key2)
                        obj = val
                    )
                )
            else
                if(g_array
                    if(!has
                    then
                        tab = _NewTable()
                        obj[key2] = list(tab)
                        _MetaSet(g_meta append1(cur key2) "array")
                        _MetaSet(g_meta append1(append1(cur key2) 1) "explicit")
                        cur = append1(append1(cur key2) 1)
                        obj = tab
                    else
                        if(listp(val)
                        then
                            kind = _MetaGet(g_meta append1(cur key2))
                            unless(kind == "array"
                                _Error(t_s n_pos "key is not an array of tables")
                            )
                            tab = _NewTable()
                            obj[key2] = append1(val tab)
                            last = length(obj[key2])
                            _MetaSet(g_meta append1(append1(cur key2) last) "explicit")
                            cur = append1(append1(cur key2) last)
                            obj = tab
                        else
                            _Error(t_s n_pos "key is not an array of tables")
                        )
                    )
                    if(!has
                    then
                        tab = _NewTable()
                        obj[key2] = tab
                        _MetaSet(g_meta append1(cur key2) "explicit")
                        cur = append1(cur key2)
                        obj = tab
                    else
                        unless(tablep(val)
                            _Error(t_s n_pos "key is not a table")
                        )
                        kind = _MetaGet(g_meta append1(cur key2))
                        cond(
                            (kind == "implicit"
                                _MetaSet(g_meta append1(cur key2) "explicit")
                            )
                            (kind == "explicit"
                                _Error(t_s n_pos "table already defined")
                            )
                            (kind == "dotted"
                                _Error(t_s n_pos "table already defined")
                            )
                            (kind == "inline"
                                _Error(t_s n_pos "cannot extend an inline table")
                            )
                            (t
                                _Error(t_s n_pos "table already defined")
                            )
                        )
                        cur = append1(cur key2)
                        obj = val
                    )
                )
            )
        )
        list(obj cur)
    )
)

unuseNamespace("ycToml")

; END
