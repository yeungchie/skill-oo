# ycIO

[返回首页](../../README.md)

Cadence SKILL++ 的文件与字符串端口库：包装原生 port，提供方法式读写、定位、格式化读取、幂等关闭与 `ycWith` 自动关闭。

## 概要

- `ycIO::Open` 按模式打开文件并返回 `ycIO::Port`：`"r"` 读取、`"w"` 截断写入、`"a"` 追加写入。
- `ycIO::FromString` 从字符串创建只读 `ycIO::StringPort`；`ycIO::ToString` 创建只写 `StringPort`。
- 读取方法保留行尾换行；`readLine` 在末尾返回 `nil`，`readAll` 在空内容上返回 `""`。
- `write` 返回端口自身，可以链式调用；文件写入可能需要 `flush()` 或 `close()` 才落盘，字符串 writer 用 `text()` 取内容。
- `fscanf` 的变量名以符号列表传入；`seek` / `tell` 基于原生定位接口，两个端口类的 `seek` 对越界目标都返回 `nil`。
- `close` 幂等；关闭后的读写、格式化与定位都以 `error()` 中断。
- `StringPort` 的 writer 在 `close()` 时捕获文本，因此 `text()` 在 `ycWith` 退出后仍可读取。
- `Port` 与 `StringPort` 是两个独立类，共享同一套端口方法协议；`StringPort` 内部组合一个 `Port`。
- `port()` 返回原生 port，仅作逃生口；常规读写、格式化与定位不需要它。
- 只包装文件与字符串 port，不涉及标准输入输出与管道。

## 快速上手

```lisp
; 文件：覆盖写入后读取
p = ycIO::Open("./a.txt" ?mode "w")
p->write("hello\n")->close()

r = ycIO::Open("./a.txt")
r->readAll()
; => "hello\n"
r->close()

; 字符串 reader：格式化读取与定位
sr = ycIO::FromString("10 20 hello\nsecond\n")
sr->fscanf("%d %d %s" list('a 'b 'c))
; => 3（a=10，b=20，c="hello"）
sr->seek(0)
sr->readLine()
; => "10 20 hello\n"
sr->close()

; 字符串 writer：关闭后仍可取内容
sw = ycIO::ToString()
sw->write("x\n")->write("y\n")
sw->text()
; => "x\ny\n"
sw->close()
sw->text()
; => "x\ny\n"

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

### ycIO::FromString <sub>`function`</sub>

```text
ycIO::FromString(
    t_text
)
=> ycIO::StringPort
```

**描述**

从字符串创建只读字符串端口。读取按字节进行，UTF-8 内容原样保留；空串是合法的，首次读取即返回 `nil`。reader 的 `seek` 会重建内部输入 port，因此读到 EOF 后仍可回到起点重新读取。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_text | str | 输入字符串 |

**返回值**

`ycIO::StringPort` — 只读字符串端口；输入不是字符串时以 `error()` 中断。

**例程**

```lisp
r = ycIO::FromString("a\nb\n")
r->readLine()
; => "a\n"
r->readAll()
; => "b\n"
r->close()
```

### ycIO::ToString <sub>`function`</sub>

```text
ycIO::ToString()
=> ycIO::StringPort
```

**描述**

创建只写字符串端口。写入内容保存在内存中；`text()` 在端口打开时返回当前内容，在 `close()` 后返回关闭时捕获的内容。writer 的 `seek` 与文件写端口一致，目标须落在已写内容范围内；在末尾 `write()` 即追加内容。

**参数**

无。

**返回值**

`ycIO::StringPort` — 只写字符串端口。

**例程**

```lisp
w = ycIO::ToString()
w->write("abc")->write("def")
w->text()
; => "abcdef"
w->close()
w->text()
; => "abcdef"
```

### ycIO::Port <sub>`class`</sub>

文件端口包装类。实例由 `ycIO::Open` 构造，不直接调用 `makeInstance`；`StringPort` 通过组合一个 `Port` 复用其底层操作。

**方法**

> 必须使用 `->` 符号调用方法。

#### readLine <sub>`method`</sub>

```text
p->readLine()
=> str / nil
```

读取一行，保留行尾换行；到达文件末尾返回 `nil`。端口已关闭或不是读端口时以 `error()` 中断。

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

读取到文件末尾并拼接，保留换行；空文件返回空串。端口已关闭或不是读端口时以 `error()` 中断。

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

#### fscanf <sub>`method`</sub>

```text
p->fscanf(
    t_format
    l_vars
)
=> int / nil
```

从文件读端口按格式读取。`l_vars` 是接收结果的变量名列表；结果写入调用方同名变量。返回成功读取的项数；格式不匹配返回 `0`；EOF 返回 `nil`。端口已关闭或不是读端口时以 `error()` 中断；`l_vars` 不是符号列表时以 `error()` 中断。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_format | str | 格式串 |
| l_vars | list[symbol] | 接收值的变量名 |

**返回值**

`int / nil` — 成功读取的项数；EOF 返回 `nil`。

**例程**

```lisp
p = ycIO::Open("./a.txt" ?mode "w")
p->write("10 20 hello\n")->close()

