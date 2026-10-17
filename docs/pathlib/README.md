# ycPathLib

Cadence SKILL++ 的路径处理库：纯路径操作与文件系统操作。

## 概要

+ 方法名采用 lowerCamelCase 命名（如 `withSuffix`、`relativeTo`、`expandUser`）。
+ 纯路径操作按词法解析，不访问磁盘；`..` 部件保留不折叠，仅 `resolve()` 规范化。
+ 例程中 `; =>` 表示返回值，`(...)` 为省略的输出、括注「示例值」「本地时间字符串」者为示意；`Path` 返回值常缩写为字符串形式，`$PWD` 与 `$HOME` 分别表示当前工作目录与 HOME 环境变量。类型标记沿用 docstring 轻量伪代码词表（`str`/`int`/`list[T]`/`A | nil` 等）。

## 快速上手

```lisp
; 构造与拼接
ycPathLib::Path("/a" "b" "c.txt")                   ; => "/a/b/c.txt"
ycPathLib::Path("a")->join("b")->str()              ; => "a/b"

; 名称与后缀
ycPathLib::Path("archive.tar.gz")->stem()           ; => "archive.tar"
ycPathLib::Path("a/b.txt")->withSuffix(".md")->str() ; => "a/b.md"

; 相对化
ycPathLib::Path("/a/b/c")->relativeTo("/a")->str()  ; => "b/c"

; 链式组合
ycPathLib::Path("a")->join("b")->withName("c.md")->str() ; => "a/c.md"
```

## API 参考

### ycPathLib::Path <sub>`function`</sub> <sub>`class`</sub>

```text
ycPathLib::Path(g_args ...)
=> ycPathLib::Path
```

**描述**

构造路径对象。零参等价 `Path("")`（结果 `"."`）；多段按 `/` 连接，遇绝对段则丢弃此前拼接；每段为字符串或 `Path`（后者等价于取其 `str()` 再解析），其他类型以 `error()` 中断。

解析规则（词法，不访问磁盘）：

+ 按 `/` 拆分，丢弃空部件与 `.` 部件；首字符为 `/` 则为绝对路径。
+ `..` 部件保留不折叠（仅 `resolve()` 规范化）。

比较：`==` 与 `equal()` 对 `Path` 实例均为身份比较；相同规范化字符串驻留同一实例，因此 `Path("a") == Path("a")` → `t`（不同规范化串的独立实例比较 → `nil`）。值比较用 `p1->str() == p2->str()`。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| g_args ... | str \| Path | 每段；零段时为 `"."` |

**返回值**

`ycPathLib::Path` — 按解析规则拼接后的新路径对象。

**例程**

```lisp
ycPathLib::Path()                    ; => ycPathLib::Path(".")
ycPathLib::Path("")                  ; => ycPathLib::Path(".")
ycPathLib::Path("/a/b/c.txt")        ; => ycPathLib::Path("/a/b/c.txt")
ycPathLib::Path("a" "b")             ; => ycPathLib::Path("a/b")
ycPathLib::Path("a" "/b" "c")        ; => ycPathLib::Path("/b/c")
ycPathLib::Path(ycPathLib::Path("a") "b")  ; => ycPathLib::Path("a/b")
ycPathLib::Path("a" 5)
; *Error* ycPathLib::Path: expected string or Path, got 5
```

实例显示为命名空间限定的构造调用形式（如 `ycPathLib::Path("a/b")`）；顶层用 `evalstring` 执行该串可得同一驻留实例。

**方法**

> 必须使用 `->` 符号调用方法。

#### 字符串化

##### str <sub>`method`</sub>

```text
p->str()
=> str
```

**描述**

取路径的规范化字符串形式：丢弃空部件与 `.` 部件、去除尾部 `/`、`..` 保留。

**参数**

无

**返回值**

`str` — 归一后的路径串；空路径为 `"."`，根为 `"/"`。

**例程**

```lisp
ycPathLib::Path("a//b")->str()       ; => "a/b"
ycPathLib::Path("")->str()           ; => "."
ycPathLib::Path("/a/b/../c")->str()  ; => "/a/b/../c"
```

#### 名称与词干

##### name <sub>`method`</sub>

