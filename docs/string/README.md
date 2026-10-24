# ycString

[返回首页](../../README.md)

Cadence SKILL++ 的字符串工具库：常用操作、转义与标识符转换。

## 概要

+ 字符级操作按 UTF-8 码点处理；显示宽度与 `ycUtf8` 的宽度规则一致。
+ 字面量接口（`ycString::Replace` / `ycString::Count` / `ycString::StrSplit`）默认区分大小写、按字面量匹配；`?regex t` 时按 `ycRegEx` 的模式与替换模板语义。
+ 命名风格转换（`ycString::Words` / `ycString::JoinWords` / `ycString::Sanitize`）按大小写与数字边界切词；ASCII 字母数字以外的码点算词内字符。
+ 记法约定：例程注释中 `; =>` 标记返回值，`; *Error*` 标记错误消息。
+ 库内校验触发的错误消息以 `ycString::<过程>:` 为前缀，可用 `errset` 捕获。

## 快速上手

```lisp
; 修剪、补宽与宽度
ycString::Trim("  hello  ")                    ; => "hello"
ycString::Pad("ab" 5 ?fill "-")                ; => "ab---"
ycString::Width("中文")                        ; => 4

; 切分与连接
ycString::StrSplit("a,,b" ?sep ",")            ; => ("a" "" "b")
ycString::StrJoin(list("a" "b") ?sep "-")      ; => "a-b"

; 替换、统计与转义
ycString::Replace("baaacaa" "a+" "X" ?regex t) ; => "bXcX"
ycString::Count("banana" "a")                  ; => 3
ycString::Escape("a\nb")                       ; => "a\\nb"
ycString::Unescape("a\\nb")                    ; => "a\nb"

; 标识符转换
ycString::ToSnake("HTMLParser")                ; => "html_parser"
ycString::ToPascal("html_parser")              ; => "HtmlParser"
```

## API 参考

### ycString::Trim <sub>`function`</sub>

```text
ycString::Trim(
    t_s
    [ ?chars ]
)
=> str
```

**描述**

去除字符串两端的字符集内字符；`?chars` 为字面字符集（非正则），默认空白类字符（空格、制表、回车、换行）。全部被剥离时返回空串。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_s | str |  | 输入串 |
| ?chars | str | `" \t\r\n"` | 待剥离的字面字符集 |

**返回值**

`str` — 剥离后的串；全剥离为空串。

**例程**

```lisp
ycString::Trim("  ab  ")               ; => "ab"
ycString::Trim("xxabxx" ?chars "x")    ; => "ab"
ycString::Trim("中中a中中" ?chars "中") ; => "a"
```

### ycString::TrimStart <sub>`function`</sub>

```text
ycString::TrimStart(
    t_s
    [ ?chars ]
)
=> str
```

**描述**

同 `ycString::Trim`，仅去除前端字符。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_s | str |  | 输入串 |
| ?chars | str | `" \t\r\n"` | 待剥离的字面字符集 |

**返回值**

`str` — 剥离后的串；全剥离为空串。

**例程**

```lisp
ycString::TrimStart("  ab  ") ; => "ab  "
```

### ycString::TrimEnd <sub>`function`</sub>

```text
ycString::TrimEnd(
    t_s
    [ ?chars ]
)
=> str
```

**描述**

同 `ycString::Trim`，仅去除尾端字符。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_s | str |  | 输入串 |
| ?chars | str | `" \t\r\n"` | 待剥离的字面字符集 |

**返回值**

`str` — 剥离后的串；全剥离为空串。

**例程**

```lisp
ycString::TrimEnd("  ab  ") ; => "  ab"
```

### ycString::Pad <sub>`function`</sub>

```text
ycString::Pad(
    t_s
    n_width
    [ ?fill ]
    [ ?side ]
    [ ?unit ]
    [ ?ambiguous ]
)
=> str
```

**描述**

把字符串补足到目标宽度，永不截断（已足宽原样返回）。宽度按 `?unit` 计：`"display"`（默认）为显示列宽，`"char"` 为码点数；补在 `?side` 指定的一端。填充字符须为单字符；显示模式下还须单列宽（全角字符需配 `?unit "char"`）。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_s | str |  | 输入串 |
| n_width | int |  | 目标宽度（≥0） |
| ?fill | str | `" "` | 填充字符（单字符） |
| ?side | str | `"end"` | `"end"` 尾补或 `"start"` 首补 |
| ?unit | str | `"display"` | `"display"` 显示列宽或 `"char"` 码点数 |
| ?ambiguous | int | 1 | East Asian Ambiguous 的宽度（1 或 2） |

**返回值**

`str` — 补足后的串；已足宽原样返回。

**例程**

