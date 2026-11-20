;--------------------------
; Program  : ycString(src/string.il)
; Language : Cadence Skill
;--------------------------

useNamespace("ycString")


; ---------- 类定义 ----------

defclass(String () (
    ; String 实例：不可变字符串包装；链式方法返回新实例，->str() 取原生串。
    ; 字符串值由 initializeInstance 的闭包持有，不作为实例槽暴露。
    str()
    trim()
    trimStart()
    trimEnd()
    pad()
    width()
    split()
    join()
    startsWith()
    endsWith()
    replace()
    count()
    escape()
    unescape()
    words()
    sanitize()
    toSnake()
    toKebab()
    toCamel()
    toPascal()
    naturalLess()
))

defmethod(printself (self(String))  ; -> str
    ; 返回 String 的打印描述串，形如 ycString::String("abc")。
    ;
    ; **返回**
    ;   (str) - 命名空间限定的构造调用形式，顶层 evalstring 可复得同值对象
    lsprintf("%A(%A)" className(self) self->str())
)


; ---------- 构造 ----------

procedure(_MkString(t_value "t")  ; -> String
    ; 用原生字符串构造 String 实例（内部实现）。
    ;
    ; **参数**
    ;   t_value  (str) - 原生字符串
    ;
    ; **返回**
    ;   (String) - 新的不可变包装对象
    makeInstance('String ?value t_value)
)

procedure(String(t_s "t")  ; -> String
    ; 构造不可变字符串包装对象。
    ;
    ; **参数**
    ;   t_s  (str) - 原生字符串
    ;
    ; **返回**
    ;   (String) - 新的包装对象；每个链式方法都返回新对象，原对象不变
    _MkString(t_s)
)


; ---------- 方法安装 ----------

inScheme(
procedure(_InstallString(self t_value "gt")  ; -> any
    ; 把 String 的全部方法安装到实例（由 initializeInstance 调用）。
    ;
    ; **参数**
    ;   t_value  (str) - 实例持有的原生字符串
    ;
    ; **返回**
    ;   (any) - 返回最后一条安装赋值的结果，调用方忽略

self->str = lambda(()  ; -> str
    ; 返回当前包装的原生字符串。
    ;
    ; **返回**
    ;   (str) - 原生字符串值
    t_value
)

self->trim = lambda((\@key (chars " \t\r\n") "t")  ; -> String
    ; 去除两端字符集内字符，返回新的 String。
    ;
    ; **参数**
    ;   ?chars  (str) - 待剥离的字面字符集；默认空格/制表/回车/换行
    ;
    ; **返回**
    ;   (String) - 剥离后的新对象；原对象不变
    _MkString(Trim(t_value ?chars chars))
)

self->trimStart = lambda((\@key (chars " \t\r\n") "t")  ; -> String
    ; 只去除前端字符集内字符，返回新的 String。
    ;
    ; **参数**
    ;   ?chars  (str) - 待剥离的字面字符集；默认空格/制表/回车/换行
    ;
    ; **返回**
    ;   (String) - 剥离后的新对象；原对象不变
    _MkString(TrimStart(t_value ?chars chars))
)

self->trimEnd = lambda((\@key (chars " \t\r\n") "t")  ; -> String
    ; 只去除尾端字符集内字符，返回新的 String。
    ;
    ; **参数**
    ;   ?chars  (str) - 待剥离的字面字符集；默认空格/制表/回车/换行
    ;
    ; **返回**
    ;   (String) - 剥离后的新对象；原对象不变
    _MkString(TrimEnd(t_value ?chars chars))
)

self->pad = lambda((n_width \@key (fill " ") (side "end") (unit "display") (ambiguous 1) "xtttx")  ; -> String
    ; 补足到目标宽度，返回新的 String；永不截断。
    ;
    ; **参数**
    ;   n_width    (int) - 目标宽度（>= 0）
    ;   ?fill      (str) - 填充字符（单字符）；默认空格
    ;   ?side      (str) - "end" 尾补（默认）/ "start" 首补
    ;   ?unit      (str) - "display" 显示列宽（默认）/ "char" 码点数
    ;   ?ambiguous (int) - East Asian Ambiguous 宽度（1 或 2）；默认 1
    ;
    ; **返回**
    ;   (String) - 补足后的新对象；已足宽时新对象内容相同
    _MkString(Pad(t_value n_width
        ?fill fill ?side side ?unit unit ?ambiguous ambiguous))
)

self->width = lambda((\@key (unit "display") (ambiguous 1) "tx")  ; -> int
    ; 计算显示列宽或码点数。
    ;
    ; **参数**
    ;   ?unit      (str) - "display"（默认）/ "char"
    ;   ?ambiguous (int) - East Asian Ambiguous 宽度（1 或 2）；默认 1
    ;
    ; **返回**
    ;   (int) - 显示列宽或码点数
    Width(t_value ?unit unit ?ambiguous ambiguous)
)

self->split = lambda((\@key (sep nil) (regex nil) (keepEmpty t) "ggg")  ; -> list[str]
    ; 切分当前字符串，返回切分段列表。
    ;
    ; **参数**
    ;   ?sep       (str|nil) - 分隔符或正则模式；缺省时按空白符切分
    ;   ?regex     (any)     - 非 nil 时 ?sep 按正则模式解释
    ;   ?keepEmpty (any)     - 非 nil 时保留空段；默认 t
    ;
    ; **返回**
    ;   (list[str]) - 切分段列表
    Split(t_value
        ?sep sep ?regex regex ?keepEmpty keepEmpty)
)

self->join = lambda((l_items "l")  ; -> String
    ; 以当前字符串为分隔符连接字符串列表，返回新的 String。
    ;
    ; **参数**
    ;   l_items  (list[str]) - 待连接项（全部须为字符串）
    ;
    ; **返回**
    ;   (String) - 连接结果的新对象；空列表为空串
    _MkString(Join(l_items ?sep t_value))
)

self->startsWith = lambda((t_prefix "t")  ; -> t | nil
    ; 判断当前字符串是否以指定前缀开始。
    ;
    ; **参数**
    ;   t_prefix  (str) - 前缀
    ;
    ; **返回**
    ;   (t|nil) - 是则为 t；空前缀回 t
    StartsWith(t_value t_prefix)
)

self->endsWith = lambda((t_suffix "t")  ; -> t | nil
    ; 判断当前字符串是否以指定后缀结束。
    ;
    ; **参数**
    ;   t_suffix  (str) - 后缀
    ;
    ; **返回**
    ;   (t|nil) - 是则为 t；空后缀回 t
    EndsWith(t_value t_suffix)
)

self->replace = lambda((t_old t_new \@key (regex nil) "ttg")  ; -> String
    ; 替换全部出现，返回新的 String。
    ;
    ; **参数**
    ;   t_old  (str) - 待替换串或正则模式
    ;   t_new  (str) - 替换串
    ;   ?regex (any) - 非 nil 时 t_old 按正则模式解释
    ;
    ; **返回**
    ;   (String) - 替换后的新对象；原对象不变
    _MkString(Replace(t_value t_old t_new ?regex regex))
)

self->count = lambda((t_sub \@key (regex nil) "tg")  ; -> int
    ; 统计非重叠出现次数。
    ;
    ; **参数**
    ;   t_sub  (str) - 待计数子串或正则模式
    ;   ?regex (any) - 非 nil 时 t_sub 按正则模式解释
    ;
    ; **返回**
    ;   (int) - 出现次数
    Count(t_value t_sub ?regex regex)
)

self->escape = lambda((\@key (quote nil) "g")  ; -> String
    ; 转义反斜杠、双引号、换行、制表与回车，返回新的 String。
    ;
    ; **参数**
    ;   ?quote  (any) - 非 nil 时包裹双引号
    ;
    ; **返回**
    ;   (String) - 转义后的新对象；原对象不变
    _MkString(Escape(t_value ?quote quote))
)

self->unescape = lambda((\@key (strict nil) "g")  ; -> String
    ; 还原转义序列，返回新的 String。
    ;
    ; **参数**
    ;   ?strict  (any) - 非 nil 时未知转义与悬尾反斜杠报错
    ;
    ; **返回**
    ;   (String) - 还原后的新对象；原对象不变
    _MkString(Unescape(t_value ?strict strict))
)

self->words = lambda(()  ; -> list[str]
    ; 按大小写与数字边界切分为词列表。
    ;
    ; **返回**
    ;   (list[str]) - 词列表；无词时为 nil
    Words(t_value)
)

self->sanitize = lambda((\@key (style "snake") "t")  ; -> String
    ; 清洗为合法标识符形态，返回新的 String。
    ;
    ; **参数**
    ;   ?style  (str) - "snake"（默认）/ "kebab" / "camel" / "pascal"
    ;
    ; **返回**
    ;   (String) - 清洗后的新对象；原对象不变
    _MkString(Sanitize(t_value ?style style))
)

self->toSnake = lambda(()  ; -> String
    ; 转换为 snake 形式标识符，返回新的 String。
    ;
    ; **返回**
    ;   (String) - snake 形式的新对象；原对象不变
    _MkString(ToSnake(t_value))
)

self->toKebab = lambda(()  ; -> String
    ; 转换为 kebab 形式标识符，返回新的 String。
    ;
    ; **返回**
    ;   (String) - kebab 形式的新对象；原对象不变
    _MkString(ToKebab(t_value))
)

self->toCamel = lambda(()  ; -> String
    ; 转换为 camel 形式标识符，返回新的 String。
    ;
    ; **返回**
    ;   (String) - camel 形式的新对象；原对象不变
    _MkString(ToCamel(t_value))
)

self->toPascal = lambda(()  ; -> String
    ; 转换为 pascal 形式标识符，返回新的 String。
    ;
    ; **返回**
    ;   (String) - pascal 形式的新对象；原对象不变
    _MkString(ToPascal(t_value))
)

self->naturalLess = lambda((t_other "t")  ; -> t | nil
    ; 按自然序比较当前字符串与另一个字符串。
    ;
    ; **参数**
    ;   t_other  (str) - 右串
    ;
    ; **返回**
    ;   (t|nil) - 当前串排在 t_other 之前为 t；相等或在后回 nil
    NaturalLess(t_value t_other)
)

))

inScheme(
defmethod(initializeInstance (self(String) \@key (value ""))
    ; 构造 String 实例时把原生串收进闭包并安装全部方法。
    ;
    ; **参数**
    ;   ?value  (str) - 原生字符串；默认空串
    ;
    ; **返回**
    ;   (t) - 安装完成后返回 t
    unless(stringp(value)
        error("%A: ?value must be a string, got %A" className(self) value)
    )
    _InstallString(self value)
    t
)
)


unuseNamespace("ycString")

; END
