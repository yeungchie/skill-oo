# ycLang

[返回首页](../../README.md)

Cadence SKILL++ 的语言级辅助库：`ycWith` 作用域宏与配套的对象进入/退出协议。

## 概要

- `ycWith` 把对象表达式求值一次并绑定，进入时调用 `__ycWithEnter__`，退出时（正常或异常）调用 `__ycWithExit__`。
- 绑定变量拿到的是进入钩子的返回值；进入钩子可以返回对象自身，也可以返回实际使用的子资源。
- `s_name` 传 `nil` 时不建立绑定，两个钩子照常执行，进入钩子的返回值被丢弃。
- 展开里的临时对象使用唯一符号，不会与体内同名变量互相干扰。
- 协议方法是两个全局通用函数，类通过 `defmethod` 接入；不在每个对象上增加槽。
- 支持继承：对象自身或任一父类实现了两个钩子即可使用。
- 根类 `t` 上有默认钩子，只在绕过宏直接调用通用函数时给出带类名的错误，不计入「已接入」。
- 进入前检查两个钩子；缺任一钩子时以 `error()` 中断，体内的代码不会执行。
- `ycWith` 是全局宏，不能写成 `ycLang::ycWith`。

## 快速上手

```lisp
; 日志器：退出时自动关闭文件端口
ycWith(lg ycLog::Logger("flow" ?file "./run.log")
    lg->info("start")
    lg->warn("done")
)

; 自定义作用域：进入返回自身，退出设置 closed
defclass(MyScope () (
    closed(\@initarg closed \@initform nil)
))
defmethod(__ycWithEnter__ (self(MyScope))
    self
)
defmethod(__ycWithExit__ (self(MyScope))
    self->closed = t
    t
)
my = makeInstance('MyScope)
ycWith(s my
    s->closed
)
; => nil
my->closed
; => t

; 嵌套：内层先退出
ycWith(a makeInstance('MyScope)
    ycWith(b makeInstance('MyScope)
        list(a->closed b->closed)
    )
)
; => (nil nil)
```

## API 参考

### ycWith <sub>`macro`</sub>

```text
ycWith(
    s_name
    g_expr
    [ expr ... ]
)
=> any
```

**描述**

在 with 作用域内执行代码。`g_expr` 求值一次后，先检查对象的两个协议钩子，再把 `__ycWithEnter__` 的返回值绑定到 `s_name`，执行体内表达式，最后调用 `__ycWithExit__`。

- 缺 `__ycWithEnter__` 或 `__ycWithExit__` 时以 `error()` 中断，体内代码不执行。
- `g_expr` 结果为 `nil` 时以 `error()` 中断。
- `s_name` 为 `nil` 时只执行两个钩子，不建立绑定；进入钩子的返回值被丢弃，返回值仍是体内最后一个表达式的值。
- `s_name` 必须是符号或 `nil`；其他值在展开时以 `error()` 中断。
- 进入钩子出错时不调用退出钩子；体内出错时先执行退出钩子，再继续上抛原错误。
- 多个资源直接嵌套；退出顺序为内层先、外层后。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| s_name | sym / nil |  | 绑定变量名，不参与求值；`nil` 表示不绑定 |
| g_expr | any |  | 对象表达式，只求值一次 |
| expr | any |  | 可选，作用域内的表达式；最后一个的值作为返回 |

**返回值**

`any` — 体内最后一个表达式的值；参数缺失、对象为 `nil` 或钩子缺失时以 `error()` 中断。

**例程**

```lisp
defclass(MyScope () (
    closed(\@initarg closed \@initform nil)
))

defmethod(__ycWithEnter__ (self(MyScope))
    self
)

defmethod(__ycWithExit__ (self(MyScope))
    self->closed = t
    t
)

my = makeInstance('MyScope)
ycWith(s my
    s->closed
)
; => nil
my->closed
; => t

; s_name 为 nil：不绑定，两个钩子照常执行
scope = makeInstance('MyScope)
ycWith(nil scope
    42
)
; => 42
scope->closed
; => t
```

### __ycWithEnter__ <sub>`function`</sub>

```text
__ycWithEnter__(self)
=> any
```

**描述**

with 协议的进入钩子。`ycWith` 在检查通过后调用它一次，返回值作为绑定变量的值。类通过 `defmethod` 实现；未接入的类会命中根类 `t` 上的默认方法，以 `error()` 中断并报告类名。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| self | any | 对象实例 |

**返回值**

`any` — 绑定给 `ycWith` 变量的值；常用对象自身或实际子资源。

**例程**

```lisp
defclass(MyScope () ())

defmethod(__ycWithEnter__ (self(MyScope))
    self
)
```

### __ycWithExit__ <sub>`function`</sub>

```text
__ycWithExit__(self)
=> any
```

**描述**

with 协议的退出钩子。`ycWith` 在体内执行完毕或体内出错后调用它一次，始终作用于原对象，返回值被忽略。类通过 `defmethod` 实现；未接入的类会命中根类 `t` 上的默认方法，以 `error()` 中断并报告类名。

**参数**

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| self | any | 对象实例 |

**返回值**

`any` — 返回值被忽略；建议返回 `t`。

**例程**

```lisp
defclass(MyScope () ())

defmethod(__ycWithExit__ (self(MyScope))
    printf("leaving scope\n")
    t
)
```

## 接入 with 协议

类只要实现两个零参钩子即可接入：

```lisp
defclass(MyScope () (
    closed(\@initarg closed \@initform nil)
))

defmethod(__ycWithEnter__ (self(MyScope))
    self
)

defmethod(__ycWithExit__ (self(MyScope))
    self->closed = t
    t
)
```

子类可以直接继承父类的钩子：

```lisp
defclass(SubScope (MyScope) ())

sub = makeInstance('SubScope)
ycWith(s sub
    s->closed
)
; => nil
sub->closed
; => t
```

只实现其中一个钩子会在进入前被拒绝：

```lisp
defclass(BrokenScope () ())

defmethod(__ycWithEnter__ (self(BrokenScope))
    self
)

ycWith(s makeInstance('BrokenScope)
    s
)
; => 以 error() 中断（does not implement __ycWithExit__）
```

[返回首页](../../README.md)