```lisp
ycString::Pad("ab" 5 ?fill "-")               ; => "ab---"
ycString::Pad("ab" 5 ?side "start" ?fill "-") ; => "---ab"
ycString::Pad("中" 4 ?unit "char" ?fill "-")  ; => "中---"
ycString::Pad("ab" 1)                         ; => "ab"
ycString::Pad("a" 2 ?unit "char" ?fill "中")  ; => "a中"
ycString::Pad("a" -1)
; *Error* ycString::Pad: width must be a non-negative integer (-1)
ycString::Pad("a" 2 ?fill "中")
; *Error* ycString::Pad: fill must be single width in display mode ("中")
```

### ycString::Width <sub>`function`</sub>

```text
ycString::Width(
    t_s
    [ ?unit ]
    [ ?ambiguous ]
)
=> int
```

**描述**

计算显示列宽（默认）或码点数。`"display"` 按显示列宽逐码点求和（规则同 `ycUtf8`）；`"char"` 数 UTF-8 码点。`?unit` 取其他值时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_s | str |  | 输入串 |
| ?unit | str | `"display"` | `"display"` 显示列宽或 `"char"` 码点数 |
| ?ambiguous | int | 1 | East Asian Ambiguous 的宽度（1 或 2） |

**返回值**

`int` — 显示列宽或码点数。

**例程**

```lisp
ycString::Width("中文")              ; => 4
ycString::Width("中文" ?unit "char") ; => 2
ycString::Width("")                  ; => 0
ycString::Width("a" ?unit "px")
; *Error* ycString::Width: unknown unit "px"
```

### ycString::StrSplit <sub>`function`</sub>

```text
ycString::StrSplit(
    t_s
    [ ?sep ]
    [ ?regex ]
    [ ?keepEmpty ]
)
=> list[str] | nil
```

**描述**

切分字符串。缺省按空白字符连续段切分并丢弃空段；给定 `?sep` 时按字面分隔符切分并保留空段；`?sep` 配 `?regex t` 时按正则模式切分（内部经 `ycRegEx`）。`?keepEmpty nil` 时去除空段。字面分隔符不能为空串；正则模式要求非空模式。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_s | str |  | 输入串 |
| ?sep | str | nil | 分隔符或正则模式；缺省时按空白符切分 |
| ?regex | any | nil | 非 nil 时 `?sep` 按正则模式解释 |
| ?keepEmpty | any | t | 非 nil 时保留空段 |

**返回值**

`list[str] | nil` — 切分段列表；无段时为 `nil`。

**例程**

```lisp
ycString::StrSplit("  a\tb\n c ")                   ; => ("a" "b" "c")
ycString::StrSplit("")                              ; => nil
ycString::StrSplit("a,,b" ?sep ",")                 ; => ("a" "" "b")
ycString::StrSplit(",a," ?sep ",")                  ; => ("" "a" "")
ycString::StrSplit("a,,b" ?sep "," ?keepEmpty nil)  ; => ("a" "b")
ycString::StrSplit("a1b22c" ?sep "[0-9]+" ?regex t) ; => ("a" "b" "c")
ycString::StrSplit("a" ?sep "")
; *Error* ycString::StrSplit: separator must not be empty
```

### ycString::StrJoin <sub>`function`</sub>

```text
ycString::StrJoin(
    l_items
    [ ?sep ]
)
=> str
```

**描述**

以 `?sep` 连接字符串列表；元素须全为字符串，否则以 `error()` 中断。空列表返回空串。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| l_items | list[str] |  | 待连接的字符串列表 |
| ?sep | str | `""` | 分隔符 |

**返回值**

`str` — 连接结果；空列表为空串。

**例程**

```lisp
ycString::StrJoin(list("a" "b" "c"))      ; => "abc"
ycString::StrJoin(list("a" "b") ?sep "-") ; => "a-b"
ycString::StrJoin(nil)                    ; => ""
ycString::StrJoin(list("a" 1))
; *Error* ycString::StrJoin: item #2 is not a string (1)
```

### ycString::StartsWith <sub>`function`</sub>

```text
ycString::StartsWith(
    t_s
    t_prefix
)
=> t | nil
```

**描述**

判断 `t_s` 是否以 `t_prefix` 开始；空前缀恒为真。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_s | str | 输入串 |
| t_prefix | str | 前缀 |

**返回值**

`t | nil` — 是则为 `t`，否则为 `nil`。

**例程**

```lisp
ycString::StartsWith("abc" "ab")       ; => t
ycString::StartsWith("abc" "")         ; => t
ycString::StartsWith("中文abc" "中文") ; => t
ycString::StartsWith("abc" "abcd")     ; => nil
```

### ycString::EndsWith <sub>`function`</sub>

