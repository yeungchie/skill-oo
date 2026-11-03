# ycDateTime

[返回首页](../../README.md)

Cadence SKILL++ 的 Unix 时间对象库：`DateTime` 以秒为唯一状态，提供格式化、字段读取、偏移与比较，同一时刻共享同一实例。

## 概要

- `DateTime` 包装一个 Unix 秒值（1970-01-01 00:00:00 UTC 起算，可为负），不可变：任何"修改"都返回新实例。
- 同一秒对应的实例驻留共享，`==` 即表示同一时刻；`printself` 输出 `ycDateTime::DateTime(<秒>)`，可用 `evalstring` 复得同一实例。
- 时间字段按本地时间解释（与 `timeToTm` 一致）；不提供时区换算。
- 格式化使用本库自己的模板方言（见「格式令牌」），默认 `"%Y-%m-%d %H:%M:%S"`；未知令牌与末尾悬空 `%` 以 `error()` 中断，不会静默输出。
- `add` 只做固定时长偏移（一天按 86400 秒），不做日历月/年运算。
- `diff` 与 `compare` 接受 `DateTime` 或整数秒，便于和外部时间值直接比较。

## 快速上手

```lisp
let((p)
    ; 当前时刻
    p = ycDateTime::Now()
    printf("%s\n" p->format())                          ; => 2026-11-03 22:10:57（示例值）

    ; 指定格式
    printf("%s\n" p->format(?pattern "%Y/%m/%d %H:%M"))  ; => 2026/11/03 22:10（示例值）
    printf("%s\n" p->format(?pattern "%a %b %d %Y"))     ; => Tue Nov 03 2026（示例值）

    ; 偏移与差值
    printf("%d\n" p->add(?days 1)->diff(p))              ; => 86400
    printf("%d\n" p->add(?hours -2)->compare(p))         ; => -1

    ; 字段
    printf("%d-%02d-%02d\n" p->year() p->month() p->day())  ; => 2026-11-03（示例值）
)
```

## API 参考

### ycDateTime::Now <sub>`function`</sub>

```text
ycDateTime::Now()
=> ycDateTime::DateTime
```

**描述**

返回当前时刻的 `DateTime`。内部由 `getCurrentTime()` 换算，跟随本地时间。

**参数**

无

**返回值**

`ycDateTime::DateTime` — 当前时刻；读取失败时以 `error()` 中断。

**例程**

```lisp
ycDateTime::Now()->format()
; => "2026-11-03 22:10:57"（示例值）
ycDateTime::Now()->epoch()
; => 1793715057（示例值）
```

### ycDateTime::DateTime <sub>`function`</sub> <sub>`class`</sub>

```text
ycDateTime::DateTime(n_time)
=> ycDateTime::DateTime
```

**描述**

按 Unix 秒构造时间对象；同一秒共享同一实例。构造后实例不可变，所有派生操作返回新实例。

**方法**

> 必须使用 `->` 符号调用方法。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| n_time | int | Unix 秒（1970-01-01 00:00:00 UTC 起算，可为负） |

**返回值**

`ycDateTime::DateTime` — 该秒的驻留实例；非整数参数以 `error()` 中断。

**例程**

```lisp
p = ycDateTime::DateTime(1793715057)
p->format(?pattern "%Y-%m-%d")   ; => "2026-11-03"（示例值）
ycDateTime::DateTime(0)->epoch() ; => 0
ycDateTime::DateTime(1234) == ycDateTime::DateTime(1234)  ; => t
```

#### 字段

##### epoch <sub>`method`</sub>

```text
p->epoch()
=> int
```

**描述**

返回构造时的 Unix 秒原值。

**参数**

无

**返回值**

`int` — Unix 秒（可为负）。

**例程**

```lisp
ycDateTime::DateTime(1793715057)->epoch()   ; => 1793715057
```

##### year <sub>`method`</sub>

```text
p->year()
=> int
```

**描述**

返回本地时间的年份。

**参数**

无

**返回值**

`int` — 实际年份（如 `2026`）。

**例程**

```lisp
ycDateTime::DateTime(1793715057)->year()   ; => 2026（示例值，按本地时区）
```

##### month <sub>`method`</sub>

```text
p->month()
=> int
```

**描述**

返回本地时间的月份。

**参数**

无

**返回值**

`int` — `1`～`12`。

**例程**

```lisp
ycDateTime::DateTime(1793715057)->month()   ; => 11（示例值，按本地时区）
```

##### day <sub>`method`</sub>

```text
p->day()
=> int
```

**描述**

返回本地时间的日。

**参数**

无

**返回值**

`int` — `1`～`31`。

**例程**

```lisp
ycDateTime::DateTime(1793715057)->day()   ; => 3（示例值，按本地时区）
```

##### hour <sub>`method`</sub>

```text
p->hour()
=> int
```

**描述**

返回本地时间的小时。

**参数**

无

**返回值**

`int` — `0`～`23`。

**例程**

```lisp
ycDateTime::DateTime(1793715057)->hour()   ; => 22（示例值，按本地时区）
```

##### minute <sub>`method`</sub>

```text
p->minute()
=> int
```

**描述**

返回本地时间的分钟。

**参数**

无

**返回值**

`int` — `0`～`59`。

**例程**

```lisp
ycDateTime::DateTime(1793715057)->minute()   ; => 10（示例值，按本地时区）
```

##### second <sub>`method`</sub>

```text
p->second()
=> int
```

**描述**

返回本地时间的秒。

**参数**

无

**返回值**

`int` — `0`～`59`。

**例程**

