# ycCsv

Cadence SKILL++ 的 CSV/TSV 编解码库：RFC 4180 风格字段规则与带可选表头的 Table 模型。

## 概要

+ 解码入口：`decode()`；编码入口：`encode()`；`?format` 选 `"csv"`（默认）或 `"tsv"`。
+ 解码结果统一为不可变对象 `ycCsv::Table`；编码输入必须是 `ycCsv::Table`。
+ 字段一律为字符串，不做数字/布尔推断；不 trim、不排序、不做 Unicode 规范化。
+ 支持引号内分隔符与换行、双引号转义、LF/CRLF/CR 行尾、可选表头、BOM 剥离与自定义单字节分隔符。
+ 表格行列均 1-based；无表头时可按索引访问，有表头时另可按列名取值。
+ 空行解码为含一个空字段的记录；有表头时短行缺位为 `ycCodec::Missing`（见 [ycCodec](../core/README.md)），超长行以 `error()` 中断。
+ 只处理内存文本；文件读写请配合 pathlib 的 `readText()` / `writeText()`。
+ `Table->render()` / `Table->print()` 可渲染美化表格；依赖 `ycTabulate`，`?maxColWidth` 折行由 `ycTextwrap` 提供。

## 快速上手

`t_csv_header` 的值如下所示：

```text
name,qty
apple,3
```

`t_csv_rows` 的值如下所示：

```text
a,b
c,d
```

`t_csv_quoted` 的值如下所示：

```text
"a,b",c
```

`t_csv_tsv` 的值如下所示（字段之间是制表符）：

```text
a	b
```

`t_csv_semicolon` 的值如下所示：

```text
x;y
```

```lisp
; 解码为 Table（首行作表头）
t_v = ycCsv::decode(t_csv_header ?header t)
t_v->header()                                       ; => ("name" "qty")
t_v->rowCount()                                     ; => 1
t_v->value(1 "qty")                                 ; => "3"

; 无表头：按行/列索引访问
t_v = ycCsv::decode(t_csv_rows)
t_v->rows()                                         ; => (("a" "b") ("c" "d"))
t_v->cell(2 1)                                      ; => "c"

; 引号、TSV 与自定义分隔符
ycCsv::decode(t_csv_quoted)->row(1)                 ; => ("a,b" "c")
ycCsv::decode(t_csv_tsv ?format "tsv")->row(1)      ; => ("a" "b")
ycCsv::decode(t_csv_semicolon ?delimiter ";")->row(1) ; => ("x" "y")

; 编码
ycCsv::encode(ycCsv::Table(list(list("a,b" "c"))))  ; => "\"a,b\",c\n"
ycCsv::encode(ycCsv::Table(list(list("a" "b"))) ?format "tsv")
; => "a\tb\n"
```

## API 参考

### ycCsv::Table <sub>`function`</sub> <sub>`class`</sub>

```text
ycCsv::Table(
    l_rows
    [ ?header l_header ]
)
=> Table
```

**描述**

构造不可变 CSV 表格。`l_rows` 为行列表，每行至少一个字段且字段全为字符串；`?header` 为可选列名列表，列名必须唯一（空字符串允许）。有表头时每行宽度不得超过列名数，短行合法；无表头时允许不规则行。构造时拷贝行与表头，调用方后续修改原列表不会影响表格。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| l_rows | list[list[str]] | | 数据行 |
| ?header | list[str] \| nil | nil | 可选列名列表；`nil` 表示无表头 |

**返回值**

`Table` — 新表格实例；行/表头类型非法、空行、重复列名或行宽超过表头时以 `error()` 中断。

**例程**

```lisp
t_v = ycCsv::Table(list(list("a" "b") list("c" "d")))
t_v->rowCount()                                     ; => 2
t_v->columnCount()                                  ; => 2

t_v = ycCsv::Table(list(list("1" "2")) ?header list("x" "y"))
t_v->value(1 "y")                                   ; => "2"

ycCsv::Table(list(list("1" "2")) ?header list("x"))
; *Error* ycCsv::Table: row 1 has 2 fields but header has 1
```

