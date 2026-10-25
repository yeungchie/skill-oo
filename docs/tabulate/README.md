# ycTabulate

[返回首页](../../README.md)

Cadence SKILL++ 的文本表格库：把行数据渲染为定宽文本表。

## 概要

+ 输入为行列表，每行是等长单元格列表；`?headers` 提供表头。单元格支持字符串、整数、浮点、`nil` 与其他值。
+ 列宽按显示列计算（默认 `?unit "display"`）；`?unit "char"` 时按码点数计算。
+ 四种输出格式：`"plain"`、`"simple"`（默认）、`"grid"`、`"pipe"`（竖线表格）。
+ 对齐支持 `"left"`、`"right"`、`"center"`、`"decimal"`；可单值应用于所有列，也可逐列指定。
+ `?maxColWidth` 对单元格折行（复用 `ycTextwrap::Wrap`）；多行单元格在非 pipe 格式中展开为多物理行。
+ 记法约定：例程注释中 `; =>` 标记返回值，多行输出在后续 `;` 注释中逐行展示；`; *Error*` 标记错误消息；错误消息以 `ycTabulate::Render:` 为前缀。

## 快速上手

```lisp
; 基本表格
ycTabulate::Render(list(list("a" 1) list("bb" 22)) ?headers list("name" "n"))
; => name  n
;    ----  --
;    a     1
;    bb    22

; 网格与小数点对齐
ycTabulate::Render(
    list(list("1.2" 10) list("22.345" 3.4))
    ?headers list("a" "b")
    ?format "grid"
    ?align "decimal"
)
; => +--------+------+
;    |  a     |  b   |
;    +========+======+
;    |  1.2   | 10   |
;    +--------+------+
;    | 22.345 |  3.4 |
;    +--------+------+

; 单元格折行
ycTabulate::Render(
    list(list("alpha beta" "x") list("c" "y"))
    ?headers list("long" "z")
    ?maxColWidth 5
)
; => long   z
;    -----  -
;    alpha  x
;    beta
;    c      y

; pipe 格式（多行转 <br>，竖线转义）
ycTabulate::Render(list(list("a\nb" "c|d")) ?headers list("h1" "h2") ?format "pipe")
; => | h1     | h2   |
;    | :----- | :--- |
;    | a<br>b | c\|d |
```

## API 参考

### ycTabulate::Render <sub>`function`</sub>

```text
ycTabulate::Render(
    l_rows
    [ ?headers nil ]
    [ ?format "simple" ]
    [ ?align "left" ]
    [ ?floatFmt "%g" ]
    [ ?missingVal "" ]
    [ ?maxColWidth nil ]
    [ ?unit "display" ]
    [ ?ambiguous 1 ]
)
=> str
```

**描述**

把行数据渲染为文本表格。每行须为列表且各行列数相同；`?headers` 为 nil 或与列数等长的列表。单元格转换：字符串原样；`nil` 替换为 `?missingVal`；整数按 `%d`；浮点按 `?floatFmt`；其他类型按 `%A`。

列宽取该列表头与各单元格物理行的最大宽度；`?maxColWidth` 非 nil 时先折行再取宽度。`?format` 选择输出样式（见[格式](#格式)），`?align` 选择对齐方式（见[对齐](#对齐)）。无列（无表头且无行）时返回空串。行不齐、表头与行宽不一致、格式/对齐选项非法、浮点格式不可用等情形以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| l_rows | list[list[any]] / nil |  | 行数据 |
| ?headers | list[any] / nil | nil | 表头单元格；nil 无表头 |
| ?format | str | `"simple"` | `"plain"` / `"simple"` / `"grid"` / `"pipe"` |
| ?align | str / list[str] | `"left"` | 单值或逐列对齐 |
| ?floatFmt | str | `"%g"` | 浮点单元格格式 |
| ?missingVal | str | `""` | nil 单元格的替代文本 |
| ?maxColWidth | int / nil | nil | 单元格折行宽度；nil 不折行 |
| ?unit | str | `"display"` | `"display"` 显示列宽或 `"char"` 码点数 |
| ?ambiguous | int | 1 | East Asian Ambiguous 宽度（1 或 2） |

**返回值**

`str` — 表格文本；无列时为 `""`。

**例程**

```lisp
ycTabulate::Render(list(list("a" 1) list("bb" 22)) ?headers list("name" "n"))
; => name  n
;    ----  --
;    a     1
;    bb    22

ycTabulate::Render(list(list(nil 'sym "s")) ?headers list("a" "b" "c") ?missingVal "NA" ?format "grid")
; => +----+-----+---+
;    | a  | b   | c |
;    +====+=====+===+
;    | NA | sym | s |
;    +----+-----+---+

ycTabulate::Render(list(list(1.23456 2.0)) ?floatFmt "%.2f")
; => "1.23  2.00"

ycTabulate::Render(list(list("a" 1) list("bb" 22)) ?headers list("name" "n") ?align list("left" "right"))
; => name   n
;    ----  --
;    a      1
;    bb    22

ycTabulate::Render(list(list("a" 1)) ?format "unknown")
; => 以 error() 中断（未知格式）
```

## 格式

| 格式 | 说明 |
| --- | --- |
| `plain` | 无边框；单元格间以两个空格分隔，无表头分隔线 |
| `simple` | 无边框；表头后加由 `-` 组成的分隔线 |
| `grid` | `+---+` 边框；表头后用 `+===+`，每行数据后加边框 |
| `pipe` | 竖线表格；表头后输出对齐分隔行 |

`pipe` 格式中，单元格内的 `|` 写成 `\|`，多行单元格以 `<br>` 连接；列宽至少为 3，保证分隔行有效。其余格式中，多行单元格展开为多物理行，较短单元格补空白。

```lisp
ycTabulate::Render(list(list("a" 1) list("bb" 22)) ?headers list("name" "n") ?format "grid")
; => +------+----+
;    | name | n  |
;    +======+====+
;    | a    | 1  |
;    +------+----+
;    | bb   | 22 |
;    +------+----+

ycTabulate::Render(list(list("a" 1) list("bb" 22)) ?headers list("name" "n") ?format "pipe")
; => | name | n   |
;    | :--- | :-- |
;    | a    | 1   |
;    | bb   | 22  |
```

## 对齐

| 对齐 | 行为 |
| --- | --- |
| `left` | 左对齐（默认） |
| `right` | 右对齐 |
| `center` | 居中；余量左侧取 floor、右侧取 ceil |
| `decimal` | 按各物理行首个 `.` 分左右两段，分别取最大宽度后对齐小数点；无小数点视为右段为空 |

```lisp
ycTabulate::Render(
    list(list("1.2" "10") list("22.345" "3.4") list("5" "6.78"))
    ?headers list("a" "b")
    ?align "decimal"
)
; =>  a       b
;    ------  -----
;     1.2    10
;    22.345   3.4
;     5       6.78

ycTabulate::Render(list(list("a" 1) list("bb" 22)) ?headers list("name" "n") ?align "center")
; => name  n
;    ----  --
;     a    1
;     bb   22
```

[返回首页](../../README.md)
