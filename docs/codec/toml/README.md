# ycToml

Cadence SKILL++ 的 TOML 1.0 编解码库。

## 概要

+ 解码入口：`decode()`；编码入口：`encode()`。
+ 解码返回根 `table`；编码输入必须是 `table`。
+ 日期与时间解码为原始文本字符串，编码时按普通字符串加引号；不做日期时间对象转换。
+ 布尔值使用 `ycCodec::True` / `ycCodec::False`；缺键返回 `ycCodec::Missing`；TOML 无 null。
+ 整数按 32 位 fixnum 范围校验，越界以 `error()` 中断；浮点支持 `inf` / `nan`。
+ 解码 `nil` 表示空数组；编码 `nil` 输出 `[]`。表数组解码为 table 列表。
+ 输入与输出字符串必须是合法 UTF-8；解码剥离开头 BOM，并接受 LF / CRLF / CR 行尾。
+ 解码语法错误消息带行列号；非法 UTF-8 以 `error()` 中断。

## 快速上手

`t_toml` 的值如下所示：

```text
title = "demo"

[server]
host = "localhost"
ports = [8000, 8001]
```

`t_toml_date` 的值如下所示：

```text
d = 1979-05-27
```

`t_toml_products` 的值如下所示：

```text
[[products]]
name = "Hammer"
```

`t_toml_bad_int` 的值如下所示：

```text
x = 2147483648
```

```lisp
t_v = ycToml::decode(t_toml)
t_v["title"]                                        ; => "demo"
t_v["server"]["host"]                               ; => "localhost"
t_v["server"]["ports"]                              ; => (8000 8001)
t_v["missing"]                                      ; => ycCodec::Missing

ycToml::encode(t_v ?sortKeys t)
; => title = "demo"
;
;    [server]
;    host = "localhost"
;    ports = [8000, 8001]

ycToml::decode(t_toml_date)["d"]                    ; => "1979-05-27"
ycToml::decode(t_toml_products)["products"]
; => (<table: name = "Hammer">)

ycToml::decode(t_toml_bad_int)
; *Error* ycToml::decode: integer out of fixnum range at line 1, column 5
```

## API 参考

### ycToml::decode <sub>`function`</sub>

```text
ycToml::decode(
    t_str
    [ ?maxDepth n_max ]
)
=> table
```

**描述**

解码完整 TOML 文档为根 `table`。支持 TOML 1.0 的注释、裸键/引号键/点分键、表、表数组、内联表、数组、基本字符串/字面量字符串/多行字符串、整数、浮点、布尔和日期时间。数组与块式表结构允许换行和注释；内联表禁止换行与尾逗号；重复键、表冲突、非法转义、非法数字、非法日期、非法 UTF-8 和未闭合结构均以 `error()` 中断。`?maxDepth` 限制嵌套深度，防止过深结构耗尽栈（默认 800）。

日期、时间和日期时间保留输入原文，不转换为时间对象；解码结果与字符串无法区分。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_str | str | | 输入文本 |
| ?maxDepth | int | 800 | 最大嵌套深度（≥1；超限以 `error()` 中断） |

**返回值**

`table` — 文档根表；空文档返回空表。语法或语义错误以 `error()` 中断，消息带 `line` / `column`。

**例程**

`t_toml_dotted` 的值如下所示：

```text
a.b = 1
```

`t_toml_escape` 的值如下所示：

```text
name = "a\tb"
```

`t_toml_arrays` 的值如下所示：

```text
[[a]]
x = 1

[[a]]
x = 2
```

`t_toml_numbers` 的值如下所示：

```text
f = 1e3
n = nan
```

`t_toml_duplicate` 的值如下所示：

```text
a = 1
a = 2
```

`t_toml_bad_date` 的值如下所示：

```text
a = 2023-02-29
```

