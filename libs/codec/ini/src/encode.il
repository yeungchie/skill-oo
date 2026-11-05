;--------------------------
; Program  : codec/ini(encode.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::Require("ycCodec")

useNamespace("ycIni")

procedure(_EmitScalar(l_p g_obj g_key g_opt t_ctx "lgggt")  ; -> list
    ; 在行容器后追加一个 key = value 行。
    ;
    ; **参数**
    ;   l_p     (list) - tconc 行容器
    ;   g_obj   (table) - 键所在表
    ;   g_key   (any) - 键
    ;   g_opt   (table) - 编码选项
    ;   t_ctx   (str) - 错误前缀
    ;
    ; **返回**
    ;   (list) - 更新后的行容器
    tconc(l_p
        lsprintf("%s %s %s"
            _KeyText(g_key g_opt)
            g_opt["delimiter"]
            _ValueText(g_obj[g_key] t_ctx)
        )
    )
)

procedure(_EmitSection(l_p g_obj g_key g_opt "lggg")  ; -> list
    ; 输出一个 INI 段：段头、空行分隔与段内标量键值。
    ;
    ; **参数**
    ;   l_p    (list) - tconc 行容器
    ;   g_obj  (table) - 根表
    ;   g_key  (any) - 段名键
    ;   g_opt  (table) - 编码选项
    ;
    ; **返回**
    ;   (list) - 更新后的行容器；段内嵌套表报错
    let((name sec keys val)
        name = _SectionText(g_key g_opt)
        when(car(l_p)
            l_p = tconc(l_p "")
        )
        l_p = tconc(l_p lsprintf("[%s]" name))
        sec = g_obj[g_key]
        keys = _TableKeys(sec g_opt "section")
        foreach(key keys
            val = sec[key]
            when(tablep(val)
                error("ycIni::Encode: nested table in section %A is not supported" name)
            )
            l_p = _EmitScalar(l_p sec key g_opt "ycIni::Encode")
        )
        l_p
    )
)

procedure(Encode(g_val \@key (sortKeys nil) (strict nil) (delimiter nil) (finalNewline t) "ggggg")  ; -> str
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
        error("ycIni::Encode: root value must be a table")
    )
    let((opt delim keys scalars sections p out)
        delim = _Delim(delimiter "ycIni::Encode")
        opt = makeTable("ycIniOpt" nil)
        opt["sortKeys"] = sortKeys
        opt["strict"] = strict
        opt["delimiter"] = delim
        keys = _TableKeys(g_val opt "root")
        foreach(key keys
            if(tablep(g_val[key])
                sections = tconc(sections key)
                scalars = tconc(scalars key)
            )
        )
        foreach(key car(scalars)
            p = _EmitScalar(p g_val key opt "ycIni::Encode")
        )
        foreach(key car(sections)
            p = _EmitSection(p g_val key opt)
        )
        out = buildString(car(p) "\n")
        cond(
            (out == "" "")
            (finalNewline
                strcat(out "\n")
            )
            (t out)
        )
    )
)

unuseNamespace("ycIni")

; END
