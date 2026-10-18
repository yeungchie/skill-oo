# ycString

Cadence SKILL++ 的字符串工具库：常用操作、转义与标识符转换。

## 概要

+ 字符级操作按 UTF-8 码点处理；显示宽度与 `ycUtf8` 的宽度规则一致。
+ 字面量接口（`replace` / `count`）区分大小写；`?regex t` 时按 `ycRegEx` 的模式与替换模板语义。
+ 所有错误带 `ycString::<过程>:` 前缀，可用 `errset` 捕获。

## API

| 过程 | 说明 |
| --- | --- |
| `trim(t_s ?chars " \t\r\n")` / `trimStart` / `trimEnd` | 去两端/单端字符集中的字符 |
| `pad(t_s n_width ?fill " " ?side "end" ?unit "display" ?ambiguous 1)` | 补足目标宽度；已足宽不截断 |
| `width(t_s ?unit "display" ?ambiguous 1)` | 显示列宽或码点数 |
| `split(t_s ?sep nil ?regex nil ?keepEmpty t)` | 切分：默认按空白符；字面分隔保留空段；`?regex` 正则切分 |
| `join(l_items ?sep "")` | 连接字符串列表 |
| `startsWith(t_s t_prefix)` / `endsWith(t_s t_suffix)` | 前缀/后缀判断 |
| `replace(t_s t_old t_new ?regex nil)` | 替换全部出现（非重叠） |
| `count(t_s t_sub ?regex nil)` | 统计非重叠出现次数 |
| `escape(t_s ?quote nil)` / `unescape(t_s ?strict nil)` | 转义/还原反斜杠、双引号、换行、制表、回车 |
| `words(t_s)` | 切分为词列表 |
| `joinWords(l_words ?style "snake")` | 按 snake/kebab/camel/pascal 拼接 |
| `sanitize(t_s ?style "snake")` | 清洗为标识符形态 |
| `toSnake` / `toKebab` / `toCamel` / `toPascal` | `sanitize` 的固定风格便捷形式 |

## 例程

```lisp
ycString::trim("  hello  ")                      ; => "hello"
ycString::trim("中中a中中" ?chars "中")           ; => "a"
ycString::pad("ab" 5)                            ; => "ab   "
ycString::pad("中" 4)                            ; => "中  "（显示宽 2）
ycString::width("中文")                          ; => 4
ycString::width("中文" ?unit "char")             ; => 2
ycString::split("  a\tb ")                       ; => ("a" "b")
ycString::split("a,,b" ?sep ",")                 ; => ("a" "" "b")
ycString::split("a1b22c" ?sep "[0-9]+" ?regex t) ; => ("a" "b" "c")
ycString::join(list("a" "b") ?sep "-")           ; => "a-b"
ycString::replace("baaacaa" "a+" "X" ?regex t)   ; => "bXcX"
ycString::count("banana" "a")                    ; => 3
ycString::escape("a\"b" ?quote t)                ; => 转义后的带引号字面量
ycString::toSnake("HTMLParser")                  ; => "html_parser"
ycString::toPascal("html_parser")                ; => "HtmlParser"
```

## 显示宽度

`?unit "display"` 与 `ycUtf8::width` 一致：控制字符为 0、East Asian Wide/Fullwidth 为 2、Ambiguous 由 `?ambiguous` 决定（默认 1）。宽度按码点求和，不合并字素簇；需要按字符数对齐时用 `?unit "char"`。
