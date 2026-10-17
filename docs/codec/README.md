# ycCodec

Cadence SKILL++ 的文本编解码库：JSON、放宽 JSON（jsonc）与 JSON Lines（jsonl）的解析与输出。

## 概要

+ 解析入口：`jsonParse()`（严格）、`jsoncParse()`（允许注释与尾逗号）、`jsonlParse()`（逐行文档）。
+ 输出入口：`jsonDump()`（单值）、`jsonlDump()`（值列表逐行）。
+ 函数均在 `ycCodec` 命名空间下，以 `ycCodec::` 前缀调用。
+ `false` 与 `null` 不坍缩为 `nil`，分别解析为哨兵符号 `ycCodec::jsonFalse` 与 `ycCodec::jsonNull`；`nil` 仅表示空数组。
+ 例程中 `; =>` 表示返回值；`(...)` 为省略的输出或示意值。

## 快速上手

```lisp
; 解析
t_v = ycCodec::jsonParse("{\"a\":[1,2.5,true,null]}")
t_v["a"]                                            ; => (1 2.5 t jsonNull)

; 输出（默认紧凑、对象键排序）
ycCodec::jsonDump(t_v)                              ; => "{\"a\":[1,2.5,true,null]}"

; 缩进美化
ycCodec::jsonDump(t_v ?indent 2)
; => "{\n  \"a\": [\n    1,\n    2.5,\n    true,\n    null\n  ]\n}"

; 放宽文本与逐行格式
ycCodec::jsoncParse("{ // 备注\n \"a\": 1, }")      ; => <table: a = 1>
ycCodec::jsonlParse("1\n{\"a\":2}\n")               ; => (1 <table: a = 2>)
ycCodec::jsonlDump(list(1 "x"))                     ; => "1\n\"x\"\n"
```

## 类型映射

| JSON | 库内表示 |
| --- | --- |
| object | table |
| array | list（空数组为 `nil`） |
| string | 字符串（UTF-8 字节级透传） |
| number（整数） | fixnum（32 位范围内），超出为 flonum |
| number（含小数或指数） | flonum |
| true | `t` |
| false | `ycCodec::jsonFalse` |
| null | `ycCodec::jsonNull` |

对象缺键以 `ycCodec::jsonMissing` 表示：解析出的 table 以此为缺省值，读取不存在的键返回它；它一旦作为待输出值出现即报错。判断缺键写法：

```lisp
t_v["flag"] == ycCodec::jsonFalse    ; 值为 false
t_v["list"] == nil                   ; 值为空数组
t_v["nope"] == ycCodec::jsonMissing  ; 键不存在
```

## API 参考

### ycCodec::jsonParse <sub>`function`</sub>

```text
ycCodec::jsonParse(t_str)
=> any
```

**描述**

解析严格 JSON 单文档：前导与尾随空白允许；尾随非空白字符、注释、尾逗号均报错。重复键取最后值。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_str | str | JSON 文本 |

**返回值**

`any` — 解析产物，按「类型映射」转换；解析失败以 `error()` 中断。

**例程**

```lisp
ycCodec::jsonParse("42")                    ; => 42
ycCodec::jsonParse("1e3")                   ; => 1000.0
ycCodec::jsonParse("2147483648")            ; => 2147483648.0
ycCodec::jsonParse("\"a\\u4e2d\"")          ; => "a中"
ycCodec::jsonParse("[1, 2,]")
; *Error* ycCodec: unexpected character at line 1, column 7
```

### ycCodec::jsoncParse <sub>`function`</sub>

```text
ycCodec::jsoncParse(t_str)
=> any
```

**描述**

解析放宽 JSON 单文档：在 `jsonParse()` 规则之外，允许 `//` 行注释、`/* */` 块注释与数组/对象尾逗号；双引号字符串内的注释标记不生效。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_str | str | 放宽 JSON 文本 |

**返回值**

`any` — 解析产物；解析失败以 `error()` 中断。

**例程**

```lisp
ycCodec::jsoncParse("{ \"a\": 1, }")        ; => <table: a = 1>
ycCodec::jsoncParse("[1, /* c */ 2]")       ; => (1 2)
ycCodec::jsoncParse("// c\n1")              ; => 1
ycCodec::jsoncParse("/* c")
; *Error* ycCodec: unterminated block comment at line 1, column 1
```

