# ycGeom

[返回首页](../../README.md)

平面点、线段、直线、keyhole 多边形与区域布尔运算。

## 概要

- 所有坐标在构造时转为浮点数；整数输入不会产生舍入误差，`toSkill()` 始终输出浮点坐标。
- `Polygon` 只保存一个闭合点列；洞用切割线并入外环，不保存 holes/seams 字段。
- `perimeter()` 默认扣除切割线，`?includeSeams t` 时按完整点列环计算。
- `Region` 表示 0..n 个多边形的并集，默认归一化为互不重叠的多边形集合。
- `?eps` 默认 `1e-9`；布尔运算支持 `?grid` 吸附。
- 对象按不可变值使用；运算返回新对象，不修改输入。
- 五类对象都提供 `toSkill()`，输出只含 list 与 float 的原生数据。

## 快速上手

```lisp
; 点与线段
g_p = ycGeom::Point(3 4)
g_q = ycGeom::Point(0 0)
g_p->distanceTo(g_q)
; => 5.0

g_s = ycGeom::Segment(ycGeom::Point(0 0) ycGeom::Point(10 0))
g_s->midpoint()->toSkill()
; => (5.0 0.0)
g_s->contains(ycGeom::Point(5 0))
; => t

; 无限直线
g_l = ycGeom::Line(ycGeom::Point(0 0) ycGeom::Point(0 10))
g_l->distanceTo(ycGeom::Point(5 3))
; => 5.0

; 正方形多边形
g_sq = ycGeom::Polygon(list(
    ycGeom::Point(0 0)
    ycGeom::Point(10 0)
    ycGeom::Point(10 10)
    ycGeom::Point(0 10)
))
g_sq->area()
; => 100.0
g_sq->contains(ycGeom::Point(5 5))
; => t

; 区域并集
g_a = ycGeom::Region(list(g_sq))
g_b = ycGeom::Region(list(ycGeom::Polygon(list(
    ycGeom::Point(5 5)
    ycGeom::Point(15 5)
    ycGeom::Point(15 15)
    ycGeom::Point(5 15)
))))
g_a->union(g_b)->area()
; => 175.0
```

## API 参考

### ycGeom::Point <sub>`function`</sub> <sub>`class`</sub>

构造不可变平面点。

```text
ycGeom::Point(n_x n_y)
=> Point
```

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `n_x` | num | | x 坐标 |
| `n_y` | num | | y 坐标 |

**返回值**

`Point` — 坐标已转为浮点数的新点。

**例程**

```lisp
ycGeom::Point(1 2)->toSkill()
; => (1.0 2.0)
```

**方法**

> 必须使用 `->` 符号调用方法。

#### x <sub>`method`</sub>

```text
Point->x()
=> float
```

返回 x 坐标。

#### y <sub>`method`</sub>

```text
Point->y()
=> float
```

返回 y 坐标。

#### distanceTo <sub>`method`</sub>

```text
Point->distanceTo(g_other)
=> float
```

返回与另一点的欧氏距离。

| 参数 | 说明 |
| --- | --- |
| `g_other` | 另一个 `Point` |

#### midpoint <sub>`method`</sub>

```text
Point->midpoint(g_other)
=> Point
```

返回与另一点的中点。

| 参数 | 说明 |
| --- | --- |
| `g_other` | 另一个 `Point` |

#### translate <sub>`method`</sub>

```text
Point->translate(n_dx n_dy)
=> Point
```

返回按给定位移平移后的新点。

| 参数 | 说明 |
| --- | --- |
| `n_dx` | x 位移 |
| `n_dy` | y 位移 |

#### equals <sub>`method`</sub>

```text
Point->equals(g_other [ ?eps ])
=> t | nil
```

判断两个点的坐标是否都在容差内相等。

| 参数 | 说明 |
| --- | --- |
| `g_other` | 另一个 `Point` |
| `?eps` | 容差；默认 `1e-9` |

