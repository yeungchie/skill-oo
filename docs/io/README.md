# ycIO

[返回首页](../../README.md)

Cadence SKILL++ 的文件端口库：包装原生 file port，提供方法式读写、幂等关闭与 `ycWith` 自动关闭。

## 概要

- `ycIO::Open` 按模式打开文件并返回 `ycIO::Port`：`"r"` 读取、`"w"` 截断写入、`"a"` 追加写入。
- 读取方法保留行尾换行；`readLine` 在文件末尾返回 `nil`。
- `write` 返回端口自身，可以链式调用；写入内容可能先进入缓冲，`flush()` 或 `close()` 才落盘。
- `flush()` 把写入缓冲刷到文件并返回端口自身；只读端口上无操作。
- `close` 幂等；即使底层关闭报错，端口也会标记为已关闭。关闭后的 `readLine`、`readAll`、`write`、`flush` 都以 `error()` 中断。
- `Port` 独占底层原生 port；需要底层对象时调用 `port()`。
- `ycWith` 在正常退出与体内出错两条路径上都会调用 `close()`。
- 只包装文件 port，不涉及标准输入输出与管道。

## 快速上手

```lisp
; 覆盖写入后关闭
p = ycIO::Open("./a.txt" ?mode "w")
p->write("hello\n")->close()

; 追加
p = ycIO::Open("./a.txt" ?mode "a")
p->write("world\n")->close()

; 读取全文
p = ycIO::Open("./a.txt")
text = p->readAll()
p->close()
; text => "hello\nworld\n"

; with：离开作用域自动关闭
ycWith(q ycIO::Open("./b.txt" ?mode "w")
    q->write("bye\n")
)
```

## API 参考

### ycIO::Open <sub>`function`</sub>

```text
ycIO::Open(
    t_path
    [ ?mode t_mode ]
)
=> ycIO::Port
```

**描述**

打开文件并返回端口包装。相对路径按当前工作目录解析；返回的 `Port` 独占该原生 port。模式非法、文件无法打开时以 `error()` 中断；`"r"` 模式要求目标是已存在的文件，目录、空路径或文件缺失同样以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_path | str |  | 文件路径 |
| ?mode t_mode | str | `"r"` | `"r"` / `"w"` / `"a"` |

`?mode` 的有效值：

| 有效值 | 结果 |
| --- | --- |
| `"r"` | 只读打开；目标必须是已存在文件 |
| `"w"` | 创建或截断已有内容后写入 |
| `"a"` | 创建或追加写入 |

其他值以 `error()` 中断。

**返回值**

`ycIO::Port` — 新的端口包装；打开失败时以 `error()` 中断。

**例程**

```lisp
p = ycIO::Open("./a.txt" ?mode "w")
p->write("x")->close()

r = ycIO::Open("./a.txt")
r->readAll()
; => "x"
r->close()

ycIO::Open("./a.txt" ?mode "b")
; *Error* ycIO::Open: invalid mode: 'b'
```

### ycIO::Port <sub>`class`</sub>

文件端口包装类。实例由 `ycIO::Open` 构造，不直接调用 `makeInstance`。

**方法**

> 必须使用 `->` 符号调用方法。

#### readLine <sub>`method`</sub>

```text
p->readLine()
=> str / nil
```

读取一行，保留行尾换行；到达文件末尾返回 `nil`。端口已关闭时以 `error()` 中断。

**返回值**

`str / nil` — 一行文本；EOF 返回 `nil`。

**例程**

```lisp
p = ycIO::Open("./a.txt" ?mode "w")
p->write("one\ntwo\n")->close()

r = ycIO::Open("./a.txt")
r->readLine()
; => "one\n"
r->readLine()
; => "two\n"
r->readLine()
; => nil
r->close()
```

#### readAll <sub>`method`</sub>

```text
p->readAll()
=> str
```

读取到文件末尾并拼接，保留换行；空文件返回空串。端口已关闭时以 `error()` 中断。

**返回值**

`str` — 剩余内容；空文件为 `""`。

**例程**

```lisp
p = ycIO::Open("./a.txt" ?mode "w")
p->write("a\nb\n")->close()

r = ycIO::Open("./a.txt")
r->readAll()
; => "a\nb\n"
r->close()
```

#### write <sub>`method`</sub>

```text
p->write(
    t_text
)
=> ycIO::Port
```

向端口写入字符串并返回自身，便于链式调用。写入内容可能先进入缓冲，需要 `flush()` 或 `close()` 才落盘。`t_text` 非字符串时以 `error()` 中断；端口已关闭时以 `error()` 中断。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_text | str | 写入内容 |

**返回值**

`ycIO::Port` — 端口自身。

**例程**

```lisp
p = ycIO::Open("./a.txt" ?mode "w")
p->write("x\n")->write("y\n")->close()

ycPathLib::Path("./a.txt")->readText()
; => "x\ny\n"
```

#### flush <sub>`method`</sub>

```text
p->flush()
=> ycIO::Port
```

把写入缓冲刷到文件，返回端口自身。只读端口上无操作；端口已关闭时以 `error()` 中断。

**返回值**

`ycIO::Port` — 端口自身。

**例程**

```lisp
p = ycIO::Open("./a.txt" ?mode "w")
p->write("x")->flush()
; 此时其他读者可读到 x
p->close()
```

#### close <sub>`method`</sub>

```text
p->close()
=> t
```

关闭底层原生 port。可重复调用；已关闭时直接返回 `t`。若底层关闭报错，端口仍标记为已关闭，错误照常外传；后续 `close()` 直接返回 `t`。

**返回值**

`t` — 恒为 `t`。

**例程**

```lisp
p = ycIO::Open("./a.txt")
p->close()
; => t
p->close()
; => t
```

#### isClosed <sub>`method`</sub>

```text
p->isClosed()
=> t / nil
```

查询端口是否已关闭。

**返回值**

`t / nil` — 已关闭为 `t`，否则为 `nil`。

**例程**

```lisp
p = ycIO::Open("./a.txt")
p->isClosed()
; => nil
p->close()
p->isClosed()
; => t
```

#### port <sub>`method`</sub>

```text
p->port()
=> port
```

返回底层原生 file port。关闭后仍返回原对象，便于调用原生函数或排查状态。

**返回值**

`port` — 原生 file port。

**例程**

```lisp
p = ycIO::Open("./a.txt")
port = p->port()
; port 是原生 file port，可直接传给原生函数
let((line)
    gets(line port)
)
p->close()
```

[返回首页](../../README.md)
