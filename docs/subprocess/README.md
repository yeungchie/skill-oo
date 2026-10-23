# ycSubProcess

Cadence SKILL++ 的子进程封装库：启动进程、实时读写输出、按事件回调，同步与异步双接口。

## 概要

+ 同步接口 `RunJob()` 执行并等待；异步接口 `CreateJob()` 返回 `AsyncJob` 对象，控制进程生命周期。
+ 进程状态以符号表示：`'None`（未启动）/ `'Active`（运行中）/ `'Dead`（已结束）/ `'Stopped`（已暂停）。
+ 输出按条收进 `Stream` 对象：`text()` 全量拼接、`last()`/`shift()` 取单条；耗时由 `Elapsed` 记录。
+ 回调函数按事件符号触发：`'stdout`/`'stderr`/`'post`/`'beforeBegin`/`'afterBegin`。
+ 命令串按 shell 语法解释：引号、`$` 展开、反斜杠转义、管道均照常生效；`print()` 写入的数据直接送达子进程标准输入、不经 shell。
+ 例程中 `; =>` 表示返回值，括注「示例值」者为示意。

## 快速上手

```lisp
; 同步执行：执行并等待，输出实时打印
ycSubProcess::RunJob("whoami")                              ; => t

; 异步执行：启动后取标准输出
aj = ycSubProcess::CreateJob("date")
aj->await()                                                 ; => "Tue Sep 15 22:50:10 CST 2026\n"

; 链式调用：向子进程标准输入写入
aj = ycSubProcess::CreateJob("cat")\
    ->start()\
    ->print("hello")\
    ->print("world")\
    ->close()
aj->await()                                                 ; => "hello\nworld\n"
```

## API 参考

### ycSubProcess::RunJob <sub>`function`</sub>

```text
ycSubProcess::RunJob(
    g_arg
    [ g_args ... ]
)
=> t | nil
```

**描述**

执行给定命令并等待任务完成，子进程输出内容将实时打印。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_arg | Any | | 命令，非字符串会自动转换 |
| g_args | Any | | 命令的其余部分 |

**返回值**

`t | nil` — `t` 表示任务进程正常结束；`nil` 表示执行失败，即进程返回状态码非零。

**例程**

```lisp
ycSubProcess::RunJob("whoami")
; yeung
; => t
```

```lisp
ycSubProcess::RunJob("date")
; Tue Sep 15 22:50:10 CST 2026
; => t
```

```lisp
ycSubProcess::RunJob("bad cmd")
; sh: bad: command not found
; => nil
```

### ycSubProcess::CreateJob <sub>`function`</sub>

```text
ycSubProcess::CreateJob(
    g_arg
    [ g_args ... ]
    [ ?callback g_funcobj ]
    [ ?verbose g_enable ]
)
=> ycSubProcess::AsyncJob
```

**描述**

创建异步任务对象，可通过回调函数处理输出。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_arg | Any | | 命令，非字符串会自动转换 |
| g_args | Any | | 命令的其余部分 |
| ?callback g_funcobj | nil / symbol / funobj | nil | 可选，回调函数 |
| ?verbose g_enable | nil / t | nil | 可选，控制是否实时打印子进程输出 |

回调函数签名：`callback(s_event, g_job)`

+ `s_event`指定事件类型。

    | 有效值 | 触发时机 |
    | --- | --- |
    | `'stdout` | 标准输出有新数据 |
    | `'stderr` | 标准错误输出有新数据 |
    | `'post` | 任务进程执行结束后 |
    | `'beforeBegin` | 任务进程开始执行前 |
    | `'afterBegin` | 任务进程开始执行后 |

+ `g_job`为 `AsyncJob` 对象。

+ 触发顺序：`'beforeBegin` → `'afterBegin` → `'stdout`/`'stderr`（随输出多次触发、可交错）→ `'post`。

+ 回调抛出的错误会被打印，但不会中断任务。

**返回值**

`ycSubProcess::AsyncJob` — 未启动的任务对象，需调用 `start()` 启动。

**例程**

```lisp
aj = ycSubProcess::CreateJob("free -h")
; => <ycSubProcess::AsyncJob status=None, returncode=nil>

printf("%s" aj->await())
;               total        used        free      shared  buff/cache   available
; Mem:            15G        1.6G        8.9G        140M        5.0G         13G
; Swap:          4.0G          0B        4.0G
```

### ycSubProcess::AsyncJob <sub>`function`</sub> <sub>`class`</sub>

