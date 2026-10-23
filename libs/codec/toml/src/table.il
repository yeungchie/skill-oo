;--------------------------
; Program  : codec/toml(table.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::Require("ycCodec")

useNamespace("ycToml")

procedure(_AssignValue(t_s t_meta l_base t_obj l_path g_val n_pos n_max "tglglgxx")  ; -> t
    ; 将点分键值写入当前表；自动创建中间表并检测重复/冲突。
    ;
    ; **参数**
    ;   t_s      (str) - 输入串（错误定位）
    ;   t_meta   (table) - 路径元数据表
    ;   l_base   (list) - 当前表的规范路径
    ;   t_obj    (table) - 当前表
    ;   l_path   (list[str]) - 点分键路径
    ;   g_val    (any) - 待写入值
    ;   n_pos    (int) - 键起始位置
    ;   n_max    (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (t) - 写入成功
    let((l_cur n_i n_n t_key g_next t_tab t_kind)
        when(length(l_base) + length(l_path) > n_max
            _Error(t_s n_pos "nesting too deep")
        )
        l_cur = l_base
        n_i = 0
        n_n = length(l_path)
        foreach(t_key l_path
            n_i = n_i + 1
            if(n_i < n_n
                if(!_HasKey(t_obj t_key)
                    {
                    t_tab = _NewTable()
                    t_obj[t_key] = t_tab
                    _MetaSet(t_meta append1(l_cur t_key) "dotted")
                    l_cur = append1(l_cur t_key)
                    t_obj = t_tab
                    }
                    {
                    g_next = t_obj[t_key]
                    when(listp(g_next)
                        _Error(t_s n_pos "key path crosses an array")
                    )
                    unless(tablep(g_next)
                        _Error(t_s n_pos "key path crosses a value")
                    )
                    t_kind = _MetaGet(t_meta append1(l_cur t_key))
                    when(t_kind == "inline"
                        _Error(t_s n_pos "cannot extend an inline table")
                    )
                    when(t_kind == "array"
                        _Error(t_s n_pos "key path crosses an array")
                    )
                    l_cur = append1(l_cur t_key)
                    t_obj = g_next
                    }
                )
                {
                when(_HasKey(t_obj t_key)
                    _Error(t_s n_pos "duplicate key")
                )
                t_obj[t_key] = g_val
                _MarkInline(t_meta append1(l_cur t_key) g_val)
                }
            )
        )
        t
    )
)

procedure(_HeaderTarget(t_s t_root t_meta l_path n_pos g_array n_max "tgglxgx")  ; -> list
    ; 按表头路径定位目标表；普通表头与表数组分别处理。
    ;
    ; **参数**
    ;   t_s      (str) - 输入串
    ;   t_root   (table) - 文档根表
    ;   t_meta   (table) - 路径元数据表
    ;   l_path   (list[str]) - 表头键路径
    ;   n_pos    (int) - 表头起始位置
    ;   g_array  (t|nil) - t 时为 [[...]]
    ;   n_max    (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (list) - (目标表 规范路径)
    let((n_n n_i t_obj t_key g_val t_kind t_tab l_cur n_last g_has)
        when(length(l_path) > n_max
            _Error(t_s n_pos "nesting too deep")
        )
        n_n = length(l_path)
        n_i = 0
        t_obj = t_root
        l_cur = nil
        foreach(t_key l_path
            n_i = n_i + 1
            g_has = _HasKey(t_obj t_key)
            g_val = t_obj[t_key]
            if(n_i < n_n
                if(!g_has
                    {
                    t_tab = _NewTable()
                    t_obj[t_key] = t_tab
                    _MetaSet(t_meta append1(l_cur t_key) "implicit")
                    l_cur = append1(l_cur t_key)
                    t_obj = t_tab
                    }
                    {
                    if(listp(g_val)
                        {
                        t_kind = _MetaGet(t_meta append1(l_cur t_key))
                        unless(t_kind == "array" && length(g_val) > 0
                            _Error(t_s n_pos "key path is not a table")
                        )
                        n_last = length(g_val)
                        l_cur = append1(append1(l_cur t_key) n_last)
                        t_obj = nth(n_last - 1 g_val)
                        }
                        {
                        unless(tablep(g_val)
                            _Error(t_s n_pos "key path is not a table")
                        )
                        t_kind = _MetaGet(t_meta append1(l_cur t_key))
                        when(t_kind == "inline"
                            _Error(t_s n_pos "cannot extend an inline table")
                        )
                        when(t_kind == "array"
                            _Error(t_s n_pos "key path is not a table")
                        )
                        l_cur = append1(l_cur t_key)
                        t_obj = g_val
                        }
                    )
                    }
                )
                {
                if(g_array
                    if(!g_has
                        {
                        t_tab = _NewTable()
                        t_obj[t_key] = list(t_tab)
                        _MetaSet(t_meta append1(l_cur t_key) "array")
                        _MetaSet(t_meta append1(append1(l_cur t_key) 1) "explicit")
                        l_cur = append1(append1(l_cur t_key) 1)
                        t_obj = t_tab
                        }
                        {
                        if(listp(g_val)
                            {
                            t_kind = _MetaGet(t_meta append1(l_cur t_key))
                            unless(t_kind == "array"
                                _Error(t_s n_pos "key is not an array of tables")
                            )
                            t_tab = _NewTable()
                            t_obj[t_key] = append1(g_val t_tab)
                            n_last = length(t_obj[t_key])
                            _MetaSet(t_meta append1(append1(l_cur t_key) n_last) "explicit")
                            l_cur = append1(append1(l_cur t_key) n_last)
                            t_obj = t_tab
                            }
                            _Error(t_s n_pos "key is not an array of tables")
                        )
                        }
                    )
                    if(!g_has
                        {
                        t_tab = _NewTable()
                        t_obj[t_key] = t_tab
                        _MetaSet(t_meta append1(l_cur t_key) "explicit")
                        l_cur = append1(l_cur t_key)
                        t_obj = t_tab
                        }
                        {
                        unless(tablep(g_val)
                            _Error(t_s n_pos "key is not a table")
                        )
                        t_kind = _MetaGet(t_meta append1(l_cur t_key))
                        cond(
                            (t_kind == "implicit"
                                _MetaSet(t_meta append1(l_cur t_key) "explicit")
                            )
                            (t_kind == "explicit"
                                _Error(t_s n_pos "table already defined")
                            )
                            (t_kind == "dotted"
                                _Error(t_s n_pos "table already defined")
                            )
                            (t_kind == "inline"
                                _Error(t_s n_pos "cannot extend an inline table")
                            )
                            (t
                                _Error(t_s n_pos "table already defined")
                            )
                        )
                        l_cur = append1(l_cur t_key)
                        t_obj = g_val
                        }
                    )
                )
                }
            )
        )
        list(t_obj l_cur)
    )
)

unuseNamespace("ycToml")

; END
