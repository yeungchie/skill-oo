# ycUnits

Cadence SKILL++ 的 SI 工程计数与单位库：工程计数解析、格式化与数值/单位拆分。

## 概要

+ `parse` 解析带 SI 前缀的数值串（`"1k"`、`"2.5uF"`、`"4.7meg"`），返回 `(数值 单位)`。
+ `format` 把数值写成工程计数（指数取 3 的倍数），可拼接单位。
+ 前缀区分大小写：`m` 为 milli、`M` 为 mega；femto 为小写 `f`，大写 `F` 是法拉单位。
+ 数值与后缀之间有空白时，后缀整体作为单位、不识别前缀：`"1m"` → 0.001，`"1 m"` → 1 米；`"1T"` → 1e12，`"1 T"` → 1 特斯拉。
+ 单位后缀按字符串保留，不做物理量纲或复合单位换算。
+ 记法约定：例程注释中 `; =>` 标记返回值，`; *Error*` 标记错误消息；错误消息以 `ycUnits::<过程>:` 为前缀。

## 快速上手

```lisp
; 解析
ycUnits::parse("1k")       ; => (1000.0 "")
ycUnits::parse("2.5uF")    ; => (2.5e-06 "F")
ycUnits::parse("4.7meg")   ; => (4700000.0 "")
ycUnits::parse("1 F")      ; => (1.0 "F")

; 格式化
ycUnits::format(1234)                       ; => "1.234k"
ycUnits::format(2.5e-6 ?unit "F")           ; => "2.5uF"
ycUnits::format(999.9 ?precision 3)         ; => "1k"
ycUnits::format(1e-4)                       ; => "100u"

; 拆分
ycUnits::toNumber("2.5uF") ; => 2.5e-06
ycUnits::toUnit("2.5uF")   ; => "F"
```

## API 参考

### ycUnits::parse <sub>`function`</sub>

```text
ycUnits::parse(t_text)
=> list
```

**描述**

解析工程计数串，返回 `(数值 单位)`。数值部分支持符号、整数/小数与科学计数法；后缀按[前缀与单位规则](#前缀与单位规则)拆成前缀倍率与单位。数值与后缀之间允许空白；后缀内部空白、非法数值、空串以 `error()` 中断。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_text | str | 输入文本 |

**返回值**

`list` — 两元素列表：折算后的数值与单位；无单位时单位为空串。

**例程**

```lisp
ycUnits::parse("1k")       ; => (1000.0 "")
ycUnits::parse("2.5u")     ; => (2.5e-06 "")
ycUnits::parse("1kHz")     ; => (1000.0 "Hz")
ycUnits::parse("1.5mF")    ; => (0.0015 "F")
ycUnits::parse("1F")       ; => (1.0 "F")
ycUnits::parse("1f")       ; => (1e-15 "")
ycUnits::parse("1e3")      ; => (1000.0 "")
ycUnits::parse("-2.5u")    ; => (-2.5e-06 "")
ycUnits::parse("abc")
; => 以 error() 中断（缺少数值）
ycUnits::parse("1e")
; => 以 error() 中断（指数缺少数字）
```

### ycUnits::format <sub>`function`</sub>

```text
ycUnits::format(
    n_value
    [ ?unit "" ]
    [ ?precision 6 ]
)
=> str
```

**描述**

把数值格式化为工程计数：指数取 3 的倍数并选用对应前缀，去掉末尾无意义的零。`?precision` 为有效数字位数（1–15，默认 6）。舍入进位跨越一千时自动提升一级（`999.9` 精度 3 → `"1k"`）。0 输出 `"0"`；负数保留符号。绝对值小于 `1e-24` 或大于等于 `1e27` 时，退化用 `%g` 原样输出，不加强制前缀。单位与数字紧接，如 `"2.5uF"`。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| n_value | num |  | 待格式化数值（整数或浮点） |
| ?unit | str | `""` | 附加单位 |
| ?precision | int | 6 | 有效数字位数（1–15） |

**返回值**

`str` — 工程计数文本；可含单位。

**例程**

```lisp
ycUnits::format(1234)                         ; => "1.234k"
ycUnits::format(0)                            ; => "0"
ycUnits::format(-2.5e-6)                      ; => "-2.5u"
ycUnits::format(1e-4)                         ; => "100u"
ycUnits::format(1.23456789)                   ; => "1.23457"
ycUnits::format(12345 ?precision 3)           ; => "12.3k"
ycUnits::format(999.9 ?precision 3)           ; => "1k"
ycUnits::format(2.5e-6 ?unit "F")             ; => "2.5uF"
ycUnits::format(0 ?unit "F")                  ; => "0F"
ycUnits::format(1e30)                         ; => "1e+30"
ycUnits::format(1 ?precision 0)
; => 以 error() 中断（精度须为 1–15）
```

### ycUnits::toNumber <sub>`function`</sub>

```text
ycUnits::toNumber(t_text)
=> num
```

**描述**

解析工程计数串并只返回数值；等价于 `car(ycUnits::parse(t_text))`。解析错误消息上下文为 `ycUnits::toNumber:`。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_text | str | 输入文本 |

**返回值**

`num` — 前缀折算后的数值。

**例程**

```lisp
ycUnits::toNumber("2.5uF") ; => 2.5e-06
ycUnits::toNumber("-1k")   ; => -1000.0
```

### ycUnits::toUnit <sub>`function`</sub>

```text
ycUnits::toUnit(t_text)
=> str
```

**描述**

解析工程计数串并只返回单位；等价于 `cadr(ycUnits::parse(t_text))`。解析错误消息上下文为 `ycUnits::toUnit:`。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_text | str | 输入文本 |

**返回值**

`str` — 单位部分；无单位为 `""`。

**例程**

```lisp
ycUnits::toUnit("2.5uF") ; => "F"
ycUnits::toUnit("1k")    ; => ""
```

## 前缀与单位规则

| 指数 | 前缀 | 名称别名 |
| --- | --- | --- |
| -24 | `y` | `yocto` |
| -21 | `z` | `zepto` |
| -18 | `a` | `atto` |
| -15 | `f` | `femto` |
| -12 | `p` | `pico` |
| -9 | `n` | `nano` |
| -6 | `u` | `micro` |
| -3 | `m` | `milli` |
| 0 | 无 |  |
| 3 | `k` | `kilo` |
| 6 | `M` | `mega` / `meg` |
| 9 | `G` | `giga` |
| 12 | `T` | `tera` |
| 15 | `P` | `peta` |
| 18 | `E` | `exa` |
| 21 | `Z` | `zetta` |
| 24 | `Y` | `yotta` |

+ 后缀与数值之间无空白时先按前缀解析，剩余部分作为单位：`"2.5uF"` → 2.5e-6 F。
+ 后缀与数值之间有空白时整体作为单位：`"1 m"` → 1 m；`"1 T"` → 1 T。
+ 后缀不是前缀时整体作为单位：`"1Hz"` → 1 Hz；`"1x"` → 1 x。
+ 单位内容不校验；复合单位、单位换算（如 mil）不在本库范围内。