```text
ycSubProcess::AsyncJob(
    t_cmd
    [ ?callback g_funcobj ]
    [ ?userData g_data ]
    [ ?verbose g_enable ]
)
=> ycSubProcess::AsyncJob
```

**描述**

异步任务对象，用于控制和获取任务及进程信息。命令串为已拼接好的完整命令；一般经 `CreateJob()`（先拼接命令段）创建。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_cmd | str | | 完整命令串 |
| ?callback g_funcobj | nil / symbol / funobj | nil | 可选，回调函数（签名见 `CreateJob`） |
| ?userData g_data | Any | nil | 可选，可用于携带任意数据 |
| ?verbose g_enable | nil / t | nil | 可选，控制是否实时打印子进程输出 |

**返回值**

`ycSubProcess::AsyncJob` — 未启动的任务对象，需调用 `start()` 启动。

**属性**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| cmd | str | 执行的命令 |
| userData | Any | 可用于携带任意数据 |
| callback | nil / symbol / funcobj | 特定事件触发的回调函数 |
| verbose | nil / t | 控制是否实时打印子进程输出 |
| ipcId | nil / ipcId | 进程间通信 ID，任务还未启动时的值为 `nil` |
| returncode | nil / int | 进程退出状态码，任务还未启动时的值为 `nil` |
| stdout | ycSubProcess::Stream | 标准输出流 |
| stderr | ycSubProcess::Stream | 标准错误输出流 |
| elapsed | ycSubProcess::Elapsed | 任务执行时间 |

**方法**

> 必须使用 `->` 符号调用方法。

#### start <sub>`method`</sub>

```text
aj->start()
=> ycSubProcess::AsyncJob
```

运行任务，启动进程。若已启动则报错。

```lisp
aj = ycSubProcess::CreateJob("whoami")
aj->start()
; => <ycSubProcess::AsyncJob status=Active, returncode=nil>
```

#### wait <sub>`method`</sub>

```text
aj->wait(
    [ n_timeout ]
    [ n_interval ]
)
=> ycSubProcess::AsyncJob
```

等待任务完成。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| n_timeout | int | 1000000 | 单位 **秒**，等待超时时间 |
| n_interval | int | 30 | 单位 **秒**，提示信息打印时间间隔 |

#### await <sub>`method`</sub>

```text
aj->await(
    [ ?check g_enable ]
)
=> str
```

自动启动并等待完成，返回标准输出内容。

任务处于 `'Stopped` 时无法等到结束，会抛出错误，需先 `continue()` 继续或 `kill()` 终止。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?check g_enable | bool | nil | 是否检查返回码，非零时抛出错误 |

```lisp
ycSubProcess::CreateJob("whoami")->await()
; => "yeung\n"
```

设置 `?check t` 时，进程返回码非零会抛出错误。

```lisp
ycSubProcess::CreateJob("whoamii")->await(?check t)
; sh: whoamii: command not found
; *Error* funcall: job failed, returncode is 127
```

#### kill <sub>`method`</sub>

```text
aj->kill()
=> t | nil
```

强制终止任务。

#### state <sub>`method`</sub>

```text
aj->state()
=> sym
```

获取任务进程状态。

| 状态 | 说明 |
| --- | --- |
| `'None` | 未启动 |
| `'Active` | 运行中 |
| `'Dead` | 已结束 |
| `'Stopped` | 已暂停 |

#### stop <sub>`method`</sub>

```text
aj->stop()
=> t | nil
```

暂停任务，类似 Ctrl+Z。

#### continue <sub>`method`</sub>

```text
aj->continue()
=> t | nil
```

继续执行已暂停的任务。

#### print <sub>`method`</sub>

```text
aj->print(
    t_formatString
    [ g_args ... ]
    [ ?end t_string ]
)
=> ycSubProcess::AsyncJob
```

向标准输入写入内容。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_formatString | str | | 格式化字符串 |
| g_args | Any | | 格式化参数 |
| ?end t_string | str | `"\n"` | 结尾字符 |

```lisp
aj = ycSubProcess::CreateJob("cat")
aj->start()
; => t

aj->print("123")
aj->stdout->text()
; => "123\n"

aj->print("456")
aj->print("789")
aj->close()
aj->await()
; => "123\n456\n789\n"
```

#### close <sub>`method`</sub>

```text
aj->close()
=> t | nil
```

关闭标准输入通道，类似 `Ctrl + D`。

#### signal <sub>`method`</sub>

```text
aj->signal(
    s_signal
)
=> t | nil
```

发送信号。

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| s_signal | symbol | 向任务进程发送信号 |

