# ycQueue

[返回首页](../../README.md)

Cadence SKILL++ 的队列库：提供先进先出与后进先出两个队列类，成员可为任意值，支持可选容量上限与显式空读返回值。

## 概要

+ 两个队列类：`ycQueue::FIFO`（先进先出）与 `ycQueue::LIFO`（后进先出）；接口完全同构，只有取放顺序相反。
+ 成员可以是任意 SKILL 值——字符串、数字、符号、列表、`nil`、对象都能入队；`nil` 是合法成员，与「队列为空」互不混淆。
+ `put` / `get` / `size` / `isEmpty` / `isFull` / `maxLimit` / `clear` 均为 O(1)；`peek` 的两个端点 O(1)，其余位置 O(n)。
+ 空队列读取默认以 `error()` 中断；用 `?onEmpty` 指定返回值可改为返回给定值。
+ 空读的缺省标记是语言层共享符号常量 `ycLang::NoneArg`；调用方一般无需关心，显式把它传给 `?onEmpty` 等同未指定。
+ 可选容量上限 `?maxLimit`：达到上限后 `put` 以 `error()` 中断且不入队；不指定则不限容量。
+ 记法约定：例程中的 `; =>` 表示该表达式的返回值。

## 快速上手

```lisp
; 先进先出：最早入队的先被取出
q = ycQueue::FIFO()
q->put("a")->put("b")->put("c")
q->get()
; => "a"

; 后进先出：最新入队的先被取出
s = ycQueue::LIFO()
s->put("a")->put("b")->put("c")
s->get()
; => "c"

; 空队列不给 ?onEmpty 会中断；给了就返回给定值
ycQueue::FIFO()->get()
; *Error* ycQueue::FIFO->get: queue is empty
ycQueue::FIFO()->get(?onEmpty nil)
; => nil

; 容量上限
c = ycQueue::FIFO(?maxLimit 2)
c->put(1)->put(2)
c->put(3)
; *Error* ycQueue::FIFO->put: queue is full (maxLimit 2)
```

## API 参考

### ycQueue::FIFO <sub>`function`</sub> <sub>`class`</sub>

```text
ycQueue::FIFO(
    [ ?maxLimit n_limit ]
)
=> ycQueue::FIFO
```

**描述**

先进先出队列：`put` 追加到队尾，`get` 从队首取出。成员可为任意值。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?maxLimit n_limit | int / nil | nil | 可选，容量上限；`nil` 表示不限制，正整数表示最多容纳的元素数 |

`?maxLimit` 只接受 `nil` 或正整数；`0`、负数、浮点数、字符串、列表、`t` 均以 `error()` 中断。

**返回值**

`ycQueue::FIFO` — 新队列实例。

**例程**

```lisp
q = ycQueue::FIFO()
; => <ycQueue::FIFO size=0>

q = ycQueue::FIFO(?maxLimit 10)
q->maxLimit()
; => 10
```

**方法**

> 必须使用 `->` 符号调用方法。

#### put <sub>`method`</sub>

```text
q->put(g_value)
=> ycQueue::FIFO
```

把 `g_value` 追加到队尾。已达容量上限时以 `error()` 中断且不入队，队列内容与顺序不变。返回 `self`，支持链式调用。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_value | any | | 任意 SKILL 值 |

```lisp
q = ycQueue::FIFO()
q->put("a")->put(2)->put(nil)
q->size()
; => 3
```

#### get <sub>`method`</sub>

```text
q->get(
    [ ?onEmpty g_fallback ]
)
=> any
```

取出并移除最早入队的元素。空队列且未指定 `?onEmpty` 时以 `error()` 中断；指定了则原样返回给定值，队列状态不变。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?onEmpty g_fallback | any | | 可选，空队列时的返回值；未指定（或传入共享标记 `ycLang::NoneArg`）时空读中断 |

```lisp
q = ycQueue::FIFO()
q->put("a")->put("b")
q->get()
; => "a"
q->get(?onEmpty nil)
; => "b"
q->get(?onEmpty 'none)
; => none
q->get()
; *Error* ycQueue::FIFO->get: queue is empty
```

#### peek <sub>`method`</sub>

```text
q->peek(
    [ ?index n_position ]
    [ ?onEmpty g_fallback ]
)
=> any
```

返回指定位置的元素而不移除。`?index` 为 0-based：`0` 是下一个将被取出的元素，正值向队尾数，负值从队尾反向数（`-1` 为最后被取出的元素）。越界时以 `error()` 中断；空队列优先走 `?onEmpty` 契约，不判断索引。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?index n_position | int | 0 | 可选，0-based 位置；负值从队尾数 |
| ?onEmpty g_fallback | any | | 可选，空队列时的返回值；未指定（或传入共享标记 `ycLang::NoneArg`）时空读中断 |