```lisp
ycGeom::Point(0 0)->equals(ycGeom::Point(1e-10 0) ?eps 1e-9)
; => t
```

#### toSkill <sub>`method`</sub>

```text
Point->toSkill()
=> list[float]
```

返回 `(x y)` 浮点坐标列表。

### ycGeom::Segment <sub>`function`</sub> <sub>`class`</sub>

构造不可变线段；零长度合法。

```text
ycGeom::Segment(g_start g_end)
=> Segment
```

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `g_start` | Point | | 起点 |
| `g_end` | Point | | 终点 |

**返回值**

`Segment` — 新线段。

**例程**

```lisp
ycGeom::Segment(ycGeom::Point(0 0) ycGeom::Point(3 4))->length()
; => 5.0
```

**方法**

> 必须使用 `->` 符号调用方法。

#### start <sub>`method`</sub>

```text
Segment->start()
=> Point
```

返回起点。

#### end <sub>`method`</sub>

```text
Segment->end()
=> Point
```

返回终点。

#### length <sub>`method`</sub>

```text
Segment->length()
=> float
```

返回线段长度。

#### midpoint <sub>`method`</sub>

```text
Segment->midpoint()
=> Point
```

返回线段中点。

#### direction <sub>`method`</sub>

```text
Segment->direction()
=> list[float] | nil
```

返回单位方向向量；零长度线段返回 nil。

#### project <sub>`method`</sub>

```text
Segment->project(g_point)
=> Point
```

返回到无限直线的投影点，可能落在线段外；零长度线段返回起点。

| 参数 | 说明 |
| --- | --- |
| `g_point` | 待投影的 `Point` |

#### nearestPoint <sub>`method`</sub>

```text
Segment->nearestPoint(g_point)
=> Point
```

返回线段上距离查询点最近的点；零长度线段返回起点。

| 参数 | 说明 |
| --- | --- |
| `g_point` | 查询点 |

#### distanceTo <sub>`method`</sub>

```text
Segment->distanceTo(g_point)
=> float
```

返回到线段的距离。

| 参数 | 说明 |
| --- | --- |
| `g_point` | 查询点 |

#### contains <sub>`method`</sub>

```text
Segment->contains(g_point [ ?eps ])
=> t | nil
```

判断点是否落在线段上（含端点）。

| 参数 | 说明 |
| --- | --- |
| `g_point` | 查询点 |
| `?eps` | 容差；默认 `1e-9` |

#### bbox <sub>`method`</sub>

```text
Segment->bbox()
=> list[float]
```

返回 `(xmin ymin xmax ymax)`。

#### intersection <sub>`method`</sub>

```text
Segment->intersection(g_other [ ?eps ])
=> Point | Segment | nil
```

计算与 `Line` 或 `Segment` 的交点。

| 参数 | 说明 |
| --- | --- |
| `g_other` | `Line` 或 `Segment` |
| `?eps` | 容差；默认 `1e-9` |

- 唯一交点返回 `Point`。
- 共线重叠返回重叠部分 `Segment`。
- 零长度线段按点处理。
- 平行或无交返回 nil。
- 其他对象类型以 `error()` 中断。

#### toSkill <sub>`method`</sub>

```text
Segment->toSkill()
=> list[list[float]]
```

返回 `((sx sy) (ex ey))` 浮点坐标列表。

### ycGeom::Line <sub>`function`</sub> <sub>`class`</sub>

构造不可变无限直线。

```text
ycGeom::Line(g_p1 g_p2)
=> Line
```

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `g_p1` | Point | | 点一 |
| `g_p2` | Point | | 点二，必须与点一不同 |

**返回值**

`Line` — 新直线；构造点重合时以 `error()` 中断。

**例程**

```lisp
g_l = ycGeom::Line(ycGeom::Point(0 0) ycGeom::Point(10 0))
g_l->contains(ycGeom::Point(4 0))
; => t
```

**方法**

> 必须使用 `->` 符号调用方法。

#### a <sub>`method`</sub>

```text
Line->a()
=> float
```

