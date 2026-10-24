# ycIni

[返回首页](../../../README.md)

Cadence SKILL++ 的 INI 配置编解码库：把行式配置文本读成 table，或把 table 写成 INI 文本。

## 概要

- 行式格式：每行一个 `键 = 值`；`[段名]` 开始一个段，段内键值归入该段的子 table。
- 只有整行注释：行首（可带空格或制表符）的 `;` 或 `#` 后整行忽略；值和段名中的 `;`、`#` 是普通字符，不支持行内注释。
- 根表的键值位于第一个段之前；段名是字面量，不做点分嵌套；段内键值只保存在对应子 table 中。
- 解码得到的值一律是字符串，包括空值；引号、反斜杠、空格都按原样保留，不做转义或类型推断。
- 支持 UTF-8 BOM 与 LF、CRLF、CR 行尾；按字节处理，非 ASCII 字符原样保留。
- 编码时根标量键先输出，段按需在其后输出，段与段之间空一行；不可表示的值、非法键名以 `error()` 中断。

## 快速上手

```lisp
t_cfg = ycIni::Decode("root = value\n[server]\nhost = localhost\nport = 8080\n")
t_cfg["root"]              ; => "value"
t_cfg["server"]["host"]    ; => "localhost"
t_cfg["server"]["port"]    ; => "8080"

ycIni::Encode(t_cfg ?sortKeys t)
; => root = value
;
;    [server]
;    host = localhost
;    port = 8080

t_cfg = ycIni::Decode("a: 1\n[s]\nb: 2\n" ?delimiter ":")
t_cfg["a"]                 ; => "1"
t_cfg["s"]["b"]            ; => "2"
```

## API 参考

### ycIni::Decode <sub>`function`</sub>

```text
ycIni::Decode(
    t_str
    [ ?delimiter ]
    [ ?duplicates ]
)
=> table
```

**描述**

把 INI 文本解码为根 table。根表的键值直接保存在根表；每个段保存为同名的子 table。段名是字面量，`[a.b]` 得到键 `"a.b"`，不会展开为嵌套 table。

解码只识别整行注释：去掉行首空格和制表符后，以 `;` 或 `#` 开头的行被忽略。值和段名中的这两个字符没有特殊含义，不支持行内注释、续行或转义。键和值两侧的空格、制表符会被去掉；值内部的空白保留。空值解码为 `""`。重复键、重复段、非法段头、空键、缺少分隔符以及控制字符（制表符除外）均以 `error()` 中断。

默认分隔符是 `"="`；可用 `?delimiter` 指定其他单字节分隔符。分隔符不能是空白、`#`、`;`、`[` 或 `]`。`?duplicates` 控制重复项：

- `"error"`（默认）：重复键或重复段以 `error()` 中断。
- `"first"`：保留第一次出现的值；重复段继续合并后面出现的新键。
- `"last"`：后出现的值覆盖先前的值；重复段继续合并新键。

段名与根键同名时始终以 `error()` 中断，不受 `?duplicates` 影响。输入可以是空串；空文档返回空 table。缺失的键读出 `ycCodec::Missing`。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `t_str` | `str` | | INI 文本 |
| `?delimiter` | `str \| nil` | `"="` | 单字节键值分隔符 |
| `?duplicates` | `str \| nil` | `"error"` | 重复项策略：`"error"`、`"first"`、`"last"` |

**返回值**

`table` — 解码后的根 table；每个段是一个子 table

**例程**

```lisp
ycIni::Decode("")
; => 空 table

ycIni::Decode("a = 1\nb = text\n")
; => table，a 为 "1"，b 为 "text"

ycIni::Decode("[server]\nhost = localhost\n")
; => table，server 为子 table，host 为 "localhost"

ycIni::Decode("a = 1\na = 2\n" ?duplicates "last")
; => table，a 为 "2"

ycIni::Decode("[a]\n[a]\n")
; *Error* ycIni::Decode: duplicate section at line 2, column 1

ycIni::Decode("a = 1\n" ?delimiter " ")
; *Error* ycIni::Decode: ?delimiter must be a printable character other than '#' ';' '[' ']'
```

### ycIni::Encode <sub>`function`</sub>

```text
ycIni::Encode(
    g_val
    [ ?sortKeys ]
    [ ?strict ]
    [ ?delimiter ]
    [ ?finalNewline ]
)
=> str
```

**描述**

把根 table 编码为 INI 文本。根表的标量键先输出；子 table 作为段输出，段与段之间空一行。空段只输出段头。值支持字符串、符号、整数、有限浮点数、`t`、`ycCodec::True`、`ycCodec::False` 和 `nil`：布尔值写成 `true` / `false`，`nil` 写成空值，数字写成可回读的十进制文本。列表、嵌套 table、`ycCodec::Null`、`ycCodec::Missing` 以及其他不可表示的值以 `error()` 中断。

键默认接受字符串、符号和整数；`?strict t` 时只接受字符串。键不能为空、不能有首尾空白或控制字符、不能以 `[`、`#`、`;` 开头，也不能包含当前分隔符。段名同样不能为空、不能有首尾空白或控制字符，且不能包含 `[` 或 `]`。值的首尾空白和控制字符会被拒绝；制表符可以出现在值内部，但原样写出。字符串中的引号和反斜杠不转义，直接写出。

不同键转换成文本后若发生碰撞（例如字符串键 `"a"` 与符号键 `'a`），以 `error()` 中断；根标量键与段名碰撞也以 `error()` 中断。`?sortKeys t` 分别排序根键、段名和段内键；默认保持 table 的遍历顺序，不承诺跨实现的稳定顺序。

`?delimiter` 与解码的约束相同，默认 `"="`。输出非空时默认在末尾补一个换行；`?finalNewline nil` 不补。空 table 始终返回空串。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `g_val` | `table` | | 根 table |
| `?sortKeys` | `t \| nil` | `nil` | 分别排序根键、段名和段内键 |
| `?strict` | `t \| nil` | `nil` | 键必须为字符串 |
| `?delimiter` | `str \| nil` | `"="` | 单字节键值分隔符 |
| `?finalNewline` | `t \| nil` | `t` | 非空输出末尾补换行 |

**返回值**

`str` — INI 文本；根不是 table 或内容不可表示时以 `error()` 中断

**例程**

```lisp
t_cfg = makeTable("demo" ycCodec::Missing)
t_cfg["title"] = "demo"
t_cfg["server"] = makeTable("demo" ycCodec::Missing)
t_cfg["server"]["host"] = "localhost"

ycIni::Encode(t_cfg ?sortKeys t)
; => title = demo
;
;    [server]
;    host = localhost

ycIni::Encode(t_cfg ?delimiter ":")
; => title : demo
;
;    [server]
;    host : localhost

ycIni::Encode(t_cfg ?finalNewline nil)
; => title = demo
;
;    [server]
;    host = localhost

t_cfg["items"] = list(1 2)
ycIni::Encode(t_cfg)
; *Error* ycIni::Encode: list values are not supported

ycIni::Encode("not a table")
; *Error* ycIni::Encode: root value must be a table
```

[返回首页](../../../README.md)