```text
p->name()
=> str
```

**描述**

取路径末尾的文件或目录名。

**参数**

无

**返回值**

`str` — 末位部件名；`.`、`/` 等无名路径为 `""`。

**例程**

```lisp
ycPathLib::Path("/a/b/c.txt")->name()  ; => "c.txt"
ycPathLib::Path("/")->name()           ; => ""
```

##### stem <sub>`method`</sub>

```text
p->stem()
=> str
```

**描述**

去掉最后一个后缀的名称。规则：`foo.` → `"foo."`；`.bashrc` → `".bashrc"`；`..foo` → `"."`；`a..b` → `"a."`；`..` → `".."`。

**参数**

无

**返回值**

`str` — 剥离末尾后缀后的名称；无有效后缀时即整个名称。

**例程**

```lisp
ycPathLib::Path("/a/b/c.txt")->stem()      ; => "c"
ycPathLib::Path("archive.tar.gz")->stem()  ; => "archive.tar"
ycPathLib::Path("noext")->stem()           ; => "noext"
```

##### suffix <sub>`method`</sub>

```text
p->suffix()
=> str
```

**描述**

取最后一个后缀；取值规则：`.bashrc` → `""`（隐藏名不算后缀）；`foo.` → `""`；`..foo` → `".foo"`。

**参数**

无

**返回值**

`str` — 末尾后缀（含点）；无后缀时为 `""`。

**例程**

```lisp
ycPathLib::Path("archive.tar.gz")->suffix()  ; => ".gz"
ycPathLib::Path("a.b.c")->suffix()           ; => ".c"
ycPathLib::Path(".bashrc")->suffix()         ; => ""
```

##### suffixes <sub>`method`</sub>

```text
p->suffixes()
=> list[str]
```

**描述**

取名称首点之后的全部后缀。注意 `a..b` → `("." ".b")`，`x.y.`、`foo.` → `nil`。

**参数**

无

**返回值**

`list[str]` — 全部后缀列表；无后缀时为 `nil`。

**例程**

```lisp
ycPathLib::Path("archive.tar.gz")->suffixes()  ; => (".tar" ".gz")
ycPathLib::Path("a.b.c")->suffixes()           ; => (".b" ".c")
ycPathLib::Path("noext")->suffixes()           ; => nil
```

#### 路径结构

##### parts <sub>`method`</sub>

```text
p->parts()
=> list[str]
```

**描述**

取路径按 `/` 拆分的部件列表，`..` 保留不折叠。

**参数**

无

**返回值**

`list[str]` — 拆分后的部件；绝对路径首元素为 `"/"`，`.` 与空路径为 `nil`。

**例程**

```lisp
ycPathLib::Path("/a/b/c.txt")->parts()  ; => ("/" "a" "b" "c.txt")
ycPathLib::Path("a//b")->parts()        ; => ("a" "b")
ycPathLib::Path(".")->parts()           ; => nil
```

##### parent <sub>`method`</sub>

```text
p->parent()
=> Path
```

**描述**

取上级目录路径。

**参数**

无

**返回值**

`Path` — 上级目录；单部件相对路径与 `.` 为 `"."`，根为自身。

**例程**

```lisp
ycPathLib::Path("a/b/c")->parent()->str()  ; => "a/b"
ycPathLib::Path("a")->parent()->str()      ; => "."
ycPathLib::Path("/")->parent()->str()      ; => "/"
```

##### parents <sub>`method`</sub>

```text
p->parents()
=> list[Path]
```

**描述**

取自上级起直至根的全部祖先（不含自身）。

**参数**

无

**返回值**

`list[Path]` — 祖先 `Path` 列表；`.`、根为 `nil`。

**例程**

```lisp
ycPathLib::Path("a/b/c")->parents()  ; => ("a/b" "a" ".")
ycPathLib::Path("/a/b")->parents()   ; => ("/a" "/")
ycPathLib::Path("/")->parents()      ; => nil
```

##### isAbsolute <sub>`method`</sub>

```text
p->isAbsolute()
=> t | nil
```

**描述**

是否为绝对路径（锚非空）。

**参数**

无

**返回值**

`t | nil` — 绝对路径为 `t`，相对路径为 `nil`。