返回规范化方程 `a*x+b*y+c=0` 的 `a`。

#### b <sub>`method`</sub>

```text
Line->b()
=> float
```

返回方程系数 `b`。

#### c <sub>`method`</sub>

```text
Line->c()
=> float
```

返回方程系数 `c`。

#### anchor <sub>`method`</sub>

```text
Line->anchor()
=> Point
```

返回直线上离原点最近的点。

#### direction <sub>`method`</sub>

```text
Line->direction()
=> list[float]
```

返回单位方向向量。

#### normal <sub>`method`</sub>

```text
Line->normal()
=> list[float]
```

返回单位法向量。

#### project <sub>`method`</sub>

```text
Line->project(g_point)
=> Point
```

返回到直线的投影点。

| 参数 | 说明 |
| --- | --- |
| `g_point` | 待投影点 |

#### distanceTo <sub>`method`</sub>

```text
Line->distanceTo(g_point)
=> float
```

返回到直线的距离。

| 参数 | 说明 |
| --- | --- |
| `g_point` | 查询点 |

#### contains <sub>`method`</sub>

```text
Line->contains(g_point [ ?eps ])
=> t | nil
```

判断点是否在直线上。

| 参数 | 说明 |
| --- | --- |
| `g_point` | 查询点 |
| `?eps` | 容差；默认 `1e-9` |

#### isParallel <sub>`method`</sub>

```text
Line->isParallel(g_line [ ?eps ])
=> t | nil
```

判断两条直线是否平行或重合。

| 参数 | 说明 |
| --- | --- |
| `g_line` | 另一条 `Line` |
| `?eps` | 容差；默认 `1e-9` |

#### intersection <sub>`method`</sub>

```text
Line->intersection(g_other [ ?eps ])
=> Point | Segment | nil
```

计算与 `Line` 或 `Segment` 的交点。

| 参数 | 说明 |
| --- | --- |
| `g_other` | `Line` 或 `Segment` |
| `?eps` | 容差；默认 `1e-9` |

- 唯一交点返回 `Point`。
- 与线段共线时返回重叠 `Segment`。
- 两条直线平行或重合返回 nil。
- 其他对象类型以 `error()` 中断。

#### toSkill <sub>`method`</sub>

```text
Line->toSkill()
=> list[list[float]]
```

返回 `((ax ay) (bx by))`，两点为 anchor 与 anchor 加单位方向。

### ycGeom::Polygon <sub>`function`</sub> <sub>`class`</sub>

构造不可变 keyhole 多边形。

```text
ycGeom::Polygon(l_points)
=> Polygon
```

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `l_points` | list[Point] | | 闭合点列；切割边以同一无向边往返出现两次表示 |

**返回值**

`Polygon` — 复制外层点列的新多边形；非法点列以 `error()` 中断。

**例程**

```lisp
g_p = ycGeom::Polygon(list(
    ycGeom::Point(0 0)
    ycGeom::Point(4 0)
    ycGeom::Point(4 4)
    ycGeom::Point(0 4)
))
g_p->area()
; => 16.0
```

**方法**

> 必须使用 `->` 符号调用方法。

#### points <sub>`method`</sub>

```text
Polygon->points()
=> list[Point]
```

返回内部点列；调用方不得原地修改。

#### edges <sub>`method`</sub>

```text
Polygon->edges()
=> list[Segment]
```

返回相邻点形成的所有边，包含切割边。

#### area <sub>`method`</sub>

```text
Polygon->area()
=> float
```

返回绝对面积；切割线往返抵消。

#### perimeter <sub>`method`</sub>

```text
Polygon->perimeter([ ?includeSeams ] [ ?eps ])
=> float
```

返回周长；默认扣除切割线。

| 参数 | 说明 |
| --- | --- |
| `?includeSeams` | t 时计入切割线；默认 nil |
| `?eps` | 容差；默认 `1e-9` |

#### centroid <sub>`method`</sub>

```text
Polygon->centroid()
=> Point
```

返回面积加权质心。