```text
ycString::EndsWith(
    t_s
    t_suffix
)
=> t | nil
```

**描述**

判断 `t_s` 是否以 `t_suffix` 结束；空后缀恒为真。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_s | str | 输入串 |
| t_suffix | str | 后缀 |

**返回值**

`t | nil` — 是则为 `t`，否则为 `nil`。

**例程**

```lisp
ycString::EndsWith("abc" "bc")      ; => t
ycString::EndsWith("abc" "")        ; => t
ycString::EndsWith("中文abc" "abc") ; => t
ycString::EndsWith("abc" "abcd")    ; => nil
```

### ycString::Replace <sub>`function`</sub>

```text
ycString::Replace(
    t_s
    t_old
    t_new
    [ ?regex ]
)
=> str
```

**描述**

把 `t_s` 中全部非重叠出现替换为 `t_new`。默认按字面量匹配；`?regex t` 时 `t_old` 为正则模式、`t_new` 按 `ycRegEx` 的替换模板展开。`t_old` 不能为空；无匹配时原样返回。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_s | str |  | 输入串 |
| t_old | str |  | 待替换文字或正则模式 |
| t_new | str |  | 替换文字或替换模板 |
| ?regex | any | nil | 非 nil 时 `t_old` 按正则模式解释 |

**返回值**

`str` — 替换后的串；无匹配原样返回。

**例程**

```lisp
ycString::Replace("aaa" "a" "b")                  ; => "bbb"
ycString::Replace("aaa" "aa" "b")                 ; => "ba"
ycString::Replace("abc" "x" "y")                  ; => "abc"
ycString::Replace("a1b22c" "[0-9]+" "N" ?regex t) ; => "aNbNc"
ycString::Replace("a" "" "b")
; *Error* ycString::Replace: search string must not be empty
ycString::Replace("a" "" "b" ?regex t)
; *Error* ycString::Replace: pattern must not be empty
```

### ycString::Count <sub>`function`</sub>

```text
ycString::Count(
    t_s
    t_sub
    [ ?regex ]
)
=> int
```

**描述**

统计 `t_sub` 在 `t_s` 中的非重叠出现次数。默认按字面量匹配；`?regex t` 时按正则模式统计。`t_sub` 不能为空。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_s | str |  | 输入串 |
| t_sub | str |  | 待计数文字或正则模式 |
| ?regex | any | nil | 非 nil 时 `t_sub` 按正则模式解释 |

**返回值**

`int` — 出现次数。

**例程**

```lisp
ycString::Count("banana" "a")           ; => 3
ycString::Count("aaaa" "aa")            ; => 2
ycString::Count("abc" "x")              ; => 0
ycString::Count("banana" "a+" ?regex t) ; => 3
ycString::Count("a" "")
; *Error* ycString::Count: search string must not be empty
```

### ycString::Escape <sub>`function`</sub>

```text
ycString::Escape(
    t_s
    [ ?quote ]
)
=> str
```

**描述**

转义反斜杠、双引号、换行、制表与回车（反斜杠加字母形式）；`?quote` 非 nil 时再以双引号包裹，结果可直接经 `evalstring` 回读。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_s | str |  | 输入串 |
| ?quote | any | nil | 非 nil 时以双引号包裹结果 |

**返回值**

`str` — 转义后的串。

**例程**

```lisp
ycString::Escape("a\\b")        ; => "a\\\\b"
ycString::Escape("a\"b")        ; => "a\\\"b"
ycString::Escape("a\nb")        ; => "a\\nb"
ycString::Escape("a\tb")        ; => "a\\tb"
ycString::Escape("ab" ?quote t) ; => "\"ab\""
```

### ycString::Unescape <sub>`function`</sub>

```text
ycString::Unescape(
    t_s
    [ ?strict ]
)
=> str
```

**描述**

还原 `ycString::Escape` 的转义序列。默认未知转义与悬尾反斜杠原样保留；`?strict` 非 nil 时两者均以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_s | str |  | 输入串 |
| ?strict | any | nil | 非 nil 时未知转义与悬尾反斜杠以 `error()` 中断 |

**返回值**

`str` — 还原后的串。

**例程**

```lisp
ycString::Unescape("a\\nb") ; => "a\nb"
ycString::Unescape("a\\tb") ; => "a\tb"
ycString::Unescape("a\\qb") ; => "a\\qb"
ycString::Unescape("a\\")   ; => "a\\"
ycString::Unescape("a\\qb" ?strict t)
; *Error* ycString::Unescape: unknown escape \q
ycString::Unescape("a\\" ?strict t)
; *Error* ycString::Unescape: trailing backslash
```

### ycString::Words <sub>`function`</sub>

```text
ycString::Words(t_s)
=> list[str] | nil
```

