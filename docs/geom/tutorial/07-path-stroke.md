# 第 7 章 路径描边

[返回目录](README.md) ｜ [上一章：面积与质心的稳定计算](06-area-and-centroid.md)

![描边的组成：边带、接头与端帽](img/stroke-parts.svg)

## 7.1 问题：把线加粗成面

给定一条中心线（折线或闭合环）和一个总宽度 `w`，求「距离中心线不超过 `w / 2` 的点集」。这就是描边。听起来只是把线往两边平移，实际有四个难点：

1. **接头**：折线转弯处，两条偏移线不相交，需要补一个角。
2. **端帽**：开放路径的起点和终点要封口，否则区域不闭合。
3. **自交**：急转弯或短边会让偏移线互相穿插，必须求并集，不能逐段拼。
4. **逆推**：给一个区域，判断它是不是等宽描边、中心线在哪。

## 7.2 偏移：沿法线走半个宽度

对方向向量 `d = (dx, dy)`，单位法线是：

```text
n = (-dy, dx) / |d|
```

中心线两侧的偏移点就是 `P ± n * (w / 2)`：

```lisp
; 可运行
procedure(_OffsetLine(g_a g_b n_dist "ggn")  ; -> list[Point]
    let((dx dy len nx ny)
        dx = g_b->x() - g_a->x()
        dy = g_b->y() - g_a->y()
        len = sqrt(dx * dx + dy * dy)
        nx = -dy / len
        ny = dx / len
        list(
            ycGeom::Point(list(
                g_a->x() + nx * n_dist
                g_a->y() + ny * n_dist))
            ycGeom::Point(list(
                g_b->x() + nx * n_dist
                g_b->y() + ny * n_dist)))
    )
)

_OffsetLine(ycGeom::Point(0:0) ycGeom::Point(10:0) 1.0)   ; => 两点，y 均为 1.0
```

一条边带就是「原边 + 两条偏移线」围成的矩形；整条路径的区域是所有边带、接头、端帽的并集。

## 7.3 接头：miter、bevel、round

在拐点 B 处，前一段的方向是 `d1`，后一段是 `d2`，两条外侧偏移线的交点是 miter 角：

```text
p = (A + n1 * h) + t * d1
t = ((B + n2 * h) - (A + n1 * h)) × d2 / (d1 × d2)
```

```lisp
; 可运行
procedure(_MiterPoint(g_a g_b g_c n_half "gggn")  ; -> Point | nil
    let((d1x d1y d2x d2y n1x n1y n2x n2y
         p1x p1y p2x p2y den tt)
        d1x = g_b->x() - g_a->x()
        d1y = g_b->y() - g_a->y()
        d2x = g_c->x() - g_b->x()
        d2y = g_c->y() - g_b->y()
        n1x = -d1y / sqrt(d1x * d1x + d1y * d1y)
        n1y = d1x / sqrt(d1x * d1x + d1y * d1y)
        n2x = -d2y / sqrt(d2x * d2x + d2y * d2y)
        n2y = d2x / sqrt(d2x * d2x + d2y * d2y)
        p1x = g_a->x() + n1x * n_half
        p1y = g_a->y() + n1y * n_half
        p2x = g_b->x() + n2x * n_half
        p2y = g_b->y() + n2y * n_half
        den = d1x * d2y - d1y * d2x
        unless(abs(den) <= 1e-12
            tt = ((p2x - p1x) * d2y - (p2y - p1y) * d2x) / den
            ycGeom::Point(list(p1x + tt * d1x p1y + tt * d1y))
        )
    )
)

A = ycGeom::Point(0:0)
B = ycGeom::Point(10:0)
C = ycGeom::Point(10:10)

_MiterPoint(A B C 1.0)->toSkill()   ; => (9.0 1.0)
```

三种接头风格：

| 风格 | 做法 | 特点 |
| --- | --- | --- |
| `'miter` | 取两条偏移线的交点 | 尖锐；转角很小时 miter 长度会爆炸 |
| `'bevel` | 直接用直线连接两个外角点 | 平切，面积略小 |
| `'round` | 以拐点为圆心画圆弧（多边形近似） | 圆滑，面积介于两者之间 |

miter 长度按 `1 / sin(θ/2)` 增长。工程上用 **miter limit** 限制它：超过阈值就退回 bevel，否则尖角会伸出去很远。