```lisp
q = ycQueue::FIFO()
q->put("a")->put("b")->put("c")
q->peek()
; => "a"
q->peek(?index 2)
; => "c"
q->peek(?index -1)
; => "c"
q->peek(?index 3)
; *Error* ycQueue::FIFO->peek: index 3 out of range (size 3)
ycQueue::FIFO()->peek(?index 5 ?onEmpty nil)
; => nil
```

#### size <sub>`method`</sub>

```text
q->size()
=> int
```

返回当前元素个数。

```lisp
q = ycQueue::FIFO()
q->size()
; => 0
q->put(1)
q->size()
; => 1
```

#### isEmpty <sub>`method`</sub>

```text
q->isEmpty()
=> t / nil
```

队列为空时返回 `t`，否则返回 `nil`。

```lisp
q = ycQueue::FIFO()
q->isEmpty()
; => t
q->put(1)
q->isEmpty()
; => nil
```

#### isFull <sub>`method`</sub>

```text
q->isFull()
=> t / nil
```

达到容量上限时返回 `t`；不限容量或尚未满时返回 `nil`。

```lisp
q = ycQueue::FIFO(?maxLimit 2)
q->isFull()
; => nil
q->put(1)->put(2)
q->isFull()
; => t
q->get()
q->isFull()
; => nil
```

#### maxLimit <sub>`method`</sub>

```text
q->maxLimit()
=> int / nil
```

返回构造时给定的容量上限；不限容量返回 `nil`。只读，上限在构造时固定。

```lisp
ycQueue::FIFO(?maxLimit 3)->maxLimit()
; => 3
ycQueue::FIFO()->maxLimit()
; => nil
```

#### clear <sub>`method`</sub>

```text
q->clear()
=> ycQueue::FIFO
```

移除全部元素，回到初始状态；容量上限保留。空队列上调用无副作用。返回 `self`，支持链式调用。

```lisp
q = ycQueue::FIFO(?maxLimit 3)
q->put(1)->put(2)->clear()->put(3)
q->toList()
; => (3)
q->maxLimit()
; => 3
```

#### toList <sub>`method`</sub>

```text
q->toList(
    [ ?clear g_flag ]
)
=> list
```

按出队顺序返回元素表：先进先出，即最早 → 最新。空队列返回 `nil`。

默认返回浅拷贝：顶层表是新副本，改写顶层元素不影响队列；嵌套成员与队列共享引用，改写会同时反映到队列。`?clear` 非 `nil` 时直接把内部表移交给调用方并清空队列，不拷贝；之后对返回表的修改与队列无关。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?clear g_flag | t / nil | nil | 可选，非 `nil` 时移交并清空队列 |

```lisp
q = ycQueue::FIFO()
q->put("a")->put("b")
q->toList()
; => ("a" "b")
q->size()
; => 2，队列未被清空

d = ycQueue::FIFO()
d->put(1)->put(2)
d->toList(?clear t)
; => (1 2)
d->size()
; => 0
```

### ycQueue::LIFO <sub>`function`</sub> <sub>`class`</sub>

```text
ycQueue::LIFO(
    [ ?maxLimit n_limit ]
)
=> ycQueue::LIFO
```

**描述**

后进先出队列：`put` 压到队首，`get` 从队首取出。接口与 `FIFO` 完全同构，仅取放顺序相反：`get` 与 `toList` 都是最新 → 最早，`peek(?index 0)` 是最新元素，`-1` 是最早元素。成员可为任意值。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?maxLimit n_limit | int / nil | nil | 可选，容量上限；`nil` 表示不限制，正整数表示最多容纳的元素数 |

`?maxLimit` 只接受 `nil` 或正整数；`0`、负数、浮点数、字符串、列表、`t` 均以 `error()` 中断。

**返回值**

`ycQueue::LIFO` — 新队列实例。

**例程**

```lisp
s = ycQueue::LIFO()
; => <ycQueue::LIFO size=0>

s = ycQueue::LIFO(?maxLimit 10)
s->maxLimit()
; => 10
```

**方法**

> 必须使用 `->` 符号调用方法。

#### put <sub>`method`</sub>

```text
s->put(g_value)
=> ycQueue::LIFO
```

把 `g_value` 压到队首（最新入队）。已达容量上限时以 `error()` 中断且不入队。返回 `self`，支持链式调用。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_value | any | | 任意 SKILL 值 |

```lisp
s = ycQueue::LIFO()
s->put("a")->put(2)->put(nil)
s->size()
; => 3
```

#### get <sub>`method`</sub>

```text
s->get(
    [ ?onEmpty g_fallback ]
)
=> any
```

取出并移除最新入队的元素。空队列且未指定 `?onEmpty` 时以 `error()` 中断；指定了则原样返回给定值，队列状态不变。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?onEmpty g_fallback | any | | 可选，空队列时的返回值；未指定（或传入共享标记 `ycLang::NoneArg`）时空读中断 |

```lisp
s = ycQueue::LIFO()
s->put("a")->put("b")
s->get()
; => "b"
s->get(?onEmpty nil)
; => "a"
s->get(?onEmpty 'none)
; => none
s->get()
; *Error* ycQueue::LIFO->get: queue is empty
```