**描述**

把字符串切分为词列表：以非词内字符（空白、标点等）为界，并在大小写与数字边界处拆分（`HTMLParser` → `HTML` `Parser`、`camelCase` → `camel` `Case`、`foo2Bar` → `foo2` `Bar`）；ASCII 字母数字以外的码点算词内字符。无词返回 `nil`。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_s | str | 输入串 |

**返回值**

`list[str] | nil` — 词列表；无词为 `nil`。

**例程**

```lisp
ycString::Words("HTMLParser")  ; => ("HTML" "Parser")
ycString::Words("camelCase")   ; => ("camel" "Case")
ycString::Words("foo_bar-baz") ; => ("foo" "bar" "baz")
ycString::Words("foo2Bar")     ; => ("foo2" "Bar")
ycString::Words("中文 abc")    ; => ("中文" "abc")
ycString::Words("  ")          ; => nil
```

### ycString::JoinWords <sub>`function`</sub>

```text
ycString::JoinWords(
    l_words
    [ ?style ]
)
=> str
```

**描述**

按命名风格拼接词列表：`"snake"`（默认，下划线连接）、`"kebab"`（连字符连接）、`"camel"`（首词小写、后续词首字母大写）、`"pascal"`（各词首字母大写）；词先转小写再拼接。空列表返回空串。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| l_words | list[str] |  | 词列表 |
| ?style | str | `"snake"` | `"snake"`、`"kebab"`、`"camel"` 或 `"pascal"` |

**返回值**

`str` — 拼接结果；空列表为空串。

**例程**

```lisp
ycString::JoinWords(list("a" "b"))                         ; => "a_b"
ycString::JoinWords(list("a" "b") ?style "kebab")          ; => "a-b"
ycString::JoinWords(list("HTML" "Parser") ?style "camel")  ; => "htmlParser"
ycString::JoinWords(list("HTML" "Parser") ?style "pascal") ; => "HtmlParser"
ycString::JoinWords(list("a") ?style "dot")
; *Error* ycString::JoinWords: unknown style "dot"
```

### ycString::Sanitize <sub>`function`</sub>

```text
ycString::Sanitize(
    t_s
    [ ?style ]
)
=> str
```

**描述**

把任意字符串清洗为指定风格的标识符：等价 `ycString::Words` 切词后 `ycString::JoinWords` 拼接；结果以数字开头时前置下划线。无有效字符时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_s | str |  | 输入串 |
| ?style | str | `"snake"` | 目标风格（同 `ycString::JoinWords`） |

**返回值**

`str` — 标识符；数字开头时带前导 `_`。

**例程**

```lisp
ycString::Sanitize("1st place")                 ; => "_1st_place"
ycString::Sanitize("HTMLParser" ?style "kebab") ; => "html-parser"
ycString::Sanitize("!!!")
; *Error* ycString::Sanitize: no valid characters ("!!!")
```

### ycString::ToSnake <sub>`function`</sub>

```text
ycString::ToSnake(t_s)
=> str
```

**描述**

`ycString::Sanitize` 的 snake 风格便捷形式。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_s | str | 输入串 |

**返回值**

`str` — snake 形式标识符。

**例程**

```lisp
ycString::ToSnake("HTMLParser") ; => "html_parser"
```

### ycString::ToKebab <sub>`function`</sub>

```text
ycString::ToKebab(t_s)
=> str
```

**描述**

`ycString::Sanitize` 的 kebab 风格便捷形式。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_s | str | 输入串 |

**返回值**

`str` — kebab 形式标识符。

**例程**

```lisp
ycString::ToKebab("HTMLParser") ; => "html-parser"
```

### ycString::ToCamel <sub>`function`</sub>

```text
ycString::ToCamel(t_s)
=> str
```

**描述**

`ycString::Sanitize` 的 camel 风格便捷形式。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_s | str | 输入串 |

**返回值**

`str` — camel 形式标识符。

**例程**

```lisp
ycString::ToCamel("html_parser") ; => "htmlParser"
```

### ycString::ToPascal <sub>`function`</sub>

```text
ycString::ToPascal(t_s)
=> str
```

**描述**

`ycString::Sanitize` 的 pascal 风格便捷形式。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_s | str | 输入串 |

**返回值**

`str` — pascal 形式标识符。

**例程**

```lisp
ycString::ToPascal("html_parser") ; => "HtmlParser"
```

## 显示宽度

`?unit "display"` 与 `ycUtf8::Width` 一致：控制字符为 0、East Asian Wide/Fullwidth 为 2、Ambiguous 由 `?ambiguous` 决定（默认 1）。宽度按码点求和，不合并字素簇；需要按字符数对齐时用 `?unit "char"`。

[返回首页](../../README.md)
