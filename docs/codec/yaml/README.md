# ycYaml

Cadence SKILL++ 的 YAML 1.2 编解码库：块式与流式集合、块标量、锚点别名、核心标签与多文档流。

## 概要

+ 解码入口：`decode()`；`?format` 选 `"yaml"`（单文档，默认）或 `"yaml-stream"`（多文档流）。
+ 编码入口：`encode()`；默认块式输出，`?flow t` 切换流式风格；`?format "yaml-stream"` 逐文档输出。
+ `null`、`true`、`false` 解码为哨兵对象 `ycCodec::Null`、`ycCodec::True`、`ycCodec::False`；`nil` 表示空序列，不表示 `null`。
+ 解码得到的 table 以 `ycCodec::Missing` 为缺键默认值；空映射是长度为 0 的 table，空序列是 `nil`。
+ 哨兵对象由 `ycCodec` 命名空间统一提供，各编解码库共用同一组实例；类型与转换规则见 [ycCodec](../core/README.md)。
+ 支持块映射/序列、流式映射/序列、单双引号标量、字面/折叠块标量、注释、文档标记、锚点别名、`<<` 合并键与核心标签。
+ 不支持复杂映射键（`?` 形式）、自定义标签与跨行流式集合；这些输入以 `error()` 中断。`%YAML` 指令会被跳过，不做版本校验。
+ 例程中 `; =>` 表示返回值；字符串输出中的 `\n` 是转义表示。

## 快速上手

```lisp
; 块式文档
t_v = ycYaml::decode("name: demo\nitems:\n  - 1\n  - 2\n")
t_v["name"]                                         ; => "demo"
t_v["items"]                                        ; => (1 2)

; 标量类型与哨兵
ycYaml::decode("null")                              ; => ycCodec::Type("Null")
ycYaml::decode("true")                              ; => ycCodec::Type("True")
ycYaml::decode("0x10")                              ; => 16
ycYaml::decode("[]")                                ; => nil

; 锚点、别名与合并
t_v = ycYaml::decode("base: &b {a: 1}\ncopy: *b\n")
t_v["copy"]["a"]                                    ; => 1

; 多文档流
ycYaml::decode("---\n1\n---\n2\n" ?format "yaml-stream")
; => (1 2)

; 编码
ycYaml::encode(list(1 2))                           ; => "- 1\n- 2\n"
ycYaml::encode(t_v ?flow t ?sortKeys t)             ; => "{base: {a: 1}, copy: {a: 1}}\n"
```

## API 参考

### ycYaml::decode <sub>`function`</sub>

```text
ycYaml::decode(
    t_str
    [ ?format t_format ]
    [ ?maxDepth n_max ]
)
=> any | list
```

**描述**

解码 YAML 文本。`?format "yaml"`（默认）解析单个文档，多文档输入以 `error()` 中断；空输入或仅含注释的输入返回 `ycCodec::Null`。`?format "yaml-stream"` 按 `---`/`...` 拆分并返回文档列表，空输入返回 `nil`。

块映射与序列按缩进解析；空序列解码为 `nil`，空映射解码为长度为 0 的 table。流式集合须位于同一行。单引号按 YAML 规则转义单引号，双引号支持常见转义与 `\xNN`、`\uNNNN`、`\UNNNNNNNN`。

锚点定义后可用 `*name` 引用；别名与锚点值共享同一对象。`<<` 合并键接受映射或映射列表，已存在的显式键优先，`<<` 本身不保留在结果 table 中。支持核心标签 `!!str`、`!!int`、`!!float`、`!!bool`、`!!null`、`!!seq`、`!!map` 及其 `tag:yaml.org,2002:` 形式。

`?maxDepth` 控制容器嵌套深度（默认 800）；超限以 `error()` 中断。解码错误消息带行号与列号（部分深层错误只保留统一前缀）。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_str | str | | 输入文本 |
| ?format | str | "yaml" | `"yaml"` 或 `"yaml-stream"`；其他值以 `error()` 中断 |
| ?maxDepth | int | 800 | 最大容器嵌套深度（≥1；超限以 `error()` 中断） |

**返回值**

`any|list` — 单文档值，或 `"yaml-stream"` 的文档值列表；空文档为 `ycCodec::Null`。输入非法、格式未知或标签/别名无法解析时以 `error()` 中断。

