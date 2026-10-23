;--------------------------
; Program  : codec/ini(encode.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::require("ycCodec")

useNamespace("ycIni")

procedure(_emitScalar(l_p t_obj g_key g_opt t_ctx "lgggt")  ; -> list
    ; 在行容器后追加一个 key = value 行。
    ;
    ; **参数**
    ;   l_p     (list) - tconc 行容器
    ;   t_obj   (table) - 键所在表
    ;   g_key   (any) - 键
    ;   g_opt   (table) - 编码选项
    ;   t_ctx   (str) - 错误前缀
    ;
    ; **返回**
    ;   (list) - 更新后的行容器
    tconc(l_p
        lsprintf("%s %s %s"
            _keyText(g_key g_opt)
            g_opt["delimiter"]
            _valueText(t_obj[g_key] t_ctx)
        )
    )
)

procedure(_emitSection(l_p t_obj g_key g_opt "lggg")  ; -> list
    ; 输出一个 INI 段：段头、空行分隔与段内标量键值。
    ;
    ; **参数**
    ;   l_p    (list) - tconc 行容器
    ;   t_obj  (table) - 根表
    ;   g_key  (any) - 段名键
    ;   g_opt  (table) - 编码选项
    ;
    ; **返回**
    ;   (list) - 更新后的行容器；段内嵌套表报错
    let((t_name t_sec l_keys g_val)
        t_name = _sectionText(g_key g_opt)
        when(car(l_p)
            l_p = tconc(l_p "")
        )
        l_p = tconc(l_p lsprintf("[%s]" t_name))
        t_sec = t_obj[g_key]
        l_keys = _tableKeys(t_sec g_opt "section")
        foreach(t_key l_keys
            g_val = t_sec[t_key]
            when(tablep(g_val)
                error("ycIni::encode: nested table in section %A is not supported" t_name)
            )
            l_p = _emitScalar(l_p t_sec t_key g_opt "ycIni::encode")
        )
        l_p
    )
)

procedure(encode(g_val \@key (sortKeys nil) (strict nil) (delimiter nil) (finalNewline t) "ggggg")  ; -> str
    ; 编码根 table 为 INI 文本。
    ;
    ; **参数**
    ;   g_val         (table) - 根表
    ;   ?sortKeys     (t|nil) - 根键、段名、段内键分别排序；默认 nil
    ;   ?strict       (t|nil) - t 时键必须为字符串；默认 nil
    ;   ?delimiter    (str) - 单字节分隔符；默认 "="
    ;   ?finalNewline (t|nil) - 非空输出末尾是否补换行；默认 t
    ;
    ; **返回**
    ;   (str) - INI 文本；不可表示或根不是 table 时以 error() 中断
    unless(tablep(g_val)
        error("ycIni::encode: root value must be a table")
    )
    let((g_opt t_delim l_keys t_scalars t_sections l_p t_out)
        t_delim = _delim(delimiter "ycIni::encode")
        g_opt = makeTable("ycIniOpt" nil)
        g_opt["sortKeys"] = sortKeys
        g_opt["strict"] = strict
        g_opt["delimiter"] = t_delim
        l_keys = _tableKeys(g_val g_opt "root")
        foreach(g_key l_keys
            if(tablep(g_val[g_key])
                t_sections = tconc(t_sections g_key)
                t_scalars = tconc(t_scalars g_key)
            )
        )
        foreach(g_key car(t_scalars)
            l_p = _emitScalar(l_p g_val g_key g_opt "ycIni::encode")
        )
        foreach(g_key car(t_sections)
            l_p = _emitSection(l_p g_val g_key g_opt)
        )
        t_out = buildString(car(l_p) "\n")
        if(t_out == ""
            ""
            if(finalNewline
                strcat(t_out "\n")
                t_out
            )
        )
    )
)

unuseNamespace("ycIni")

; END