**例程**

```lisp
ycPathLib::Path("/a/b")->isAbsolute()  ; => t
ycPathLib::Path("a/b")->isAbsolute()   ; => nil
```

##### absolute <sub>`method`</sub>

```text
p->absolute()
=> Path
```

**描述**

相对路径基于 `getWorkingDir()` 拼接，不做规范化。

**参数**

无

**返回值**

`Path` — 已绝对时为自身，否则为当前工作目录与原路径的拼接结果。

**例程**

```lisp
ycPathLib::Path("/x/y")->absolute()->str()  ; => "/x/y"
ycPathLib::Path("a")->absolute()->str()     ; => $PWD/a
```

##### resolve <sub>`method`</sub>

```text
p->resolve()
=> Path
```

**描述**

`absolute()` 后经 `simplifyFilename` 词法规范化；**不**解析符号链接。

**参数**

无

**返回值**

`Path` — 规范化后的绝对路径，`.` 与 `..` 已折叠。

**例程**

```lisp
ycPathLib::Path("/a/b/../c")->resolve()->str()  ; => "/a/c"
ycPathLib::Path("/")->resolve()->str()          ; => "/"
```

##### join <sub>`method`</sub>

```text
p->join(
    g_args ...
)
=> Path
```

**描述**

将各段拼接为新路径；绝对片段重置此前拼接；`.` 片段丢弃；`..` 保留不折叠；库不提供 `/` 运算符。非 `str`/`Path` 片段以 `error()` 中断。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| g_args ... | str \| Path | 每段 |

**返回值**

`Path` — 由全部片段拼接出的新路径（原对象不变）。

**例程**

```lisp
ycPathLib::Path("/a")->join("b" "c")  ; => "/a/b/c"
ycPathLib::Path("a")->join("/b")      ; => "/b"
ycPathLib::Path("/a")->join("../b")   ; => "/a/../b"
ycPathLib::Path("a")->join(42)
; *Error* ycPathLib::Path->join: expected string or Path, got 42
```

##### relativeTo <sub>`method`</sub>

```text
p->relativeTo(g_other)
=> Path
```

**描述**

计算相对 `g_other` 的路径；前缀不匹配（含绝对/相对混用）以 `error()` 中断。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| g_other | str \| Path | 前缀路径 |

**返回值**

`Path` — 与前缀相等时为 `"."`，否则为去掉前缀后的相对路径。

**例程**

```lisp
ycPathLib::Path("/a/b/c")->relativeTo("/a")  ; => "b/c"
ycPathLib::Path("a/b")->relativeTo("a/b")    ; => "."
ycPathLib::Path("a/b")->relativeTo("a/c")
; *Error* ycPathLib::Path->relativeTo: 'a/b' is not in the subpath of 'a/c'
```

##### isRelativeTo <sub>`method`</sub>

```text
p->isRelativeTo(g_other)
=> t | nil
```

**描述**

`relativeTo` 的布尔版（不以 `error()` 中断；仅参数类型非法时以 `error()` 中断）。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| g_other | str \| Path | 前缀路径 |

**返回值**

`t | nil` — 前缀匹配为 `t`，不匹配为 `nil`。

**例程**

```lisp
ycPathLib::Path("a/b")->isRelativeTo("a")    ; => t
ycPathLib::Path("/a/b")->isRelativeTo("/b")  ; => nil
ycPathLib::Path("a")->isRelativeTo(42)
; *Error* ycPathLib::Path->isRelativeTo: expected string or Path, got 42
```

##### withName <sub>`method`</sub>

```text
p->withName(t_name)
=> Path
```

**描述**

替换最后一个部件。非法输入以 `error()` 中断：新名为空 / 含 `/` / 等于 `"."` → `Invalid name`；self 无名（`.`、`/`）→ `has an empty name`；`..` 可作为新名。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_name | str | 新的最后部件 |

**返回值**

`Path` — 用新名替换末部件后的新路径（原对象不变）。

**例程**

```lisp
ycPathLib::Path("a/b.txt")->withName("b.md")  ; => "a/b.md"
ycPathLib::Path("/a/b")->withName("x")        ; => "/a/x"
ycPathLib::Path("a/b")->withName("c/d")
; *Error* ycPathLib::Path->withName: Invalid name 'c/d'
```

