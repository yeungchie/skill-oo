# ycJson

[返回首页](../../../README.md)

Cadence SKILL++ 的 JSON 家族编解码库：JSON、放宽 JSON（jsonc）与 JSON Lines（jsonl）的解码与编码。

## 概要

+ 解码入口：`Decode()`；`?format` 选 `"json"`（严格单文档）、`"jsonc"`（允许注释与尾逗号）或 `"jsonl"`（逐行文档）。
+ 编码入口：`Encode()`；`?format` 选 `"json"`/`"jsonc"`（单值）或 `"jsonl"`（值列表逐行）。
+ 函数均在 `ycJson` 命名空间下，以 `ycJson::` 前缀调用。
+ `true`、`false` 与 `null` 不坍缩为 `t`/`nil`，分别解码为哨兵对象 `ycCodec::True`、`ycCodec::False` 与 `ycCodec::Null`（均为 `ycCodec::Type` 唯一实例，所有编解码库共用同一组对象，可用 `->toSkill()` 显式转为 SKILL 原生值）；`nil` 仅表示空数组；哨兵类型见 [ycCodec](../core/README.md)。
+ 例程中 `; =>` 表示返回值；`(...)` 为省略的输出或示意值。

## 快速上手

`t_json` 的值如下所示：

```text
{
  "a": [1, 2.5, true, null]
}
```

`t_jsonc` 的值如下所示：

```text
{ // 备注
  "a": 1,
}
```

`t_jsonl` 的值如下所示：

```text
1
{"a": 2}
```

```lisp
; 解码
t_v = ycJson::Decode(t_json)
t_v["a"]                                            ; => (1 2.5 ycCodec::Type("True") ycCodec::Type("Null"))

; 编码（默认紧凑、键序随表；?sortKeys t 可排序）
ycJson::Encode(t_v)                                 ; => "{\"a\":[1,2.5,true,null]}"

; 缩进美化
ycJson::Encode(t_v ?indent 2)
; => "{\n  \"a\": [\n    1,\n    2.5,\n    true,\n    null\n  ]\n}"

; 放宽文本与逐行格式
ycJson::Decode(t_jsonc ?format "jsonc")             ; => <table: a = 1>
ycJson::Decode(t_jsonl ?format "jsonl")             ; => (1 <table: a = 2>)
ycJson::Encode(list(1 "x") ?format "jsonl")          ; => "1\n\"x\"\n"
```

## API 参考

### ycJson::Decode <sub>`function`</sub>

```text
ycJson::Decode(
    t_str
    [ ?format t_format ]
    [ ?maxDepth n_max ]
)
=> any | list
```

**描述**

解码文本为库内表示。`?format "json"`（默认）解析严格单文档：前导与尾随空白允许；尾随非空白字符、注释、尾逗号均以 `error()` 中断；重复键取最后值。`?format "jsonc"` 在严格规则之外允许 `//` 行注释、`/* */` 块注释与数组/对象尾逗号，双引号字符串内的注释标记不生效。`?format "jsonl"` 逐行解码：每个非空行须是完整且严格的 JSON 文档（不支持注释与跨行），空行与全空白行跳过。`?maxDepth` 调整嵌套深度上限（默认 800）；超过语言递归能力时由运行环境以栈溢出错误中断（可捕获）。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_str | str | | 输入文本 |
| ?format | str | "json" | `"json"`、`"jsonc"` 或 `"jsonl"`；其他值以 `error()` 中断 |
| ?maxDepth | int | 800 | 最大嵌套深度（≥1；超限以 `error()` 中断） |

**返回值**

`any|list` — 解码产物，按「类型映射」转换；`"jsonl"` 返回按行序的列表（无有效行时为 `nil`）。失败以 `error()` 中断；`"jsonl"` 的错误消息带原始文本行号。

**例程**

`t_jsonc_array` 的值如下所示：

```text
[1, /* c */ 2]
```

`t_jsonl_values` 的值如下所示：

```text
1
2
```

`t_jsonl_bad` 的值如下所示：

```text
1
2
bad
```

```lisp
ycJson::Decode("42")                        ; => 42
ycJson::Decode("1e3")                       ; => 1000.0
ycJson::Decode("2147483648")                ; => 2147483648.0
ycJson::Decode("\"a\\u4e2d\"")              ; => "a中"
ycJson::Decode("[1, 2,]")
; *Error* ycJson::Decode: unexpected character at line 1, column 7

ycJson::Decode(t_jsonc ?format "jsonc")             ; => <table: a = 1>
ycJson::Decode(t_jsonc_array ?format "jsonc")       ; => (1 2)
ycJson::Decode(t_jsonl_values ?format "jsonl")      ; => (1 2)
ycJson::Decode(t_jsonl_bad ?format "jsonl")
; *Error* ycJson::Decode: invalid literal at line 3, column 1

ycJson::Decode("1" ?format "xml")
; *Error* ycJson::Decode: unknown format "xml"
```

### ycJson::Encode <sub>`function`</sub>

