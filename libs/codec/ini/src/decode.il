;--------------------------
; Program  : codec/ini(decode.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::Require("ycCodec")

useNamespace("ycIni")

; ---------- 单行结构 ----------

procedure(_HeaderName(t_body n_line n_col "txx")  ; -> str
    ; 解析段头并校验段名与行尾。
    ;
    ; **参数**
    ;   t_body  (str) - 已去左侧空白的行内容
    ;   n_line  (int) - 行号
    ;   n_col   (int) - 行首字节列号
    ;
    ; **返回**
    ;   (str) - 段名；格式非法时报错
    let((close len name rest)
        close = _Find(t_body "]")
        unless(close
            _Error(n_line n_col "unterminated section header")
        )
        len = close - 2
        name = if(len > 0
            substring(t_body 2 len)
            ""
        )
        name = _Trim(name)
        when(name == ""
            _Error(n_line n_col "empty section name")
        )
        when(_HasControl(name)
            _Error(n_line n_col "control character in section name")
        )
        when(_Find(name "[") || _Find(name "]")
            _Error(n_line n_col "section name must not contain '[' or ']'")
        )
        len = length(t_body) - close
        rest = if(len > 0
            _Trim(substring(t_body close + 1 len))
            ""
        )
        unless(rest == ""
            _Error(n_line n_col "unexpected characters after section header")
        )
        name
    )
)

procedure(_KeyValue(t_body n_line n_col t_delim "txxt")  ; -> list
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
    let((pos len key val)
        pos = _Find(t_body t_delim)
        unless(pos
            _Error(n_line n_col lsprintf("expected delimiter %A" t_delim))
        )
        len = pos - 1
        key = _Trim(if(len > 0 substring(t_body 1 len) ""))
        when(key == ""
            _Error(n_line n_col "empty key")
        )
        when(_HasControl(key)
            _Error(n_line n_col "control character in key")
        )
        len = length(t_body) - pos
        val = _Trim(if(len > 0 substring(t_body pos + 1 len) ""))
        when(_HasControl(val)
            _Error(n_line n_col "control character in value")
        )
        list(key val)
    )
)

; ---------- 文档解码 ----------

procedure(_DecodeText(t_s t_delim t_dup "ttt")  ; -> table
    ; 解析完整 INI 文本，返回根表。
    ;
    ; **参数**
    ;   t_s      (str) - 已归一化的输入文本
    ;   t_delim  (str) - 分隔符
    ;   t_dup    (str) - 重复键策略
    ;
    ; **返回**
    ;   (table) - 文档根表；段以字面子表保存
    let((lines line root cur body ind col kv name)
        root = _NewTable()
        cur = root
        line = 0
        lines = _SplitLines(t_s)
        foreach(line2 lines
            line++
            ind = _LineIndent(line2)
            body = _Ltrim(line2)
            unless(body == "" || _Code(body 1) == 35 || _Code(body 1) == 59
                col = ind + 1
                if(_Code(body 1) == 91
                then
                    name = _HeaderName(body line col)
                    if(_HasKey(root name)
                    then
                        unless(tablep(root[name])
                            _Error(line col "section name conflicts with key")
                        )
                        when(t_dup == "error"
                            _Error(line col "duplicate section")
                        )
                        cur = root[name]
                    else
                        cur = _NewTable()
                        root[name] = cur
                    )
                else
                    kv = _KeyValue(body line col t_delim)
                    when(_HasKey(cur car(kv))
                        when(t_dup == "error"
                            _Error(line col lsprintf("duplicate key %A" car(kv)))
                        )
                    )
                    unless(t_dup == "first" && _HasKey(cur car(kv))
                        cur[car(kv)] = cadr(kv)
                    )
                )
            )
        )
        root
    )
)

procedure(Decode(t_str \@key (delimiter nil) (duplicates nil) "tgg")  ; -> table
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
        error("ycIni::Decode: expects a string")
    )
    let((delim dup)
        delim = _Delim(delimiter "ycIni::Decode")
        dup = _Policy(duplicates "ycIni::Decode")
        _DecodeText(_Normalize(t_str) delim dup)
    )
)

unuseNamespace("ycIni")

; END
