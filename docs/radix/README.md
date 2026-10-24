# ycRadix

[返回首页](../../README.md)

Cadence SKILL++ 的任意进制转换库：2–36 进制整数解析、格式化与 32 位掩码辅助。

## 概要

- 数值范围为 SKILL 32 位有符号整数；超出范围时 `Parse` 默认以 `error()` 中断，`?wrap t` 可接受 32 位无符号位型。
- `Parse` 支持 `0b`/`0o`/`0x` 前缀与前导 `0` 八进制，也支持显式 `?base`；数字大小写不敏感。
- `Format` 支持任意 2–36 进制、规范或自定义前缀、大小写、数字宽度与单字符填充。
- 格式化采用符号加绝对值；`?width` 只约束数字部分，符号与前缀不计入宽度。
- 未显式指定 `?base` 且启用前缀识别时，`0` 开头与 `0o` 开头都按八进制；显式 `?base` 以指定进制为准，`?prefix nil` 关闭前缀与前导 0 推断。
- 解析不接受空白、下划线或浮点数。
- 错误消息以 `ycRadix::<过程>:` 开头。

## 快速上手

```lisp
; 解析
ycRadix::Parse("010")                   ; => 8
ycRadix::Parse("1010" ?base 2)          ; => 10
ycRadix::Parse("0x1f")                  ; => 31
ycRadix::Parse("z" ?base 36)            ; => 35
ycRadix::Parse("0xffffffff" ?wrap t)    ; => -1

; 格式化
ycRadix::Format(255 ?base 16)                            ; => "ff"
ycRadix::Format(255 ?base 16 ?prefix t ?upper t ?width 4) ; => "0X00FF"
ycRadix::Format(-255 ?base 16 ?prefix t ?width 4)         ; => "-0x00ff"

; 掩码
ycRadix::Mask(8)              ; => 255
ycRadix::ApplyMask(4660 8)    ; => 52
```

## API 参考

### ycRadix::Parse <sub>`function`</sub>

```text
ycRadix::Parse(
    t_text
    [ ?base g_base ]
    [ ?prefix g_prefix ]
    [ ?wrap g_wrap ]
)
=> int
```

**描述**

按指定或由前缀推断的进制解析整数。文本可带一个前导 `+` 或 `-`，其后至少一位数字；数字 `0–9`、`a–z` 不区分大小写。`?base` 为 `nil` 时，若识别到 `0b`/`0o`/`0x` 前缀则据此推断；否则若以 `0` 开头则按八进制，其余按十进制。显式 `?base` 以指定进制为准；规范前缀与显式 base 冲突时以 `error()` 中断。文本含空白、下划线、非法数字或超出范围时以 `error()` 中断。

`?wrap t` 允许 0 到 0xFFFFFFFF 的 32 位位型：最高位为 1 时返回等价的负数。超过 32 位仍以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_text | str |  | 输入文本 |
| ?base g_base | int | nil | 2–36；nil 时按前缀或前导 `0` 推断，否则十进制 |
| ?prefix g_prefix | t \| nil | t | 是否识别 `0b`/`0o`/`0x` 与前导 `0` 八进制 |
| ?wrap g_wrap | t \| nil | nil | t 时允许 32 位无符号位型 |

**返回值**

`int` — 解析结果；负数由前导符号或 `?wrap` 的补码语义产生。

**例程**

```lisp
ycRadix::Parse("0")                     ; => 0
ycRadix::Parse("+255")                  ; => 255
ycRadix::Parse("-0x10")                 ; => -16
ycRadix::Parse("0b1010")                ; => 10
ycRadix::Parse("010")                   ; => 8
ycRadix::Parse("0o17")                  ; => 15
ycRadix::Parse("0X1F")                  ; => 31
ycRadix::Parse("010" ?prefix nil)       ; => 10
ycRadix::Parse("z" ?base 36)            ; => 35
ycRadix::Parse("ff" ?base 16 ?prefix nil) ; => 255
ycRadix::Parse("0x80000000" ?wrap t)    ; => -2147483648
ycRadix::Parse("0xffffffff" ?wrap t)    ; => -1
ycRadix::Parse("010" ?base 10)          ; => 10
ycRadix::Parse("2147483647")            ; => 2147483647
ycRadix::Parse("-2147483648")           ; => -2147483648
ycRadix::Parse("")                      ; => 以 error() 中断（空串）
ycRadix::Parse("08")                    ; => 以 error() 中断（八进制无数字 8）
ycRadix::Parse("102" ?base 2)           ; => 以 error() 中断（数字超出进制）
ycRadix::Parse("0x10" ?base 10)         ; => 以 error() 中断（前缀与显式 base 冲突）
ycRadix::Parse("2147483648")            ; => 以 error() 中断（超出有符号 32 位）
```

