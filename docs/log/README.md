# ycLog

[返回首页](../../README.md)

Cadence SKILL++ 的分级日志库：按级别过滤，同时写 CIW 与控制台输出、可选写入文件。

## 概要

- 级别固定为 `debug` / `info` / `warn` / `error` 四级，按优先级过滤；默认阈值为 `info`。
- 输出目标可组合：`?console t` 写 CIW / 标准输出，`?file` 指定日志文件；两者可同时开启。
- 文件默认追加打开；`?append nil` 时截断重写。
- `?flush t`（默认）在每条记录后立即落盘，文件可被外部实时读取；高吞吐场景可置 `nil`，由 `flush()` 或 `close()` 统一落盘。
- 时间戳默认 `[%F %T]`（形如 `[2026-11-14 21:32:47]`），可用 `?timeFormat` 传模板自定义；`?timeFormat nil` 关闭。
- 时间戳依赖 `ycDateTime`：默认模板要求 `ycDateTime` 已加载，未加载时构造器以 `error()` 中断；`?timeFormat nil` 可完全避开该依赖。
- 构造器错误以 `ycLog::Logger:` 开头，方法错误以 `ycLog::Logger-><方法>:` 开头。级别方法（`debug`/`info`/`warn`/`error`/`log`）带可变参数，格式串类型错误由方法报告，额外参数交给格式化处理；普通方法（如 `setLevel`）的参数类型错误由参数绑定报告 `argument #N ...`。

## 快速上手

```lisp
; 控制台日志
lg = ycLog::Logger("flow")
lg->info("start")
; 控制台输出：
;   [2026-11-14 21:32:47] [INFO] [flow] start

; 同时写文件，并只保留 warn 及以上
lg = ycLog::Logger("flow" ?file "./run.log" ?level 'warn)
lg->info("hidden")
lg->warn("disk %d%%" 90)
lg->error("failed: %s" "timeout")

; 调整阈值
lg->setLevel('debug)
lg->debug("detail %d" 1)

; 关闭文件端口（控制台仍可用）
lg->close()
```

## API 参考

### ycLog::Logger <sub>`function`</sub> <sub>`class`</sub>

```text
ycLog::Logger(
    t_name
    [ ?level s_level ]
    [ ?file t_file ]
    [ ?console g_console ]
    [ ?append g_append ]
    [ ?flush g_flush ]
    [ ?timeFormat t_timeFormat ]
)
=> ycLog::Logger
```

**描述**

构造分级日志器。`t_name` 写进每行前缀；空串时不显示名称段。

`?file` 在构造时打开：所在目录不存在或不可写、文件名为空串时以 `error()` 中断；不会自动创建父目录。`?console` 与 `?file` 相互独立，至少应开启一个才有输出。

日志行形如：

```text
[2026-11-14 21:32:47] [INFO] [flow] message
[2026-11-14 21:32:47] [WARN] message
```

`?timeFormat` 是 `ycDateTime` 的格式模板：`%F` / `%T` 等令牌原样生效，`%%` 表示字面 `%`，未支持的令牌以 `error()` 中断，错误消息会附带 `ycDateTime` 给出的具体原因（如 `unknown format token %z`）；格式结果后自动补一个空格再接级别标签。`nil` 去掉时间戳段；名称为空时去掉 `[name]` 段。使用非 `nil` 模板时要求 `ycDateTime` 已加载。

```lisp
lg = ycLog::Logger("demo" ?timeFormat "%F")
lg->info("custom")
; 控制台输出：
;   2026-11-14 [INFO] [demo] custom
lg->close()
```

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_name | str |  | 日志器名称；空串不显示名称段 |
| ?level s_level | sym | 'info | 过滤阈值：`'debug` / `'info` / `'warn` / `'error` |
| ?file t_file | str / nil | nil | 日志文件路径；nil 不写文件 |
| ?console g_console | t / nil | t | t 写 CIW / 标准输出，nil 不写 |
| ?append g_append | t / nil | t | t 追加，nil 截断 |
| ?flush g_flush | t / nil | t | t 每条记录后立即落盘 |
| ?timeFormat t_timeFormat | str / nil | "[%F %T]" | 时间戳模板；nil 关闭 |

`?level` 的取值与过滤结果：

| 有效值 | 输出范围 |
| --- | --- |
| `'debug` | debug、info、warn、error 全部输出 |
| `'info` | info、warn、error；debug 丢弃 |
| `'warn` | warn、error；debug、info 丢弃 |
| `'error` | 仅 error |

**返回值**

`ycLog::Logger` — 新日志器；级别未知、选项不是 `t`/`nil`、文件参数非法或文件打不开、时间戳开启但 `ycDateTime` 未加载、`?timeFormat` 非法时以 `error()` 中断。

**例程**

