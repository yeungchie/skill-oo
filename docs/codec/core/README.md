# ycCodec

[返回首页](../../../README.md)

Cadence SKILL++ 编解码库共享的哨兵类型库：统一表示 `true`、`false`、`null` 与缺键标记。

## 概要

+ `ycJson`、`ycYaml` 等编解码库共用同一组哨兵对象：解码得到的布尔与空值即 `ycCodec::True`、`ycCodec::False`、`ycCodec::Null`，缺键标记为 `ycCodec::Missing`。
+ 每个哨兵都是 `ycCodec::Type` 的唯一实例，相同规范名总是同一对象，可直接用 `==` 比较。
+ 哨兵可跨编解码库直接使用：`ycJson::Decode` 的结果可直接交给 `ycYaml::Encode`，反之亦然。
+ `->toSkill()` 转为 SKILL 原生值，转换有损：`False` 与空容器同域，`Null` 与 `Missing` 同域。
+ 构造器接受大小写不敏感的四名：`"true"`、`"false"`、`"null"`、`"missing"`。
+ 例程中 `; =>` 表示返回值。

## 快速上手

```lisp
; 哨兵与原生值
ycCodec::True->toSkill()                             ; => t
ycCodec::False->toSkill()                            ; => nil
ycCodec::Null->toSkill()                             ; => unbound

; 相同规范名返回同一实例
ycCodec::Type("TRUE") == ycCodec::True               ; => t

; 各编解码库共用同一组对象
ycJson::Decode("true") == ycCodec::True              ; => t
ycYaml::Decode("null")                               ; => ycCodec::Type("Null")
ycJson::Encode(ycCodec::Null)                        ; => "null"
```

## API 参考

### ycCodec::Type <sub>`function`</sub> <sub>`class`</sub>

```text
ycCodec::Type(t_name)
=> ycCodec::Type
```

**描述**

构造哨兵对象（`true`/`false`/`null` 与缺键标记 `missing` 的库内表示）：`t_name` 接受任意大小写，返回规范名对应的**唯一实例**——相同参数总是同一对象，可直接用 `==` 比较。规范名随实例显示为 `"True"`、`"False"`、`"Null"`、`"Missing"`。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| t_name | str | `"true"`、`"false"`、`"null"` 或 `"missing"`（任意大小写）；其他值以 `error()` 中断 |

**返回值**

`ycCodec::Type` — 规范名对应的驻留唯一实例。

**例程**

```lisp
ycCodec::Type("true") == ycCodec::True         ; => t
ycCodec::Type("TRUE") == ycCodec::True         ; => t
ycCodec::Type("xml")
; *Error* ycCodec::Type: unknown type name "xml"
ycCodec::Type(42)
; *Error* ycCodec::Type: unknown type name 42
```

实例显示为命名空间限定的构造调用形式（如 `ycCodec::Type("True")`）；顶层用 `evalstring` 执行该串可得同一驻留实例。

**方法**

> 必须使用 `->` 符号调用方法。

#### toSkill <sub>`method`</sub>

```text
inst->toSkill()
=> any
```

**描述**

转换为 SKILL 原生值：`ycCodec::True` → `t`，`ycCodec::False` → `nil`，`ycCodec::Null`/`ycCodec::Missing` → `'unbound`。该转换有损：`False` 与空容器同域，`Null` 与 `Missing` 同域，仅供 SKILL 侧取值使用。

**参数**

无

**返回值**

`any` — 转换结果。

**例程**

```lisp
ycCodec::True->toSkill()                       ; => t
ycCodec::False->toSkill()                      ; => nil
ycCodec::Null->toSkill()                       ; => unbound
```

### ycCodec::True <sub>`constant`</sub>

布尔 `true` 的哨兵对象（`Type` 唯一实例）：各编解码库解码 `true` 得到该对象；编码该对象（或 `t`）得 `true`。

### ycCodec::False <sub>`constant`</sub>

布尔 `false` 的哨兵对象（`Type` 唯一实例）：解码 `false` 得到该对象；编码该对象得 `false`。

### ycCodec::Null <sub>`constant`</sub>

空值 `null` 的哨兵对象（`Type` 唯一实例）：解码 `null` 得到该对象；编码该对象得 `null`。

### ycCodec::Missing <sub>`constant`</sub>

容器缺键的缺省标记（`Type` 唯一实例）：解码出的 table 以它为缺省值；编码时作为值出现即以 `error()` 中断。

[返回首页](../../../README.md)