#### contains <sub>`method`</sub>

```text
Polygon->contains(g_point [ ?boundary ] [ ?eps ])
=> t | nil
```

判断点是否在多边形内或边界上。

| 参数 | 说明 |
| --- | --- |
| `g_point` | 查询点 |
| `?boundary` | `"inside"` 或 `"outside"`；默认 `"inside"` |
| `?eps` | 容差；默认 `1e-9` |

```lisp
g_p->contains(ycGeom::Point(0 0))
; => t
g_p->contains(ycGeom::Point(0 0) ?boundary "outside")
; => nil
```

#### onBoundary <sub>`method`</sub>

```text
Polygon->onBoundary(g_point [ ?includeSeams ] [ ?eps ])
=> t | nil
```

判断点是否在真实边界上；默认不把切割线视为边界。

| 参数 | 说明 |
| --- | --- |
| `g_point` | 查询点 |
| `?includeSeams` | t 时把切割线视为边界；默认 nil |
| `?eps` | 容差；默认 `1e-9` |

#### bbox <sub>`method`</sub>

```text
Polygon->bbox()
=> list[float]
```

返回 `(xmin ymin xmax ymax)`。

#### isClockwise <sub>`method`</sub>

```text
Polygon->isClockwise([ ?eps ])
=> t | nil
```

按 signed shoelace 判断点列是否顺时针。

| 参数 | 说明 |
| --- | --- |
| `?eps` | 容差；默认 `1e-9` |

#### reverse <sub>`method`</sub>

```text
Polygon->reverse()
=> Polygon
```

返回反向绕行的新多边形。

#### toSkill <sub>`method`</sub>

```text
Polygon->toSkill()
=> list[list[float]]
```

返回 `((x1 y1) (x2 y2) ...)`，保留切割线与点序。

### ycGeom::Region <sub>`function`</sub> <sub>`class`</sub>

构造不可变区域；空区域合法。

```text
ycGeom::Region(l_polygons [ ?normalize ] [ ?grid ] [ ?eps ])
=> Region
```

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `l_polygons` | list[Polygon] | | 多边形列表；nil 表示空区域 |
| `?normalize` | t \\| nil | `t` | 是否归一化为互不重叠 |
| `?grid` | num \\| nil | nil | 布尔网格；只影响归一化 |
| `?eps` | num \\| nil | nil | 容差；默认 `1e-9` |

**返回值**

`Region` — 新区域；非法参数以 `error()` 中断。

**例程**

```lisp
g_r = ycGeom::Region(nil)
g_r->isEmpty()
; => t
```

**方法**

> 必须使用 `->` 符号调用方法。

#### polygons <sub>`method`</sub>

```text
Region->polygons()
=> list[Polygon]
```

返回内部 Polygon 列表；调用方不得原地修改。

#### area <sub>`method`</sub>

```text
Region->area()
=> float
```

返回面积和；空区域为 `0.0`。

#### perimeter <sub>`method`</sub>

```text
Region->perimeter([ ?includeSeams ] [ ?eps ])
=> float
```

返回周长和；空区域为 `0.0`。

| 参数 | 说明 |
| --- | --- |
| `?includeSeams` | t 时计入切割线；默认 nil |
| `?eps` | 容差；默认 `1e-9` |

#### centroid <sub>`method`</sub>

```text
Region->centroid()
=> Point | nil
```

返回面积加权质心；空区域返回 nil。

#### contains <sub>`method`</sub>

```text
Region->contains(g_point [ ?boundary ] [ ?eps ])
=> t | nil
```

判断点是否属于区域。

| 参数 | 说明 |
| --- | --- |
| `g_point` | 查询点 |
| `?boundary` | `"inside"` 或 `"outside"`；默认 `"inside"` |
| `?eps` | 容差；默认 `1e-9` |

#### onBoundary <sub>`method`</sub>

```text
Region->onBoundary(g_point [ ?includeSeams ] [ ?eps ])
=> t | nil
```

判断点是否在区域边界上。

