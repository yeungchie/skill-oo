# ycRegEx

Cadence SKILL++ 的正则表达式库：模块级自由函数与 `reCompile()` 编译对象双套 API，提供 `Pattern`/`Match` 两类对象，零第三方依赖。

## 概要

- 正则引擎按字节工作：匹配位置、`.` 与字符类均按字节计，字面量按字节等值匹配。
- 未提供的能力（按名取组、`groupdict()`、位置方法的组号参数等）在调用时以 `error()` 中断，API 参考各条目中逐一注明。
- 捕获组数不设上限；位置扫描的锚定偏移上限为 65535 字节，超出时以 `error()` 中断。
- 模板（`t_repl`/`expand`）按引擎方言展开：`\1`~`\9` 反向引用；`&`/`\0` 整体匹配；带编译对象时 `\{n}` 引用任意组，第 10 组以上必须用此形式；`\n` 是字面 `n`，换行请写真实换行字符；其他形式按字面处理。
- flags 以关键字 `?flags` 传入（符号或字符串，如 `'I` 或 `"imsx"`）；全局匹配用 `?all t`。详见「flags 参数」。
- 各自由函数的 `g_pat` 可传模式串或已编译 `Pattern`；传 `Pattern` 时直接复用、不重编译（与 `?flags` 同用会报错）。
- pattern 与模板中的反斜杠在 SKILL 源字符串中写作两字符（如 `"\\d+"`、`"\\1"`）。

## 快速上手

```lisp
; 搜索 + 提取
let((m)
    m = ycRegEx::reSearch("(\\d+)-(\\d+)" "inv 10-20 ok")
    when(m
        printf("%s span=%L groups=%L\n" m->group() m->span() m->groups())
        ; => "10-20" span=(4 9) groups=("10" "20")
    )
)

; 编译复用：一次编译、多次调用
let((p)
    p = ycRegEx::reCompile("\\d+")
    printf("%L\n" p->findall("a1b22"))        ; => ("1" "22")
    printf("%s\n" p->sub("#" "a1b2" ?all t))  ; => "a#b#"
)
```

## API 参考

### ycRegEx::reCompile <sub>`function`</sub>

```text
ycRegEx::reCompile(g_pat [ ?flags g_flags ] [ ?compileOpts g_compileOpts ])
=> Pattern
```

**描述**

