# ycUtf8

Cadence SKILL++ 的 UTF-8 工具库：字节串与码点互转、按码点计数与切片、显示宽度测量。

## 概要

+ 按 UTF-8 **码点**处理字符；所有位置参数使用 1-based 索引，与 `substring` / `getchar` 一致。
+ 默认严格校验 UTF-8：遇非法序列以 `error()` 中断；`?strict nil` 时逐字节替换为 U+FFFD 继续处理。
+ 显示宽度按 Unicode East Asian Width 计算；汉字与全角字符恒为 2 列。
+ 记法约定：例程注释中 `; =>` 标记返回值，`; *Error*` 标记错误消息。
+ 宽度数据基于 Unicode 15.0.0，随库发布，运行期无外部依赖。

## 快速上手

```lisp
; 码点互转
ycUtf8::decode("中")                        ; => (20013)
ycUtf8::encode(list(20013))                 ; => "中"

; 计数与切片（1-based、按码点）
ycUtf8::charCount("a中b")                   ; => 3
ycUtf8::slice("a中b" 2 1)                   ; => "中"

; 显示宽度
ycUtf8::width("中文")                       ; => 4
ycUtf8::charWidth(20013)                    ; => 2

; 合法性检查
ycUtf8::isValid("abc")                      ; => t
ycUtf8::isValid(strcat(intToChar(128)))     ; => nil
```

## API 参考

### ycUtf8::decode <sub>`function`</sub>

```text
ycUtf8::decode(
    t_str
    [ ?strict ]
)
=> list | nil
```

**描述**

将 UTF-8 字节串解码为码点列表。默认严格模式：遇非法序列（孤立续字节、截断、过长编码、代理区、超 U+10FFFF）以 `error()` 中断，消息含首次出错字节的位置；`?strict nil` 时逐个非法字节替换为 U+FFFD 并前进一字节。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_str | str |  | UTF-8 字节串 |
| ?strict | any | t | 非 nil 时非法序列以 `error()` 中断；`nil` 时逐字节替换为 U+FFFD |

**返回值**

`list | nil` — 码点列表；空串为 `nil`。

**例程**

```lisp
ycUtf8::decode("中")                               ; => (20013)
ycUtf8::decode("")                                 ; => nil
ycUtf8::decode(strcat(intToChar(226) intToChar(130) intToChar(172)))  ; => (8364)
ycUtf8::decode(strcat(intToChar(128)) ?strict nil) ; => (65533)
ycUtf8::decode(strcat(intToChar(192) intToChar(128)) ?strict nil)     ; => (65533 65533)
ycUtf8::decode(strcat("a" intToChar(128)))
; *Error* ycUtf8::decode: invalid UTF-8 at byte 2
```

### ycUtf8::encode <sub>`function`</sub>

```text
ycUtf8::encode(l_cps)
=> str
```

**描述**

将码点列表编码为 UTF-8 字节串。每个元素须为 0..0x10FFFF 的非代理区整数；U+0000 不可表示（SKILL 字符串无法承载 NUL 字节）。非整数、负数、代理区、超上限与 U+0000 均以 `error()` 中断，消息含 1-based 元素下标。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| l_cps | list[int] |  | 码点列表；`nil` 视为空 |

**返回值**

`str` — UTF-8 字节串；空列表为 `""`。

**例程**

```lisp
ycUtf8::encode(list(97 98 99)) ; => "abc"
ycUtf8::encode(list(20013))    ; => "中"
ycUtf8::encode(nil)            ; => ""
ycUtf8::encode(list(0))
; *Error* ycUtf8::encode: codepoint at index 1 (0) cannot be represented in a SKILL string
ycUtf8::encode(list(97 55296))
; *Error* ycUtf8::encode: invalid codepoint at index 2 (55296)
```

### ycUtf8::charCount <sub>`function`</sub>

```text
ycUtf8::charCount(
    t_str
    [ ?strict ]
)
=> int
```

**描述**

统计码点个数（非字节数）。校验语义与 `ycUtf8::decode` 相同。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_str | str |  | UTF-8 字节串 |
| ?strict | any | t | 非 nil 时非法序列以 `error()` 中断；`nil` 时逐字节替换为 U+FFFD |

**返回值**

`int` — 码点个数；空串为 `0`。

**例程**

```lisp
ycUtf8::charCount("a中b")   ; => 3
ycUtf8::charCount("")       ; => 0
ycUtf8::charCount(strcat("a" intToChar(128)) ?strict nil) ; => 2
```

### ycUtf8::slice <sub>`function`</sub>

```text
ycUtf8::slice(
    t_str
    n_start
    n_len
    [ ?strict ]
)
=> str | nil
```

**描述**

按码点切片：跳过前 `n_start - 1` 个码点后，取至多 `n_len` 个码点并重新编码。起点超过码点总数（空串亦然）返回 `nil`；`n_len` 超过剩余码点数时截到串尾；起点合法且 `n_len` 为 0 时返回 `""`。严格模式只校验扫描经过的字节（前导段与窗口本身），窗口之后的非法字节不影响结果；需要整串校验时用 `ycUtf8::isValid`。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_str | str |  | UTF-8 字节串 |
| n_start | int |  | 1-based 码点起点（>= 1） |
| n_len | int |  | 切取的码点长度（>= 0） |
| ?strict | any | t | 非 nil 时非法序列以 `error()` 中断；`nil` 时以 U+FFFD 替换 |

