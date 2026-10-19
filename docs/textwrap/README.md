# ycTextwrap

Cadence SKILL++ 的文本折行与块缩进库：定宽折行、公共缩进处理与超长截断。

## 概要

+ 折行宽度按显示列计算（默认 `?unit "display"`）；汉字与全角字符占两列。`?unit "char"` 时按码点数计算。
+ 逻辑行内的空白（空格、制表符）连续段折叠为单个空格并去两端；物理换行是硬边界，显式空行保留。
+ 缩进计入行宽：首行用 `?initialIndent`，其余内容行用 `?subsequentIndent`。
+ 超宽词默认硬切；`?breakOnHyphens t` 时优先在连字符后断。`?maxLines` 可限制输出行数并用占位符标记截断。
+ 记法约定：例程注释中 `; =>` 标记返回值，`; *Error*` 标记错误消息。
+ 库内校验触发的错误消息以 `ycTextwrap::<过程>:` 为前缀，可用 `errset` 捕获。

## 快速上手

```lisp
; 定宽折行
ycTextwrap::wrap("one two three" ?width 7)                  ; => ("one two" "three")
ycTextwrap::wrap("中文测试" ?width 4)                       ; => ("中文" "测试")
ycTextwrap::wrap("one two three" ?width 9 ?initialIndent "> " ?subsequentIndent "  ")
; => ("> one two" "  three")

; 长词与截断
ycTextwrap::wrap("abcdefgh" ?width 4)                       ; => ("abcd" "efgh")
ycTextwrap::wrap("one two three four" ?width 7 ?maxLines 2) ; => ("one two" "thre...")

; 拼回、缩进与截断
ycTextwrap::fill("one two three" ?width 7)                  ; => "one two\nthree"
ycTextwrap::dedent("  a\n    b\n  c")                       ; => "a\n  b\nc"
ycTextwrap::indent("a\n b" ?prefix "- ")                    ; => "- a\n-  b"
ycTextwrap::shorten("hello world" 8)                        ; => "hello..."
```

## API 参考

### ycTextwrap::wrap <sub>`function`</sub>

```text
ycTextwrap::wrap(
    t_text
    [ ?width 70 ]
    [ ?initialIndent "" ]
    [ ?subsequentIndent "" ]
    [ ?breakLongWords t ]
    [ ?breakOnHyphens t ]
    [ ?maxLines nil ]
    [ ?placeholder "..." ]
    [ ?unit "display" ]
    [ ?ambiguous 1 ]
)
=> list[str] | nil
```

**描述**

按目标宽度把文本折成行列表。物理换行（`\n`、`\r\n`、`\r`）是硬边界，每个逻辑行独立折行；行内空白连续段折叠为单空格并去两端。首行内容加 `?initialIndent`，其余内容行加 `?subsequentIndent`；显式空行输出为 `""`，不加缩进。

超宽词在 `?breakLongWords` 非 nil 时按码点边界硬切，不拆多字节字符；`?breakOnHyphens` 非 nil 时优先在可用宽度内最后一个连字符后断开。`?maxLines` 非 nil 且输出超限时只保留前 N 行，末行按占位符宽度截断并追加 `?placeholder`；占位符本身宽于行宽时按宽度截断。空文本或仅空白的单行输入返回 `nil`。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_text | str |  | 输入文本 |
| ?width | int | 70 | 目标行宽（含缩进，≥ 1） |
| ?initialIndent | str | `""` | 首行缩进 |
| ?subsequentIndent | str | `""` | 其余内容行缩进 |
| ?breakLongWords | t \| nil | t | 非 nil 时硬切超宽词 |
| ?breakOnHyphens | t \| nil | t | 非 nil 时优先在连字符后断 |
| ?maxLines | int \| nil | nil | 最大输出行数；nil 不限 |
| ?placeholder | str | `"..."` | 截断占位符 |
| ?unit | str | `"display"` | `"display"` 显示列宽或 `"char"` 码点数 |
| ?ambiguous | int | 1 | East Asian Ambiguous 宽度（1 或 2） |

**返回值**

`list[str] | nil` — 各行文本（含缩进）；空文本或全空白单行为 `nil`。

**例程**

```lisp
ycTextwrap::wrap("hello world" ?width 11)  ; => ("hello world")
ycTextwrap::wrap("hello world" ?width 7)   ; => ("hello" "world")
ycTextwrap::wrap("a\n\nb" ?width 10)       ; => ("a" "" "b")
ycTextwrap::wrap("中文" ?width 2 ?unit "char") ; => ("中文")
ycTextwrap::wrap("ab-cdefgh" ?width 4)     ; => ("ab-" "cdef" "gh")
ycTextwrap::wrap("abcdefgh" ?width 4 ?breakLongWords nil) ; => ("abcdefgh")
ycTextwrap::wrap("one two three four" ?width 7 ?maxLines 2 ?placeholder "…")
; => ("one two" "three…")
ycTextwrap::wrap("a" ?width 0)
; => 以 error() 中断（宽度须为正整数）
```