### ycCodec::jsonlParse <sub>`function`</sub>

```text
ycCodec::jsonlParse(t_str)
=> list
```

**描述**

逐行解析 JSON Lines 文本：每个非空行须是完整且严格的 JSON 文档（不支持注释与跨行）；空行与全空白行跳过。错误消息中的行号为原始文本行号。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_str | str | JSON Lines 文本 |

**返回值**

`list` — 按行序的解析产物；无有效行时为 `nil`。

**例程**

```lisp
ycCodec::jsonlParse("1\n2\n")               ; => (1 2)
ycCodec::jsonlParse("")                     ; => nil
ycCodec::jsonlParse("1\n2\nbad")
; *Error* ycCodec: invalid literal at line 3, column 1
```

### ycCodec::jsonDump <sub>`function`</sub>

```text
ycCodec::jsonDump(
    g_val
    [ ?indent n_indent ]
    [ ?sortKeys g_sort ]
)
=> str
```

**描述**

输出单个值为 JSON 文本。`nil` 输出 `[]`、`t` 输出 `true`、哨兵输出对应字面量；对象键支持字符串（原样）、符号（取符号名）与 fixnum（十进制），其他键型报错。不可表示的值（普通符号、缺键标记、非有限浮点、其他类型）报错。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_val | any | | 待输出值 |
| ?indent | int | nil | 缩进空格数；正整数启用多行美化，其余等价紧凑输出 |
| ?sortKeys | t \| nil | t | 对象键是否按字符串升序输出 |

**返回值**

`str` — JSON 文本；无法表示时以 `error()` 中断。

**例程**

```lisp
ycCodec::jsonDump(nil)                      ; => "[]"
ycCodec::jsonDump(1.0)                      ; => "1.0"
ycCodec::jsonDump("a\"b")                   ; => "\"a\\\"b\""
ycCodec::jsonDump(list(nil))                ; => "[[]]"
ycCodec::jsonDump('foo)
; *Error* ycCodec: cannot dump value of type symbol
```

### ycCodec::jsonlDump <sub>`function`</sub>

```text
ycCodec::jsonlDump(
    l_vals
    [ ?sortKeys g_sort ]
)
=> str
```

**描述**

把值列表逐行输出为 JSON Lines 文本；每个元素按 `jsonDump()` 的紧凑规则输出为一行，非空输入末尾带一个换行。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| l_vals | list | | 待输出值列表 |
| ?sortKeys | t \| nil | t | 对象键是否按字符串升序输出 |

**返回值**

`str` — 每值一行、行间换行的文本；空列表输出空串。

**例程**

```lisp
ycCodec::jsonlDump(nil)                     ; => ""
ycCodec::jsonlDump(list(1 2))               ; => "1\n2\n"
ycCodec::jsonlDump(list(ycCodec::jsonNull)) ; => "null\n"
```

## 哨兵常量

### ycCodec::jsonFalse <sub>`constant`</sub>

`false` 的哨兵符号：解析 `false` 得到该符号；输出该符号得 `false`。

### ycCodec::jsonNull <sub>`constant`</sub>

`null` 的哨兵符号：解析 `null` 得到该符号；输出该符号得 `null`。

### ycCodec::jsonMissing <sub>`constant`</sub>

对象缺键的缺省标记：解析出的 table 以它为缺省值；输出时作为值出现即报错。

## 边界与限制

+ 嵌套深度上限 1000：解析与输出在更深的嵌套处报错（消息含 `nesting too deep`）。
+ 整数字面量在 32 位范围内解析为 fixnum，超出范围解析为 flonum；输出 fixnum 为精确十进制，输出 flonum 为最短可回环形式（整数值保留一位小数，如 `1.0`）。
+ 非有限浮点（无穷、NaN）不可输出，报错。
+ `\u0000`（NUL）无法保存在字符串中，解析时被丢弃。
+ 解析错误消息格式为 `ycCodec: <说明> at line <行>, column <列>`（均从 1 起，列按字节计）。