##### withSuffix <sub>`method`</sub>

```text
p->withSuffix(t_suffix)
=> Path
```

**描述**

替换最后一个后缀；`""` 清除后缀；无后缀则追加。非法输入以 `error()` 中断：非空且不以 `.` 开头、等于 `"."`、含 `/` → `Invalid suffix`；self 无名（`.`、`/`）→ `has an empty name`。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_suffix | str | 新后缀（`.` 开头）或 `""` |

**返回值**

`Path` — 应用新后缀后的路径（原对象不变）。

**例程**

```lisp
ycPathLib::Path("a/b.txt")->withSuffix(".md")  ; => "a/b.md"
ycPathLib::Path("a.tar.gz")->withSuffix(".xz") ; => "a.tar.xz"
ycPathLib::Path("a/b")->withSuffix("")         ; => "a/b"
ycPathLib::Path("a/b.txt")->withSuffix("c")
; *Error* ycPathLib::Path->withSuffix: Invalid suffix 'c'
```

##### match <sub>`method`</sub>

```text
p->match(t_pattern)
=> t | nil
```

**描述**

按部件匹配：以 `/` 开头的 pattern 要求锚相等并按整路径部件比较（root-only 路径例外，`/` 可与 `**` 对齐）；否则右对齐到部件边界比较；支持 `*`、`?` 与字符类 `[seq]` / `[!seq]`（不跨部件）；大小写敏感；解析后无部件（如 `"."`、`""`）以 `error()` 中断，消息 `empty pattern`。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_pattern | str | 匹配模式 |

**返回值**

`t | nil` — 匹配为 `t`，不匹配为 `nil`。

**例程**

```lisp
ycPathLib::Path("a/b/c.txt")->match("*.txt")     ; => t
ycPathLib::Path("/a/b")->match("/?/b")           ; => t
ycPathLib::Path("hello.txt")->match("*.tx[yz]")  ; => nil
ycPathLib::Path("a/b")->match("**/b")           ; => t
ycPathLib::Path(".")->match(".")
; *Error* ycPathLib::Path->match: empty pattern
```

##### expandUser <sub>`method`</sub>

```text
p->expandUser()
=> Path
```

**描述**

`~` 开头才展开：`~other` 以 `error()` 中断；`HOME` 未设置或为空串以 `error()` 中断。

**参数**

无

**返回值**

`Path` — `~`、`~/...` 展开为 `HOME` 前缀，其余形式原样返回。

**例程**

```lisp
ycPathLib::Path("~")->expandUser()->str()    ; => $HOME
ycPathLib::Path("~/x")->expandUser()->str()  ; => $HOME/x
ycPathLib::Path("~other")->expandUser()
; *Error* ycPathLib::Path->expandUser: user home directories are not supported: '~other'
```

#### 文件系统

##### exists <sub>`method`</sub>

```text
p->exists()
=> t | nil
```

**描述**

目标是否存在（`isDir || isFile`，跟随符号链接）。

**参数**

无

**返回值**

`t | nil` — 存在为 `t`，不存在为 `nil`（broken symlink 视为不存在）。

**例程**

```lisp
p = ycPathLib::Path(".")
p->mkdir(?parents t)
p->exists()  ; => t
```

##### isDir <sub>`method`</sub>

```text
p->isDir()
=> t | nil
```

**描述**

是否为目录（跟随符号链接）。

**参数**

无

**返回值**

`t | nil` — 是目录为 `t`，否则为 `nil`（路径不存在同样为 `nil`）。

**例程**

```lisp
ycPathLib::Path(".")->isDir()  ; => t
```

##### isFile <sub>`method`</sub>

```text
p->isFile()
=> t | nil
```

**描述**

是否为普通文件（跟随符号链接）。

**参数**

无

**返回值**

`t | nil` — 是普通文件为 `t`，否则为 `nil`（路径不存在同样为 `nil`）。

**例程**

```lisp
ycPathLib::Path("./hello.txt")->isFile()  ; => t
```

##### isSymlink <sub>`method`</sub>

```text
p->isSymlink()
=> t | nil
```

**描述**

