# 第 3 章 规范点与键

[返回目录](README.md) ｜ [上一章：直线、线段与方向判定](02-lines-and-orientation.md) ｜ [下一章：多边形规范化与 keyhole](04-polygon-normalization.md)

![网格吸附后，相近的坐标落到同一个键](img/point-keys.svg)

*图 3.1 网格吸附后，相近的坐标落到同一个键。*

**本章目标**：分清「容差相等」与「键相等」，并写出点键、边键、环键；学完能理解布尔运算为什么依赖网格与精确键。

**上一章留下**：叉积定方向、参数方程求交、射线法判包含。

**这一章要用**：第 1 章的网格吸附——键要精确，所以先把近似坐标变成同一个坐标。

**教学函数与库接口**

| 教学函数 | 库里的等价接口 | 差别 |
| --- | --- | --- |
| `_PointKey` | 无公开的键接口 | 库内键由吸附后的坐标文本构成，不是取整后的整数键 |
| `_UndirEdgeKey` | 无公开接口 | 库内边键按两个端点的文本排序 |
| `_RingKeyText` | 无公开接口 | 库内用点键 / 边键查表比较，不做全旋转取最小串 |

## 3.1 问题：相等不等于可作键

上一章解决的是「两个点算不算同一个点」。但几何算法里还有另一类需求：**把点放进 table、去重、配对**。这类操作依赖的是「键相等」，不是容差判断。

先看一个反例。用坐标文本直接作键：

```lisp
; 可运行
key1 = lsprintf("%.17g|%.17g" 0.1 + 0.2 0.0)
key2 = lsprintf("%.17g|%.17g" 0.3 0.0)
key1 == key2    ; => nil
```

数学上两点相同，键却不同。反过来，如果键只保留少量有效位，两个真正不同的点又会撞成同一个键。**容差判断和键相等是两套语义，不能混用。**

一个可用的键必须满足：

1. **稳定**：同一位置无论经过什么运算，键都相同；
2. **可重复**：同一输入两次算出的键一致；
3. **方向无关**（针对边、环）：`A→B` 与 `B→A` 应得到同一个键；
4. **碰撞可控**：真不同的几何对象不应轻易撞键。

## 3.2 点键：先把坐标变成整数

最常用的做法是在吸附后的网格上取整：

```text
key(P) = "%d|%d" % (round(P.x / g), round(P.y / g))
```

```lisp
; 可运行
procedure(_PointKey(g_p n_grid "gn")  ; -> str
    ; 坐标除以网格后取整，用整数对作键
    lsprintf("%d|%d" round(g_p->x() / n_grid) round(g_p->y() / n_grid))
)

pts = list(ycGeom::Point(0:0)
    ycGeom::Point(1e-12:0)
    ycGeom::Point(1:0)
    ycGeom::Point(0:0))

tab = makeTable("tutorialPointKey" nil)
foreach(p pts tab[_PointKey(p 1.0)] = t)

keys = nil
foreach(k tab keys = cons(k keys))
length(keys)        ; => 2
keys                ; => 两个键（顺序由 table 决定）
```

四个点里，`(0, 0)` 出现两次、`(1e-12, 0)` 与它落在同一格，去重后只剩两个键。

几个实现细节：

- **取整规则要和库对齐。** 恰好在半格时 `round` 远离零；但半格附近受浮点表示误差影响，同一个点从两条路径算出来可能取到相邻格。库内网格吸附会修正这一步，而且键不是「取整后的整数」，是吸附后坐标的精确文本。教程用整数键是为了直观；需要与库一致时直接用 `?grid`，不要自己造键。
- **大坐标不要用 fixnum。** `round` 返回整数，超过 32 位范围会截断。坐标很大时改用 `sprintf(nil "%.0f" ...)` 生成整数字符串。
- **负零统一。** `-0.0` 与 `0.0` 应产出同一个键；取整后通常自然一致，但用文本格式化时要显式处理。

## 3.3 边键：无向

边没有方向：`A→B` 与 `B→A` 是同一条边。作键时把两个端点键按字典序排好再拼接：

```lisp
; 可运行
procedure(_UndirEdgeKey(g_a g_b n_grid "ggn")  ; -> str
    ; 无向边：两个端点键按字典序拼接，与方向无关
    let((ka kb)
        ka = _PointKey(g_a n_grid)
        kb = _PointKey(g_b n_grid)
        if(alphalessp(ka kb)
            lsprintf("%s~%s" ka kb)
            lsprintf("%s~%s" kb ka))
    )
)

_UndirEdgeKey(ycGeom::Point(0:0) ycGeom::Point(10:0) 1.0)   ; => "0|0~10|0"
_UndirEdgeKey(ycGeom::Point(10:0) ycGeom::Point(0:0) 1.0)   ; => "0|0~10|0"
```

![A→B 与 B→A 得到同一个边键](img/edge-key.svg)

*图 3.2 A→B 与 B→A 得到同一个边键。*

布尔运算里，这个键用来做两件事：拆分后的边去重；识别「同一条边被两个多边形共用」——后者是共边合并与洞拼接的基础（图 3.2）。

## 3.4 环键：旋转与方向归一

一条闭合环可以从任意顶点开始写，也可以顺时针或逆时针写。环键要把这些等价写法归一到同一个：