```text
ycJson::Encode(
    g_val
    [ ?format t_format ]
    [ ?indent n_indent ]
    [ ?sortKeys g_sort ]
    [ ?strict g_strict ]
    [ ?nilAs t_nilAs ]
    [ ?finalNewline g_finalNewline ]
    [ ?maxDepth n_max ]
)
=> str
```

**描述**

编码库内表示为文本。`?format "json"`（默认）或 `"jsonc"` 输出单个值：`nil` 按 `?nilAs` 输出 `[]` 或 `false`、`t` 与 `ycCodec::True` 输出 `true`、其余哨兵输出对应字面量；对象键默认把字符串原样、符号取符号名、fixnum 转为十进制（`?strict t` 时非字符串键以 `error()` 中断；其他键型始终以 `error()` 中断）；不同键转为同一文本时以 `error()` 中断；不可表示的值（普通符号、缺键标记、非有限浮点、其他类型）以 `error()` 中断。`?format "jsonl"` 把值列表逐行输出：每个元素按紧凑规则输出为一行，行间以换行分隔，非空输入末尾默认补一个换行（`?finalNewline nil` 可关），`g_val` 非列表即以 `error()` 中断；`?indent` 仅对单值格式生效。对象键默认不排序（随表序），需要确定性输出时传 `?sortKeys t`。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_val | any | | 待编码值；`"jsonl"` 时为列表 |
| ?format | str | "json" | `"json"`/`"jsonc"` 或 `"jsonl"`；其他值以 `error()` 中断 |
| ?indent | int | nil | 缩进空格数；正整数启用多行美化，其余等价紧凑输出 |
| ?sortKeys | t / nil | nil | 对象键是否按字符串升序输出；默认随表序 |
| ?strict | t / nil | nil | t 时对象键必须为字符串，符号/整数键以 `error()` 中断 |
| ?nilAs | str | "array" | `nil` 的输出形式：`"array"`（`[]`）或 `"false"` |
| ?finalNewline | t / nil | t | `"jsonl"` 非空输出末尾是否补换行 |
| ?maxDepth | int | 800 | 最大嵌套深度（≥1；超限以 `error()` 中断） |

**返回值**

`str` — 文本；`"jsonl"` 为每值一行、行间换行（空列表输出空串）。无法表示或不合法输入以 `error()` 中断。

**例程**

```lisp
ycJson::Encode(nil)                         ; => "[]"
ycJson::Encode(1.0)                         ; => "1.0"
ycJson::Encode("a\"b")                      ; => "\"a\\\"b\""
ycJson::Encode(list(nil))                   ; => "[[]]"
ycJson::Encode('foo)
; *Error* ycJson::Encode: cannot dump value of type symbol

ycJson::Encode(list(1 2) ?format "jsonl")           ; => "1\n2\n"
ycJson::Encode(list(ycCodec::Null) ?format "jsonl")  ; => "null\n"
```

## 类型映射

| JSON | 库内表示 |
| --- | --- |
| object | table |
| array | list（空数组为 `nil`） |
| string | 字符串（UTF-8 字节级透传） |
| number（整数） | fixnum（32 位范围内），超出为 flonum |
| number（含小数或指数） | flonum |
| true | `ycCodec::True`（`ycCodec::Type` 实例） |
| false | `ycCodec::False`（`ycCodec::Type` 实例） |
| null | `ycCodec::Null`（`ycCodec::Type` 实例） |

编码方向兼容：`t` 与 `ycCodec::True` 均输出 `true`；要输出 `false`/`null` 须使用对应哨兵实例。

对象缺键以 `ycCodec::Missing` 表示：解码出的 table 以此为缺省值，读取不存在的键返回它；它一旦作为待编码值出现即以 `error()` 中断。判断缺键写法：

```lisp
t_v["flag"] == ycCodec::False    ; 值为 false
t_v["list"] == nil              ; 值为空数组
t_v["nope"] == ycCodec::Missing  ; 键不存在
```

## 边界与限制

+ 嵌套深度默认上限 800，可用 `?maxDepth` 调整（≥1）；超限以 `error()` 中断（消息含 `nesting too deep`）。解码约 900 层、编码约 1150 层触语言递归栈上界（简单递归语言栈约 8000–9000 帧；编解码每层耗多帧），默认值留安全余量；超过语言栈能力时由运行环境以栈溢出错误中断（可捕获）。
+ `?nilAs "false"` 有损：`nil` 编码为 `false` 后解码得 `ycCodec::False`；默认模式同一表内 `"1"` 与 `1` 会坍缩为同一输出键（`?strict t` 可规避）。
+ 整数字面量在 32 位范围内解码为 fixnum，超出为 flonum；编码 fixnum 为精确十进制，编码 flonum 为最短可回环形式（整数值保留一位小数，如 `1.0`）。
+ 非有限浮点（无穷、NaN）不可编码，以 `error()` 中断。
+ `\u0000`（NUL）无法保存在字符串中，解码时被丢弃。
+ 错误消息以当前上下文前缀标识来源：解码为 `ycJson::Decode: <说明> at line <行>, column <列>`（均从 1 起，列按字节计），编码为 `ycJson::Encode:`，类型对象为 `ycCodec::Type:` / `ycCodec::Type->toSkill:`。

[返回首页](../../../README.md)
