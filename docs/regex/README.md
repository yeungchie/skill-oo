# ycRegEx

[返回首页](../../README.md)

Cadence SKILL++ 的正则表达式库：模块级自由函数与 `Compile()` 编译对象双套 API，提供 `Pattern`/`Matched` 两类对象，零第三方依赖。

## 概要

- 正则引擎按字节工作：匹配位置、`.` 与字符类均按字节计，字面量按字节等值匹配。
- 未提供的能力（按名取组、`groupdict()`、位置方法的组号参数等）在调用时以 `error()` 中断，API 参考各条目中逐一注明。
- 捕获组数不设上限。普通匹配、非空 `finditer`/`findall` 与可批量导出的零宽匹配不受 65535 字节偏移限制；复杂数字组引用（含字符类/`\g`/`\k`）或混合非空零宽模式无法安全批量，回退扫描仍以 65535 字节为上限。
- 模板（`t_repl`/`expand`）按引擎方言展开：`\1`~`\9` 反向引用；`&`/`\0` 整体匹配；带编译对象时 `\{n}` 引用任意组，第 10 组以上必须用此形式；`\n` 是字面 `n`，换行请写真实换行字符；其他形式按字面处理。
- flags 以关键字 `?flags` 传入（符号或字符串，如 `'I` 或 `"imsx"`）；`Split` 默认切分全部、`?first t` 只切首处；`Sub`/`Subn` 默认替换首处、`?all t` 替换全部。详见「flags 参数」。
- 各自由函数的 `g_pat` 可传模式串或已编译 `Pattern`；传 `Pattern` 时直接复用、不重编译（与 `?flags` 同用会以 `error()` 中断）。
- pattern 与模板中的反斜杠在 SKILL 源字符串中写作两字符（如 `"\\d+"`、`"\\1"`）。

## 快速上手

```lisp
; 搜索 + 提取
let((m)
    m = ycRegEx::Search("(\\d+)-(\\d+)" "inv 10-20 ok")
    when(m
        printf("%s span=%L groups=%L\n" m->group() m->span() m->groups())
        ; => "10-20" span=(4 9) groups=("10" "20")
    )
)

; 编译复用：一次编译、多次调用
let((p)
    p = ycRegEx::Compile("\\d+")
    printf("%L\n" p->findall("a1b22"))        ; => ("1" "22")
    printf("%s\n" p->sub("#" "a1b2" ?all t))  ; => "a#b#"
)
```

## API 参考

### ycRegEx::Compile <sub>`function`</sub>

```text
ycRegEx::Compile(
    g_pat
    [ ?flags g_flags ]
    [ ?compileOpts g_compileOpts ]
)
=> Pattern
```

**描述**