lstat 视角：判断符号链接本身（不跟随目标）。

**参数**

无

**返回值**

`t | nil` — 是符号链接为 `t`（含 broken symlink），否则为 `nil`。

**例程**

```lisp
ycPathLib::Path("./link.txt")->isSymlink()  ; => t
```

##### readable <sub>`method`</sub>

```text
p->readable()
=> t | nil
```

**描述**

判断当前用户是否可读该路径（跟随符号链接）。访问失败即返 `nil`（不预检、不报错），与 `os.access` 同构。

**参数**

无

**返回值**

`t | nil` — 可读为 `t`；路径不存在或不可读为 `nil`（不报错）。

**例程**

```lisp
p = ycPathLib::Path("./hello.txt")
p->readable()                               ; => t
ycPathLib::Path("no-such-entry")->readable() ; => nil（不报错，直接 nil）
```

##### writable <sub>`method`</sub>

```text
p->writable()
=> t | nil
```

**描述**

判断当前用户是否可写该路径（跟随符号链接）。

**参数**

无

**返回值**

`t | nil` — 可写为 `t`；路径不存在或不可写为 `nil`（不报错）。

**例程**

```lisp
ycPathLib::Path("./hello.txt")->writable()  ; => t
```

##### executable <sub>`method`</sub>

```text
p->executable()
=> t | nil
```

**描述**

判断当前用户是否可执行该路径（跟随符号链接）。目录的可执行位表示可穿越。

**参数**

无

**返回值**

`t | nil` — 可执行为 `t`；路径不存在或不可执行为 `nil`（不报错）。

**例程**

```lisp
ycPathLib::Path(".")->executable()               ; => t（目录）
ycPathLib::Path("./hello.txt")->executable()     ; => nil（文本文件无 x 位）
```

> 注意：三个谓词对不存在的路径**不报错**、直接返回 `nil`。

##### size <sub>`method`</sub>

```text
p->size()
=> int
```

**描述**

取文件字节数（跟随符号链接取目标值）。目标不存在（含 broken symlink）以 `error()` 中断。

**参数**

无

**返回值**

`int` — 文件大小（字节）；目录返回目录自身字节数。

**例程**

```lisp
p = ycPathLib::Path("./a.txt")
p->writeText("x")
p->size()    ; => 1
```

##### mtime <sub>`method`</sub>

```text
p->mtime()
=> int
```

**描述**

取文件最后修改时间（跟随符号链接取目标值）；目标不存在（含 broken symlink）以 `error()` 中断。转本地时间字符串：`timeToString(p->mtime())`（`timeToString`/`stringToTime` 家族按本地时间处理，非 GMT）。

**参数**

无

**返回值**

`int` — 修改时间的整数秒时间戳。

**例程**

```lisp
p = ycPathLib::Path("./a.txt")
p->mtime()               ; => 1791055804（示例值，随机器而异）
timeToString(p->mtime()) ; => 本地时间字符串
```

##### mkdir <sub>`method`</sub>

```text
p->mkdir(
    [ ?parents ]
    [ ?existOk ]
)
=> t
```

**描述**

创建目录。已存在目录 → 以 `error()` 中断（`?existOk t` 豁免）；已存在非目录条目不豁免；父目录缺失 → 以 `error()` 中断（`?parents t` 逐级创建）。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?parents | t \| nil | nil | 逐级创建父目录 |
| ?existOk | t \| nil | nil | 目录已存在时不以 `error()` 中断 |

**返回值**

`t` — 成功为 `t`。

**例程**

```lisp
p = ycPathLib::Path("./a/b/c")
p->mkdir(?parents t)  ; => t
p->mkdir()
; *Error* ycPathLib::Path->mkdir: file exists: ./a/b/c
p->mkdir(?existOk t)  ; => t
```

##### rmdir <sub>`method`</sub>

```text
p->rmdir()
=> t
```

**描述**

删除空目录。非目录 / 非空 / 不存在均以 `error()` 中断。

**参数**

无

**返回值**

`t` — 删除成功为 `t`。

**例程**

```lisp
p = ycPathLib::Path("./e")
p->mkdir(?parents t)  ; => t
p->rmdir()            ; => t
```