**例程**

```lisp
ycYaml::decode("a: 1\nb: 2\n")                    ; => <table: a = 1, b = 2>
ycYaml::decode("[1, 2.5, true, null]")
; => (1 2.5 ycCodec::Type("True") ycCodec::Type("Null"))
ycYaml::decode("s: |\n  a\n  b\n")["s"]            ; => "a\nb\n"
ycYaml::decode("s: >\n  a\n  b\n")["s"]            ; => "a b\n"
ycYaml::decode("a: 1\r\nb: 2\r\n")["b"]            ; => 2

ycYaml::decode("a: [1, 2\n")
; *Error* ycYaml::decode: unterminated or invalid flow value at line 1, column 3

ycYaml::decode("a: 1\n b: 2\n")
; *Error* ycYaml::decode: unexpected indentation at line 2, column 1
```

### ycYaml::encode <sub>`function`</sub>

```text
ycYaml::encode(
    g_val
    [ ?format t_format ]
    [ ?indent n_indent ]
    [ ?sortKeys g_sort ]
    [ ?strict g_strict ]
    [ ?flow g_flow ]
    [ ?explicitStart g_start ]
    [ ?explicitEnd g_end ]
    [ ?finalNewline g_newline ]
    [ ?maxDepth n_max ]
)
=> str
```

**描述**

把库内表示编码为 YAML 文本。默认块式风格；`?flow t` 时全部值使用流式风格。`nil` 输出 `[]`（空序列），`ycCodec::Null` 输出 `null`，`ycCodec::True`/`ycCodec::False` 输出 `true`/`false`；普通符号、`ycCodec::Missing` 与无法表示的容器以 `error()` 中断。

映射键支持字符串、符号与 fixnum：字符串按需加双引号，符号取符号名，fixnum 输出十进制数字；`?strict t` 时非字符串键以 `error()` 中断；其他键型始终以 `error()` 中断。默认不排序映射键；`?sortKeys t` 按编码后的键文本升序输出。

`?indent` 指定每层空格数（默认 2）。`?explicitStart`/`?explicitEnd` 只在单文档格式添加 `---`/`...`，对 `"yaml-stream"` 不生效。`?format "yaml-stream"` 要求 `g_val` 为列表，每个元素输出为一个 `---` 文档；空列表输出空串。`?finalNewline nil` 去掉单文档末尾换行；非空流输出同样受此控制。

`?maxDepth` 控制容器嵌套深度（默认 800），超限以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_val | any | | 待编码值；`"yaml-stream"` 时为文档列表 |
| ?format | str | "yaml" | `"yaml"` 或 `"yaml-stream"`；其他值以 `error()` 中断 |
| ?indent | int | 2 | 每层缩进空格数（须为正整数） |
| ?sortKeys | t \| nil | nil | t 时映射键按编码后的文本升序输出 |
| ?strict | t \| nil | nil | t 时映射键必须为字符串 |
| ?flow | t \| nil | nil | t 时全部使用流式风格 |
| ?explicitStart | t \| nil | nil | 单文档格式是否在开头添加 `---` |
| ?explicitEnd | t \| nil | nil | 单文档格式是否在末尾添加 `...` |
| ?finalNewline | t \| nil | t | 输出末尾是否补换行 |
| ?maxDepth | int | 800 | 最大容器嵌套深度（≥1；超限以 `error()` 中断） |

**返回值**

`str` — YAML 文本；`"yaml-stream"` 空列表返回空串。值或选项非法时以 `error()` 中断。

**例程**

```lisp
ycYaml::encode(nil)                                ; => "[]\n"
ycYaml::encode(list(1 2))                          ; => "- 1\n- 2\n"
ycYaml::encode(list(nil))                          ; => "- []\n"
ycYaml::encode("a\nb")                             ; => "\"a\\nb\"\n"
ycYaml::encode(list(1 2) ?flow t)                  ; => "[1, 2]\n"
ycYaml::encode(1 ?explicitStart t)                 ; => "---\n1\n"
ycYaml::encode(list(1 2) ?format "yaml-stream")    ; => "---\n1\n---\n2\n"

ycYaml::encode('foo)
; *Error* ycYaml::encode: cannot dump value of type symbol
ycYaml::encode(ycCodec::Missing)
; *Error* ycYaml::encode: cannot dump the Missing marker
```