**方法**

> 必须使用 `->` 符号调用方法。

#### rowCount <sub>`method`</sub>

```text
rowCount()
=> int
```

返回数据行数；空表为 0。

#### columnCount <sub>`method`</sub>

```text
columnCount()
=> int
```

返回列数：有表头时为列名数，否则为最长行宽；空表为 0。

#### header <sub>`method`</sub>

```text
header()
=> list[str] | nil
```

返回表头列名列表；无表头返回 `nil`。返回内部列表，请勿原地修改。

#### rows <sub>`method`</sub>

```text
rows()
=> list
```

返回数据行列表（每行为 `list[str]`）。返回内部列表，请勿原地修改。

#### row <sub>`method`</sub>

```text
row(g_row)
=> list[str]
```

返回第 `g_row` 行（1-based）。行号非整数或越界时以 `error()` 中断。

| 参数 | 说明 |
| --- | --- |
| g_row | 行号（1-based） |

#### cell <sub>`method`</sub>

```text
cell(g_row g_col)
=> str | any
```

返回第 `g_row` 行第 `g_col` 列的值（1-based）。短行缺位返回 `ycCodec::Missing`；行/列非整数或越界时以 `error()` 中断。

| 参数 | 说明 |
| --- | --- |
| g_row | 行号（1-based） |
| g_col | 列号（1-based） |

#### columnAt <sub>`method`</sub>

```text
columnAt(g_col)
=> list
```

按列号返回整列值（1-based）；短行缺位为 `ycCodec::Missing`。列号非整数或越界时以 `error()` 中断。

| 参数 | 说明 |
| --- | --- |
| g_col | 列号（1-based） |

#### value <sub>`method`</sub>

```text
value(g_row g_name)
=> str | any
```

按列名取第 `g_row` 行的值（1-based）。无表头、列名未知、行号非整数或越界时以 `error()` 中断；短行缺位返回 `ycCodec::Missing`。

| 参数 | 说明 |
| --- | --- |
| g_row | 行号（1-based） |
| g_name | 列名（字符串） |

#### render <sub>`method`</sub>

```text
render(
    [ ?format t_format ]
    [ ?align g_align ]
    [ ?missingVal t_missingVal ]
    [ ?maxColWidth n_max ]
    [ ?unit t_unit ]
    [ ?ambiguous n_amb ]
)
=> str
```

渲染美化表格文本。表头自动取自 Table；有表头时按表头宽度补齐短行，无表头时按最长行宽补齐；`ycCodec::Missing` 与补齐单元格均使用 `?missingVal`。需要先加载 `ycTabulate`，未加载时以 `error()` 中断。`?maxColWidth` 非 nil 时由 tabulate 调用 textwrap 对单元格折行。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?format | str | "simple" | `plain` / `simple` / `grid` / `pipe` |
| ?align | str \| list | "left" | 单列或逐列对齐 |
| ?missingVal | str | "" | 缺失单元格替代文本 |
| ?maxColWidth | int \| nil | nil | 单元格折行宽度 |
| ?unit | str | "display" | `display` 或 `char` |
| ?ambiguous | int | 1 | East Asian Ambiguous 宽度 |

`t_csv` 的值如下所示：

```text
name,qty
apple,3
```

**例程**

```lisp
t_v = ycCsv::decode(t_csv ?header t)
t_v->render()
; => name   qty
;    -----  ---
;    apple  3

t_v->render(?format "grid")
; => +-------+-----+
;    | name  | qty |
;    +=======+=====+
;    | apple | 3   |
;    +-------+-----+
```

#### print <sub>`method`</sub>

```text
print(
    [ l_args ... ]
)
=> t
```

`print` 使用与 `render` 相同的选项渲染表格并输出到 stdout，末尾补一个换行；空表不输出。需要先加载 `ycTabulate`，否则以 `error()` 中断。

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| l_args ... | any | 原样透传给 `render` 的实参（`?format`、`?align`、`?missingVal`、`?maxColWidth`、`?unit`、`?ambiguous`，可全部省略）；详见上面的 `render` 条目。 |