1. 每个顶点取点键；
2. 从每个位置开始绕一圈拼成字符串（相当于所有旋转）；
3. 正向、反向各算一遍；
4. 取字典序最小的那个作为环键。

`tconc` 把元素追加到列表尾部并返回一个头部 cons，`car` 取出真正的列表——这比头插再 `reverse` 更直观。

```lisp
; 可运行
procedure(_RingKeyText(l_pts n_grid "ln")  ; -> str
    ; 环键：旋转不变、方向不变，取字典序最小的写法
    let((keys n best text i j r)
        foreach(p l_pts keys = tconc(keys _PointKey(p n_grid)))
        keys = car(keys)
        n = length(keys)
        for(i 0 n - 1
            ; 从第 i 个顶点起正向绕一圈
            text = ""
            for(j 0 n - 1
                r = remainder(i + j n)
                text = strcat(text nth(r keys) ";")
            )
            when(best == nil || alphalessp(text best) best = text)
            ; 再从第 i 个顶点起反向绕一圈
            text = ""
            for(j 0 n - 1
                r = remainder(i - j n)
                when(r < 0 r = r + n)
                text = strcat(text nth(r keys) ";")
            )
            when(alphalessp(text best) best = text)
        )
        best
    )
)
```

环键的比较只需要几行：

```lisp
; 可运行
square = list(ycGeom::Point(0:0) ycGeom::Point(4:0)
    ycGeom::Point(4:4) ycGeom::Point(0:4))
rotated = list(ycGeom::Point(4:0) ycGeom::Point(4:4)
    ycGeom::Point(0:4) ycGeom::Point(0:0))
reversed = list(ycGeom::Point(0:0) ycGeom::Point(0:4)
    ycGeom::Point(4:4) ycGeom::Point(4:0))

_RingKeyText(square 1.0) == _RingKeyText(rotated 1.0)    ; => t
_RingKeyText(square 1.0) == _RingKeyText(reversed 1.0)   ; => t
```

这一版每次旋转都拼一遍整串，复杂度是 O(n²)；库内为了避免这一点，用点键 / 边键查表比较，不做全旋转取最小串。

![旋转与反向都归一到同一个环键](img/ring-rotation.svg)

*图 3.3 旋转与反向都归一到同一个环键。*

注意这是**精确键**：只要有一个顶点不同，环键就不同（图 3.3）。环的「近似相等」仍要用逐点容差比较，环键只负责快速判等与去重。

## 3.5 在 ycGeom 里的位置

- `?grid` 在布尔运算前把坐标吸附到网格，之后的交点、端点都落在格点上；
- 拆分边、去重、追踪环全部用精确键（点键与边键），不再做容差比较；
- 因此布尔运算的输入如果有「几乎重合但不重合」的边，必须给网格，否则键对不上；
- 输出 `Region` 里的多边形已经过规范化，同一环不会以旋转或反向的等价形式重复出现。

```lisp
; 可运行
polyA = ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))
polyB = ycGeom::Polygon('((2 2) (6 2) (6 6) (2 6)))
union = ycGeom::Region(list(polyA))->or(ycGeom::Region(list(polyB)))
length(union->polygons())   ; => 1
```

## 3.6 本章未展开的部分

| 省略内容 | 为什么省略 | 想深挖 |
| --- | --- | --- |
| 键的查表实现与冲突处理 | 教程版用字符串，够讲清归一化 | [API 手册](../README.md#ycgeompolygon-function-class) |
| 网格碰撞的定量分析 | 需要概率模型，超出教程范围 | 数值分析资料 |
| 大坐标下整数键的溢出 | 已提示改用文本键 | [第 1 章](01-tolerance-and-grid.md) |

## 3.7 边界与常见误解

- **键不可逆。** 从键回不到精确坐标；需要坐标时保留原始点，键只用于比较与索引。
- **网格越粗，碰撞越多。** 两个不同顶点被吸进同一格时，键相同，几何信息就被合并了。网格间距必须远小于最小特征尺寸，经验上取它的 1/10 以下。
- **键相等不代表几何相等。** 两个环键相同只能说明顶点序列一致，形状是否等价还要看坐标与方向。
- **不要用浮点文本作键。** `%.17g` 会把运算顺序的差异原样暴露；`%g` 又会丢掉有效位。先吸附，再取整。

## 小结

- 容差判断回答「像不像同一点」，键相等回答「是不是同一个索引」。
- 点键 = 网格整数坐标；边键 = 端点键排序；环键 = 旋转与方向归一后取字典序最小。
- 键是精确比较，所以必须先用网格把近似变成精确。
- 布尔运算的稳定性，很大程度上取决于键与网格是否配套。

下一章开始处理面：多边形怎么表示、怎么规范化，以及如何用一个环表示带洞的形状。

## 自检

1. 为什么「两个点在容差内相等」不能直接当 table 的键？
2. 边键为什么要排序？环键为什么要同时试正向和反向？

<details><summary>参考答案</summary>

1. 容差相等不满足传递性，键必须精确相等；否则同一位置的不同计算结果会落到不同键。
2. 边没有方向，`A→B` 与 `B→A` 是同一条边；环可以从任意顶点、任意方向写，必须归一到同一个串。

</details>

[返回目录](README.md) ｜ [下一章](04-polygon-normalization.md)