#### peek <sub>`method`</sub>

```text
s->peek(
    [ ?index n_position ]
    [ ?onEmpty g_fallback ]
)
=> any
```

返回指定位置的元素而不移除。`?index` 为 0-based：`0` 是下一个将被取出的元素（最新），正值向更早的元素数，负值从最早一端反向数（`-1` 为最后被取出的元素）。越界时以 `error()` 中断；空队列优先走 `?onEmpty` 契约，不判断索引。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?index n_position | int | 0 | 可选，0-based 位置；负值从最早一端数 |
| ?onEmpty g_fallback | any | | 可选，空队列时的返回值；未指定（或传入共享标记 `ycLang::NoneArg`）时空读中断 |

```lisp
s = ycQueue::LIFO()
s->put("a")->put("b")->put("c")
s->peek()
; => "c"
s->peek(?index 2)
; => "a"
s->peek(?index -1)
; => "a"
s->peek(?index 3)
; *Error* ycQueue::LIFO->peek: index 3 out of range (size 3)
ycQueue::LIFO()->peek(?index 5 ?onEmpty nil)
; => nil
```

#### size <sub>`method`</sub>

```text
s->size()
=> int
```

返回当前元素个数。

```lisp
s = ycQueue::LIFO()
s->size()
; => 0
s->put(1)
s->size()
; => 1
```

#### isEmpty <sub>`method`</sub>

```text
s->isEmpty()
=> t / nil
```

队列为空时返回 `t`，否则返回 `nil`。

```lisp
s = ycQueue::LIFO()
s->isEmpty()
; => t
s->put(1)
s->isEmpty()
; => nil
```

#### isFull <sub>`method`</sub>

```text
s->isFull()
=> t / nil
```

达到容量上限时返回 `t`；不限容量或尚未满时返回 `nil`。

```lisp
s = ycQueue::LIFO(?maxLimit 2)
s->isFull()
; => nil
s->put(1)->put(2)
s->isFull()
; => t
s->get()
s->isFull()
; => nil
```

#### maxLimit <sub>`method`</sub>

```text
s->maxLimit()
=> int / nil
```

返回构造时给定的容量上限；不限容量返回 `nil`。只读，上限在构造时固定。

```lisp
ycQueue::LIFO(?maxLimit 3)->maxLimit()
; => 3
ycQueue::LIFO()->maxLimit()
; => nil
```

#### clear <sub>`method`</sub>

```text
s->clear()
=> ycQueue::LIFO
```

移除全部元素，回到初始状态；容量上限保留。空队列上调用无副作用。返回 `self`，支持链式调用。

```lisp
s = ycQueue::LIFO(?maxLimit 3)
s->put(1)->put(2)->clear()->put(3)
s->toList()
; => (3)
s->maxLimit()
; => 3
```

#### toList <sub>`method`</sub>

```text
s->toList(
    [ ?clear g_flag ]
)
=> list
```

按出队顺序返回元素表：后进先出，即最新 → 最早。空队列返回 `nil`。

默认返回浅拷贝：顶层表是新副本，改写顶层元素不影响队列；嵌套成员与队列共享引用，改写会同时反映到队列。`?clear` 非 `nil` 时直接把内部表移交给调用方并清空队列，不拷贝；之后对返回表的修改与队列无关。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?clear g_flag | t / nil | nil | 可选，非 `nil` 时移交并清空队列 |

```lisp
s = ycQueue::LIFO()
s->put("a")->put("b")
s->toList()
; => ("b" "a")
s->size()
; => 2，队列未被清空

d = ycQueue::LIFO()
d->put(1)->put(2)
d->toList(?clear t)
; => (2 1)
d->size()
; => 0
```

## 顺序对照

| 操作 | `ycQueue::FIFO` | `ycQueue::LIFO` |
| --- | --- | --- |
| 连续 `put` `1` `2` `3` 后 `toList()` | `(1 2 3)` | `(3 2 1)` |
| `peek()` | `1`（最早） | `3`（最新） |
| `peek(?index -1)` | `3`（最新） | `1`（最早） |
| 连续 `get()` | `1` `2` `3` | `3` `2` `1` |

## 复杂度

| 操作 | 复杂度 | 说明 |
| --- | --- | --- |
| `put` | O(1) | 尾追加或头插，常数时间 |
| `get` | O(1) | 从表头摘除 |
| `size` / `isEmpty` / `isFull` / `maxLimit` | O(1) | 读取计数器或构造参数 |
| `clear` | O(1) | 换用新的空表头 |
| `peek(?index 0)` / `peek(?index -1)` | O(1) | 直接取表头或末格 |
| `peek` 其他位置 | O(n) | 从表头起遍历到目标位置 |
| `toList()` | O(n) | 复制整条元素表 |
| `toList(?clear t)` | O(1) | 移交内部表，不复制 |

[返回首页](../../README.md)