| 有效值 | 说明 |
| --- | --- |
| `'INT` | 中断任务进程，类似 `Ctrl + C` |
| `'QUIT` | 退出任务进程，类似 `Ctrl + \` |
| `'TERM` | 终止任务进程， 类似 `kill -15 PID` |
| `'KILL` | 强制终止任务进程，类似 `kill -9 PID` |

#### sleep <sub>`method`</sub>

```text
aj->sleep(
    [ n_second ]
)
=> ycSubProcess::AsyncJob
```

控制父进程休眠，单位秒。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| n_second | int / float | 0 | 单位 **秒** |

#### 方法链

以下方法支持链式调用。

+ `start`
+ `print`
+ `wait`
+ `sleep`

```lisp
ycSubProcess::CreateJob("cat")\
    ->start()\
    ->print("hello")\
    ->print("world")\
    ->close()
; => t
```

```lisp
ycSubProcess::CreateJob("sleep 1")\
    ->start()\
    ->wait()\
    ->elapsed->humanReadable()
; => "1s"
```

### ycSubProcess::Stream <sub>`class`</sub>

一个 FIFO 数据流对象，用于获取任务进程输出。

**方法**

> 必须使用 `->` 符号调用方法。

#### push <sub>`method`</sub>

```text
aj->stdout->push(
    t_text
)
=> t
```

向数据流尾部追加一条数据。

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| t_text | str | 待追加的数据 |

```lisp
aj->stdout->push("hello\n")
aj->stdout->last()
; => "hello\n"
```

#### text <sub>`method`</sub>

```text
aj->stdout->text(
    [ ?clear g_enable ]
)
=> str
```

获取所有输出内容并拼接为字符串，空流时返回空字符串。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?clear g_enable | bool | nil | 获取后是否清空数据流 |

```lisp
aj->stdout->text()
; => "hello world\n"
```

#### size <sub>`method`</sub>

```text
aj->stdout->size()
=> int
```

获取数据流中数据数量。

#### isEmpty <sub>`method`</sub>

```text
aj->stdout->isEmpty()
=> t | nil
```

判断数据是否为空。

#### last <sub>`method`</sub>

```text
aj->stdout->last()
=> str | nil
```

获取最后一条数据，无数据时返回 nil。

#### shift <sub>`method`</sub>

```text
aj->stdout->shift()
=> str | nil
```

获取并移除第一条数据，无数据时返回 nil。

### ycSubProcess::Elapsed <sub>`class`</sub>

一个时间流逝对象，用于记录和计算任务进程执行时间。

**方法**

> 必须使用 `->` 符号调用方法。

#### mark <sub>`method`</sub>

```text
aj->elapsed->mark()
=> str | nil
```

标记时间点。

前两次调用会返回当前时间，并依次记录为开始时间和结束时间，此后每次调用只会返回 `nil` 无实际效果。

跟随 `AsyncJob` 使用时不需要手动执行，任务会在进程启动和结束时会自动记录。

```lisp
aj->elapsed->mark()
; => "Sep 27 19:46:09 2026"

aj->elapsed->mark()
; => "Sep 27 19:46:10 2026"

aj->elapsed->mark()
; => nil
```

#### getStart <sub>`method`</sub>

```text
aj->elapsed->getStart()
=> str | nil
```

获取开始时间。

当开始时间未标记时返回 `nil`。

```lisp
aj->elapsed->getStart()
; => "Sep 27 19:46:09 2026"
```

#### getEnd <sub>`method`</sub>

```text
aj->elapsed->getEnd()
=> str | nil
```

获取结束时间。

当结束时间未标记时返回 `nil`。

```lisp
aj->elapsed->getEnd()
; => "Sep 27 19:46:10 2026"
```

#### getSeconds <sub>`method`</sub>

```text
aj->elapsed->getSeconds()
=> int
```

获取流逝时间，单位 **秒**。

当开始和结束时间未标记时会抛出错误。

```lisp
aj->elapsed->getSeconds()
; => 1
```

#### humanReadable <sub>`method`</sub>

```text
aj->elapsed->humanReadable()
=> str
```

以人类可读格式返回耗时信息。

返回的格式有如下几种情况：

| 耗时(s) | 示例 |
| --- | --- |
| 0 | `~0s` |
| 1 | `1s` |
| 60 | `1m` |
| 61 | `1m1s` |
| 3600 | `1h` |
| 3601 | `1h1s` |
| 3660 | `1h1m` |
| 3661 | `1h1m1s` |

```lisp
aj->elapsed->humanReadable()
; => "1s"
```