**返回值**

`str | nil` — 切片结果；起点越界为 `nil`。

**例程**

```lisp
ycUtf8::slice("a中b" 2 1)   ; => "中"
ycUtf8::slice("a中b" 3 9)   ; => "b"
ycUtf8::slice("a中b" 1 0)   ; => ""
ycUtf8::slice("a中b" 4 1)   ; => nil
ycUtf8::slice(strcat("a" intToChar(128)) 1 1)                 ; => "a"
ycUtf8::slice(strcat("a" intToChar(128) "b") 2 1 ?strict nil) ; => "�"（U+FFFD）
ycUtf8::slice("a" 0 1)
; *Error* ycUtf8::slice: start must be an integer >= 1
ycUtf8::slice("a" 1 -1)
; *Error* ycUtf8::slice: length must be an integer >= 0
ycUtf8::slice(strcat("a" intToChar(128)) 4 1)
; *Error* ycUtf8::slice: invalid UTF-8 at byte 2
```

### ycUtf8::width <sub>`function`</sub>

```text
ycUtf8::width(
    t_str
    [ ?strict ]
    [ ?ambiguous ]
)
=> int
```

**描述**

按[宽度规则](#宽度规则)逐码点求和，得到显示列宽。不合并字素簇；换行与制表符计 0。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_str | str |  | UTF-8 字节串 |
| ?strict | any | t | 非 nil 时非法序列以 `error()` 中断；`nil` 时以 U+FFFD 替换 |
| ?ambiguous | int | 1 | East Asian Ambiguous 的宽度（1 或 2） |

**返回值**

`int` — 显示列宽；空串为 `0`。

**例程**

```lisp
ycUtf8::width("中文")           ; => 4
ycUtf8::width("§")              ; => 1
ycUtf8::width("§" ?ambiguous 2) ; => 2
ycUtf8::width(strcat(intToChar(9) intToChar(10))) ; => 0
ycUtf8::width(strcat("a" intToChar(128)) ?strict nil) ; => 2
ycUtf8::width("a" ?ambiguous 0)
; *Error* ycUtf8::width: ambiguous must be 1 or 2
```

### ycUtf8::charWidth <sub>`function`</sub>

```text
ycUtf8::charWidth(
    n_cp
    [ ?ambiguous ]
)
=> int
```

**描述**

单个码点的显示宽度（0 / 1 / 2，规则同[宽度规则](#宽度规则)）。码点须为 0..0x10FFFF 的非代理区整数，否则以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| n_cp | int |  | 码点（0..0x10FFFF，非代理区） |
| ?ambiguous | int | 1 | East Asian Ambiguous 的宽度（1 或 2） |

**返回值**

`int` — 显示宽度；控制字符等为 `0`。

**例程**

```lisp
ycUtf8::charWidth(97)               ; => 1
ycUtf8::charWidth(20013)            ; => 2
ycUtf8::charWidth(167)              ; => 1
ycUtf8::charWidth(167 ?ambiguous 2) ; => 2
ycUtf8::charWidth(769)              ; => 0
ycUtf8::charWidth(55296)
; *Error* ycUtf8::charWidth: invalid codepoint (55296)
```

### ycUtf8::isValid <sub>`function`</sub>

```text
ycUtf8::isValid(t_str)
=> t | nil
```

**描述**

判断整个字节串是否为合法 UTF-8（含过长编码、代理区、超上限等检查）。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_str | str | 待检查字节串 |

**返回值**

`t | nil` — 合法回 `t`，非法回 `nil`。

**例程**

```lisp
ycUtf8::isValid("")                                             ; => t
ycUtf8::isValid("abc")                                          ; => t
ycUtf8::isValid(strcat(intToChar(128)))                         ; => nil
ycUtf8::isValid(strcat(intToChar(228) intToChar(184)))          ; => nil
```

## 严格与宽松

宽松模式每遇到一个非法字节产出一个 U+FFFD 并前进一字节；`ycUtf8::slice` 返回重新编码后的替换字符，不保留原始非法字节。严格模式下 `ycUtf8::slice` 只校验扫描经过的字节（窗口及其前导段）；窗口之后的非法字节不影响切片结果，需要整串校验时用 `ycUtf8::isValid`。

## 宽度规则

1. 控制字符（U+0000–U+001F、U+007F–U+009F）→ 0
2. 软连字符 U+00AD → 1
3. 组合标记、零宽字符、Hangul 连接 Jamo（U+1160–U+11FF）→ 0
4. East Asian Wide/Fullwidth → 2
5. East Asian Ambiguous → `?ambiguous`（默认 1，在 CJK 显示环境可传 2）
6. 其余 → 1

宽度按码点求和，不合并字素簇；emoji ZWJ 序列、旗帜、肤色修饰符、VS16 表情呈现等可能与终端实际显示不同。换行与制表符计 0，折行前请自行展开制表符。
