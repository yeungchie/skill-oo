;--------------------------
; Program  : codec/toml(core.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::Require("ycCodec")

useNamespace("ycToml")

; ---------- 基础工具 ----------

procedure(_Code(t_s n_i "tx")  ; -> int | nil
    ; 取字节索引处的字符码（1-based）；索引越界返回 nil。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 1-based 字节索引
    ;
    ; **返回**
    ;   (int|nil) - 该字节的字符码；越界时为 nil
    let((c)
        c = getchar(t_s n_i)
        when(c
            charToInt(c)
        )
    )
)

procedure(_Digitp(g_c "g")  ; -> t | nil
    ; 判断字符码是否为 ASCII 数字（nil 安全）。
    ;
    ; **参数**
    ;   g_c  (any) - 字符码或 nil
    ;
    ; **返回**
    ;   (t|nil) - 48..57 时为 t，否则 nil
    g_c && g_c >= 48 && g_c <= 57
)

procedure(_LineCol(t_s n_i "tx")  ; -> list
    ; 按字节索引计算行列：行/列均 1-based，列按行内字节偏移。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 1-based 字节索引
    ;
    ; **返回**
    ;   (list) - (行 列) 两元素表
    let((line last)
        line = 1
        last = 0
        when(1 < n_i
            for(k 1 n_i - 1
                when(_Code(t_s k) == 10
                    line++
                    last = k
                )
            )
        )
        list(line n_i - last)
    )
)

procedure(_Error(t_s n_i t_msg "txt")  ; -> never
    ; 按统一格式 error() 中断：ycToml::Decode: <说明> at line <行>, column <列>。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   n_i    (int) - 1-based 字节索引（错误位置）
    ;   t_msg  (str) - 错误说明（英文短语）
    ;
    ; **返回**
    ;   (never) - 总是调用 error()，不返回
    let((pos)
        pos = _LineCol(t_s n_i)
        error("ycToml::Decode: %s at line %d, column %d" t_msg car(pos) cadr(pos))
    )
)

procedure(_Build(l_p "l")  ; -> str
    ; 将 tconc 头容器（或 nil）拼接为字符串。
    ;
    ; **参数**
    ;   l_p  (list) - tconc 头容器或 nil
    ;
    ; **返回**
    ;   (str) - 各片段顺序拼接
    buildString(car(l_p) "")
)

procedure(_Normalize(t_s "t")  ; -> str
    ; 去掉 UTF-8 BOM，并把 CRLF/CR 行尾统一为 LF。
    ;
    ; **参数**
    ;   t_s  (str) - 原始输入
    ;
    ; **返回**
    ;   (str) - 归一化文本
    let((i len p)
        when(length(t_s) >= 3 && _Code(t_s 1) == 239 && _Code(t_s 2) == 187 && _Code(t_s 3) == 191
            t_s = substring(t_s 4)
        )
        i = 1
        len = length(t_s)
        while(i <= len
            if(_Code(t_s i) == 13
            then
                p = tconc(p "\n")
                i++
                when(_Code(t_s i) == 10
                    i++
                )
            else
                p = tconc(p substring(t_s i 1))
                i++
            )
        )
        _Build(p)
    )
)

procedure(_SkipWs(t_s n_i g_newlines g_comments "txgg")  ; -> int
    ; 跳过空白；可选跨行与注释。
    ;
    ; **参数**
    ;   t_s         (str) - 输入串
    ;   n_i         (int) - 起始位置
    ;   g_newlines  (t|nil) - t 时把换行也当作空白
    ;   g_comments  (t|nil) - t 时跳过 # 注释
    ;
    ; **返回**
    ;   (int) - 首个未跳过的位置
    let((len stop c)
        len = length(t_s)
        stop = nil
        while(!stop && n_i <= len
            case(_Code(t_s n_i)
                ((32 9)
                    n_i++
                )
                (10
                    if(g_newlines
                        n_i++
                        stop = t
                    )
                )
                (35
                    if(g_comments
                    then
                        while(n_i <= len && _Code(t_s n_i) != 10
                            c = _Code(t_s n_i)
                            when((c < 32 && c != 9) || c == 127
                                _Error(t_s n_i "control character in comment")
                            )
                            n_i++
                        )
                        when(!g_newlines
                            stop = t
                        )
                    else
                        stop = t
                    )
                )
                (t
                    stop = t
                )
            )
        )
        n_i
    )
)

procedure(_LineEnd(t_s n_i "tx")  ; -> int
    ; 校验当前语句后只余空白/注释/换行，并返回下一行起点。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 当前位置
    ;
    ; **返回**
    ;   (int) - 换行后的位置；到串尾时为 length+1
    let((len)
        len = length(t_s)
        n_i = _SkipWs(t_s n_i nil t)
        case(_Code(t_s n_i)
            (10 n_i + 1)
            (nil n_i)
            (t _Error(t_s n_i "unexpected trailing characters"))
        )
    )
)

; ---------- 路径与元数据 ----------

procedure(_PathKey(l_path "l")  ; -> str
    ; 将路径段序列化为元数据表键；字符串段带长度前缀、数组索引带 i 前缀。
    ;
    ; **参数**
    ;   l_path  (list) - 由键名与整数索引组成的路径
    ;
    ; **返回**
    ;   (str) - 用换行连接的稳定路径键
    let((p)
        foreach(seg l_path
            p = tconc(p
                if(fixp(seg)
                    lsprintf("i%d" seg)
                    lsprintf("s%d:%s" length(seg) seg)
                )
            )
        )
        buildString(car(p) "\n")
    )
)

procedure(_MetaNew()  ; -> table
    ; 创建路径元数据表。
    ;
    ; **返回**
    ;   (table) - 空元数据表
    makeTable("ycTomlMeta" nil)
)

procedure(_MetaSet(g_meta l_path t_kind "glt")  ; -> t
    ; 写入路径的元数据种类。
    ;
    ; **参数**
    ;   g_meta  (table) - 元数据表
    ;   l_path  (list) - 路径
    ;   t_kind  (str) - implicit/explicit/dotted/inline/array
    ;
    ; **返回**
    ;   (t) - 写入成功
    g_meta[_PathKey(l_path)] = t_kind
    t
)

procedure(_MetaGet(g_meta l_path "gl")  ; -> str | nil
    ; 读取路径的元数据种类。
    ;
    ; **参数**
    ;   g_meta  (table) - 元数据表
    ;   l_path  (list) - 路径
    ;
    ; **返回**
    ;   (str|nil) - 种类；未登记时为 nil
    g_meta[_PathKey(l_path)]
)

procedure(_NewTable()  ; -> table
    ; 创建使用 ycCodec::Missing 作为缺省值的 TOML 表。
    ;
    ; **返回**
    ;   (table) - 空表
    makeTable("ycTomlTable" ycCodec:::Missing)
)

procedure(_HasKey(g_obj t_key "gt")  ; -> t | nil
    ; 判断表是否已有该键；缺省哨兵不算存在。
    ;
    ; **参数**
    ;   g_obj  (table) - 目标表
    ;   t_key  (str) - 键名
    ;
    ; **返回**
    ;   (t|nil) - 存在时为 t
    g_obj[t_key] != ycCodec:::Missing
)

procedure(_IsTableList(g_val "g")  ; -> t | nil
    ; 判断值是否为非空且全部由 table 组成的列表。
    ;
    ; **参数**
    ;   g_val  (any) - 待判断值
    ;
    ; **返回**
    ;   (t|nil) - 非空表列表时为 t
    let((ok)
        ok = g_val && listp(g_val)
        when(ok
            foreach(item g_val
                unless(tablep(item)
                    ok = nil
                )
            )
        )
        ok
    )
)

procedure(_MarkInline(g_meta l_path g_val "glg")  ; -> t
    ; 把内联表及其嵌套表递归标记为 inline，禁止后续继续扩展。
    ;
    ; **参数**
    ;   g_meta  (table) - 元数据表
    ;   l_path  (list) - 当前路径
    ;   g_val   (any) - 值
    ;
    ; **返回**
    ;   (t) - 标记完成
    cond(
        (tablep(g_val)
            _MetaSet(g_meta l_path "inline")
            foreach(key g_val
                _MarkInline(g_meta append1(l_path key) g_val[key])
            )
        )
        (listp(g_val)
            let((i)
                i = 0
                foreach(item g_val
                    i++
                    _MarkInline(g_meta append1(l_path i) item)
                )
            )
        )
    )
    t
)

; ---------- UTF-8 ----------

procedure(_Utf8Str(n_cp "x")  ; -> str
    ; 将 Unicode 码点编码为 UTF-8；NUL 无法存入 SKILL 字符串，返回空串。
    ;
    ; **参数**
    ;   n_cp  (int) - 0..0x10FFFF 的码点
    ;
    ; **返回**
    ;   (str) - UTF-8 字节串；非法码点报错
    cond(
        (n_cp == 0 "")
        (n_cp < 0 || n_cp > 1114111
            error("ycToml::Decode: invalid Unicode codepoint %d" n_cp)
        )
        (n_cp >= 55296 && n_cp <= 57343
            error("ycToml::Decode: invalid Unicode codepoint %d" n_cp)
        )
        (n_cp < 128
            strcat(intToChar(n_cp))
        )
        (n_cp < 2048
            strcat(intToChar(192 + n_cp/64) intToChar(128 + remainder(n_cp 64)))
        )
        (n_cp < 65536
            strcat(
                intToChar(224 + n_cp/4096)
                intToChar(128 + remainder(n_cp/64 64))
                intToChar(128 + remainder(n_cp 64))
            )
        )
        (t
            strcat(
                intToChar(240 + n_cp/262144)
                intToChar(128 + remainder(n_cp/4096 64))
                intToChar(128 + remainder(n_cp/64 64))
                intToChar(128 + remainder(n_cp 64))
            )
        )
    )
)

procedure(_HexVal(n_c "x")  ; -> int | nil
    ; 单个十六进制字符码转数值。
    ;
    ; **参数**
    ;   n_c  (int) - 字符码
    ;
    ; **返回**
    ;   (int|nil) - 0..15；非十六进制为 nil
    cond(
        (n_c >= 48 && n_c <= 57 n_c - 48)
        (n_c >= 97 && n_c <= 102 n_c - 87)
        (n_c >= 65 && n_c <= 70 n_c - 55)
        (t nil)
    )
)

procedure(_ContByte(g_c "g")  ; -> t | nil
    ; 判断字符码是否为 UTF-8 连续字节（0x80..0xBF）。
    ;
    ; **参数**
    ;   g_c  (any) - 字符码或 nil
    ;
    ; **返回**
    ;   (t|nil) - 连续字节时为 t
    g_c && g_c >= 128 && g_c <= 191
)

procedure(_ValidUtf8(t_s "t")  ; -> t | nil
    ; 校验文本是否为合法 UTF-8：拒绝无效首字节、过长编码、代理区与超范围码点。
    ;
    ; **参数**
    ;   t_s  (str) - 输入文本
    ;
    ; **返回**
    ;   (t|nil) - 合法时为 t
    let((len i b b1 b2 b3 ok)
        len = length(t_s)
        i = 1
        ok = t
        while(ok && i <= len
            b = _Code(t_s i)
            cond(
                (b <= 127
                    i++
                )
                ((b >= 194 && b <= 223)
                    b1 = _Code(t_s i + 1)
                    if(_ContByte(b1)
                        i = i + 2
                        ok = nil
                    )
                )
                (b == 224
                    b1 = _Code(t_s i + 1)
                    b2 = _Code(t_s i + 2)
                    if(b1 && b1 >= 160 && b1 <= 191 && _ContByte(b2)
                        i = i + 3
                        ok = nil
                    )
                )
                ((b >= 225 && b <= 236) || (b >= 238 && b <= 239)
                    b1 = _Code(t_s i + 1)
                    b2 = _Code(t_s i + 2)
                    if(_ContByte(b1) && _ContByte(b2)
                        i = i + 3
                        ok = nil
                    )
                )
                (b == 237
                    b1 = _Code(t_s i + 1)
                    b2 = _Code(t_s i + 2)
                    if(b1 && b1 >= 128 && b1 <= 159 && _ContByte(b2)
                        i = i + 3
                        ok = nil
                    )
                )
                (b == 240
                    b1 = _Code(t_s i + 1)
                    b2 = _Code(t_s i + 2)
                    b3 = _Code(t_s i + 3)
                    if(b1 && b1 >= 144 && b1 <= 191 && _ContByte(b2) && _ContByte(b3)
                        i = i + 4
                        ok = nil
                    )
                )
                ((b >= 241 && b <= 243)
                    b1 = _Code(t_s i + 1)
                    b2 = _Code(t_s i + 2)
                    b3 = _Code(t_s i + 3)
                    if(_ContByte(b1) && _ContByte(b2) && _ContByte(b3)
                        i = i + 4
                        ok = nil
                    )
                )
                (b == 244
                    b1 = _Code(t_s i + 1)
                    b2 = _Code(t_s i + 2)
                    b3 = _Code(t_s i + 3)
                    if(b1 && b1 >= 128 && b1 <= 143 && _ContByte(b2) && _ContByte(b3)
                        i = i + 4
                        ok = nil
                    )
                )
                (t
                    ok = nil
                )
            )
        )
        ok
    )
)

unuseNamespace("ycToml")

; END