**例程**

```lisp
t_v->print(?format "grid")
; 输出：
; +-------+-----+
; | name  | qty |
; +=======+=====+
; | apple | 3   |
; +-------+-----+
; => t
```

#### 打印形式

`printself` 输出形如 `<ycCsv::Table rows=2 columns=3>`。

### ycCsv::decode <sub>`function`</sub>

```text
ycCsv::decode(
    t_str
    [ ?format t_format ]
    [ ?header g_header ]
    [ ?delimiter t_delimiter ]
    [ ?skipEmpty g_skipEmpty ]
    [ ?stripBom g_stripBom ]
)
=> Table
```

**描述**

解码 CSV/TSV 文本为 `Table`。`?format "csv"`（默认）以逗号为分隔符，`"tsv"` 以制表符为分隔符；`?delimiter` 可覆盖为任意单字节字符（不能是引号、CR、LF）。`?header t` 取首条记录作列名（`?skipEmpty t` 时取首条非空记录），`?header list` 使用给定列名，默认 `nil` 表示无表头。`?skipEmpty t` 跳过“单个空字段”的记录；`?stripBom` 默认 `t`，剥离开头 UTF-8 BOM。字段仅当以 `"` 开头时按引号规则解析；引号内 `""` 表示一个 `"`，可含分隔符与换行。空文本返回空 Table；行尾只作记录终止符，不额外产生空记录。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_str | str | | 输入文本 |
| ?format | str | "csv" | `"csv"` 或 `"tsv"`；其他值以 `error()` 中断 |
| ?header | t \| list[str] \| nil | nil | `t` 首行作表头（`?skipEmpty t` 时为首个非空行）；列表使用给定列名；`nil` 无表头 |
| ?delimiter | str \| nil | nil | 单字节分隔符覆盖；默认逗号或制表符 |
| ?skipEmpty | t \| nil | nil | t 时跳过单空字段记录 |
| ?stripBom | t \| nil | t | t 时剥离开头 UTF-8 BOM |

**返回值**

`Table` — 解码结果；格式/选项非法、引号未闭合或表头行超宽时以 `error()` 中断。

**例程**

`t_csv_values` 的值如下所示：

```text
a,b
1,2
```

`t_csv_blank` 的值如下所示：

```text
a

b
```

`t_csv_overlong` 的值如下所示：

```text
a,b
1,2,3
```

```lisp
t_v = ycCsv::decode(t_csv_rows)
t_v->rows()                                         ; => (("a" "b") ("c" "d"))

t_v = ycCsv::decode(t_csv_header ?header t)
t_v->header()                                       ; => ("name" "qty")
t_v->value(1 "name")                                ; => "apple"

ycCsv::decode(t_csv_values ?header list("x" "y"))->value(1 "y")
; => "b"

ycCsv::decode(t_csv_quoted)->row(1)                 ; => ("a,b" "c")
ycCsv::decode(t_csv_blank)->rowCount()              ; => 3
ycCsv::decode(t_csv_blank ?skipEmpty t)->rowCount() ; => 2
ycCsv::decode(t_csv_tsv ?format "tsv")->row(1)      ; => ("a" "b")

ycCsv::decode("\"a\"x\n")
; *Error* ycCsv::decode: unexpected character after closing quote at line 1, column 4
ycCsv::decode(t_csv_overlong ?header t)
; *Error* ycCsv::decode: row 1 has 3 fields but header has 2 at line 2, column 1
```

### ycCsv::encode <sub>`function`</sub>

```text
ycCsv::encode(
    g_table
    [ ?format t_format ]
    [ ?delimiter t_delimiter ]
    [ ?eol t_eol ]
    [ ?quoteAll g_quoteAll ]
    [ ?finalNewline g_finalNewline ]
)
=> str
```

**描述**

