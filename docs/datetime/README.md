# ycDateTime

[返回首页](../../README.md)

Cadence SKILL++ 的 Unix 时间对象库：`DateTime` 以「秒 + 纳秒」为状态，提供格式化、字段读取、偏移与比较，同一时刻共享同一实例。

## 概要

- `DateTime` 包装 Unix 秒（1970-01-01 00:00:00 UTC 起算，可为负）与秒内纳秒，不可变：任何"修改"都返回新实例；构造时可传浮点秒，按「秒 + 小数」拆分。
- 秒值是 32 位整数，可表示范围约为 1901-12-13 至 2038-01-19（本地时间）；构造、偏移与解析超出该范围时以 `error()` 中断，不会静默截断。
- 同一时刻（秒与纳秒都相同）在缓存容量内驻留共享，`==` 即表示同一实例；缓存最多保留 8192 个时刻，超出后整体清空、较早的实例不再共享，需要按值比较时用 `compare`。`printself` 输出 `ycDateTime::DateTime(<秒>)` 或两参形式，可用 `evalstring` 复得同一实例（缓存内）。
- 时间字段按本地时间解释（与 `timeToTm` 一致）；不提供时区换算。
- 格式化使用本库自己的模板方言（令牌见 `format` 条目），默认 `"%F %T"`（等值于 `"%Y-%m-%d %H:%M:%S"`）；未知令牌与末尾悬空 `%` 以 `error()` 中断，不会静默输出。
- `add` 只做固定时长偏移（一天按 86400 秒），不做日历月/年运算。
- `diff` 与 `compare` 接受 `DateTime` 或整数秒，便于和外部时间值直接比较。
- `Parse` 按同一套模板把文本反向解析为 `DateTime`；周序号类令牌（`%U %W %V %G %g`）与 `%z`/`%Z` 不支持，`%s` 不能与日期时间字段混用，但可配合 `%N`/`%L` 读秒内小数。
- 全局宏 `ycTimeIt` 测量被包裹代码的耗时并返回 `DateTime`（epoch 0 起）；宏无法命名空间化，故不带 `ycDateTime::` 前缀。

## 快速上手

```lisp
let((p)
    ; 当前时刻
    p = ycDateTime::Current()
    printf("%s\n" p->format())                          ; => 2026-11-03 22:10:57（示例值）

    ; 指定格式
    printf("%s\n" p->format("%F %T"))                    ; => 2026-11-03 22:10:57（示例值）
    printf("%s\n" p->format("%Y/%m/%d %H:%M"))           ; => 2026/11/03 22:10（示例值）
    printf("%s\n" p->format("%a %b %d %Y"))              ; => Tue Nov 03 2026（示例值）

    ; 偏移与差值
    printf("%d\n" p->add(?days 1)->diff(p))              ; => 86400
    printf("%d\n" p->add(?hours -2)->compare(p))         ; => -1

    ; 字段
    printf("%d-%02d-%02d\n" p->year() p->month() p->day())  ; => 2026-11-03（示例值）
)
```

## API 参考

### ycDateTime::Current <sub>`function`</sub>

```text
ycDateTime::Current()
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
ycDateTime::Current()->format()
; => "2026-11-03 22:10:57"（示例值）
ycDateTime::Current()->epoch()
; => 1793715057（示例值）
```

### ycDateTime::DateTime <sub>`function`</sub> <sub>`class`</sub>

```text
ycDateTime::DateTime(n_time [ n_nanos ])
=> ycDateTime::DateTime
```

**描述**

按 Unix 秒与秒内纳秒构造时间对象；同一时刻共享同一实例。`n_time` 可以是整数秒，也可以是浮点秒（按「秒 + 小数」拆分）。构造后实例不可变，所有派生操作返回新实例。

**方法**