### ycRadix::Format <sub>`function`</sub>

```text
ycRadix::Format(
    n_value
    [ ?base g_base ]
    [ ?prefix g_prefix ]
    [ ?upper g_upper ]
    [ ?width g_width ]
    [ ?pad t_pad ]
)
=> str
```

**描述**

把整数格式化为指定进制的文本。负数写作 `-` 加绝对值；数字 10–35 默认小写，`?upper t` 时大写。

`?prefix` 为 `t` 时，2/8/16 进制分别使用 `0b`/`0o`/`0x`，其他进制以 `error()` 中断；传字符串则使用该自定义前缀，`?upper` 不改变自定义前缀。自定义前缀只用于输出；`Parse` 只识别 `0b`/`0o`/`0x` 与前导 `0`。

`?width` 指定数字部分的最小宽度，不足时用 `?pad`（必须是单字符，默认 `"0"`）左补；符号与前缀不计入宽度。宽度小于数字长度时不截断。`?base` 非 2–36、选项类型不符时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| n_value | int |  | 待格式化整数 |
| ?base g_base | int | 10 | 2–36 |
| ?prefix g_prefix | t \| nil \| str | nil | t 时按 2/8/16 使用规范前缀；字符串为自定义前缀 |
| ?upper g_upper | t \| nil | nil | t 时数字与规范前缀大写 |
| ?width g_width | int | nil | 数字部分最小宽度；nil 不补 |
| ?pad t_pad | str | "0" | 单字符填充 |

**返回值**

`str` — 格式化文本；含符号、前缀与填充。

**例程**

```lisp
ycRadix::Format(0)                                      ; => "0"
ycRadix::Format(255 ?base 16)                           ; => "ff"
ycRadix::Format(255 ?base 16 ?upper t)                  ; => "FF"
ycRadix::Format(255 ?base 16 ?prefix t)                 ; => "0xff"
ycRadix::Format(255 ?base 16 ?prefix t ?upper t)        ; => "0XFF"
ycRadix::Format(255 ?base 2 ?prefix t ?width 8)         ; => "0b11111111"
ycRadix::Format(255 ?base 16 ?prefix t ?width 4)        ; => "0x00ff"
ycRadix::Format(-255 ?base 16 ?prefix t ?width 4)       ; => "-0x00ff"
ycRadix::Format(-1 ?base 2 ?width 8)                    ; => "-00000001"
ycRadix::Format(35 ?base 36)                            ; => "z"
ycRadix::Format(35 ?base 36 ?upper t)                   ; => "Z"
ycRadix::Format(10 ?prefix "0d")                        ; => "0d10"
ycRadix::Format(10 ?width 5 ?pad "x")                   ; => "xxx10"
ycRadix::Format(ycRadix::Parse("-2147483648") ?base 16) ; => "-80000000"
ycRadix::Format(10 ?base 1)                             ; => 以 error() 中断（base 超范围）
ycRadix::Format(10 ?prefix t)                           ; => 以 error() 中断（十进制无规范前缀）
ycRadix::Format(10 ?pad "00")                           ; => 以 error() 中断（填充须为单字符）
```

### ycRadix::Mask <sub>`function`</sub>

```text
ycRadix::Mask(n_bits)
=> int
```

**描述**

返回低 `n_bits` 位全 1 的掩码。位宽取 0–32；`Mask(0)` 为 `0`，`Mask(32)` 为 `-1`。位宽越界以 `error()` 中断。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| n_bits | int | 位宽 0–32 |

**返回值**

`int` — 低位掩码。

**例程**

```lisp
ycRadix::Mask(0)    ; => 0
ycRadix::Mask(8)    ; => 255
ycRadix::Mask(16)   ; => 65535
ycRadix::Mask(31)   ; => 2147483647
ycRadix::Mask(32)   ; => -1
ycRadix::Mask(33)   ; => 以 error() 中断（位宽超范围）
```

### ycRadix::ApplyMask <sub>`function`</sub>

```text
ycRadix::ApplyMask(
    n_value
    n_bits
)
=> int
```

**描述**

返回 `n_value` 的低 `n_bits` 位，等价于 `n_value & ycRadix::Mask(n_bits)`。位宽越界以 `error()` 中断。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| n_value | int | 输入整数 |
| n_bits | int | 位宽 0–32 |

**返回值**

`int` — 掩码后的整数。

**例程**

```lisp
ycRadix::ApplyMask(4660 8)   ; => 52
ycRadix::ApplyMask(-1 8)     ; => 255
ycRadix::ApplyMask(256 8)    ; => 0
ycRadix::ApplyMask(-1 32)    ; => -1
ycRadix::ApplyMask(1 0)      ; => 0
```