## 7.4 端帽：butt、square、round

开放路径的两端：

| 风格 | 做法 | 面积增量 |
| --- | --- | --- |
| `'butt` | 在端点处平切 | 0 |
| `'square` | 沿方向再延伸 `w / 2` | 每端 `w² / 4` |
| `'round` | 半圆（多边形近似） | 每端约 `π * w² / 8` |

闭合路径没有端帽，接头环绕一整圈。

## 7.5 自交：交给并集

急转弯时，前一段的边带和后一段的边带会重叠；短边的偏移线甚至会互相交叉。手工裁剪这些自交非常容易出错，正确做法是：

1. 每条边生成一条独立边带；
2. 每个接头、每个端帽生成独立多边形；
3. 全部丢进区域并集，重叠部分自动合并。

`ycGeom` 的 `Path->toRegion` 就是这么做的，所以它能处理任意折线而不会产生重叠碎片。

## 7.6 跑一遍

```lisp
; 可运行
openPath = ycGeom::Path(list(0:0 10:0) ?width 2)

openPath->toRegion()->area()          ; => 20.0，10 x 2
openPath->toRegion()->bBox()          ; => ((0.0 -1.0) (10.0 1.0))
openPath->toRegion(?cap 'round)->area()    ; => 23.12145
openPath->toRegion(?cap 'square)->area()   ; => 24.0
```

圆帽比平帽多出两个半圆，理论增量约 `π ≈ 3.14`；库用多边形近似圆，得到 `23.12`。

L 形折线比较三种接头：

```lisp
; 可运行
bentPath = ycGeom::Path(list(0:0 10:0 10:10) ?width 2)

bentPath->toRegion()->area()                    ; => 40.0，miter
bentPath->toRegion(?join 'bevel)->area()        ; => 39.5
bentPath->toRegion(?join 'round)->area()        ; => 39.78036
```

闭合路径没有端帽，面积等于「周长 x 宽度」：

```lisp
; 可运行
closedPath = ycGeom::Path(list(0:0 10:0 10:10 0:10 0:0) ?width 2)

closedPath->isClosed()                ; => t
closedPath->toRegion()->area()        ; => 80.0，40 x 2
```

## 7.7 逆推：从区域恢复路径

给定一个区域，判断它是否是等宽描边：

1. 找到一对平行且等距的边，推测中心线与宽度；
2. 用推测的中心线重新生成描边；
3. 与输入区域比对，重合才接受；
4. 候选不唯一（或存在洞、变宽、圆角）时返回 `nil`。

```lisp
; 可运行
bar = ycGeom::Polygon(list(0:0 10:0 10:4 0:4))
back = bar->toPath()

back->route()->toSkill()   ; => ((0.0 2.0) (10.0 2.0))
back->width()              ; => 4.0
```

闭合方形描边也能还原，只是中心线的起点和方向可能与原路径不同：

```lisp
; 可运行
outline = car(closedPath->toRegion()->polygons())->toPath()
outline->width()                  ; => 2.0
outline->isClosed()               ; => t
```

**逆推不是有损压缩。** 它只在形状确实由等宽描边生成时成功；多洞、变宽、圆角或 bevel 描边都会返回 `nil`，因为「中心线 + 宽度」表达不了这些形状。

## 7.8 边界与常见误解

- **圆角是多边形。** `'round` 用若干段直线近似圆弧，`?roundSegments` 控制段数；段数越多越圆，但顶点也越多。
- **宽度太小会被网格吃掉。** 描边区域经过布尔并集，特征尺寸小于布尔采样距离时可能退化；必要时给 `?grid`。
- **miter limit 必须有。** 没有上限的 miter 在极小夹角下会伸出极远，既不好看也会拖慢布尔运算。
- **闭合路径的首点。** 首点重复只表示闭合，不会产生额外的零长度边；`isClosed()` 会识别。

## 小结

- 描边 = 边带 + 接头 + 端帽的并集。
- 偏移沿单位法线走半个宽度；miter 是两条偏移线的交点，靠 miter limit 兜底。
- 自交不要手工裁剪，交给区域并集。
- 逆推靠「等宽 + 重合验证」，表达不了的形状返回 `nil`。

至此，从坐标、方向、键、面、布尔到描边的完整链路就讲完了。回到 [API 手册](../README.md) 可以查到每个接口的完整参数与边界。

[返回目录](README.md)