| 参数 | 说明 |
| --- | --- |
| `g_point` | 查询点 |
| `?includeSeams` | t 时计入切割线；默认 nil |
| `?eps` | 容差；默认 `1e-9` |

#### bbox <sub>`method`</sub>

```text
Region->bbox()
=> list[float] | nil
```

返回 `(xmin ymin xmax ymax)`；空区域返回 nil。

#### isEmpty <sub>`method`</sub>

```text
Region->isEmpty()
=> t | nil
```

空区域返回 t。

#### union <sub>`method`</sub>

```text
Region->union(g_other [ ?grid ] [ ?eps ])
=> Region
```

返回并集。

| 参数 | 说明 |
| --- | --- |
| `g_other` | 另一 `Region` |
| `?grid` | 布尔网格；默认 nil |
| `?eps` | 容差；默认 `1e-9` |

#### intersection <sub>`method`</sub>

```text
Region->intersection(g_other [ ?grid ] [ ?eps ])
=> Region
```

返回交集。

| 参数 | 说明 |
| --- | --- |
| `g_other` | 另一 `Region` |
| `?grid` | 布尔网格；默认 nil |
| `?eps` | 容差；默认 `1e-9` |

#### difference <sub>`method`</sub>

```text
Region->difference(g_other [ ?grid ] [ ?eps ])
=> Region
```

返回 `A-B`。

| 参数 | 说明 |
| --- | --- |
| `g_other` | 另一 `Region` |
| `?grid` | 布尔网格；默认 nil |
| `?eps` | 容差；默认 `1e-9` |

#### xor <sub>`method`</sub>

```text
Region->xor(g_other [ ?grid ] [ ?eps ])
=> Region
```

返回对称差。

| 参数 | 说明 |
| --- | --- |
| `g_other` | 另一 `Region` |
| `?grid` | 布尔网格；默认 nil |
| `?eps` | 容差；默认 `1e-9` |

#### toSkill <sub>`method`</sub>

```text
Region->toSkill()
=> list[list[list[float]]] | nil
```

返回每个 Polygon 一个坐标点列；空区域返回 nil。

## 几何约定

### keyhole 多边形

有洞多边形使用切割线把内环并入外环：

```text
外环若干点 -> 切割线进入内环 -> 内环一圈 -> 沿切割线返回 -> 外环剩余点
```

切割边通过同一无向边出现两次识别，不写入对象状态。外环与洞环应反向绕行；布尔运算输出保证这一点。

```lisp
g_hole = ycGeom::Polygon(list(
    ycGeom::Point(0 0)
    ycGeom::Point(10 0)
    ycGeom::Point(3 3)
    ycGeom::Point(3 7)
    ycGeom::Point(7 7)
    ycGeom::Point(7 3)
    ycGeom::Point(3 3)
    ycGeom::Point(10 0)
    ycGeom::Point(10 10)
    ycGeom::Point(0 10)
))
g_hole->area()
; => 84.0
g_hole->perimeter()
; => 56.0
```

### 区域归一化与布尔运算

- 默认 `?normalize t` 会把输入合并、裁剪为互不重叠的多边形集合。
- `?normalize nil` 信任输入已互不重叠，跳过归一化；此时面积按各块面积求和。
- `?grid` 把输入和输出顶点吸附到网格；吸附导致拓扑塌缩时以 `error()` 中断。
- 第一版布尔核心使用 O(n²) 求交，优先保证正确性与确定性。

```lisp
g_a = ycGeom::Polygon(list(
    ycGeom::Point(0 0) ycGeom::Point(4 0)
    ycGeom::Point(4 4) ycGeom::Point(0 4)
))
g_b = ycGeom::Polygon(list(
    ycGeom::Point(2 2) ycGeom::Point(6 2)
    ycGeom::Point(6 6) ycGeom::Point(2 6)
))
ycGeom::Region(list(g_a))->intersection(ycGeom::Region(list(g_b)))->area()
; => 4.0
```

[返回首页](../../README.md)