```lisp
ycDateTime::DateTime(1793715057)->second()   ; => 57（示例值，按本地时区）
```

##### weekday <sub>`method`</sub>

```text
p->weekday()
=> int
```

**描述**

返回本地时间的星期。

**参数**

无

**返回值**

`int` — `0`～`6`，`0` 为周日。

**例程**

```lisp
ycDateTime::DateTime(1793715057)->weekday()   ; => 2（示例值，按本地时区；周二）
```

##### yday <sub>`method`</sub>

```text
p->yday()
=> int
```

**描述**

返回本地时间在当年中的序日。

**参数**

无

**返回值**

`int` — `1`～`366`。

**例程**

```lisp
ycDateTime::DateTime(1793715057)->yday()   ; => 307（示例值，按本地时区）
```

#### 格式化

##### format <sub>`method`</sub>

```text
p->format([ ?pattern t_pattern ])
=> str
```

**描述**

按模板把本地时间格式化为字符串。模板中 `%` 后跟一个令牌字母（见「格式令牌」），`%%` 表示字面 `%`；其余字符原样输出。未知令牌或模板末尾悬空 `%` 以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?pattern t_pattern | str | `"%Y-%m-%d %H:%M:%S"` | 格式化模板 |

**返回值**

`str` — 格式化结果。

**例程**

```lisp
p = ycDateTime::DateTime(1793715057)
p->format()                              ; => "2026-11-03 22:10:57"（示例值）
p->format(?pattern "%Y%m%d")             ; => "20261103"（示例值）
p->format(?pattern "%H:%M")              ; => "22:10"（示例值）
p->format(?pattern "100%%")              ; => "100%"
p->format(?pattern "%Q")                 ; *Error* ycDateTime::DateTime->format: unknown format token %Q
```

#### 运算与比较

##### add <sub>`method`</sub>

```text
p->add([ ?seconds n_seconds ] [ ?minutes n_minutes ] [ ?hours n_hours ] [ ?days n_days ])
=> ycDateTime::DateTime
```

**描述**

按固定时长偏移，返回新实例，原实例不变。多项增量相加；全部省略或全为 `0` 时返回自身（同一驻留实例）。一天按 86400 秒计，不处理夏令时导致的实际日长差异。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?seconds n_seconds | int | `0` | 秒增量，可为负 |
| ?minutes n_minutes | int | `0` | 分钟增量，可为负 |
| ?hours n_hours | int | `0` | 小时增量，可为负 |
| ?days n_days | int | `0` | 天数增量，可为负 |

**返回值**

`ycDateTime::DateTime` — 偏移后的时刻。

**例程**

```lisp
p = ycDateTime::DateTime(1000)
p->add(?seconds 5)->epoch()          ; => 1005
p->add(?minutes 1)->epoch()          ; => 1060
p->add(?hours 1)->epoch()            ; => 4600
p->add(?days 1)->epoch()             ; => 87400
p->add(?seconds -5)->epoch()         ; => 995
p->add() == p                        ; => t
```

##### diff <sub>`method`</sub>

```text
p->diff(g_other)
=> int
```

**描述**

返回与另一时刻的秒差；`p` 更晚为正。`g_other` 可以是 `DateTime`，也可以是整数 Unix 秒。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| g_other | ycDateTime::DateTime / int | 另一个时刻，或整数 Unix 秒 |

**返回值**

`int` — `p` 减 `g_other` 的秒数；参数不可识别时以 `error()` 中断。

**例程**

```lisp
a = ycDateTime::DateTime(1000)
b = ycDateTime::DateTime(1300)
b->diff(a)     ; => 300
a->diff(b)     ; => -300
a->diff(1000)  ; => 0
a->diff("x")   ; *Error* ycDateTime::DateTime->diff: expected a DateTime or an integer time, got "x"
```

##### compare <sub>`method`</sub>

```text
p->compare(g_other)
=> int
```

**描述**

比较两个时刻的先后；`g_other` 可以是 `DateTime` 或整数 Unix 秒。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| g_other | ycDateTime::DateTime / int | 另一个时刻，或整数 Unix 秒 |

**返回值**

`int` — `p` 早于为 `-1`、相同为 `0`、晚于为 `1`；参数不可识别时以 `error()` 中断。

**例程**

```lisp
a = ycDateTime::DateTime(1000)
b = ycDateTime::DateTime(1300)
a->compare(b)     ; => -1
b->compare(a)     ; => 1
a->compare(1000)  ; => 0
a->compare(nil)   ; *Error* ycDateTime::DateTime->compare: expected a DateTime or an integer time, got nil
```

## 格式令牌

模板中 `%` 后跟一个令牌字母；未知字母以 `error()` 中断。

| 令牌 | 含义 | 示例 |
| --- | --- | --- |
| `%Y` | 四位年份 | `2026` |
| `%y` | 两位年份 | `26` |
| `%m` | 月份（01–12） | `11` |
| `%d` | 日（01–31） | `03` |
| `%H` | 小时（00–23） | `22` |
| `%M` | 分钟（00–59） | `10` |
| `%S` | 秒（00–59） | `57` |
| `%j` | 序日（001–366） | `307` |
| `%w` | 星期（0–6，0 为周日） | `2` |
| `%a` | 星期缩写 | `Tue` |
| `%A` | 星期全名 | `Tuesday` |
| `%b` | 月份缩写 | `Nov` |
| `%B` | 月份全名 | `November` |
| `%p` | 上午/下午标记 | `PM` |
| `%%` | 字面 `%` | `%` |

[返回首页](../../README.md)