```lisp
lg1 = ycLog::Logger("demo")                                  ; 只写控制台
lg2 = ycLog::Logger("demo" ?file "./run.log")                ; 控制台 + 文件
lg3 = ycLog::Logger("demo" ?file "./run.log" ?append nil)    ; 文件截断重写
lg4 = ycLog::Logger("demo" ?console nil ?file "./run.log")   ; 只写文件
lg5 = ycLog::Logger("demo" ?level 'warn ?timeFormat nil)     ; 只保留 warn 及以上，无时间戳
lg6 = ycLog::Logger("demo" ?timeFormat "%F")                 ; 只保留日期
lg1->close()
lg2->close()
lg3->close()
lg4->close()
lg5->close()
lg6->close()
```

**方法**

> 必须使用 `->` 符号调用方法。

#### debug <sub>`method`</sub>

```text
lg->debug(t_fmt [ l_args ... ])
=> ycLog::Logger
```

写 `DEBUG` 级记录；低于当前阈值时不输出。消息类型校验发生在阈值判断之前，因此即使该级别被过滤，传入非字符串格式串仍会以 `error()` 中断。`l_args` 非空时按 `lsprintf` 格式化；为空时 `t_fmt` 原样输出，消息中的 `%` 不参与格式解释。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_fmt | str |  | 格式串或正文 |
| l_args | any |  | 可选，格式参数 |

```lisp
lg = ycLog::Logger("demo" ?level 'debug)
lg->debug("count=%d" 3)
lg->close()
```

#### info <sub>`method`</sub>

```text
lg->info(t_fmt [ l_args ... ])
=> ycLog::Logger
```

写 `INFO` 级记录，语义同 `debug`。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_fmt | str |  | 格式串或正文 |
| l_args | any |  | 可选，格式参数 |

```lisp
lg = ycLog::Logger("demo")
lg->info("started")
lg->close()
```

#### warn <sub>`method`</sub>

```text
lg->warn(t_fmt [ l_args ... ])
=> ycLog::Logger
```

写 `WARN` 级记录，语义同 `debug`。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_fmt | str |  | 格式串或正文 |
| l_args | any |  | 可选，格式参数 |

```lisp
lg = ycLog::Logger("demo")
lg->warn("retry %d" 3)
lg->close()
```

#### error <sub>`method`</sub>

```text
lg->error(t_fmt [ l_args ... ])
=> ycLog::Logger
```

写 `ERROR` 级记录，语义同 `debug`。这是日志级别，不会中断执行；需要中断时使用 `error()`。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_fmt | str |  | 格式串或正文 |
| l_args | any |  | 可选，格式参数 |

```lisp
lg = ycLog::Logger("demo")
lg->error("failed: %s" "timeout")
lg->close()
```

#### log <sub>`method`</sub>

```text
lg->log(s_level t_fmt [ l_args ... ])
=> ycLog::Logger
```

按运行期级别写记录。`s_level` 必须是四个级别之一；未知级别以 `error()` 中断（级别校验先于消息类型校验）。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| s_level | sym |  | 级别：`'debug` / `'info` / `'warn` / `'error` |
| t_fmt | str |  | 格式串或正文 |
| l_args | any |  | 可选，格式参数 |

| 有效值 | 输出范围 |
| --- | --- |
| `'debug` | debug、info、warn、error 全部输出 |
| `'info` | info、warn、error；debug 丢弃 |
| `'warn` | warn、error；debug、info 丢弃 |
| `'error` | 仅 error |

```lisp
lg = ycLog::Logger("demo")
lg->log('info "level from a variable")
lg->close()
```

#### level <sub>`method`</sub>

```text
lg->level()
=> sym
```

返回当前过滤阈值。

```lisp
lg = ycLog::Logger("demo" ?level 'warn)
lg->level()
; => warn
lg->close()
```

#### setLevel <sub>`method`</sub>

```text
lg->setLevel(s_level)
=> ycLog::Logger
```

修改过滤阈值；未知级别以 `error()` 中断。返回同一日志器，可继续链式调用。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| s_level | sym |  | 新阈值：`'debug` / `'info` / `'warn` / `'error` |

| 有效值 | 输出范围 |
| --- | --- |
| `'debug` | debug、info、warn、error 全部输出 |
| `'info` | info、warn、error；debug 丢弃 |
| `'warn` | warn、error；debug、info 丢弃 |
| `'error` | 仅 error |

```lisp
lg = ycLog::Logger("demo" ?level 'error)
lg->setLevel('debug)
lg->debug("now visible")
lg->close()
```

#### flush <sub>`method`</sub>

```text
lg->flush()
=> t
```

把文件缓冲落盘；未开文件或无待写内容时无操作。`?flush t` 时通常不需要手动调用。

```lisp
lg = ycLog::Logger("demo" ?file "./run.log" ?flush nil)
lg->info("buffered")
lg->flush()
lg->close()
```

#### close <sub>`method`</sub>

```text
lg->close()
=> t
```

关闭文件端口并落盘；可重复调用。关闭后不再写文件，控制台输出仍然有效。若底层关闭报错，文件端口仍会被释放（后续写日志不再访问已关闭端口），错误照常外传。

```lisp
lg = ycLog::Logger("demo" ?file "./run.log")
lg->info("last file line")
lg->close()
lg->info("console only")
```

[返回首页](../../README.md)
