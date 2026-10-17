# ycJson

Cadence SKILL++ 的 JSON 家族编解码库：JSON、放宽 JSON（jsonc）与 JSON Lines（jsonl）的解码与编码。所属集合索引见 [codec](../README.md)。

## 概要

+ 解码入口：`decode()`；`?format` 选 `"json"`（严格单文档）、`"jsonc"`（允许注释与尾逗号）或 `"jsonl"`（逐行文档）。
+ 编码入口：`encode()`；`?format` 选 `"json"`/`"jsonc"`（单值）或 `"jsonl"`（值列表逐行）。
+ 函数均在 `ycJson` 命名空间下，以 `ycJson::` 前缀调用。
+ `true`、`false` 与 `null` 不坍缩为 `t`/`nil`，分别解码为哨兵对象 `ycJson::True`、`ycJson::False` 与 `ycJson::Null`（均为 `JsonType` 唯一实例，可用 `->toSkill()` 显式转为 SKILL 原生值）；`nil` 仅表示空数组。
+ 例程中 `; =>` 表示返回值；`(...)` 为省略的输出或示意值。

## 快速上手

```lisp
; 解码
t_v = ycJson::decode("{\"a\":[1,2.5,true,null]}")
t_v["a"]                                            ; => (1 2.5 ycJson::JsonType("True") ycJson::JsonType("Null"))

; 编码（默认紧凑、对象键排序）
ycJson::encode(t_v)                                 ; => "{\"a\":[1,2.5,true,null]}"

; 缩进美化
ycJson::encode(t_v ?indent 2)
; => "{\n  \"a\": [\n    1,\n    2.5,\n    true,\n    null\n  ]\n}"

; 放宽文本与逐行格式
ycJson::decode("{ // 备注\n \"a\": 1, }" ?format "jsonc")    ; => <table: a = 1>
ycJson::decode("1\n{\"a\":2}\n" ?format "jsonl")              ; => (1 <table: a = 2>)
ycJson::encode(list(1 "x") ?format "jsonl")                   ; => "1\n\"x\"\n"
```

## 类型映射

| JSON | 库内表示 |
| --- | --- |
| object | table |
| array | list（空数组为 `nil`） |
| string | 字符串（UTF-8 字节级透传） |
| number（整数） | fixnum（32 位范围内），超出为 flonum |
| number（含小数或指数） | flonum |
| true | `ycJson::True`（`JsonType` 实例） |
| false | `ycJson::False`（`JsonType` 实例） |
| null | `ycJson::Null`（`JsonType` 实例） |

编码方向兼容：`t` 与 `ycJson::True` 均输出 `true`；要输出 `false`/`null` 须使用对应哨兵实例。

对象缺键以 `ycJson::Missing` 表示：解码出的 table 以此为缺省值，读取不存在的键返回它；它一旦作为待编码值出现即报错。判断缺键写法：

```lisp
t_v["flag"] == ycJson::False    ; 值为 false
t_v["list"] == nil              ; 值为空数组
t_v["nope"] == ycJson::Missing  ; 键不存在
```

## API 参考

### ycJson::decode <sub>`function`</sub>

```text
ycJson::decode(
    t_str
    [ ?format t_format ]
)
=> any | list
```

**描述**

解码文本为库内表示。`?format "json"`（默认）解析严格单文档：前导与尾随空白允许；尾随非空白字符、注释、尾逗号均报错；重复键取最后值。`?format "jsonc"` 在严格规则之外允许 `//` 行注释、`/* */` 块注释与数组/对象尾逗号，双引号字符串内的注释标记不生效。`?format "jsonl"` 逐行解码：每个非空行须是完整且严格的 JSON 文档（不支持注释与跨行），空行与全空白行跳过。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_str | str | | 输入文本 |
| ?format | str | "json" | `"json"`、`"jsonc"` 或 `"jsonl"`；其他值报错 |

**返回值**

`any|list` — 解码产物，按「类型映射」转换；`"jsonl"` 返回按行序的列表（无有效行时为 `nil`）。失败以 `error()` 中断；`"jsonl"` 的错误消息带原始文本行号。

**例程**

```lisp
ycJson::decode("42")                        ; => 42
ycJson::decode("1e3")                       ; => 1000.0
ycJson::decode("2147483648")                ; => 2147483648.0
ycJson::decode("\"a\\u4e2d\"")              ; => "a中"
ycJson::decode("[1, 2,]")
; *Error* ycJson: unexpected character at line 1, column 7

ycJson::decode("{ \"a\": 1, }" ?format "jsonc")     ; => <table: a = 1>
ycJson::decode("[1, /* c */ 2]" ?format "jsonc")    ; => (1 2)
ycJson::decode("1\n2\n" ?format "jsonl")            ; => (1 2)
ycJson::decode("1\n2\nbad" ?format "jsonl")
; *Error* ycJson: invalid literal at line 3, column 1

ycJson::decode("1" ?format "xml")
; *Error* ycJson: decode: unknown format "xml"
```