```lisp
t_v = ycToml::decode(t_toml_dotted)
t_v["a"]["b"]                                        ; => 1

t_v = ycToml::decode(t_toml_escape)
t_v["name"]                                          ; => "a\tb"

t_v = ycToml::decode(t_toml_arrays)
t_v["a"]                                             ; => (<table: x = 1> <table: x = 2>)

t_v = ycToml::decode(t_toml_numbers)
t_v["f"]                                             ; => 1000.0
isNaN(t_v["n"])                                      ; => t

ycToml::decode(t_toml_duplicate)
; *Error* ycToml::decode: duplicate key at line 2, column 1

ycToml::decode(t_toml_bad_date)
; *Error* ycToml::decode: invalid date at line 1, column 5
```

### ycToml::encode <sub>`function`</sub>

```text
ycToml::encode(
    g_val
    [ ?sortKeys g_sort ]
    [ ?strict g_strict ]
    [ ?finalNewline g_finalNewline ]
    [ ?maxDepth n_max ]
)
=> str
```

**描述**

编码根 `table` 为 TOML 文本。根中的标量/数组键值先输出，子表以 `[a.b]` 分节，表数组以 `[[a.b]]` 分节；分节之间空一行。空根输出空字符串。`nil` 输出空数组，`t` 与 `ycCodec::True` 输出 `true`，`ycCodec::False` 输出 `false`；`ycCodec::Null`、`ycCodec::Missing`、普通符号和其他不可表示值以 `error()` 中断。浮点的 `inf` / `nan` 按 TOML 字面量输出；字符串按键与值分别转义；非法 UTF-8 字符串以 `error()` 中断。

键默认把字符串原样、符号取符号名、fixnum 转十进制；转换后发生碰撞时以 `error()` 中断。`?strict t` 要求键必须为字符串。表键默认按表序输出；需要确定性结果时传 `?sortKeys t`。`?finalNewline nil` 关闭非空输出的末尾换行。

日期时间不自动识别：字符串中的日期文本按普通字符串加引号输出。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_val | table | | 根表 |
| ?sortKeys | t \| nil | nil | 每层键是否按字符串升序输出；默认随表序 |
| ?strict | t \| nil | nil | t 时键必须为字符串，符号/整数键以 `error()` 中断 |
| ?finalNewline | t \| nil | t | 非空输出末尾是否补换行 |
| ?maxDepth | int | 800 | 最大嵌套深度（≥1；超限以 `error()` 中断） |

**返回值**

`str` — TOML 文本；无法表示或根不是 `table` 时以 `error()` 中断。

**例程**

`t_toml_encode` 的值如下所示：

```text
title = "demo"

[server]
host = "localhost"
```

```lisp
t_v = ycToml::decode(t_toml_encode)
ycToml::encode(t_v ?sortKeys t)
; => title = "demo"
;
;    [server]
;    host = "localhost"

t_v = makeTable("demo")
t_v["a"] = list(1 2)
t_v["s"] = "a\"b"
ycToml::encode(t_v ?sortKeys t)
; => "a = [1, 2]\ns = \"a\\\"b\"\n"

ycToml::encode(makeTable("demo") ?finalNewline nil)  ; => ""

ycToml::encode("not a table")
; *Error* ycToml::encode: root value must be a table

ycToml::encode(list(1 2))
; *Error* ycToml::encode: root value must be a table
```

## 类型映射

| TOML | 解码结果 | 编码输入 |
| --- | --- | --- |
| table | table | table |
| array | list；空数组为 `nil` | list；`nil` 输出空数组 |
| string | str | str |
| integer | fixnum（32 位范围） | fixnum |
| float | flonum | flonum、`inf`、`nan` |
| boolean | `ycCodec::True` / `ycCodec::False` | `t`、`ycCodec::True`、`ycCodec::False` |
| date / time / datetime | str（原文） | str（按普通字符串输出） |

## 边界说明

+ 整数超出 32 位 fixnum 范围时以 `error()` 中断，不截断、不回绕。
+ 解码后的日期时间与普通字符串不可区分；需要保留类型语义时，由调用方自行约定字段。
+ `\u0000` 解码为空串：SKILL 字符串不能稳定承载 NUL 字节；其余 Unicode 标量值正常编码。
+ 空数组与空表数组都表示为 `nil`；编码空表数组得到空根或空表，无法保留原始书写形式。
+ 未指定 `?sortKeys` 时，表键顺序由 table 遍历顺序决定，不承诺稳定输出顺序。