> 必须使用 `->` 符号调用方法。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| n_time | int / float | Unix 秒（1970-01-01 00:00:00 UTC 起算，可为负，须落在 32 位秒值范围内）；浮点按下取整秒，小数部分四舍五入到纳秒 |
| n_nanos | int | 秒内纳秒（0～999999999，默认 0）；越界报错；仅整数时间可用 |

**返回值**

`ycDateTime::DateTime` — 该时刻的驻留实例；参数类型不符、时间或纳秒越界、浮点时间同时给纳秒时以 `error()` 中断。

**例程**

```lisp
p = ycDateTime::DateTime(1793715057)
p->format("%Y-%m-%d")   ; => "2026-11-03"（示例值）
ycDateTime::DateTime(0)->epoch() ; => 0
ycDateTime::DateTime(1 500000000)->nanos()  ; => 500000000
ycDateTime::DateTime(1.5)->nanos()          ; => 500000000
ycDateTime::DateTime(1234) == ycDateTime::DateTime(1234)  ; => t
ycDateTime::DateTime(0 1000000000)          ; *Error* ycDateTime::DateTime: nanos must be 0..999999999, got 1000000000
ycDateTime::DateTime(1e10)                  ; *Error* ycDateTime::DateTime: time 1e+10 is out of the representable range
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

##### nanos <sub>`method`</sub>

```text
p->nanos()
=> int
```

**描述**

返回秒内的小数部分（纳秒）。

**参数**

无

**返回值**

`int` — `0`～`999999999`。

**例程**

```lisp
ycDateTime::DateTime(1 345678901)->nanos()   ; => 345678901
```

##### millis <sub>`method`</sub>

```text
p->millis()
=> int
```

**描述**

返回秒内小数部分的毫秒值（截断，不含秒）。

**参数**

无

**返回值**

`int` — `0`～`999`。

**例程**

```lisp
ycDateTime::DateTime(1 345678901)->millis()   ; => 345
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
p->format([ t_pattern ])
=> str
```

**描述**

按模板把本地时间格式化为字符串。模板中 `%` 后跟一个令牌字母，其余字符原样输出；`%%` 表示字面 `%`。未知令牌（包括不提供的时区令牌 `%z`/`%Z`）或模板末尾悬空 `%` 以 `error()` 中断。模板省略时使用 `"%F %T"`。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_pattern | str | `"%F %T"` | 格式化模板，可省略 |

**模板令牌**

| 令牌 | 含义 | 示例 |
| --- | --- | --- |
| `%a` | 星期缩写 | `Tue` |
| `%A` | 星期全名 | `Tuesday` |
| `%b` | 月份缩写 | `Nov` |
| `%h` | 月份缩写（同 `%b`） | `Nov` |
| `%B` | 月份全名 | `November` |
| `%c` | 日期时间，等值于 `%a %b %e %H:%M:%S %Y` | `Tue Nov  3 22:10:57 2026` |
| `%C` | 世纪（年份前两位） | `20` |
| `%d` | 日（01–31） | `03` |
| `%D` | 日期，等值于 `%m/%d/%y` | `11/03/26` |
| `%e` | 日（空格补齐两位） | ` 3` |
| `%F` | 日期，等值于 `%Y-%m-%d` | `2026-11-03` |
| `%g` | ISO 周年的后两位 | `26` |
| `%G` | ISO 周年 | `2026` |
| `%H` | 小时（00–23） | `22` |
| `%I` | 小时（01–12） | `10` |
| `%j` | 序日（001–366） | `307` |
| `%L` | 秒内毫秒（000–999） | `345` |
| `%m` | 月份（01–12） | `11` |
| `%M` | 分钟（00–59） | `10` |
| `%n` | 换行 | |
| `%N` | 秒内纳秒（九位） | `345678901` |
| `%p` | 上午/下午标记 | `PM` |
| `%P` | 上午/下午标记（小写） | `pm` |
| `%r` | 12 小时时间，等值于 `%I:%M:%S %p` | `10:10:57 PM` |
| `%R` | 时:分，等值于 `%H:%M` | `22:10` |
| `%s` | Unix 秒 | `1793715057` |
| `%S` | 秒（00–59） | `57` |
| `%t` | 制表符 | |
| `%T` | 时:分:秒，等值于 `%H:%M:%S` | `22:10:57` |
| `%u` | ISO 星期（1–7，周一为 1） | `2` |
| `%U` | 周序号（周日为一周之首，00–53） | `44` |
| `%V` | ISO 周序号（01–53） | `45` |
| `%w` | 星期（0–6，0 为周日） | `2` |
| `%W` | 周序号（周一为一周之首，00–53） | `44` |
| `%x` | 日期，等值于 `%m/%d/%y` | `11/03/26` |
| `%X` | 时间，等值于 `%H:%M:%S` | `22:10:57` |
| `%y` | 两位年份 | `26` |
| `%Y` | 四位年份 | `2026` |
| `%%` | 字面 `%` | `%` |

**返回值**

`str` — 格式化结果。

**例程**

```lisp
p = ycDateTime::DateTime(1793715057)
p->format()                     ; => "2026-11-03 22:10:57"（示例值）
p->format("%Y%m%d")             ; => "20261103"（示例值）
p->format("%H:%M")              ; => "22:10"（示例值）
p->format("%F %T %a")           ; => "2026-11-03 22:10:57 Tue"（示例值）
p->format("%s")                 ; => "1793715057"
p->format("100%%")              ; => "100%"
p->format("%Q")                 ; *Error* ycDateTime::DateTime->format: unknown format token %Q
```

#### 运算与比较

##### add <sub>`method`</sub>

```text
p->add([ ?seconds n_seconds ] [ ?minutes n_minutes ] [ ?hours n_hours ] [ ?days n_days ] [ ?millis n_millis ] [ ?nanos n_nanos ])
=> ycDateTime::DateTime
```

**描述**

按固定时长偏移，返回新实例，原实例不变。多项增量相加；全部省略或全为 `0` 时返回同一时刻的实例（缓存命中时即自身）。一天按 86400 秒计，不处理夏令时导致的实际日长差异。增量与当前时刻之和须落在 32 位秒值范围内，否则以 `error()` 中断。`?nanos` 允许超过一秒并自动进位；构造器的 `n_nanos` 则要求严格落在 0～999999999。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?seconds n_seconds | int | `0` | 秒增量，可为负 |
| ?minutes n_minutes | int | `0` | 分钟增量，可为负 |
| ?hours n_hours | int | `0` | 小时增量，可为负 |
| ?days n_days | int | `0` | 天数增量，可为负 |
| ?millis n_millis | int | `0` | 毫秒增量，可为负；任意 32 位整数，超过一秒的部分进位 |
| ?nanos n_nanos | int | `0` | 纳秒增量，可为负；超过一秒的部分进位 |

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
p->add(?millis 1500)->nanos()        ; => 500000000
p->add(?millis 3000)->epoch()        ; => 1003
p->add(?nanos -1)->nanos()           ; => 999999999
p->add() == p                        ; => t
p->add(?days 30000)                  ; *Error* ycDateTime::DateTime->add: the delta is too large to represent
```