##### unlink <sub>`method`</sub>

```text
p->unlink(
    [ ?missingOk ]
)
=> t
```

**描述**

删除文件。不存在 → 以 `error()` 中断，`?missingOk t` 静默；目标为目录 → 以 `error()` 中断（不提供递归删除）。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?missingOk | t \| nil | nil | 目标不存在时不以 `error()` 中断 |

**返回值**

`t` — 成功删除为 `t`。

**例程**

```lisp
ycPathLib::Path("./a.txt")->unlink()  ; => t
```

##### rename <sub>`method`</sub>

```text
p->rename(g_target)
=> Path
```

**描述**

重命名/移动（POSIX `mv` 覆盖语义）。以 `error()` 中断的情形：`g_target` 非 `str`/`Path`、源不存在、目标为已存在目录、`mv` 后源仍存在或目标缺失。源与目标解析后相同则不做操作。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| g_target | str \| Path | 目标路径 |

**返回值**

`Path` — 目标路径 `g_target` 对应的新路径对象。

**例程**

```lisp
p = ycPathLib::Path("./src.txt")
p->writeText("x")
p->rename("./dst.txt")  ; => "./dst.txt"
```

##### touch <sub>`method`</sub>

```text
p->touch()
=> t
```

**描述**

文件不存在则创建；已存在不截断内容并更新修改时间（mtime）；目标为目录以 `error()` 中断。

**参数**

无

**返回值**

`t` — 操作成功为 `t`。

**例程**

```lisp
p = ycPathLib::Path("./new.txt")
p->touch()  ; => t
```

##### open <sub>`method`</sub>

```text
p->open(
    [ ?mode ]
)
=> port
```

**描述**

打开文件；模式 `"r"`（默认）/ `"w"` / `"a"`；其他模式、`"r"` 下目标为目录或文件不存在均以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?mode | str | `"r"` | `"r"` / `"w"` / `"a"` |

**返回值**

`port` — 打开的 file port。

**例程**

```lisp
p = ycPathLib::Path("./a.txt")
p->writeText("x")
g_port = p->open()               ; => port
g_port = p->open(?mode "w")      ; => port
p->open(?mode "b")
; *Error* ycPathLib::Path->open: invalid mode: 'b'
```

##### readText <sub>`method`</sub>

```text
p->readText()
=> str
```

**描述**

读取整个文件内容；文件不存在 / 为目录以 `error()` 中断。

**参数**

无

**返回值**

`str` — 文件全文（保留换行）。

**例程**

```lisp
p = ycPathLib::Path("./a.txt")
p->writeText("hi\n")
p->readText()  ; => "hi\n"
```

##### writeText <sub>`method`</sub>

```text
p->writeText(
    t_text
)
=> t
```

**描述**

写入字符串（覆盖已有内容）。父目录缺失以 `error()` 中断。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_text | str | 写入内容 |

**返回值**

`t` — 写入完成为 `t`。

**例程**

```lisp
p = ycPathLib::Path("./a.txt")
p->writeText("hi\n")  ; => t
```

##### load <sub>`method`</sub>

```text
p->load([g_password])
=> t
```

**描述**

预检后执行该路径的 SKILL 文件（原生 `load`）。文件内的运行期错误照原生 `load` 外传。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_password | str \| nil | nil | 加密文件密码；`nil` 表示无密码 |

**返回值**

`t` — 成功返回 t；路径为目录、文件缺失、密码非字符串时走 `*Error*`。

**例程**

```lisp
p = ycPathLib::Path("./script.il")
p->load()            ; 加载脚本
p->load("secret")    ; 传入密码串
```

##### loadi <sub>`method`</sub>

```text
p->loadi([g_password])
=> t
```

**描述**

预检后执行该路径的 SKILL 文件（原生 `loadi`）。与 `load` 的差别仅在**文件内运行期错误**：`loadi` 打印 `*Error*` 后照常返回，`load` 则外传。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_password | str \| nil | nil | 加密文件密码；`nil` 表示无密码 |

**返回值**

`t` — 成功返回 t；路径为目录、文件缺失、密码非字符串时走 `*Error*`。

**例程**

