# ycUtf8

Cadence SKILL++ 的 UTF-8 工具库：字节串与码点互转、按码点计数与切片、显示宽度测量。

## 概要

+ 所有位置参数使用 **1-based** 索引，与 `substring` / `getchar` 一致。
+ 默认严格校验 UTF-8；`?strict nil` 时按字节替换为 U+FFFD 继续处理。
+ 显示宽度按 Unicode East Asian Width 计算；汉字与全角字符恒为 2 列。
+ 宽度数据基于 Unicode 15.0.0，随库发布，运行期无外部依赖。

## API

| 过程 | 说明 |
| --- | --- |
| `decode(t_str ?strict t)` | UTF-8 → 码点列表；空串回 `nil` |
| `encode(l_cps)` | 码点列表 → UTF-8；`nil` 回 `""` |
| `charCount(t_str ?strict t)` | 码点个数 |
| `slice(t_str n_start n_len ?strict t)` | 按码点切片；起点越界回 `nil` |
| `width(t_str ?strict t ?ambiguous 1)` | 显示列宽 |
| `charWidth(n_cp ?ambiguous 1)` | 单码点宽度 |
| `isValid(t_str)` | 是否合法 UTF-8 |

`encode` 拒绝 U+0000：SKILL 字符串无法承载 NUL 字节，接受该码点会静默丢失数据。

## 例程

```lisp
ycUtf8::decode("中")                  ; => (20013)
ycUtf8::encode(list(20013))           ; => "中"
ycUtf8::charCount("a中b")             ; => 3
ycUtf8::slice("a中b" 2 1)             ; => "中"
ycUtf8::width("中文")                 ; => 4
ycUtf8::width("§")                    ; => 1
ycUtf8::width("§" ?ambiguous 2)       ; => 2
ycUtf8::charWidth(20013)              ; => 2
ycUtf8::isValid("abc")                ; => t
```

## 严格与宽松

```lisp
ycUtf8::decode(strcat(intToChar(128)))                 ; 报错：invalid UTF-8 at byte 1
ycUtf8::decode(strcat(intToChar(128)) ?strict nil)     ; => (65533)
```

宽松模式每遇到一个非法字节产出一个 U+FFFD 并前进一字节；`slice` 返回重新编码后的替换字符，不保留原始非法字节。

## 宽度规则

1. 控制字符（U+0000–U+001F、U+007F–U+009F）→ 0
2. 软连字符 U+00AD → 1
3. 组合标记、零宽字符、Hangul 连接 Jamo（U+1160–U+11FF）→ 0
4. East Asian Wide/Fullwidth → 2
5. East Asian Ambiguous → `?ambiguous`（默认 1，在 CJK 显示环境可传 2）
6. 其余 → 1

宽度按码点求和，不合并字素簇；emoji ZWJ 序列、旗帜、肤色修饰符、VS16 表情呈现等可能与终端实际显示不同。换行与制表符计 0，折行前请自行展开制表符。