r = ycIO::Open("./a.txt")
r->fscanf("%d %d %s" list('a 'b 'c))
; => 3
a
; => 10
b
; => 20
c
; => "hello"
r->close()
```

#### write <sub>`method`</sub>

```text
p->write(
    t_text
)
=> ycIO::Port
```

向端口写入字符串并返回自身，便于链式调用。写入内容可能先进入缓冲，需要 `flush()` 或 `close()` 才落盘。`t_text` 非字符串、端口已关闭或不是写端口时以 `error()` 中断。

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

#### seek <sub>`method`</sub>

```text
p->seek(
    x_offset
    [ ?whence x_whence ]
)
=> t / nil
```

移动文件端口位置。偏移按字节计；目标位置必须落在 `0` 到文件长度之间（含两端），否则返回 `nil` 且位置不变。读端口到达文件末尾后读取得到 EOF；写端口在定位前会先刷新缓冲，因此文件长度按已写入内容计算。端口已关闭时以 `error()` 中断；`?whence` 不是 `0/1/2` 时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| x_offset | int |  | 偏移量 |
| ?whence x_whence | int | `0` | 定位基准 |

`?whence` 的有效值：

| 有效值 | 结果 |
| --- | --- |
| `0` | 从起始位置偏移 |
| `1` | 从当前位置偏移 |
| `2` | 从末尾偏移 |

**返回值**

`t / nil` — 成功为 `t`，失败为 `nil`。

**例程**

```lisp
p = ycIO::Open("./a.txt" ?mode "w")
p->write("abcdef\n")->close()

r = ycIO::Open("./a.txt")
r->seek(2)
; => t
r->readLine()
; => "cdef\n"
r->seek(-1 ?whence 2)
; => t
r->readLine()
; => "\n"
r->seek(99)
; => nil（超出文件末尾）
r->tell()
; => 7（失败时不改变位置）
r->close()
```

#### tell <sub>`method`</sub>

```text
p->tell()
=> int
```

返回当前字节偏移，对应原生 `fileTell`。端口已关闭时以 `error()` 中断。

**返回值**

`int` — 当前偏移。

**例程**

```lisp
p = ycIO::Open("./a.txt" ?mode "w")
p->write("abc")->close()

r = ycIO::Open("./a.txt")
r->tell()
; => 0
r->seek(2)
r->tell()
; => 2
r->close()
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

返回底层原生 file port。常规读写、格式化与定位应使用包装方法；`port()` 只作逃生口。关闭后仍返回原对象。

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

### ycIO::StringPort <sub>`class`</sub>

字符串端口类。只读实例由 `ycIO::FromString` 构造，只写实例由 `ycIO::ToString` 构造；不直接调用 `makeInstance`。实现 `ycWith`：正常退出和体内出错都会关闭端口，writer 的文本保留。

**方法**

> 必须使用 `->` 符号调用方法。

#### readLine <sub>`method`</sub>

```text
sp->readLine()
=> str / nil
```

读取一行，保留行尾换行；到达末尾返回 `nil`。只写端口或已关闭端口以 `error()` 中断。

**返回值**

`str / nil` — 一行文本；EOF 返回 `nil`。

**例程**

```lisp
r = ycIO::FromString("a\nb\n")
r->readLine()
; => "a\n"
r->readLine()
; => "b\n"
r->readLine()
; => nil
r->close()
```

#### readAll <sub>`method`</sub>

```text
sp->readAll()
=> str
```

读取到末尾并拼接，保留换行；空内容返回空串。只写端口或已关闭端口以 `error()` 中断。

**返回值**

`str` — 剩余内容；空内容为 `""`。

**例程**

```lisp
r = ycIO::FromString("a\nb\n")
r->readAll()
; => "a\nb\n"
r->readAll()
; => ""
r->close()
```

#### fscanf <sub>`method`</sub>

```text
sp->fscanf(
    t_format
    l_vars
)
=> int / nil
```

从字符串读端口按格式读取。`l_vars` 是接收结果的变量名列表；结果写入调用方同名变量。返回成功读取的项数；格式不匹配返回 `0`；EOF 返回 `nil`。只写端口或已关闭端口以 `error()` 中断；`l_vars` 不是符号列表时以 `error()` 中断。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_format | str | 格式串 |
| l_vars | list[symbol] | 接收值的变量名 |

**返回值**

`int / nil` — 成功读取的项数；EOF 返回 `nil`。

**例程**

```lisp
r = ycIO::FromString("10 20 hello\n")
r->fscanf("%d %d %s" list('a 'b 'c))
; => 3
a
; => 10
b
; => 20
c
; => "hello"
r->close()
```

#### write <sub>`method`</sub>

```text
sp->write(
    t_text
)
=> ycIO::StringPort
```

向字符串 writer 写入内容并返回自身，便于链式调用。`t_text` 非字符串、端口已关闭或不是写端口时以 `error()` 中断。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_text | str | 写入内容 |

**返回值**

`ycIO::StringPort` — 端口自身。

**例程**

```lisp
w = ycIO::ToString()
w->write("x\n")->write("y\n")
w->text()
; => "x\ny\n"
w->close()
```

#### flush <sub>`method`</sub>

```text
sp->flush()
=> ycIO::StringPort
```

刷新字符串 writer 的写缓冲并返回自身；读端口上无操作。端口已关闭时以 `error()` 中断。

**返回值**

`ycIO::StringPort` — 端口自身。

**例程**

```lisp
w = ycIO::ToString()
w->write("x")->flush()
w->text()
; => "x"
w->close()
```

#### seek <sub>`method`</sub>

```text
sp->seek(
    x_offset
    [ ?whence x_whence ]
)
=> t / nil
```

移动字符串端口位置。读端口支持三种基准，并在每次 `seek` 时重建内部输入 port，因此 EOF 后可以重新读取；写端口支持三种基准，目标须落在 `0` 到已写内容长度之间（含两端），向前定位不会丢弃已写内容。端口已关闭时以 `error()` 中断；`?whence` 不是 `0/1/2` 时以 `error()` 中断。

定位目标小于 `0` 或超出内容范围时返回 `nil` 且保持当前位置。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| x_offset | int |  | 偏移量 |
| ?whence x_whence | int | `0` | 定位基准 |

`?whence` 的有效值：

| 有效值 | 结果 |
| --- | --- |
| `0` | 从起始位置偏移；reader 与 writer 都支持 |
| `1` | 从当前位置偏移；reader 与 writer 都支持 |
| `2` | 从末尾偏移；reader 与 writer 都支持 |

**返回值**

`t / nil` — 成功为 `t`，失败为 `nil`。

**例程**

```lisp
r = ycIO::FromString("abcdef")
r->readAll()
; => "abcdef"
r->seek(0)
; => t
r->readLine()
; => "abcdef"
r->close()

w = ycIO::ToString()
w->write("abc")
w->seek(0)
; => t
w->write("XY")
w->text()
; => "XYc"
w->seek(3)
; => t（定位到已写内容的末尾）
w->write("D")
w->text()
; => "XYcD"
w->close()
```

#### tell <sub>`method`</sub>

```text
sp->tell()
=> int
```

返回当前字节偏移。读端口在 EOF 时返回内容长度；写端口返回当前写入位置。端口已关闭时以 `error()` 中断。

**返回值**

`int` — 当前偏移。

**例程**

```lisp
r = ycIO::FromString("abc")
r->readAll()
; => "abc"
r->tell()
; => 3
r->close()

w = ycIO::ToString()
w->write("xy")
w->tell()
; => 2
w->close()
```

#### text <sub>`method`</sub>

```text
sp->text()
=> str
```

返回字符串 writer 写入的内容。端口打开时返回当前内容；`close()` 后返回关闭时捕获的内容。读端口以 `error()` 中断。

**返回值**

`str` — 写入内容。

**例程**

```lisp
w = ycIO::ToString()
w->write("x\n")
w->text()
; => "x\n"
w->close()
w->text()
; => "x\n"
```

#### close <sub>`method`</sub>

```text
sp->close()
=> t
```

关闭字符串端口。writer 在关闭前捕获文本，因此 `text()` 在关闭后仍可读取；可重复调用，已关闭时直接返回 `t`。

**返回值**

`t` — 恒为 `t`。

**例程**

```lisp
w = ycIO::ToString()
w->write("abc")
w->close()
; => t
w->text()
; => "abc"
```

#### isClosed <sub>`method`</sub>

```text
sp->isClosed()
=> t / nil
```

查询字符串端口是否已关闭。

**返回值**

`t / nil` — 已关闭为 `t`，否则为 `nil`。

**例程**

```lisp
w = ycIO::ToString()
w->isClosed()
; => nil
w->close()
w->isClosed()
; => t
```

#### port <sub>`method`</sub>

```text
sp->port()
=> port
```

返回当前底层原生 port。常规读写、格式化与定位应使用包装方法；`port()` 只作逃生口。reader 每次 `seek` 都会替换内部 port，不要跨 `seek` 持有旧的原生 port。

**返回值**

`port` — 原生字符串 port。

**例程**

```lisp
r = ycIO::FromString("abc")
inportp(r->port())
; => t
r->close()

w = ycIO::ToString()
outportp(w->port())
; => t
w->close()
```

[返回首页](../../README.md)