把 `Table` 编码为 CSV/TSV 文本。表头存在时先输出表头行；字段含分隔符、`"`、CR 或 LF 时自动加引号，内部 `"` 双写；`?quoteAll t` 时所有字段都加引号。`?eol` 只接受 `"\n"`（默认）或 `"\r\n"`；`?finalNewline nil` 去掉末尾行尾。空 Table 输出空串。`?format` 决定默认分隔符，`?delimiter` 可覆盖为单字节字符。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_table | Table | | 待编码表格 |
| ?format | str | "csv" | `"csv"` 或 `"tsv"`；其他值以 `error()` 中断 |
| ?delimiter | str \| nil | nil | 单字节分隔符覆盖；默认逗号或制表符 |
| ?eol | str | "\n" | 行尾 `"\n"` 或 `"\r\n"` |
| ?quoteAll | t \| nil | nil | t 时所有字段加引号 |
| ?finalNewline | t \| nil | t | 非空输出末尾是否补行尾 |

**返回值**

`str` — 编码文本；非 `Table`、选项非法或行宽超过表头时以 `error()` 中断。

**例程**

```lisp
ycCsv::encode(ycCsv::Table(list(list("a" "b"))))     ; => "a,b\n"
ycCsv::encode(ycCsv::Table(list(list("a,b" "c"))))   ; => "\"a,b\",c\n"
ycCsv::encode(ycCsv::Table(list(list("a" "b"))) ?format "tsv")
; => "a\tb\n"

ycCsv::encode(ycCsv::Table(list(list("1" "2")) ?header list("x" "y")))
; => "x,y\n1,2\n"

ycCsv::encode(ycCsv::Table(list(list("a" "b"))) ?quoteAll t)
; => "\"a\",\"b\"\n"

ycCsv::encode(ycCsv::Table(list(list("a" "b"))) ?finalNewline nil)
; => "a,b"

ycCsv::encode(ycCsv::Table(list(list(""))) ?finalNewline nil)
; => "\"\""

ycCsv::encode(nil)
; *Error* ycCsv::encode: expects a ycCsv::Table

ycCsv::encode(ycCsv::Table(list(list("a"))) ?eol "\r")
; *Error* ycCsv::encode: ?eol must be "\n" or "\r\n"
```

## 引号与空行规则

+ 引号只在一个字段的首字节为 `"` 时生效；引号内 `""` 表示一个 `"`，可包含分隔符、CR、LF。
+ 裸字段中出现 `"`、闭合引号后出现分隔符/行尾以外的字符、引号未闭合，均以 `error()` 中断并给出行列号。
+ 行尾接受 LF、CRLF、CR；文件末尾换行只作记录终止符。
+ 空行解码为 `list("")`；`?skipEmpty t` 跳过解码后为单空字段的记录（不跳过 `a,,b` 这类多字段空值行）。
+ 编码单个空字段行时默认输出空行；当 `?finalNewline nil` 且该记录是最后一条时输出 `""`，避免与空输出混淆。
+ 空格原样保留，引号前有空格不触发引号解析。

## 表头与缺位

+ `?header t` 时首条记录为表头（`?skipEmpty t` 时为首条非空记录）；只有表头时返回 0 行、`columnCount()` 等于列名数的 Table。
+ `?header list` 时全部记录都是数据；空文本返回仅含表头的 0 行 Table。
+ 列名重复以 `error()` 中断；空列名允许，但必须唯一。
+ 有表头时，记录字段数超过列名数会以 `error()` 中断；短行合法，`cell()` / `columnAt()` / `value()` 返回 `ycCodec::Missing`。
+ 无表头时行宽可不等，`columnCount()` 取最长行宽；`value()` 因无列名而以 `error()` 中断。

## 边界与限制

+ 分隔符必须是单字节；引号固定为 `"`，不支持反斜杠转义或多字符分隔符。
+ 不做类型推断：`"1"`、`"true"` 等仍是字符串；需要数值请自行转换。
+ 不 trim、不排序、不做 Unicode 规范化；字段按字节透传。
+ `?quoteAll t` 只影响输出，解码端仍按标准引号规则读取。
+ 编码不做字段换行归一化；字段内的 CR/LF 原样保留在引号中。