### ycJson::encode <sub>`function`</sub>

```text
ycJson::encode(
    g_val
    [ ?format t_format ]
    [ ?indent n_indent ]
    [ ?sortKeys g_sort ]
)
=> str
```

**描述**

编码库内表示为文本。`?format "json"`（默认）或 `"jsonc"` 输出单个值：`nil` 输出 `[]`、`t` 与 `ycJson::True` 输出 `true`、其余哨兵输出对应字面量；对象键支持字符串（原样）、符号（取符号名）与 fixnum（十进制），其他键型报错；不可表示的值（普通符号、缺键标记、非有限浮点、其他类型）报错。`?format "jsonl"` 把值列表逐行输出：每个元素按紧凑规则输出为一行，非空输入末尾带一个换行，`g_val` 非列表即报错；`?indent` 仅对单值格式生效。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_val | any | | 待编码值；`"jsonl"` 时为列表 |
| ?format | str | "json" | `"json"`/`"jsonc"` 或 `"jsonl"`；其他值报错 |
| ?indent | int | nil | 缩进空格数；正整数启用多行美化，其余等价紧凑输出 |
| ?sortKeys | t \| nil | t | 对象键是否按字符串升序输出 |

**返回值**

`str` — 文本；`"jsonl"` 为每值一行、行间换行（空列表输出空串）。无法表示或不合法输入以 `error()` 中断。

**例程**

```lisp
ycJson::encode(nil)                         ; => "[]"
ycJson::encode(1.0)                         ; => "1.0"
ycJson::encode("a\"b")                      ; => "\"a\\\"b\""
ycJson::encode(list(nil))                   ; => "[[]]"
ycJson::encode('foo)
; *Error* ycJson: cannot dump value of type symbol

ycJson::encode(list(1 2) ?format "jsonl")           ; => "1\n2\n"
ycJson::encode(list(ycJson::Null) ?format "jsonl")  ; => "null\n"
```

## 哨兵常量

### ycJson::True <sub>`constant`</sub>

`true` 的哨兵对象（`JsonType` 唯一实例）：解码 `true` 得到该对象；编码该对象（或 `t`）得 `true`。

### ycJson::False <sub>`constant`</sub>

`false` 的哨兵对象（`JsonType` 唯一实例）：解码 `false` 得到该对象；编码该对象得 `false`。

### ycJson::Null <sub>`constant`</sub>

`null` 的哨兵对象（`JsonType` 唯一实例）：解码 `null` 得到该对象；编码该对象得 `null`。

### ycJson::Missing <sub>`constant`</sub>

对象缺键的缺省标记（`JsonType` 唯一实例）：解码出的 table 以它为缺省值；编码时作为值出现即报错。

## JsonType 类型对象

哨兵对象由 `ycJson::JsonType` 类定义。构造器接受四种类型名（大小写不敏感：`true`/`false`/`null`/`missing` 的任意大小写），返回规范名对应的**唯一实例**——相同参数总是同一对象，可直接用 `==` 比较：

```lisp
ycJson::JsonType("true") == ycJson::True           ; => t
ycJson::JsonType("TRUE") == ycJson::True           ; => t
ycJson::JsonType("xml")
; *Error* ycJson: JsonType: unknown type name "xml"
```

实例提供 `->toSkill()` 转换为 SKILL 原生值（有损：`false` 与空数组同域、`null`/`missing` 同域）：

| 实例 | `->toSkill()` |
| --- | --- |
| `ycJson::True` | `t` |
| `ycJson::False` | `nil` |
| `ycJson::Null` | `'unbound` |
| `ycJson::Missing` | `'unbound` |

对象显示为命名空间限定的构造调用形式（如 `ycJson::JsonType("True")`）；顶层用 `evalstring` 执行该打印串可复得同一驻留实例。

## 边界与限制

+ 嵌套深度上限 1000：解码与编码在更深的嵌套处报错（消息含 `nesting too deep`）。
+ 整数字面量在 32 位范围内解码为 fixnum，超出为 flonum；编码 fixnum 为精确十进制，编码 flonum 为最短可回环形式（整数值保留一位小数，如 `1.0`）。
+ 非有限浮点（无穷、NaN）不可编码，报错。
+ `\u0000`（NUL）无法保存在字符串中，解码时被丢弃。
+ 错误消息以 `ycJson: ` 前缀标识来源；解码错误格式为 `ycJson: <说明> at line <行>, column <列>`（均从 1 起，列按字节计）。