### ycTextwrap::fill <sub>`function`</sub>

```text
ycTextwrap::fill(
    t_text
    [ ?width 70 ]
    [ ?initialIndent "" ]
    [ ?subsequentIndent "" ]
    [ ?breakLongWords t ]
    [ ?breakOnHyphens t ]
    [ ?maxLines nil ]
    [ ?placeholder "..." ]
    [ ?unit "display" ]
    [ ?ambiguous 1 ]
    [ ?sep "\n" ]
)
=> str
```

**描述**

折行后以 `?sep` 拼回。折行选项与 `ycTextwrap::wrap` 相同；`ycTextwrap::wrap` 返回 `nil` 时结果为空串。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_text | str |  | 输入文本 |
| ?width | int | 70 | 目标行宽 |
| ?initialIndent | str | `""` | 首行缩进 |
| ?subsequentIndent | str | `""` | 其余内容行缩进 |
| ?breakLongWords | t \| nil | t | 非 nil 时硬切超宽词 |
| ?breakOnHyphens | t \| nil | t | 非 nil 时优先在连字符后断 |
| ?maxLines | int \| nil | nil | 最大输出行数 |
| ?placeholder | str | `"..."` | 截断占位符 |
| ?unit | str | `"display"` | 宽度单位 |
| ?ambiguous | int | 1 | East Asian Ambiguous 宽度 |
| ?sep | str | `"\n"` | 行分隔符 |

**返回值**

`str` — 拼回后的文本；空输入为 `""`。

**例程**

```lisp
ycTextwrap::fill("one two three" ?width 7)       ; => "one two\nthree"
ycTextwrap::fill("one two three" ?width 7 ?sep "|") ; => "one two|three"
ycTextwrap::fill("" ?width 7)                    ; => ""
```

### ycTextwrap::dedent <sub>`function`</sub>

```text
ycTextwrap::dedent(t_text)
=> str
```

**描述**

去除所有非空白行的最长公共前导空白（空格与制表符逐字符比较）。仅空白行归一为空串；无公共缩进时仅做该归一。行数与末尾换行保留，换行统一为 LF。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_text | str | 输入文本 |

**返回值**

`str` — 去除公共缩进后的文本；空输入为 `""`。

**例程**

```lisp
ycTextwrap::dedent("  a\n    b\n  c")  ; => "a\n  b\nc"
ycTextwrap::dedent(" a\n  b")           ; => "a\n b"
ycTextwrap::dedent("  a\n\n  b")        ; => "a\n\nb"
```

### ycTextwrap::indent <sub>`function`</sub>

```text
ycTextwrap::indent(
    t_text
    [ ?prefix "  " ]
)
=> str
```

**描述**

给每个非空白行加统一前缀；空白行与空行原样保留。换行统一为 LF。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_text | str |  | 输入文本 |
| ?prefix | str | `"  "` | 行前缀 |

**返回值**

`str` — 加前缀后的文本；空输入为 `""`。

**例程**

```lisp
ycTextwrap::indent("a\n b")             ; => "  a\n   b"
ycTextwrap::indent("a\n\n b" ?prefix "- ") ; => "- a\n\n-  b"
```

### ycTextwrap::shorten <sub>`function`</sub>

```text
ycTextwrap::shorten(
    t_text
    n_width
    [ ?placeholder "..." ]
    [ ?unit "display" ]
    [ ?ambiguous 1 ]
)
=> str
```

**描述**

把空白连续段折叠为单空格并去两端；折叠后不超宽则原样返回。超宽时在 `n_width` 内截断：优先在最后一个空格处断词并去尾空白，无空格则按码点硬切，随后追加占位符。占位符宽于 `n_width` 时仅返回按宽度截断的占位符。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_text | str |  | 输入文本 |
| n_width | int |  | 目标宽度（≥ 1） |
| ?placeholder | str | `"..."` | 占位符 |
| ?unit | str | `"display"` | `"display"` 显示列宽或 `"char"` 码点数 |
| ?ambiguous | int | 1 | East Asian Ambiguous 宽度（1 或 2） |

**返回值**

`str` — 截断后的文本；未超宽时不加占位符。

**例程**

```lisp
ycTextwrap::shorten("hello world" 12)  ; => "hello world"
ycTextwrap::shorten("hello world" 8)   ; => "hello..."
ycTextwrap::shorten("abcdefghij" 5)    ; => "ab..."
ycTextwrap::shorten("中文测试" 4)       ; => "..."
ycTextwrap::shorten("abcdefgh" 5 ?placeholder "…") ; => "abcd…"
ycTextwrap::shorten("a" 0)
; => 以 error() 中断（宽度须为正整数）
```