##### diff <sub>`method`</sub>

```text
p->diff(g_other)
=> float
```

**描述**

返回与另一时刻的秒差（含亚秒部分，浮点秒）；`p` 更晚为正。`g_other` 可以是 `DateTime`，也可以是整数 Unix 秒。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| g_other | ycDateTime::DateTime / int | 另一个时刻，或整数 Unix 秒 |

**返回值**

`float` — `p` 减 `g_other` 的秒数；参数不可识别时以 `error()` 中断。

**例程**

```lisp
a = ycDateTime::DateTime(1000)
b = ycDateTime::DateTime(1300)
b->diff(a)     ; => 300.0
a->diff(b)     ; => -300.0
a->diff(1000)  ; => 0.0
ycDateTime::DateTime(2 500000000)->diff(ycDateTime::DateTime(1 0))  ; => 1.5
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

### ycDateTime::Parse <sub>`function`</sub>

```text
ycDateTime::Parse(t_text [ t_pattern ])
=> ycDateTime::DateTime
```

**描述**

按模板把文本解析为 `DateTime`。模板默认 `"%F %T"`；支持 `format` 的全部基础令牌与复合令牌，但周序号类令牌（`%U %W %V %G %g`）与时区令牌（`%z %Z`）不支持，出现即以 `error()` 中断。`%s` 可直接读 Unix 秒（允许 `%012d` 这类零填充），不能与其他日期时间字段混用，但可配合 `%N`/`%L` 读秒内小数（不足位数右补零，`%N` 与 `%L` 不能同时出现）。负的 `%s` 不能带非零小数——`%s` 是整秒、`%N` 是秒内正小数，`-1.5` 这类文本无法用两段表示；这种时刻请用 `%F %T.%N`。

日期必须由「年 + 月 + 日」或「年 + `%j`」给出，缺失的时间字段按 `0` 处理；`%I` 未配 `%p` 时按上午解释，`%p` 与 `%H` 冲突则报错。文本与模板不匹配、字段越界、日期不存在（如 2 月 30 日）、本地时间不存在（夏令时跳变）或明示的星期/序日与日期冲突时，以 `error()` 中断。

解析结果须落在 32 位秒值范围内（约 1901–2038）；`%y` 的 1969–2068 枢轴中 2068 一侧超出该范围，会报错而不是折回。夏令时回拨造成的重复本地时间由运行环境的时区规则决定（`tm_isdst = -1`），不保证取第一次还是第二次出现。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_text | str | | 待解析文本 |
| t_pattern | str | `"%F %T"` | 模板，可省略 |

**返回值**

`ycDateTime::DateTime` — 解析结果（缓存容量内与同一时刻共享实例）。

**例程**

```lisp
ycDateTime::Parse("2026-11-03 22:10:57")->format()      ; => "2026-11-03 22:10:57"
ycDateTime::Parse("2026-11-03", "%F")->hour()           ; => 0
ycDateTime::Parse("03 Nov 2026 22:10", "%d %b %Y %H:%M")->format("%F %T")
; => "2026-11-03 22:10:00"
ycDateTime::Parse("1793715057", "%s")->epoch()          ; => 1793715057
ycDateTime::Parse("1793715057.5", "%s.%N")->nanos()     ; => 500000000
ycDateTime::Parse("2024 060", "%Y %j")->format("%F")    ; => "2024-02-29"
ycDateTime::Parse("2026-02-30", "%F")                   ; *Error* ycDateTime::Parse: day 30 is invalid for 2026-02
```

### ycTimeIt <sub>`macro`</sub>

```text
ycTimeIt(expr [ expr ... ])
=> ycDateTime::DateTime
```

**描述**

测量被包裹表达式的运行耗时（墙钟），返回表示该时长的 `DateTime`（以 epoch 0 起算：`epoch()` 为整秒，`nanos()` 为秒内小数）。表达式按顺序求值且只求值一次，其结果被丢弃——需要保留时在体内赋值。

宏是**全局符号**（SKILL 的宏无法命名空间化），加载本库后直接调用，不带 `ycDateTime::` 前缀。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| expr ... | any | 被计时的表达式，至少一个 |

**返回值**

`ycDateTime::DateTime` — 耗时（秒 + 纳秒；由 `measureTime` 的浮点秒换算）。

**例程**

```lisp
d = ycTimeIt(let((x)
    x = 0
    while(x < 50000
        x = x + 1
    )
))
d->epoch()        ; => 0（示例值）
d->format("%N")   ; => "001142979"（示例值）
ycTimeIt(1 + 1)->nanos()   ; => 3099（示例值）

let((n)
    n = 0
    ycTimeIt(n = 42)
    n             ; => 42（结果留在体内变量）
)
```

[返回首页](../../README.md)