```lisp
ycPathLib::Path("./bad.il")->loadi()  ; 示意：文件内报错时打印后照常返回，不中断调用方
```

##### iterdir <sub>`method`</sub>

```text
p->iterdir()
=> list[Path] | nil
```

**描述**

列举直接子项（不含 `.`/`..`，包含点开头名与子目录）。非目录以 `error()` 中断；顺序未定义，比较请按集合。

**参数**

无

**返回值**

`list[Path] | nil` — 子项的 `Path` 列表；空目录为 `nil`。

**例程**

```lisp
ycPathLib::Path(".")->iterdir()  ; => (...)
```

#### glob 与 rglob

##### glob <sub>`method`</sub>

```text
p->glob(t_pattern)
=> list[Path] | nil
```

**描述**

按 pattern 匹配直接/递归后代。

+ 模式按 `/` 分段，每段 fnmatch（`*` `?`、字符类 `[seq]`/`[!seq]`，不跨部件）。
+ `**` 段匹配零级或多级目录；非整段 `**`（如 `a**b`、`**txt`）按单个 `*` 处理；递归不跟随目录符号链接；终端 `**` 产出自身与全部条目（文件、目录、链接目录条目——链接目录只产出不进入）。
+ 点开头的隐藏名与普通名同等待遇：`*`、`**` 均可匹配、可进入。
+ 尾部 `/` 要求匹配项为目录；`..` 段按字面拼接（`p->glob("..")` 产出 `dir/..`）。
+ 绝对 pattern → 以 `error()` 中断，消息 `Non-relative patterns are unsupported`；解析后无有效段（如空、`.`、`./`）→ 以 `error()` 中断，消息 `Unacceptable pattern: ...`。
+ 结果按字符串去重；顺序未定义（确定性但非 readdir 序），比较请按集合。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_pattern | str | 相对 pattern |

**返回值**

`list[Path] | nil` — 匹配的 `Path` 列表；起点非目录或无匹配为 `nil`。

**例程**

```lisp
ycPathLib::Path("src")->glob("**/*.il")  ; => (...)
ycPathLib::Path("src")->glob("*.txt")    ; => nil
```

##### rglob <sub>`method`</sub>

```text
p->rglob(t_pattern)
=> list[Path] | nil
```

**描述**

递归版本，语义同 `glob`（规则见上）。等价于 `glob("**/" + t_pattern)`；例外：`rglob("")` 不以 `error()` 中断，等价 `glob("**/")`。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_pattern | str | 相对 pattern（可为空） |

**返回值**

`list[Path] | nil` — 递归匹配的 `Path` 列表；无匹配为 `nil`。

**例程**

```lisp
ycPathLib::Path("src")->rglob("*.il")  ; => (...)
```

#### 方法链

**描述**

返回 `Path` 的方法均可继续链式调用：

**例程**

```lisp
ycPathLib::Path("a")->join("b")->withSuffix(".md")->str()  ; => "a/b.md"
```

### ycPathLib::cwd <sub>`function`</sub>

```text
ycPathLib::cwd()
=> Path
```

**描述**

取当前工作目录（基于 `getWorkingDir()`）。

**参数**

无

**返回值**

`Path` — 工作目录的路径对象。

**例程**

```lisp
ycPathLib::cwd()->str()  ; => $PWD
```

### ycPathLib::home <sub>`function`</sub>

```text
ycPathLib::home()
=> Path
```

**描述**

取 `HOME` 环境变量对应的路径；未设置或为空串时以 `error()` 中断。

**参数**

无

**返回值**

`Path` — `HOME` 变量对应的路径。

**例程**

```lisp
ycPathLib::home()->str()  ; => $HOME
```

### ycPathLib::currentFile <sub>`function`</sub>

```text
ycPathLib::currentFile()
=> Path
```

**描述**

仅在文件加载期间的顶层调用有效；在 CIW 直接调用或加载完成后调用会以 `error()` 中断，不会返回错误值。建议在文件顶部取一次存入变量：

**参数**

无

**返回值**

`Path` — 当前正在加载的文件路径。

**例程**

```lisp
here = ycPathLib::currentFile()->parent()
```

> 注：`get_filename` 在文件最后一个表达式处取值存在已知异常，避免在文件末行调用本函数。
