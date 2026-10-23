;--------------------------
; Program  : codec/ini(decode.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::require("ycCodec")

useNamespace("ycIni")

; ---------- 单行结构 ----------

procedure(_headerName(t_body n_line n_col "txx")  ; -> str
    ; 解析段头并校验段名与行尾。
    ;
    ; **参数**
    ;   t_body  (str) - 已去左侧空白的行内容
    ;   n_line  (int) - 行号
    ;   n_col   (int) - 行首字节列号
    ;
    ; **返回**
    ;   (str) - 段名；格式非法时报错
    let((n_close n_len t_name t_rest)
        n_close = _find(t_body "]")
        unless(n_close
            _error(n_line n_col "unterminated section header")
        )
        n_len = n_close - 2
        t_name = if(n_len > 0
            substring(t_body 2 n_len)
            ""
        )
        t_name = _trim(t_name)
        when(t_name == ""
            _error(n_line n_col "empty section name")
        )
        when(_hasControl(t_name)
            _error(n_line n_col "control character in section name")
        )
        when(_find(t_name "[") || _find(t_name "]")
            _error(n_line n_col "section name must not contain '[' or ']'")
        )
        n_len = length(t_body) - n_close
        t_rest = if(n_len > 0
            _trim(substring(t_body n_close + 1 n_len))
            ""
        )
        unless(t_rest == ""
            _error(n_line n_col "unexpected characters after section header")
        )
        t_name
    )
)

procedure(_keyValue(t_body n_line n_col t_delim "txxt")  ; -> list
    ; 解析 key = value 行并校验键值。
    ;
    ; **参数**
    ;   t_body   (str) - 已去左侧空白的行内容
    ;   n_line   (int) - 行号
    ;   n_col    (int) - 行首字节列号
    ;   t_delim  (str) - 分隔符
    ;
    ; **返回**
    ;   (list) - (键 值)；缺分隔符、空键或控制字符时报错
    let((n_pos n_len t_key t_val)
        n_pos = _find(t_body t_delim)
        unless(n_pos
            _error(n_line n_col lsprintf("expected delimiter %A" t_delim))
        )
        n_len = n_pos - 1
        t_key = _trim(if(n_len > 0 substring(t_body 1 n_len) ""))
        when(t_key == ""
            _error(n_line n_col "empty key")
        )
        when(_hasControl(t_key)
            _error(n_line n_col "control character in key")
        )
        n_len = length(t_body) - n_pos
        t_val = _trim(if(n_len > 0 substring(t_body n_pos + 1 n_len) ""))
        when(_hasControl(t_val)
            _error(n_line n_col "control character in value")
        )
        list(t_key t_val)
    )
)

; ---------- 文档解码 ----------

procedure(_decodeText(t_s t_delim t_dup "ttt")  ; -> table
    ; 解析完整 INI 文本，返回根表。
    ;
    ; **参数**
    ;   t_s      (str) - 已归一化的输入文本
    ;   t_delim  (str) - 分隔符
    ;   t_dup    (str) - 重复键策略
    ;
    ; **返回**
    ;   (table) - 文档根表；段以字面子表保存
    let((l_lines n_line t_root t_cur t_body n_ind n_col l_kv t_name)
        t_root = _newTable()
        t_cur = t_root
        n_line = 0
        l_lines = _splitLines(t_s)
        foreach(t_line l_lines
            n_line = n_line + 1
            n_ind = _lineIndent(t_line)
            t_body = _ltrim(t_line)
            unless(t_body == "" || _code(t_body 1) == 35 || _code(t_body 1) == 59
                n_col = n_ind + 1
                if(_code(t_body 1) == 91
                    {
                    t_name = _headerName(t_body n_line n_col)
                    if(_hasKey(t_root t_name)
                        {
                        unless(tablep(t_root[t_name])
                            _error(n_line n_col "section name conflicts with key")
                        )
                        when(t_dup == "error"
                            _error(n_line n_col "duplicate section")
                        )
                        t_cur = t_root[t_name]
                        }
                        {
                        t_cur = _newTable()
                        t_root[t_name] = t_cur
                        }
                    )
                    }
                    {
                    l_kv = _keyValue(t_body n_line n_col t_delim)
                    when(_hasKey(t_cur car(l_kv))
                        when(t_dup == "error"
                            _error(n_line n_col lsprintf("duplicate key %A" car(l_kv)))
                        )
                    )
                    unless(t_dup == "first" && _hasKey(t_cur car(l_kv))
                        t_cur[car(l_kv)] = cadr(l_kv)
                    )
                    }
                )
            )
        )
        t_root
    )
)

procedure(decode(t_str \@key (delimiter nil) (duplicates nil) "tgg")  ; -> table
    ; 解码 INI 文本为根 table。
    ;
    ; **参数**
    ;   t_str        (str) - 输入文本
    ;   ?delimiter   (str) - 单字节分隔符；默认 "="
    ;   ?duplicates  (str) - "error"（默认）/ "first" / "last"
    ;
    ; **返回**
    ;   (table) - 根表；语法、重复项或选项非法时以 error() 中断
    unless(stringp(t_str)
        error("ycIni::decode: expects a string")
    )
    let((t_delim t_dup)
        t_delim = _delim(delimiter "ycIni::decode")
        t_dup = _policy(duplicates "ycIni::decode")
        _decodeText(_normalize(t_str) t_delim t_dup)
    )
)

unuseNamespace("ycIni")

; END