编译 pattern，返回可复用的 `Pattern`。`g_pat` 可为模式串或已编译 `Pattern`——传 `Pattern` 时直接复用、不重编译，此时不能带 `?flags` 或 `?compileOpts`。pattern 语法错误或参数类型不符时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_pat | str \| Pattern |  | 模式串或已编译 Pattern（复用不重编译） |
| ?flags g_flags | sym \| str \| nil | nil | 修饰标志 `'I 'M 'S 'X`（大小写皆可）；详见 [flags 参数](#flags-参数) |
| ?compileOpts g_compileOpts | sym \| list \| nil | nil | 编译选项符号或列表；详见 [编译选项](#编译选项) |

**返回值**

`Pattern` — 编译后的 `Pattern` 对象。

**例程**

```lisp
p = ycRegEx::reCompile("\\d+")  ; => Pattern
ycRegEx::reCompile("ABC" ?compileOpts 'caseLess)->match("abc")  ; => Match
ycRegEx::reCompile("(")         ; => 以 error() 中断（语法错误）
```

### ycRegEx::reMatch <sub>`function`</sub>

```text
ycRegEx::reMatch(g_pat t_subj [ ?flags g_flags ])
=> Match | nil
```

**描述**

仅在 `t_subj` 起始处匹配（等价前锚 `\A`）；pattern 语法错误或参数类型不符时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_pat | str \| Pattern |  | 模式串或已编译 Pattern（复用不重编译） |
| t_subj | str |  | 被处理字符串 |
| ?flags g_flags | sym \| str \| nil | nil | 修饰标志 `'I 'M 'S 'X`（大小写皆可）；详见 [flags 参数](#flags-参数) |

**返回值**

`Match | nil` — 命中为 `Match`，未命中为 `nil`。

**例程**

```lisp
ycRegEx::reMatch("\\d+" "123a")  ; => Match，span (0 3)
ycRegEx::reMatch("\\d+" "a123")  ; => nil
```

### ycRegEx::reSearch <sub>`function`</sub>

```text
ycRegEx::reSearch(g_pat t_subj [ ?flags g_flags ])
=> Match | nil
```

**描述**

从左向右搜索首个匹配；pattern 语法错误或参数类型不符时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_pat | str \| Pattern |  | 模式串或已编译 Pattern（复用不重编译） |
| t_subj | str |  | 被处理字符串 |
| ?flags g_flags | sym \| str \| nil | nil | 修饰标志 `'I 'M 'S 'X`（大小写皆可）；详见 [flags 参数](#flags-参数) |

**返回值**

`Match | nil` — 命中为 `Match`，未命中为 `nil`。

**例程**

```lisp
m = ycRegEx::reSearch("(\\d+)-(\\d+)" "a10-20b")
m->span()              ; => (1 6)，字节位
m->group()             ; => "10-20"
m->groups()            ; => ("10" "20")
```

### ycRegEx::reFullmatch <sub>`function`</sub>

```text
ycRegEx::reFullmatch(g_pat t_subj [ ?flags g_flags ])
=> Match | nil
```

**描述**

要求匹配覆盖整个 `t_subj`（实现为 `\A(?:…)\z`）；pattern 语法错误或参数类型不符时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_pat | str \| Pattern |  | 模式串或已编译 Pattern（复用不重编译） |
| t_subj | str |  | 被处理字符串 |
| ?flags g_flags | sym \| str \| nil | nil | 修饰标志 `'I 'M 'S 'X`（大小写皆可）；详见 [flags 参数](#flags-参数) |

**返回值**

`Match | nil` — 命中为 `Match`，未命中为 `nil`。

**例程**

```lisp
ycRegEx::reFullmatch("a|ab" "ab")   ; => Match，span (0 2)
ycRegEx::reFullmatch("\\d+" "123a") ; => nil
```

### ycRegEx::reFindall <sub>`function`</sub>

```text
ycRegEx::reFindall(g_pat t_subj [ ?flags g_flags ])
=> list
```

**描述**

查找全部匹配，返回形态由捕获组数决定（见返回值）。pattern 语法错误或参数类型不符时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_pat | str \| Pattern |  | 模式串或已编译 Pattern（复用不重编译） |
| t_subj | str |  | 被处理字符串 |
| ?flags g_flags | sym \| str \| nil | nil | 修饰标志 `'I 'M 'S 'X`（大小写皆可）；详见 [flags 参数](#flags-参数) |

**返回值**

`list` — 全部匹配结果：零组为整体字符串列表，一组为扁平组值列表，两组及以上每匹配一个子列表；未命中为空列表。

**例程**

```lisp
ycRegEx::reFindall("\\d+" "a1b22")  ; => ("1" "22")
ycRegEx::reFindall("(a)|(b)" "ab")  ; => (("a" "") ("" "b"))
```

### ycRegEx::reFinditer <sub>`function`</sub>

```text
ycRegEx::reFinditer(g_pat t_subj [ ?flags g_flags ])
=> list[Match]
```

**描述**

从左向右返回全部匹配；零宽命中按 `start + 1` 推进。pattern 语法错误或参数类型不符时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_pat | str \| Pattern |  | 模式串或已编译 Pattern（复用不重编译） |
| t_subj | str |  | 被处理字符串 |
| ?flags g_flags | sym \| str \| nil | nil | 修饰标志 `'I 'M 'S 'X`（大小写皆可）；详见 [flags 参数](#flags-参数) |

**返回值**

`list[Match]` — 全部匹配的 `Match` 列表；未命中为空列表。

**例程**

```lisp
length(ycRegEx::reFinditer("\\d+" "a1b22"))  ; => 2
```

### ycRegEx::reSplit <sub>`function`</sub>

```text
ycRegEx::reSplit(g_pat t_subj [ ?flags g_flags ] [ ?all g_all ])
=> list[str]
```

**描述**

按 pattern 切分 `t_subj`；默认只切首处匹配，`?all t` 切分全部；零宽 pattern 在 `?all` 下亦仅处理首个空匹配。pattern 语法错误或参数类型不符时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_pat | str \| Pattern |  | 模式串或已编译 Pattern（复用不重编译） |
| t_subj | str |  | 被处理字符串 |
| ?flags g_flags | sym \| str \| nil | nil | 修饰标志 `'I 'M 'S 'X`（大小写皆可）；详见 [flags 参数](#flags-参数) |
| ?all g_all | t \| nil | nil | t 时处理全部匹配，否则只处理首处 |

**返回值**

`list[str]` — 切分段列表，捕获组段保留；未命中时为原串单元素列表 `(t_subj)`。

**例程**

```lisp
ycRegEx::reSplit("," "a,b,c")            ; => ("a" "b,c")（默认单次）
ycRegEx::reSplit("," "a,b,c" ?all t)     ; => ("a" "b" "c")
ycRegEx::reSplit("(\\d)" "a1b2c" ?all t) ; => ("a" "1" "b" "2" "c")
```

### ycRegEx::reSub <sub>`function`</sub>

```text
ycRegEx::reSub(g_pat t_repl t_subj [ ?flags g_flags ] [ ?all g_all ])
=> str
```

**描述**

将匹配替换为 `t_repl` 展开串。模板按引擎方言展开 `\1`~`\9`、`&`、`\0`，带编译对象时可用 `\{n}` 引用任意组；`\n` 是字面 `n`，换行请写真实换行字符。默认只替换首处匹配，`?all t` 替换全部；零宽匹配在全部模式下亦仅替换首处一次。pattern 语法错误或参数类型不符时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_pat | str \| Pattern |  | 模式串或已编译 Pattern（复用不重编译） |
| t_repl | str |  | 替换模板 |
| t_subj | str |  | 被处理字符串 |
| ?flags g_flags | sym \| str \| nil | nil | 修饰标志 `'I 'M 'S 'X`（大小写皆可）；详见 [flags 参数](#flags-参数) |
| ?all g_all | t \| nil | nil | t 时处理全部匹配，否则只处理首处 |

**返回值**

`str` — 替换后的串；未命中时为原串。

**例程**

```lisp
ycRegEx::reSub("\\d+" "#" "a1b22" ?all t) ; => "a#b#"
ycRegEx::reSub("\\d" "#" "a1b2")          ; => "a#b2"（默认单次）
ycRegEx::reSub("x*" "-" "abc")            ; => "-abc"（零宽仅首处）
```

### ycRegEx::reSubn <sub>`function`</sub>

```text
ycRegEx::reSubn(g_pat t_repl t_subj [ ?flags g_flags ] [ ?all g_all ])
=> (str, int)
```

**描述**

语义同 `reSub`。内部计数经定界标记实现，`t_subj`/`t_repl` 或组值中若含 `<YC-B>`/`<YC-N>`/`<YC-S>` 会被误剥离或误切。pattern 语法错误或参数类型不符时以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_pat | str \| Pattern |  | 模式串或已编译 Pattern（复用不重编译） |
| t_repl | str |  | 替换模板 |
| t_subj | str |  | 被处理字符串 |
| ?flags g_flags | sym \| str \| nil | nil | 修饰标志 `'I 'M 'S 'X`（大小写皆可）；详见 [flags 参数](#flags-参数) |
| ?all g_all | t \| nil | nil | t 时处理全部匹配，否则只处理首处 |

**返回值**

`(str, int)` — `(替换后的串 实际替换次数)`；未命中时为 `(原串 0)`。

**例程**

```lisp
ycRegEx::reSubn("\\d" "#" "a1b2" ?all t)  ; => ("a#b#" 2)
```

### ycRegEx::reGetRecursionLimit <sub>`function`</sub>

```text
ycRegEx::reGetRecursionLimit()
=> int
```

**描述**

返回 PCRE 匹配算法当前的最大递归深度（进程级设置），默认 `10000000`。修改后影响后续所有匹配。

**参数**

无

**返回值**

`int` — 当前最大递归深度。

**例程**

```lisp
ycRegEx::reGetRecursionLimit()  ; => 10000000
```

### ycRegEx::reSetRecursionLimit <sub>`function`</sub>

```text
ycRegEx::reSetRecursionLimit(n_limit)
=> t
```

**描述**

设置 PCRE 匹配算法的最大递归深度（进程级设置）。非整数参数以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| n_limit | int |  | 最大递归深度 |

**返回值**

`t` — 设置成功。

**例程**

```lisp
ycRegEx::reSetRecursionLimit(1000)  ; => t
ycRegEx::reGetRecursionLimit()      ; => 1000
ycRegEx::reSetRecursionLimit(10000000)  ; => t（恢复默认）
```

### ycRegEx::Pattern <sub>`class`</sub>

**描述**

`reCompile()` 的返回类型。方法与同名自由函数（去 `re` 前缀）语义相同；已是编译对象，免重复编译；编译期修饰（`i/m/s/x`）在 `reCompile` 时定死，方法不再提供 `?flags`；`split`/`sub`/`subn` 提供 `?all`。方法一律经 `->` 调用；`sub`/`subn` 首参为 `t_repl`，其余方法首参为 `t_subj`。

#### 搜索与匹配

##### match <sub>`method`</sub>

```text
p->match(t_subj)
=> Match | nil
```

**描述**

仅在 `t_subj` 起始处匹配。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_subj | str | 被处理字符串 |

**返回值**

`Match | nil` — 命中为 `Match`，未命中为 `nil`。

**例程**

```lisp
p = ycRegEx::reCompile("\\d+")
p->match("123a")  ; => Match
p->match("a123")  ; => nil
```

##### search <sub>`method`</sub>

```text
p->search(t_subj)
=> Match | nil
```

**描述**

从左向右搜索首个匹配。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_subj | str | 被处理字符串 |

**返回值**

`Match | nil` — 命中为 `Match`，未命中为 `nil`。

**例程**

```lisp
p = ycRegEx::reCompile("\\d+")
p->search("a123")  ; => Match
```

##### fullmatch <sub>`method`</sub>

```text
p->fullmatch(t_subj)
=> Match | nil
```

**描述**

要求匹配覆盖整个 `t_subj`。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_subj | str | 被处理字符串 |

**返回值**

`Match | nil` — 命中为 `Match`，未命中为 `nil`。

**例程**

```lisp
p = ycRegEx::reCompile("\\d+")
p->fullmatch("123")   ; => Match
p->fullmatch("123a")  ; => nil
```

#### 查找全部

##### findall <sub>`method`</sub>

```text
p->findall(t_subj)
=> list
```

**描述**

语义与返回形态同自由函数 `reFindall`；已编译。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_subj | str | 被处理字符串 |

**返回值**

`list` — 同自由函数 `reFindall`。

**例程**

```lisp
p = ycRegEx::reCompile("\\d+")
p->findall("a1b22")  ; => ("1" "22")
```

##### finditer <sub>`method`</sub>

```text
p->finditer(t_subj)
=> list[Match]
```

**描述**

语义同自由函数 `reFinditer`；已编译。零宽命中按 `start + 1` 推进。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_subj | str | 被处理字符串 |

**返回值**

`list[Match]` — 同自由函数 `reFinditer`。

**例程**

```lisp
p = ycRegEx::reCompile("\\d+")
length(p->finditer("a1b22"))  ; => 2
```

#### 拆分

##### split <sub>`method`</sub>

```text
p->split(t_subj [ ?all g_all ])
=> list[str]
```

**描述**

按 pattern 切分 `t_subj`。默认只切首处匹配，`?all t` 切分全部；零宽 pattern 在 `?all` 下亦仅处理首个空匹配。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_subj | str |  | 被处理字符串 |
| ?all g_all | t \| nil | nil | t 时处理全部匹配，否则只处理首处 |

**返回值**

`list[str]` — 切分段列表，捕获组段保留；未命中时为原串单元素列表 `(t_subj)`。

**例程**

```lisp
p = ycRegEx::reCompile(",")
p->split("a,b,c")         ; => ("a" "b,c")（默认单次）
p->split("a,b,c" ?all t)  ; => ("a" "b" "c")
```

#### 替换

##### sub <sub>`method`</sub>

```text
p->sub(t_repl t_subj [ ?all g_all ])
=> str
```

**描述**

将匹配替换为 `t_repl` 展开串；模板方言、零宽替换行为与 `?all` 语义同 `reSub`。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_repl | str |  | 替换模板 |
| t_subj | str |  | 被处理字符串 |
| ?all g_all | t \| nil | nil | t 时处理全部匹配，否则只处理首处 |

**返回值**

`str` — 替换后的串；未命中时为原串。

**例程**

```lisp
p = ycRegEx::reCompile("\\d+")
p->sub("#" "a1b2")        ; => "a#b2"（默认单次）
p->sub("#" "a1b2" ?all t) ; => "a#b#"
```

##### subn <sub>`method`</sub>

```text
p->subn(t_repl t_subj [ ?all g_all ])
=> (str, int)
```

**描述**

语义同 `sub`；定界标记限制同 `reSubn`。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| t_repl | str |  | 替换模板 |
| t_subj | str |  | 被处理字符串 |
| ?all g_all | t \| nil | nil | t 时处理全部匹配，否则只处理首处 |

**返回值**

`(str, int)` — `(替换后的串 实际替换次数)`；未命中时为 `(原串 0)`。

**例程**

```lisp
p = ycRegEx::reCompile("\\d")
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

捕获组数；不设自设上限。

**参数**

无

**返回值**

`int` — 捕获组数。

**例程**

```lisp
ycRegEx::reCompile("(\\d+)-(\\d+)")->groups()  ; => 2
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

`str` — 原 pattern 串，与 `reCompile` 入参一致。

**例程**

```lisp
ycRegEx::reCompile("\\d+")->pattern()  ; => "\\d+"
```

### ycRegEx::Match <sub>`class`</sub>

**描述**

匹配命中后返回的对象；`span`/`start`/`end` 返回字节位。

#### 取组

##### group <sub>`method`</sub>

```text
m->group()
m->group(n_index ...)
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
m = ycRegEx::reSearch("(\\d+)-(\\d+)" "a10-20b")
m->group()       ; => "10-20"
m->group(1)      ; => "10"
m->group(1 2)    ; => ("10" "20")
m->group("x")    ; => 以 error() 中断（按名取组不提供）
m->groupdict()   ; => 以 error() 中断（预留不提供）
```

##### groups <sub>`method`</sub>

```text
m->groups([ g_empty ])
=> list
```

**描述**

一次取回全部组值，并把所有空字符串结果替换为 `g_empty`。该替换作用于空结果，既包括未参与匹配的组，也包括真正匹配到空串的组；默认 `""`，因此省略参数时保持原有结果。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_empty | any | `""` | 空结果替换值 |

**返回值**

`list` — 组值列表，空字符串替换为 `g_empty`；零捕获组时为 `nil`；返回副本，修改不影响 `Match`。

**例程**

```lisp
m = ycRegEx::reSearch("(a)|(b)" "b")
m->groups()        ; => ("" "b")
m->groups("NA")    ; => ("NA" "b")
m->groups(nil)     ; => (nil "b")
```

#### 位置

##### span <sub>`method`</sub>

```text
m->span()
=> (int, int)
```

**描述**

取匹配的起止位置（字节位）。经 `search` 路径构造的 `Match`，定位在首次需要位置信息时才完成（`span`/`start`/`end`/`group`/`expand` 均可触发）。组号参数不提供，以 `error()` 中断。

**参数**

无

**返回值**

`(int, int)` — `(start end)` 字节位，左闭右开。

**例程**

```lisp
m = ycRegEx::reSearch("(\\d+)-(\\d+)" "a10-20b")
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
m = ycRegEx::reSearch("(\\d+)-(\\d+)" "a10-20b")
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
m = ycRegEx::reSearch("(\\d+)-(\\d+)" "a10-20b")
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
m = ycRegEx::reSearch("(\\d+)-(\\d+)" "a10-20b")
m->expand("\\2-\\1")  ; => "20-10"
```

## flags 参数

`?flags` 与 `?all` 为各函数的关键字参数（默认 `nil`）。

`?flags` 指定修饰标志，接受符号或字符串（大小写皆可，`?flags 'I` 与 `?flags "i"` 等效），内部逐字符解析：

| 字符 | 修饰 | 语义 |
| --- | --- | --- |
| `i` | `(?i)` | 大小写不敏感匹配 |
| `m` | `(?m)` | 多行：`^`/`$` 匹配每行首尾 |
| `s` | `(?s)` | 点通配换行：`.` 亦匹配 `\n` |
| `x` | `(?x)` | 详式：pattern 中空白不参与匹配 |

- 可组合：`?flags "im"` ≡ `?flags 'IM`；重复字符去重。
- `g` 不再是标志；全局匹配用 `?all t`（`?flags` 中出现 `g` 会 `error()` 并提示）。
- 非法输入（数字、未知字母）以 `error()` 中断。

`?all` 控制「单次/全部」，仅 `reSplit`/`reSub`/`reSubn` 及其 `Pattern` 同名方法提供：默认 `nil` 只处理首处匹配，`?all t` 处理全部。注意：零宽 pattern（能匹配空串者，如 `x*`）在本引擎下 `?all` 也只处理首个空匹配（`pcreReplace` 限制）。

```lisp
; ?all — 全局（对照默认单次）
ycRegEx::reSub("\\d" "a1b2c" "#" ?all t)  ; => "a#b#c"
ycRegEx::reSub("\\d" "a1b2c" "#")         ; => "a#b2c"

; i — 大小写不敏感
ycRegEx::reSearch("hello" "Say HELLO")            ; => nil
ycRegEx::reSearch("hello" "Say HELLO" ?flags 'I)  ; => Match，span (4 9)

; m — 多行：^ / $ 匹配每行首尾
ycRegEx::reSearch("^b" "a\nb")            ; => nil（默认 ^ 仅匹配串首）
ycRegEx::reSearch("^b" "a\nb" ?flags 'M)  ; => Match，span (2 3)
ycRegEx::reSearch("^hello" "Say\nHELLO" ?flags 'IM)  ; => Match，span (4 9)（与 i 组合）

; s — 点号通配换行
ycRegEx::reSearch("a.b" "a\nb")            ; => nil
ycRegEx::reSearch("a.b" "a\nb" ?flags 'S)  ; => Match，span (0 3)

; x — 详式：pattern 内空白不参与匹配
ycRegEx::reSearch("a b" "a b")            ; => Match，span (0 3)
ycRegEx::reSearch("a b" "xab" ?flags 'X)  ; => Match，span (1 3)
```

## 编译选项

`reCompile` 的 `?compileOpts` 接受单个选项符号或符号列表（默认 `nil`）。编译选项作用于返回的 `Pattern`，可与 `?flags` 同时使用；传已编译 `Pattern` 时不能带 `?compileOpts`。

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
ycRegEx::reCompile("ABC" ?compileOpts 'caseLess)->match("abc")       ; => Match
ycRegEx::reCompile("b" ?compileOpts 'anchored)->search("ab")         ; => nil
ycRegEx::reCompile("(a)" ?compileOpts 'no_auto_capture)->groups()    ; => 0
ycRegEx::reCompile("a+" ?compileOpts 'ungreedy)->match("aaa")->group()  ; => "a"
ycRegEx::reCompile("b" ?compileOpts '(anchored firstline))->search("ab")  ; => nil
```

未知选项或非符号/列表参数以 `error()` 中断。