编译 pattern，返回可复用的 `Pattern`。`g_pat` 可为模式串或已编译 `Pattern`——传 `Pattern` 时直接复用、不重编译，此时不能带 `?flags` 或 `?compileOpts`。pattern 语法错误或参数类型不符时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_pat | str / Pattern |  | 模式串或已编译 Pattern（复用不重编译） |
| ?flags g_flags | sym / str / nil | nil | 修饰标志 `'I 'M 'S 'X`（大小写皆可）；详见 [flags 参数](#flags-参数) |
| ?compileOpts g_compileOpts | sym / list / nil | nil | 编译选项符号或列表；详见 [编译选项](#编译选项) |

**返回值**

`Pattern` — 编译后的 `Pattern` 对象。

**例程**

```lisp
p = ycRegEx::Compile("\\d+")  ; => Pattern
ycRegEx::Compile("ABC" ?compileOpts 'caseLess)->match("abc")  ; => Matched
ycRegEx::Compile("(")         ; => 以 error() 中断（语法错误）
```

### ycRegEx::Match <sub>`function`</sub>

```text
ycRegEx::Match(
    g_pat
    t_subj
    [ ?flags g_flags ]
    [ ?execOpts g_execOpts ]
)
=> Matched | nil
```

**描述**

仅在 `t_subj` 起始处匹配（等价前锚 `\A`）；pattern 语法错误或参数类型不符时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_pat | str / Pattern |  | 模式串或已编译 Pattern（复用不重编译） |
| t_subj | str |  | 被处理字符串 |
| ?flags g_flags | sym / str / nil | nil | 修饰标志 `'I 'M 'S 'X`（大小写皆可）；详见 [flags 参数](#flags-参数) |
| ?execOpts g_execOpts | sym / list / nil | nil | 执行选项符号或列表；详见 [执行选项](#执行选项) |

**返回值**

`Matched | nil` — 命中为 `Matched`，未命中为 `nil`。

**例程**

```lisp
ycRegEx::Match("\\d+" "123a")  ; => Matched，span (0 3)
ycRegEx::Match("\\d+" "a123")  ; => nil
```

### ycRegEx::Search <sub>`function`</sub>

```text
ycRegEx::Search(
    g_pat
    t_subj
    [ ?flags g_flags ]
    [ ?execOpts g_execOpts ]
)
=> Matched | nil
```

**描述**

从左向右搜索首个匹配；pattern 语法错误或参数类型不符时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_pat | str / Pattern |  | 模式串或已编译 Pattern（复用不重编译） |
| t_subj | str |  | 被处理字符串 |
| ?flags g_flags | sym / str / nil | nil | 修饰标志 `'I 'M 'S 'X`（大小写皆可）；详见 [flags 参数](#flags-参数) |
| ?execOpts g_execOpts | sym / list / nil | nil | 执行选项符号或列表；详见 [执行选项](#执行选项) |

**返回值**

`Matched | nil` — 命中为 `Matched`，未命中为 `nil`。

**例程**

```lisp
m = ycRegEx::Search("(\\d+)-(\\d+)" "a10-20b")
m->span()              ; => (1 6)，字节位
m->group()             ; => "10-20"
m->groups()            ; => ("10" "20")
```

### ycRegEx::Fullmatch <sub>`function`</sub>

```text
ycRegEx::Fullmatch(
    g_pat
    t_subj
    [ ?flags g_flags ]
    [ ?execOpts g_execOpts ]
)
=> Matched | nil
```

**描述**

要求匹配覆盖整个 `t_subj`（实现为 `\A(?:…)\z`）；pattern 语法错误或参数类型不符时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_pat | str / Pattern |  | 模式串或已编译 Pattern（复用不重编译） |
| t_subj | str |  | 被处理字符串 |
| ?flags g_flags | sym / str / nil | nil | 修饰标志 `'I 'M 'S 'X`（大小写皆可）；详见 [flags 参数](#flags-参数) |
| ?execOpts g_execOpts | sym / list / nil | nil | 执行选项符号或列表；详见 [执行选项](#执行选项) |

**返回值**

`Matched | nil` — 命中为 `Matched`，未命中为 `nil`。

**例程**

```lisp
ycRegEx::Fullmatch("a|ab" "ab")   ; => Matched，span (0 2)
ycRegEx::Fullmatch("\\d+" "123a") ; => nil
```

### ycRegEx::Findall <sub>`function`</sub>

```text
ycRegEx::Findall(
    g_pat
    t_subj
    [ ?flags g_flags ]
    [ ?execOpts g_execOpts ]
)
=> list
```

**描述**

查找全部匹配，返回形态由捕获组数决定（见返回值）。pattern 语法错误或参数类型不符时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_pat | str / Pattern |  | 模式串或已编译 Pattern（复用不重编译） |
| t_subj | str |  | 被处理字符串 |
| ?flags g_flags | sym / str / nil | nil | 修饰标志 `'I 'M 'S 'X`（大小写皆可）；详见 [flags 参数](#flags-参数) |
| ?execOpts g_execOpts | sym / list / nil | nil | 执行选项符号或列表；详见 [执行选项](#执行选项) |

**返回值**

`list` — 全部匹配结果：零组为整体字符串列表，一组为扁平组值列表，两组及以上每匹配一个子列表；未命中为空列表。

**例程**

```lisp
ycRegEx::Findall("\\d+" "a1b22")  ; => ("1" "22")
ycRegEx::Findall("(a)|(b)" "ab")  ; => (("a" "") ("" "b"))
```

### ycRegEx::Finditer <sub>`function`</sub>

```text
ycRegEx::Finditer(
    g_pat
    t_subj
    [ ?flags g_flags ]
    [ ?execOpts g_execOpts ]
)
=> list[Matched]
```

**描述**

从左向右返回全部匹配；零宽命中按 `start + 1` 推进。pattern 语法错误或参数类型不符时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_pat | str / Pattern |  | 模式串或已编译 Pattern（复用不重编译） |
| t_subj | str |  | 被处理字符串 |
| ?flags g_flags | sym / str / nil | nil | 修饰标志 `'I 'M 'S 'X`（大小写皆可）；详见 [flags 参数](#flags-参数) |
| ?execOpts g_execOpts | sym / list / nil | nil | 执行选项符号或列表；详见 [执行选项](#执行选项) |

**返回值**

`list[Matched]` — 全部匹配的 `Matched` 列表；未命中为空列表。

**例程**

```lisp
length(ycRegEx::Finditer("\\d+" "a1b22"))  ; => 2
```

### ycRegEx::Partialp <sub>`function`</sub>

```text
ycRegEx::Partialp(
    g_pat
    t_subj
    [ ?flags g_flags ]
    [ ?execOpts g_execOpts ]
)
=> t | nil
```

**描述**

判断主题串是否为该模式的部分匹配或完整匹配：主题串是模式前缀时可完成匹配，或已完整匹配，均返回 `t`。用于流式输入/截断文本的探测，不返回 `Matched`。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_pat | str / Pattern |  | 模式串或已编译 Pattern（复用不重编译） |
| t_subj | str |  | 被处理字符串 |
| ?flags g_flags | sym / str / nil | nil | 修饰标志 `'I 'M 'S 'X`（大小写皆可）；详见 [flags 参数](#flags-参数) |
| ?execOpts g_execOpts | sym / list / nil | nil | 执行选项符号或列表；详见 [执行选项](#执行选项) |

**返回值**

`t | nil` — 可完成匹配（含完整匹配）为 `t`，否则为 `nil`。

**例程**

```lisp
ycRegEx::Partialp("ab" "a")   ; => t
ycRegEx::Partialp("ab" "ab")  ; => t
ycRegEx::Partialp("ab" "ac")  ; => nil
```

### ycRegEx::Split <sub>`function`</sub>

```text
ycRegEx::Split(
    g_pat
    t_subj
    [ ?flags g_flags ]
    [ ?first g_first ]
    [ ?execOpts g_execOpts ]
)
=> list[str]
```

**描述**

按 pattern 切分 `t_subj`；默认切分全部匹配，`?first t` 只切首处；零宽 pattern 受引擎限制，仅处理首个空匹配。pattern 语法错误或参数类型不符时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_pat | str / Pattern |  | 模式串或已编译 Pattern（复用不重编译） |
| t_subj | str |  | 被处理字符串 |
| ?flags g_flags | sym / str / nil | nil | 修饰标志 `'I 'M 'S 'X`（大小写皆可）；详见 [flags 参数](#flags-参数) |
| ?first g_first | t / nil | nil | t 时只切首处，否则切分全部 |
| ?execOpts g_execOpts | sym / list / nil | nil | 执行选项符号或列表；详见 [执行选项](#执行选项) |

**返回值**

`list[str]` — 切分段列表，捕获组段保留；未命中时为原串单元素列表 `(t_subj)`。

**例程**

```lisp
ycRegEx::Split("," "a,b,c")             ; => ("a" "b" "c")（默认全部）
ycRegEx::Split("," "a,b,c" ?first t)    ; => ("a" "b,c")
ycRegEx::Split("(\\d)" "a1b2c")        ; => ("a" "1" "b" "2" "c")
```

### ycRegEx::Sub <sub>`function`</sub>

```text
ycRegEx::Sub(
    g_pat
    t_repl
    t_subj
    [ ?flags g_flags ]
    [ ?all g_all ]
    [ ?execOpts g_execOpts ]
)
=> str
```

**描述**

将匹配替换为 `t_repl` 展开串。模板按引擎方言展开 `\1`~`\9`、`&`、`\0`，带编译对象时可用 `\{n}` 引用任意组；`\n` 是字面 `n`，换行请写真实换行字符。默认只替换首处匹配，`?all t` 替换全部；零宽匹配在全部模式下亦仅替换首处一次。pattern 语法错误或参数类型不符时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_pat | str / Pattern |  | 模式串或已编译 Pattern（复用不重编译） |
| t_repl | str |  | 替换模板 |
| t_subj | str |  | 被处理字符串 |
| ?flags g_flags | sym / str / nil | nil | 修饰标志 `'I 'M 'S 'X`（大小写皆可）；详见 [flags 参数](#flags-参数) |
| ?all g_all | t / nil | nil | t 时处理全部匹配，否则只处理首处 |
| ?execOpts g_execOpts | sym / list / nil | nil | 执行选项符号或列表；详见 [执行选项](#执行选项) |

**返回值**

`str` — 替换后的串；未命中时为原串。

**例程**

```lisp
ycRegEx::Sub("\\d+" "#" "a1b22" ?all t) ; => "a#b#"
ycRegEx::Sub("\\d" "#" "a1b2")          ; => "a#b2"（默认单次）
ycRegEx::Sub("x*" "-" "abc")            ; => "-abc"（零宽仅首处）
```

### ycRegEx::Subn <sub>`function`</sub>

```text
ycRegEx::Subn(
    g_pat
    t_repl
    t_subj
    [ ?flags g_flags ]
    [ ?all g_all ]
    [ ?execOpts g_execOpts ]
)
=> (str, int)
```

**描述**

语义同 `Sub`。内部计数经 `<YC-N>` 标记实现；`t_subj`/`t_repl` 或组值中若含 `<YC-N>` 会被误剥离或误切。`Split` 的 `<YC-S>`、`Search`/`Match` 组提取的 `<YC-B>` 同理会与输入冲突。pattern 语法错误或参数类型不符时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_pat | str / Pattern |  | 模式串或已编译 Pattern（复用不重编译） |
| t_repl | str |  | 替换模板 |
| t_subj | str |  | 被处理字符串 |
| ?flags g_flags | sym / str / nil | nil | 修饰标志 `'I 'M 'S 'X`（大小写皆可）；详见 [flags 参数](#flags-参数) |
| ?all g_all | t / nil | nil | t 时处理全部匹配，否则只处理首处 |
| ?execOpts g_execOpts | sym / list / nil | nil | 执行选项符号或列表；详见 [执行选项](#执行选项) |

**返回值**

`(str, int)` — `(替换后的串 实际替换次数)`；未命中时为 `(原串 0)`。

**例程**

```lisp
ycRegEx::Subn("\\d" "#" "a1b2" ?all t)  ; => ("a#b#" 2)
```

### ycRegEx::GetRecursionLimit <sub>`function`</sub>

```text
ycRegEx::GetRecursionLimit()
=> int
```

**描述**

返回正则匹配引擎当前的最大递归深度（进程级设置），默认 `10000000`。修改后影响后续所有匹配。

**参数**

无

**返回值**

`int` — 当前最大递归深度。

**例程**

```lisp
ycRegEx::GetRecursionLimit()  ; => 10000000
```

### ycRegEx::SetRecursionLimit <sub>`function`</sub>

```text
ycRegEx::SetRecursionLimit(n_limit)
=> t
```

**描述**

设置正则匹配引擎的最大递归深度（进程级设置）。非整数参数以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| n_limit | int |  | 最大递归深度 |

**返回值**

`t` — 设置成功。

**例程**

```lisp
ycRegEx::SetRecursionLimit(1000)  ; => t
ycRegEx::GetRecursionLimit()      ; => 1000
ycRegEx::SetRecursionLimit(10000000)  ; => t（恢复默认）
```

### ycRegEx::Pattern <sub>`class`</sub>

**描述**

`Compile()` 的返回类型。方法与其对应的自由函数（如 `ycRegEx::Match` 与 `Pattern->match`）语义相同；已是编译对象，免重复编译；编译期修饰（`i/m/s/x`）在 `Compile` 时定死，方法不再提供 `?flags`；`split` 提供 `?first`，`sub`/`subn` 提供 `?all`。方法一律经 `->` 调用；`sub`/`subn` 首参为 `t_repl`，其余方法首参为 `t_subj`。

#### 搜索与匹配

##### match <sub>`method`</sub>

```text
p->match(
    t_subj
    [ ?execOpts g_execOpts ]
)
=> Matched | nil
```

**描述**

仅在 `t_subj` 起始处匹配。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_subj | str | 被处理字符串 |
| ?execOpts g_execOpts | sym / list / nil | 执行选项符号或列表；详见 [执行选项](#执行选项) |

**返回值**

`Matched | nil` — 命中为 `Matched`，未命中为 `nil`。

**例程**

```lisp
p = ycRegEx::Compile("\\d+")
p->match("123a")  ; => Matched
p->match("a123")  ; => nil
```

##### search <sub>`method`</sub>

```text
p->search(
    t_subj
    [ ?execOpts g_execOpts ]
)
=> Matched | nil
```

**描述**

从左向右搜索首个匹配。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_subj | str | 被处理字符串 |
| ?execOpts g_execOpts | sym / list / nil | 执行选项符号或列表；详见 [执行选项](#执行选项) |

**返回值**

`Matched | nil` — 命中为 `Matched`，未命中为 `nil`。

**例程**

```lisp
p = ycRegEx::Compile("\\d+")
p->search("a123")  ; => Matched
```

##### fullmatch <sub>`method`</sub>

```text
p->fullmatch(
    t_subj
    [ ?execOpts g_execOpts ]
)
=> Matched | nil
```

**描述**

要求匹配覆盖整个 `t_subj`。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_subj | str | 被处理字符串 |
| ?execOpts g_execOpts | sym / list / nil | 执行选项符号或列表；详见 [执行选项](#执行选项) |

**返回值**

`Matched | nil` — 命中为 `Matched`，未命中为 `nil`。

**例程**

```lisp
p = ycRegEx::Compile("\\d+")
p->fullmatch("123")   ; => Matched
p->fullmatch("123a")  ; => nil
```

##### partialp <sub>`method`</sub>

```text
p->partialp(
    t_subj
    [ ?execOpts g_execOpts ]
)
=> t | nil
```

**描述**

判断 `t_subj` 是否为该模式的部分匹配或完整匹配；语义同 `Partialp`，不产生 `Matched`。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_subj | str | 被处理字符串 |
| ?execOpts g_execOpts | sym / list / nil | 执行选项符号或列表；详见 [执行选项](#执行选项) |

**返回值**

`t | nil` — 主题串可完成该模式（含完整匹配）为 `t`，否则为 `nil`。

**例程**

```lisp
ycRegEx::Compile("ab")->partialp("a")   ; => t
ycRegEx::Compile("ab")->partialp("ac")  ; => nil
```

#### 查找全部

##### findall <sub>`method`</sub>

```text
p->findall(
    t_subj
    [ ?execOpts g_execOpts ]
)
=> list
```

**描述**

语义与返回形态同自由函数 `Findall`；已编译。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_subj | str | 被处理字符串 |
| ?execOpts g_execOpts | sym / list / nil | 执行选项符号或列表；详见 [执行选项](#执行选项) |

**返回值**

`list` — 同自由函数 `Findall`。

**例程**

```lisp
p = ycRegEx::Compile("\\d+")
p->findall("a1b22")  ; => ("1" "22")
```

##### finditer <sub>`method`</sub>

```text
p->finditer(
    t_subj
    [ ?execOpts g_execOpts ]
)
=> list[Matched]
```

**描述**

语义同自由函数 `Finditer`；已编译。零宽命中按 `start + 1` 推进。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_subj | str | 被处理字符串 |
| ?execOpts g_execOpts | sym / list / nil | 执行选项符号或列表；详见 [执行选项](#执行选项) |

**返回值**

`list[Matched]` — 同自由函数 `Finditer`。

**例程**

```lisp
p = ycRegEx::Compile("\\d+")
length(p->finditer("a1b22"))  ; => 2
```

##### split <sub>`method`</sub>

```text
p->split(
    t_subj
    [ ?first g_first ]
    [ ?execOpts g_execOpts ]
)
=> list[str]
```

**描述**

按 pattern 切分 `t_subj`。默认切分全部匹配，`?first t` 只切首处；零宽 pattern 受引擎限制，仅处理首个空匹配。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_subj | str |  | 被处理字符串 |
| ?first g_first | t / nil | nil | t 时只切首处，否则切分全部 |
| ?execOpts g_execOpts | sym / list / nil | nil | 执行选项符号或列表；详见 [执行选项](#执行选项) |

**返回值**

`list[str]` — 切分段列表，捕获组段保留；未命中时为原串单元素列表 `(t_subj)`。

**例程**

```lisp
p = ycRegEx::Compile(",")
p->split("a,b,c")          ; => ("a" "b" "c")（默认全部）
p->split("a,b,c" ?first t) ; => ("a" "b,c")
```

#### 替换

##### sub <sub>`method`</sub>

```text
p->sub(
    t_repl
    t_subj
    [ ?all g_all ]
    [ ?execOpts g_execOpts ]
)
=> str
```

**描述**

将匹配替换为 `t_repl` 展开串；模板方言、零宽替换行为与 `?all` 语义同 `Sub`。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_repl | str |  | 替换模板 |
| t_subj | str |  | 被处理字符串 |
| ?all g_all | t / nil | nil | t 时处理全部匹配，否则只处理首处 |
| ?execOpts g_execOpts | sym / list / nil | nil | 执行选项符号或列表；详见 [执行选项](#执行选项) |

**返回值**

`str` — 替换后的串；未命中时为原串。

**例程**

```lisp
p = ycRegEx::Compile("\\d+")
p->sub("#" "a1b2")        ; => "a#b2"（默认单次）
p->sub("#" "a1b2" ?all t) ; => "a#b#"
```

##### subn <sub>`method`</sub>

```text
p->subn(
    t_repl
    t_subj
    [ ?all g_all ]
    [ ?execOpts g_execOpts ]
)
=> (str, int)
```

**描述**

语义同 `sub`；定界标记限制同 `Subn`。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_repl | str |  | 替换模板 |
| t_subj | str |  | 被处理字符串 |
| ?all g_all | t / nil | nil | t 时处理全部匹配，否则只处理首处 |
| ?execOpts g_execOpts | sym / list / nil | nil | 执行选项符号或列表；详见 [执行选项](#执行选项) |

**返回值**

`(str, int)` — `(替换后的串 实际替换次数)`；未命中时为 `(原串 0)`。

**例程**

```lisp
p = ycRegEx::Compile("\\d")
p->subn("#" "a1b2")        ; => ("a#b2" 1)（默认单次）
p->subn("#" "a1b2" ?all t) ; => ("a#b#" 2)
```

#### 元信息

##### groups <sub>`method`</sub>

```text
p->groups()
=> int
```

**描述**

捕获组数；不设上限。

**参数**

无

**返回值**

`int` — 捕获组数。

**例程**

```lisp
ycRegEx::Compile("(\\d+)-(\\d+)")->groups()  ; => 2
```

##### pattern <sub>`method`</sub>

```text
p->pattern()
=> str
```

**描述**

编译时的原 pattern 字符串。

**参数**

无

**返回值**

`str` — 原 pattern 串，与 `Compile` 入参一致。

**例程**

```lisp
ycRegEx::Compile("\\d+")->pattern()  ; => "\\d+"
```

### ycRegEx::Matched <sub>`class`</sub>

**描述**

匹配命中后返回的对象；`span`/`start`/`end` 返回字节位。方法一律经 `->` 调用。

#### 取组

##### group <sub>`method`</sub>

```text
m->group()
m->group([ n_index ... ])
=> str | list[str]
```

**描述**

取指定捕获组的值；按名取组与组号越界以 `error()` 中断。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| n_index ... | int | 组号，可省略 |

**返回值**

`str | list[str]` — 无参为整体匹配串，单组号为该组串，多组号为组值列表（`0` 可混入）；未参与的组为 `""`。

**例程**

```lisp
m = ycRegEx::Search("(\\d+)-(\\d+)" "a10-20b")
m->group()       ; => "10-20"
m->group(1)      ; => "10"
m->group(1 2)    ; => ("10" "20")
m->group("x")    ; => 以 error() 中断（按名取组不提供）
m->groupdict()   ; => 以 error() 中断（预留不提供）
```

##### groupdict <sub>`method`</sub>

```text
m->groupdict()
=> never
```

**描述**

预留的命名组字典接口，当前不提供；调用即以 `error()` 中断。

**参数**

无

**返回值**

`never` — 不会正常返回，始终以 `error()` 中断。

**例程**

```lisp
ycRegEx::Search("(?<year>\\d+)", "2026")->groupdict()
; *Error* ycRegEx::Matched->groupdict: not supported yet (reserved)
```

##### groups <sub>`method`</sub>

```text
m->groups([ ?empty g_empty ])
=> list
```

**描述**

一次取回全部组值，并把所有空字符串结果替换为 `?empty` 的实参。该替换作用于空结果，既包括未参与匹配的组，也包括真正匹配到空串的组；默认 `""`，因此省略参数时保持原有结果。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?empty g_empty | any | `""` | 空结果替换值 |

**返回值**

`list` — 组值列表，空字符串替换为 `?empty`；零捕获组时为 `nil`；返回副本，修改不影响 `Matched`。

**例程**

```lisp
m = ycRegEx::Search("(a)|(b)" "b")
m->groups()              ; => ("" "b")
m->groups(?empty "NA")   ; => ("NA" "b")
m->groups(?empty nil)    ; => (nil "b")
```

#### 位置

##### span <sub>`method`</sub>

```text
m->span()
=> (int, int)
```

**描述**

取匹配的起止位置（字节位）。`search` 路径在返回 `Matched` 时即完成位置定位，`span`/`start`/`end` 直接读取。组号参数不提供，以 `error()` 中断。

**参数**

无

**返回值**

`(int, int)` — `(start end)` 字节位，左闭右开。

**例程**

```lisp
m = ycRegEx::Search("(\\d+)-(\\d+)" "a10-20b")
m->span()        ; => (1 6)
```

##### start <sub>`method`</sub>

```text
m->start()
=> int
```

**描述**

取匹配的起始位置；组号参数不提供，以 `error()` 中断。

**参数**

无

**返回值**

`int` — 匹配起始字节位。

**例程**

```lisp
m = ycRegEx::Search("(\\d+)-(\\d+)" "a10-20b")
m->start()       ; => 1
```

##### end <sub>`method`</sub>

```text
m->end()
=> int
```

**描述**

取匹配的结束位置；组号参数不提供，以 `error()` 中断。

**参数**

无

**返回值**

`int` — 匹配结束字节位，不含。

**例程**

```lisp
m = ycRegEx::Search("(\\d+)-(\\d+)" "a10-20b")
m->end()         ; => 6
```

#### 模板与显示

##### expand <sub>`method`</sub>

```text
m->expand(t_tpl)
=> str
```

**描述**

按引擎方言将模板中的 `\1`~`\9`、`&`、`\0` 展开为对应匹配内容，带编译对象时可用 `\{n}` 引用任意组；`\n` 是字面 `n`，换行请写真实换行字符；未引用部分按字面保留。参数类型不符、状态重挂失败或模板非法时以 `error()` 中断。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_tpl | str | 模板串 |

**返回值**

`str` — 模板展开后的串。

**例程**

```lisp
m = ycRegEx::Search("(\\d+)-(\\d+)" "a10-20b")
m->expand("\\2-\\1")  ; => "20-10"
```

## flags 参数

`?flags`、`Split` 的 `?first` 与 `Sub`/`Subn` 的 `?all` 为关键字参数（默认 `nil`）。

`?flags` 指定修饰标志，接受符号或字符串（大小写皆可，`?flags 'I` 与 `?flags "i"` 等效），内部逐字符解析：

| 字符 | 修饰 | 语义 |
| --- | --- | --- |
| `i` | `(?i)` | 大小写不敏感匹配 |
| `m` | `(?m)` | 多行：`^`/`$` 匹配每行首尾 |
| `s` | `(?s)` | 点通配换行：`.` 亦匹配 `\n` |
| `x` | `(?x)` | 详式：pattern 中空白不参与匹配 |

- 可组合：`?flags "im"` ≡ `?flags 'IM`；重复字符去重。
- `g` 不再是标志；`Sub`/`Subn` 全局替换用 `?all t`，`Split` 默认全部分割、用 `?first t` 只切首处（`?flags` 中出现 `g` 会 `error()` 并提示）。
- 非法输入（数字、未知字母）以 `error()` 中断。

`?first` 与 `?all` 控制处理范围：`Split` 默认切分全部，`?first t` 只切首处；`Sub`/`Subn` 默认替换首处，`?all t` 替换全部。注意：零宽 pattern（能匹配空串者，如 `x*`）在本引擎下 `Split` 和 `Sub`/`Subn` 都只处理首个空匹配（`pcreReplace` 限制）。

```lisp
; ?all — 全局（对照默认单次）
ycRegEx::Sub("\\d" "a1b2c" "#" ?all t)  ; => "a#b#c"
ycRegEx::Sub("\\d" "a1b2c" "#")         ; => "a#b2c"

; i — 大小写不敏感
ycRegEx::Search("hello" "Say HELLO")            ; => nil
ycRegEx::Search("hello" "Say HELLO" ?flags 'I)  ; => Matched，span (4 9)

; m — 多行：^ / $ 匹配每行首尾
ycRegEx::Search("^b" "a\nb")            ; => nil（默认 ^ 仅匹配串首）
ycRegEx::Search("^b" "a\nb" ?flags 'M)  ; => Matched，span (2 3)
ycRegEx::Search("^hello" "Say\nHELLO" ?flags 'IM)  ; => Matched，span (4 9)（与 i 组合）

; s — 点号通配换行
ycRegEx::Search("a.b" "a\nb")            ; => nil
ycRegEx::Search("a.b" "a\nb" ?flags 'S)  ; => Matched，span (0 3)

; x — 详式：pattern 内空白不参与匹配
ycRegEx::Search("a b" "a b")            ; => Matched，span (0 3)
ycRegEx::Search("a b" "xab" ?flags 'X)  ; => Matched，span (1 3)
```

## 编译选项

`Compile` 的 `?compileOpts` 接受单个选项符号或符号列表（默认 `nil`）。编译选项作用于返回的 `Pattern`，可与 `?flags` 同时使用；传已编译 `Pattern` 时不能带 `?compileOpts`。

| 符号 | 语义 |
| --- | --- |
| `caseLess` | 大小写不敏感 |
| `multiLine` | `^`/`$` 匹配每行首尾 |
| `dotAll` | `.` 匹配换行 |
| `extended` | 忽略 pattern 中空白与 `#` 注释 |
| `anchored` | 仅从主题串首处起匹配 |
| `dollar_endonly` | `$` 只匹配主题串末尾 |
| `ungreedy` | 反转量词贪婪方向 |
| `no_auto_capture` | 普通括号不捕获，命名组仍可捕获 |
| `firstline` | 命中不得晚于首个换行 |

```lisp
ycRegEx::Compile("ABC" ?compileOpts 'caseLess)->match("abc")       ; => Matched
ycRegEx::Compile("b" ?compileOpts 'anchored)->search("ab")         ; => nil
ycRegEx::Compile("(a)" ?compileOpts 'no_auto_capture)->groups()    ; => 0
ycRegEx::Compile("a+" ?compileOpts 'ungreedy)->match("aaa")->group()  ; => "a"
ycRegEx::Compile("b" ?compileOpts '(anchored firstline))->search("ab")  ; => nil
```

未知选项或非符号/列表参数以 `error()` 中断。

## 执行选项

`?execOpts` 为每次匹配调用的执行选项，接受单个选项符号或符号列表（默认 `nil`）。它不改变已编译的 `Pattern`，可逐次调用覆盖。

| 符号 | 语义 |
| --- | --- |
| `anchored` | 仅从主题串首处起尝试匹配 |
| `notbol` | 主题串首字符不视为行首，`^` 不在该处命中 |
| `noteol` | 主题串末尾不视为行尾，`$` 不在该处命中 |
| `notempty` | 空匹配不算有效命中 |

```lisp
ycRegEx::Search("^a" "a" ?execOpts 'notbol)                  ; => nil
ycRegEx::Search("a$" "a" ?execOpts 'noteol)                  ; => nil
ycRegEx::Search("a?" "b" ?execOpts 'notempty)                ; => nil
ycRegEx::Search("b" "ab" ?execOpts 'anchored)                ; => nil
ycRegEx::Search("^a" "a" ?execOpts list('notbol 'notempty))  ; => nil
```

未知选项或非符号/列表参数以 `error()` 中断。`partial` 不放入 `?execOpts`，需要用 `Partialp` / `Pattern->partialp` 做布尔探测，因为它只表示主题串可完成匹配，不产生完整 `Matched`。

[返回首页](../../README.md)
