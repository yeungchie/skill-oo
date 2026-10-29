# ycGeom

[返回首页](../../README.md)

Cadence SKILL++ 的平面几何库：点、线段、直线、矩形、keyhole 多边形与区域布尔运算。

## 概要

- 所有坐标在构造时转为浮点数；整数输入不会产生舍入误差，`toSkill()` 始终输出浮点坐标。
- 构造器只接受一个列表参数；点必须是 `Point` 或 `(x y)` 列表，不接受扁平数值坐标。`Point(1:2)` 与 `Point(list(1 2))` 等价；`Point(1 2)`、`Rect(list(0 0 1 2))` 非法，`Rect(list(0:0 1:2))` 合法。列表可嵌套并识别 Point/图形对象。
- `Polygon` 只保存闭合点列；构造时按默认容差规范化非连续顶点，近重合点合并，切割线端点由计算产生时也能稳定识别；连续重复点仍非法；洞用水平或垂直切割线并入外环。
- `perimeter()` 默认扣除切割线，`?includeSeams t` 时按完整点列环计算。
- `Region` 表示 0..n 个多边形的并集，默认归一化为互不重叠的多边形集合。
- `?eps` 默认 `1e-9`；比较同时吸收坐标量级的机器精度相对误差；`?grid` 为正数或 nil；参数类型不符或取值非法时以 `error()` 中断。
- `ConvertToGeomObject` 统一接收已有图形对象或坐标数组；已有对象按其 `toSkill()` 重建新对象返回，两点数组有歧义时必须用 `?as` 指定类型。
- 对象按不可变值使用；运算返回新对象，不修改输入。
- `Polygon`、`Rect`、`Region` 可互相作为布尔运算的右操作数；结果统一为 `Region`。
- 非退化 `Rect` 与 `Polygon` 可通过 `toPolygon()`/`toRect()` 互转；退化 `Rect` 无对应 `Polygon`。
- `Polygon->removeCollinear()` 可显式获取去除共线点后的多边形。
- 例程中 `; =>` 表示返回值；六类对象都提供 `toSkill()`，输出只含 list 与 float 的原生数据。

![ycGeom 六类对象概览](img/overview.svg)

*点、线段、直线、矩形、多边形与区域。*

## 快速上手

```lisp
; 点与线段
p = ycGeom::Point(3:4)
q = ycGeom::Point(0:0)
p->distanceTo(q)
; => 5.0

s = ycGeom::Segment(list(ycGeom::Point(0:0) ycGeom::Point(10:0)))
s->midpoint()->toSkill()
; => (5.0 0.0)
s->contains(ycGeom::Point(5:0))
; => t

; 无限直线
l = ycGeom::Line(list(ycGeom::Point(0:0) ycGeom::Point(0:10)))
l->distanceTo(ycGeom::Point(5:3))
; => 5.0

; 轴对齐矩形
rect = ycGeom::Rect(list(ycGeom::Point(10:4) ycGeom::Point(2:0)))
rect->toSkill()
; => ((2.0 0.0) (10.0 4.0))

; 正方形多边形
sq = ycGeom::Polygon(list(
    ycGeom::Point(0:0)
    ycGeom::Point(10:0)
    ycGeom::Point(10:10)
    ycGeom::Point(0:10)
))
sq->area()
; => 100.0
sq->contains(ycGeom::Point(5:5))
; => t

; 区域并集
a = ycGeom::Region(list(sq))
b = ycGeom::Region(list(ycGeom::Polygon(list(
    ycGeom::Point(5:5)
    ycGeom::Point(15:5)
    ycGeom::Point(15:15)
    ycGeom::Point(5:15)
))))
a->or(b)->area()
; => 175.0
```

## API 参考

### ycGeom::Point <sub>`function`</sub> <sub>`class`</sub>

```text
ycGeom::Point(l_data)
=> Point
```

**描述**

构造不可变平面点；只接受一个 `(x y)` 坐标列表（`1:2` 与 `list(1 2)` 等价）。传入多个位置参数或非法坐标以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| l_data | list | | 一个坐标列表；元素为两个数值 |

**返回值**

`Point` — 坐标已转为浮点数的新点。

**例程**

```lisp
ycGeom::Point(1:2)->toSkill()
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

```lisp
ycGeom::Point(3:4)->x()
; => 3.0
```

#### y <sub>`method`</sub>

```text
Point->y()
=> float
```

返回 y 坐标。

```lisp
ycGeom::Point(3:4)->y()
; => 4.0
```

#### distanceTo <sub>`method`</sub>

```text
Point->distanceTo(g_other)
=> float
```

返回与另一点的欧氏距离。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_other | Point | | 另一个 `Point` |

```lisp
ycGeom::Point(3:4)->distanceTo(ycGeom::Point(0:0))
; => 5.0
```

#### midpoint <sub>`method`</sub>

```text
Point->midpoint(g_other)
=> Point
```

返回与另一点的中点。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_other | Point | | 另一个 `Point` |

```lisp
ycGeom::Point(0:0)->midpoint(ycGeom::Point(4:2))->toSkill()
; => (2.0 1.0)
```

#### translate <sub>`method`</sub>

```text
Point->translate(
    n_dx
    n_dy
)
=> Point
```

返回按给定位移平移后的新点。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| n_dx | num | | x 位移 |
| n_dy | num | | y 位移 |

```lisp
ycGeom::Point(1:2)->translate(3 -1)->toSkill()
; => (4.0 1.0)
```

#### equals <sub>`method`</sub>

```text
Point->equals(
    g_other
    [ ?eps n_eps ]
)
=> t | nil
```

判断两个点的坐标是否都在绝对容差或机器精度相对容差内相等。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_other | Point | | 另一个 `Point` |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
ycGeom::Point(0:0)->equals(ycGeom::Point(1e-10:0) ?eps 1e-9)
; => t
```

#### toSkill <sub>`method`</sub>

```text
Point->toSkill()
=> list[float]
```

返回 `(x y)` 浮点坐标列表。

```lisp
ycGeom::Point(3:4)->toSkill()
; => (3.0 4.0)
```

### ycGeom::Segment <sub>`function`</sub> <sub>`class`</sub>

```text
ycGeom::Segment(l_data)
=> Segment
```

**描述**

构造不可变线段；只接受一个列表，列表元素为 `Point` 或 `(x y)` 列表，不接受扁平数值坐标；支持任意层嵌套。零长度合法，非法参数以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| l_data | list | | 两点列表或嵌套列表；每点为 `Point` 或 `(x y)` |

**返回值**

`Segment` — 新线段。

**例程**

```lisp
ycGeom::Segment(list(ycGeom::Point(0:0) ycGeom::Point(3:4)))->length()
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

```lisp
ycGeom::Segment(list(0:0 10:0))->start()->toSkill()
; => (0.0 0.0)
```

#### end <sub>`method`</sub>

```text
Segment->end()
=> Point
```

返回终点。

```lisp
ycGeom::Segment(list(0:0 10:0))->end()->toSkill()
; => (10.0 0.0)
```

#### length <sub>`method`</sub>

```text
Segment->length()
=> float
```

返回线段长度。

```lisp
ycGeom::Segment(list(0:0 10:0))->length()
; => 10.0
```

#### midpoint <sub>`method`</sub>

```text
Segment->midpoint()
=> Point
```

返回线段中点。

```lisp
ycGeom::Segment(list(0:0 10:0))->midpoint()->toSkill()
; => (5.0 0.0)
```

#### direction <sub>`method`</sub>

```text
Segment->direction()
=> list[float] | nil
```

返回单位方向向量；零长度线段返回 nil。

```lisp
ycGeom::Segment(list(0:0 10:0))->direction()
; => (1.0 0.0)
```

#### project <sub>`method`</sub>

```text
Segment->project(g_point)
=> Point | nil
```

返回线段上的正交投影点；垂足落在线段外返回 nil，零长度线段返回起点。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_point | Point | | 待投影的 `Point` |

```lisp
ycGeom::Segment(list(0:0 10:0))->project(ycGeom::Point(3:5))->toSkill()
; => (3.0 0.0)
```

#### nearestPoint <sub>`method`</sub>

```text
Segment->nearestPoint(g_point)
=> Point
```

返回线段上距离查询点最近的点；零长度线段返回起点。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_point | Point | | 查询点 |

```lisp
ycGeom::Segment(list(0:0 10:0))->nearestPoint(ycGeom::Point(15:5))->toSkill()
; => (10.0 0.0)
```

#### distanceTo <sub>`method`</sub>

```text
Segment->distanceTo(g_point)
=> float
```

返回到线段的距离。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_point | Point | | 查询点 |

```lisp
ycGeom::Segment(list(0:0 10:0))->distanceTo(ycGeom::Point(15:0))
; => 5.0
```

#### contains <sub>`method`</sub>

```text
Segment->contains(
    g_point
    [ ?eps n_eps ]
)
=> t | nil
```

判断点是否落在线段上（含端点）。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_point | Point | | 查询点 |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
ycGeom::Segment(list(0:0 10:0))->contains(ycGeom::Point(5:0))
; => t
```

#### bBox <sub>`method`</sub>

```text
Segment->bBox()
=> list[list[float]]
```

返回 `((xmin ymin) (xmax ymax))`。

```lisp
ycGeom::Segment(list(0:0 10:0))->bBox()
; => ((0.0 0.0) (10.0 0.0))
```

#### toRect <sub>`method`</sub>

```text
Segment->toRect()
=> Rect
```

返回以该线段包围盒为范围的轴对齐矩形；水平、垂直或零长度线段得到退化矩形（宽或高为 0）。

```lisp
ycGeom::Segment(list(0:0 10:0))->toRect()->toSkill()
; => ((0.0 0.0) (10.0 0.0))
```

#### intersection <sub>`method`</sub>

```text
Segment->intersection(
    g_other
    [ ?eps n_eps ]
    [ ?as g_kind ]
)
=> Point | Segment | nil
```

计算与 `Line` 或 `Segment` 的交点：唯一交点返回 `Point`；共线重叠返回重叠部分 `Segment`；零长度线段按点处理；平行或无交返回 nil；其他对象类型以 `error()` 中断。`g_other` 为两点数组时必须用 `?as` 指定按直线还是线段解释；对象输入若带 `?as`，必须与对象类型一致。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_other | Line / Segment / list | | `Line`、`Segment` 或两点数组 |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |
| ?as g_kind | sym / nil | nil | 数组目标类型；`'Line` 或 `'Segment` |

`?as` 的有效值：

| 有效值 | 结果 |
| --- | --- |
| `'Line` | 两点数组按无限直线解释 |
| `'Segment` | 两点数组按线段解释 |

```lisp
ycGeom::Segment(list(0:0 10:0))->intersection(ycGeom::Segment(list(5:-5 5:5)))->toSkill()
; => (5.0 0.0)

ycGeom::Segment(list(0:0 10:0))->intersection(list(5:-5 5:5) ?as 'Line)->toSkill()
; => (5.0 0.0)
```

#### toLine <sub>`method`</sub>

```text
Segment->toLine()
=> Line | nil
```

返回经过起终点的无限直线；零长度线段无对应直线，返回 nil。

```lisp
ycGeom::Segment(list(0:0 10:0))->toLine()->contains(ycGeom::Point(-5:0))
; => t
```

#### toSkill <sub>`method`</sub>

```text
Segment->toSkill()
=> list[list[float]]
```

返回 `((sx sy) (ex ey))` 浮点坐标列表。

```lisp
ycGeom::Segment(list(0:0 10:0))->toSkill()
; => ((0.0 0.0) (10.0 0.0))
```

### ycGeom::Line <sub>`function`</sub> <sub>`class`</sub>

```text
ycGeom::Line(l_data)
=> Line
```

**描述**

构造不可变无限直线；只接受一个列表，列表元素为 `Point` 或 `(x y)` 列表，不接受扁平数值坐标；支持任意层嵌套。两点重合或非法参数以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| l_data | list | | 两点列表或嵌套列表；每点为 `Point` 或 `(x y)`；两点重合时以 `error()` 中断 |

**返回值**

`Line` — 新直线；构造点重合时以 `error()` 中断。

**例程**

```lisp
l = ycGeom::Line(list(ycGeom::Point(0:0) ycGeom::Point(10:0)))
l->contains(ycGeom::Point(4:0))
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

```lisp
ycGeom::Line(list(0:0 10:0))->a()
; => 0.0
```

#### b <sub>`method`</sub>

```text
Line->b()
=> float
```

返回方程系数 `b`。

```lisp
ycGeom::Line(list(0:0 10:0))->b()
; => -1.0
```

#### c <sub>`method`</sub>

```text
Line->c()
=> float
```

返回方程系数 `c`。

```lisp
ycGeom::Line(list(0:0 10:0))->c()
; => 0.0
```

#### anchor <sub>`method`</sub>

```text
Line->anchor()
=> Point
```

返回直线上离原点最近的点。

```lisp
ycGeom::Line(list(0:0 10:0))->anchor()->toSkill()
; => (0.0 0.0)
```

#### direction <sub>`method`</sub>

```text
Line->direction()
=> list[float]
```

返回单位方向向量。

```lisp
ycGeom::Line(list(0:0 10:0))->direction()
; => (1.0 0.0)
```

#### normal <sub>`method`</sub>

```text
Line->normal()
=> list[float]
```

返回单位法向量。

```lisp
ycGeom::Line(list(0:0 10:0))->normal()
; => (0.0 -1.0)
```

#### project <sub>`method`</sub>

```text
Line->project(g_point)
=> Point
```

返回到直线的投影点。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_point | Point | | 待投影点 |

```lisp
ycGeom::Line(list(0:0 10:0))->project(ycGeom::Point(3:5))->toSkill()
; => (3.0 0.0)
```

#### distanceTo <sub>`method`</sub>

```text
Line->distanceTo(g_point)
=> float
```

返回到直线的距离。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_point | Point | | 查询点 |

```lisp
ycGeom::Line(list(0:0 10:0))->distanceTo(ycGeom::Point(3:5))
; => 5.0
```

#### contains <sub>`method`</sub>

```text
Line->contains(
    g_point
    [ ?eps n_eps ]
)
=> t | nil
```

判断点是否在直线上。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_point | Point | | 查询点 |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
ycGeom::Line(list(0:0 10:0))->contains(ycGeom::Point(4:0))
; => t
```

#### isParallel <sub>`method`</sub>

```text
Line->isParallel(
    g_line
    [ ?eps n_eps ]
)
=> t | nil
```

判断两条直线是否平行或重合。`g_line` 也接受两点数组，数组按无限直线解释。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_line | Line / list | | 另一条 `Line` 或两点数组 |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
ycGeom::Line(list(0:0 10:0))->isParallel(list(0:1 10:1))
; => t
```

#### intersection <sub>`method`</sub>

```text
Line->intersection(
    g_other
    [ ?eps n_eps ]
    [ ?as g_kind ]
)
=> Point | Segment | nil
```

计算与 `Line` 或 `Segment` 的交点：唯一交点返回 `Point`；与线段共线时返回重叠 `Segment`；两条直线平行或重合返回 nil；其他对象类型以 `error()` 中断。`g_other` 为两点数组时必须用 `?as` 指定按直线还是线段解释；对象输入若带 `?as`，必须与对象类型一致。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_other | Line / Segment / list | | `Line`、`Segment` 或两点数组 |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |
| ?as g_kind | sym / nil | nil | 数组目标类型；`'Line` 或 `'Segment` |

`?as` 的有效值：

| 有效值 | 结果 |
| --- | --- |
| `'Line` | 两点数组按无限直线解释 |
| `'Segment` | 两点数组按线段解释 |

```lisp
ycGeom::Line(list(0:0 10:0))->intersection(ycGeom::Line(list(5:-5 5:5)))->toSkill()
; => (5.0 0.0)

ycGeom::Line(list(0:0 10:0))->intersection(list(5:-5 5:5) ?as 'Segment)->toSkill()
; => (5.0 0.0)
```

#### toSkill <sub>`method`</sub>

```text
Line->toSkill()
=> list[list[float]]
```

返回 `((ax ay) (bx by))`，两点为 anchor 与 anchor 加单位方向。

```lisp
ycGeom::Line(list(0:0 10:0))->toSkill()
; => ((0.0 0.0) (1.0 0.0))
```

### ycGeom::Rect <sub>`function`</sub> <sub>`class`</sub>

```text
ycGeom::Rect(l_data)
=> Rect
```

**描述**

构造不可变轴对齐矩形；只接受一个列表，列表元素为 `Point` 或 `(x y)` 列表，不接受扁平数值坐标；支持任意层嵌套，并自动规范化为 `xmin`/`ymin`/`xmax`/`ymax`。零宽或零高合法；非法参数以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| l_data | list | | 两点列表或嵌套列表；每点为 `Point` 或 `(x y)` |

**返回值**

`Rect` — 新矩形；对角点顺序任意。

**例程**

```lisp
rect = ycGeom::Rect(list(ycGeom::Point(10:4) ycGeom::Point(2:0)))
rect->width()
; => 8.0
rect->toSkill()
; => ((2.0 0.0) (10.0 4.0))
```

**方法**

> 必须使用 `->` 符号调用方法。

#### xmin <sub>`method`</sub>

```text
Rect->xmin()
=> float
```

返回左边界 `xmin`。

```lisp
ycGeom::Rect(list(0:0 10:4))->xmin()
; => 0.0
```

#### ymin <sub>`method`</sub>

```text
Rect->ymin()
=> float
```

返回下边界 `ymin`。

```lisp
ycGeom::Rect(list(0:0 10:4))->ymin()
; => 0.0
```

#### xmax <sub>`method`</sub>

```text
Rect->xmax()
=> float
```

返回右边界 `xmax`。

```lisp
ycGeom::Rect(list(0:0 10:4))->xmax()
; => 10.0
```

#### ymax <sub>`method`</sub>

```text
Rect->ymax()
=> float
```

返回上边界 `ymax`。

```lisp
ycGeom::Rect(list(0:0 10:4))->ymax()
; => 4.0
```

#### width <sub>`method`</sub>

```text
Rect->width()
=> float
```

返回宽度 `xmax - xmin`。

```lisp
ycGeom::Rect(list(0:0 10:4))->width()
; => 10.0
```

#### height <sub>`method`</sub>

```text
Rect->height()
=> float
```

返回高度 `ymax - ymin`。

```lisp
ycGeom::Rect(list(0:0 10:4))->height()
; => 4.0
```

#### area <sub>`method`</sub>

```text
Rect->area()
=> float
```

返回面积 `width * height`；退化矩形为 0。

```lisp
ycGeom::Rect(list(0:0 10:4))->area()
; => 40.0
```

#### perimeter <sub>`method`</sub>

```text
Rect->perimeter()
=> float
```

返回周长 `2 * (width + height)`；退化矩形为 0。

```lisp
ycGeom::Rect(list(0:0 10:4))->perimeter()
; => 28.0
```

#### size <sub>`method`</sub>

```text
Rect->size(
    n_value
    [ ?dir g_dir ]
    [ ?ratio g_ratio ]
    [ ?corner g_corner ]
    [ ?miterLimit n_miterLimit ]
    [ ?roundSegments n_roundSegments ]
)
=> Region
```

按真实边界做方向涨缩，返回 Region；参数语义与 `Polygon->size` 相同。退化矩形返回空 Region，结果多边形已去除共线点。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| n_value | num | | 距离或倍率 |
| ?dir g_dir | sym / list[sym] | 'all | `'all`、`'left`、`'right`、`'up`、`'down` 或方向列表；默认 `'all` |
| ?ratio g_ratio | t / nil | nil | nil 时按绝对距离，t 时按 bBox 范围的倍率；1.0 无变化 |
| ?corner g_corner | sym | 'miter | `'miter`、`'round`、`'bevel`、`'none`；默认 `'miter` |
| ?miterLimit n_miterLimit | num / nil | 4 | miter 长度限制；默认 4 |
| ?roundSegments n_roundSegments | int / nil | 8 | 每 90 度圆角线段数；默认 8 |

`?dir` 的有效值：

| 有效值 | 结果 |
| --- | --- |
| `'left` | 选择左侧（x 最小）方向的边 |
| `'right` | 选择右侧（x 最大）方向的边 |
| `'up` | 选择上方（y 最大）方向的边 |
| `'down` | 选择下方（y 最小）方向的边 |
| `'all` | 四个方向全部选择 |

`?dir` 可传方向列表组合选择，但不能与 `'all` 混用；空列表、未知符号或非法类型以 `error()` 中断。

`?corner` 的有效值：

| 有效值 | 结果 |
| --- | --- |
| `'miter` | 尖角帽；超过 `?miterLimit` 时退回 bevel |
| `'round` | 圆弧帽，段数由 `?roundSegments` 控制 |
| `'bevel` | 斜切帽 |
| `'none` | 不补帽，只保留边带 |

其他值以 `error()` 中断。

```lisp
rect = ycGeom::Rect(list(0:0 10:10))
rect->size(1)->area()
; => 144.0
rect->size(1 ?dir 'right)->area()
; => 110.0
```

#### center <sub>`method`</sub>

```text
Rect->center()
=> Point
```

返回矩形中心点。

```lisp
ycGeom::Rect(list(0:0 10:4))->center()->toSkill()
; => (5.0 2.0)
```

#### centroid <sub>`method`</sub>

```text
Rect->centroid()
=> Point
```

返回矩形中心点，语义与 `center()` 相同。

```lisp
ycGeom::Rect(list(0:0 10:4))->centroid()->toSkill()
; => (5.0 2.0)
```

#### contains <sub>`method`</sub>

```text
Rect->contains(
    g_point
    [ ?boundary t_boundary ]
    [ ?eps n_eps ]
)
=> t | nil
```

判断点是否属于矩形。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_point | Point | | 查询点 |
| ?boundary t_boundary | str | "inside" | `"inside"` 或 `"outside"`；默认 `"inside"` |
| ?eps n_eps | num / nil | 1e-9 | 边界容差；默认 `1e-9` |

`?boundary` 的有效值：

| 有效值 | 结果 |
| --- | --- |
| `"inside"` | 边界上的点视为在内部 |
| `"outside"` | 边界上的点视为在外部 |

其他值以 `error()` 中断。

```lisp
ycGeom::Rect(list(0:0 10:4))->contains(ycGeom::Point(5:2))
; => t
ycGeom::Rect(list(0:0 10:4))->contains(ycGeom::Point(0:2) ?boundary "outside")
; => nil
```

#### onBoundary <sub>`method`</sub>

```text
Rect->onBoundary(
    g_point
    [ ?eps n_eps ]
)
=> t | nil
```

判断点是否在矩形边界上；退化矩形按线或点处理。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_point | Point | | 查询点 |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
ycGeom::Rect(list(0:0 10:4))->onBoundary(ycGeom::Point(0:2))
; => t
ycGeom::Rect(list(0:0 10:4))->onBoundary(ycGeom::Point(5:2))
; => nil
```

#### bBox <sub>`method`</sub>

```text
Rect->bBox()
=> list[list[float]]
```

返回 `((xmin ymin) (xmax ymax))`。

```lisp
ycGeom::Rect(list(0:0 10:4))->bBox()
; => ((0.0 0.0) (10.0 4.0))
```

#### or <sub>`method`</sub>

```text
Rect->or(
    g_other
    [ ?grid n_grid ]
    [ ?eps n_eps ]
)
=> Region
```

返回与另一二维图形的并集 Region。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_other | Polygon / Rect / Region / list | | 另一二维图形或点列 |
| ?grid n_grid | num / nil | nil | 布尔网格；默认 nil |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
ycGeom::Rect(list(0:0 4:4))->or(ycGeom::Rect(list(2:2 6:6)))->area()
; => 28.0
```

#### and <sub>`method`</sub>

```text
Rect->and(
    g_other
    [ ?grid n_grid ]
    [ ?eps n_eps ]
)
=> Region
```

返回与另一二维图形的交集 Region；无公共部分时返回空 Region。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_other | Polygon / Rect / Region / list | | 另一二维图形或点列 |
| ?grid n_grid | num / nil | nil | 布尔网格；默认 nil |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
ycGeom::Rect(list(0:0 4:4))->and(ycGeom::Rect(list(2:2 6:6)))->area()
; => 4.0
```

#### not <sub>`method`</sub>

```text
Rect->not(
    g_other
    [ ?grid n_grid ]
    [ ?eps n_eps ]
)
=> Region
```

返回二元差集 `A - B` 的 Region；`not` 不是一元补集。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_other | Polygon / Rect / Region / list | | 另一二维图形或点列 |
| ?grid n_grid | num / nil | nil | 布尔网格；默认 nil |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
ycGeom::Rect(list(0:0 4:4))->not(ycGeom::Rect(list(2:2 6:6)))->area()
; => 12.0
```

#### xor <sub>`method`</sub>

```text
Rect->xor(
    g_other
    [ ?grid n_grid ]
    [ ?eps n_eps ]
)
=> Region
```

返回与另一二维图形的对称差 Region。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_other | Polygon / Rect / Region / list | | 另一二维图形或点列 |
| ?grid n_grid | num / nil | nil | 布尔网格；默认 nil |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
ycGeom::Rect(list(0:0 4:4))->xor(ycGeom::Rect(list(2:2 6:6)))->area()
; => 24.0
```

#### toPolygon <sub>`method`</sub>

```text
Rect->toPolygon()
=> Polygon | nil
```

返回逆时针四角 Polygon；宽/高为 0 或面积低于按尺度计算的退化阈值的矩形返回 nil。

```lisp
ycGeom::Rect(list(0:0 4:4))->toPolygon()->toSkill()
; => ((0.0 0.0) (4.0 0.0) (4.0 4.0) (0.0 4.0))
```

#### toSkill <sub>`method`</sub>

```text
Rect->toSkill()
=> list[list[float]]
```

返回 `((xmin ymin) (xmax ymax))` 浮点坐标列表。

```lisp
ycGeom::Rect(list(0:0 10:4))->toSkill()
; => ((0.0 0.0) (10.0 4.0))
```

### ycGeom::Polygon <sub>`function`</sub> <sub>`class`</sub>

```text
ycGeom::Polygon(l_points)
=> Polygon
```

**描述**

构造不可变 keyhole 多边形；只接受一个列表，元素为 `Point` 或 `(x y)` 列表，不接受扁平数值坐标；支持任意层嵌套。构造时按默认容差规范化非连续顶点，近重合点合并到同一代表点，再识别切割边；切割边以同一无向边往返出现两次表示，且必须是水平或垂直方向；连续重复点与其他非法点列以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| l_points | list | | Point 列表或 (x y) 列表；不接受扁平数值坐标 |

**返回值**

`Polygon` — 规范化并复制点列的新多边形；非法点列以 `error()` 中断。

**例程**

```lisp
p = ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))
p->area()
; => 16.0

ycGeom::Polygon(list(0:0 4:0 4:4 0:4))->area()
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

```lisp
car(ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))->points())->toSkill()
; => (0.0 0.0)
```

#### edges <sub>`method`</sub>

```text
Polygon->edges()
=> list[Segment]
```

返回相邻点形成的所有边，包含切割边。

```lisp
length(ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))->edges())
; => 4
```

#### area <sub>`method`</sub>

```text
Polygon->area()
=> float
```

返回绝对面积；切割线往返抵消。

```lisp
ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))->area()
; => 16.0
```

#### perimeter <sub>`method`</sub>

```text
Polygon->perimeter(
    [ ?includeSeams g_includeSeams ]
    [ ?eps n_eps ]
)
=> float
```

返回周长；默认扣除切割线。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?includeSeams g_includeSeams | t / nil | nil | t 时计入切割线；默认 nil |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))->perimeter()
; => 16.0
```

#### centroid <sub>`method`</sub>

```text
Polygon->centroid()
=> Point
```

返回面积加权质心。

```lisp
ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))->centroid()->toSkill()
; => (2.0 2.0)
```

#### contains <sub>`method`</sub>

```text
Polygon->contains(
    g_point
    [ ?boundary t_boundary ]
    [ ?eps n_eps ]
)
=> t | nil
```

判断点是否在多边形内或边界上。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_point | Point | | 查询点 |
| ?boundary t_boundary | str | "inside" | `"inside"` 或 `"outside"`；默认 `"inside"` |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

`?boundary` 的有效值：

| 有效值 | 结果 |
| --- | --- |
| `"inside"` | 边界上的点视为在内部 |
| `"outside"` | 边界上的点视为在外部 |

其他值以 `error()` 中断。

```lisp
p = ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))
p->contains(ycGeom::Point(0:0))
; => t
p->contains(ycGeom::Point(0:0) ?boundary "outside")
; => nil
```

#### onBoundary <sub>`method`</sub>

```text
Polygon->onBoundary(
    g_point
    [ ?includeSeams g_includeSeams ]
    [ ?eps n_eps ]
)
=> t | nil
```

判断点是否在真实边界上；默认不把切割线视为边界。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_point | Point | | 查询点 |
| ?includeSeams g_includeSeams | t / nil | nil | t 时把切割线视为边界；默认 nil |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))->onBoundary(ycGeom::Point(0:2))
; => t
```

#### bBox <sub>`method`</sub>

```text
Polygon->bBox()
=> list[list[float]]
```

返回 `((xmin ymin) (xmax ymax))`。

```lisp
ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))->bBox()
; => ((0.0 0.0) (4.0 4.0))
```

#### toRect <sub>`method`</sub>

```text
Polygon->toRect()
=> Rect
```

返回以该多边形包围盒为范围的轴对齐矩形。

```lisp
ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))->toRect()->toSkill()
; => ((0.0 0.0) (4.0 4.0))
```

#### isClockwise <sub>`method`</sub>

```text
Polygon->isClockwise([ ?eps n_eps ])
=> t | nil
```

按 signed shoelace 判断点列是否顺时针。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))->isClockwise()
; => nil
```

#### reverse <sub>`method`</sub>

```text
Polygon->reverse()
=> Polygon
```

返回反向绕行的新多边形。

```lisp
ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))->reverse()->toSkill()
; => ((0.0 4.0) (4.0 4.0) (4.0 0.0) (0.0 0.0))
```

#### removeCollinear <sub>`method`</sub>

```text
Polygon->removeCollinear([ ?eps n_eps ])
=> Polygon
```

返回去除共线中间点后的新 Polygon；切割边端点保留。`?eps` 默认 `1e-9`。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?eps n_eps | num / nil | 1e-9 | 共线判断容差；默认 `1e-9` |

```lisp
ycGeom::Polygon('((0 0) (2 0) (4 0) (4 4) (0 4)))->removeCollinear()->toSkill()
; => ((0.0 0.0) (4.0 0.0) (4.0 4.0) (0.0 4.0))
```

#### size <sub>`method`</sub>

```text
Polygon->size(
    n_value
    [ ?dir g_dir ]
    [ ?ratio g_ratio ]
    [ ?corner g_corner ]
    [ ?miterLimit n_miterLimit ]
    [ ?roundSegments n_roundSegments ]
)
=> Region
```

按真实边界做方向涨缩，返回 Region。正值外涨、负值内缩；`?ratio t` 时把 `n_value` 当作正倍率。结果多边形已去除共线点。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| n_value | num | | 距离或倍率 |
| ?dir g_dir | sym / list[sym] | 'all | `'all`、`'left`、`'right`、`'up`、`'down` 或方向列表；默认 `'all` |
| ?ratio g_ratio | t / nil | nil | nil 时按绝对距离，t 时按 bBox 范围的倍率；1.0 无变化 |
| ?corner g_corner | sym | 'miter | `'miter`、`'round`、`'bevel`、`'none`；默认 `'miter` |
| ?miterLimit n_miterLimit | num / nil | 4 | miter 长度限制；默认 4 |
| ?roundSegments n_roundSegments | int / nil | 8 | 每 90 度圆角线段数；默认 8 |

`?dir` 的有效值：

| 有效值 | 结果 |
| --- | --- |
| `'left` | 选择左侧（x 最小）方向的边 |
| `'right` | 选择右侧（x 最大）方向的边 |
| `'up` | 选择上方（y 最大）方向的边 |
| `'down` | 选择下方（y 最小）方向的边 |
| `'all` | 四个方向全部选择 |

`?dir` 可传方向列表组合选择，但不能与 `'all` 混用；空列表、未知符号或非法类型以 `error()` 中断。

`?corner` 的有效值：

| 有效值 | 结果 |
| --- | --- |
| `'miter` | 尖角帽；超过 `?miterLimit` 时退回 bevel |
| `'round` | 圆弧帽，段数由 `?roundSegments` 控制 |
| `'bevel` | 斜切帽 |
| `'none` | 不补帽，只保留边带 |

其他值以 `error()` 中断。

![?dir 方向涨缩示意](img/size.svg)

*图：`?dir` 选择边，虚线为偏移后的边界。*

`?corner 'none` 只保留边带、不补拐角，可能产生十字/缺口轮廓。offset 可能拆分或合并图形，因此统一返回 Region。

```lisp
sq = ycGeom::Polygon('((0 0) (10 0) (10 10) (0 10)))
sq->size(1 ?corner 'miter)->bBox()
; => ((-1.0 -1.0) (11.0 11.0))
sq->size(1 ?dir 'right ?corner 'miter)->bBox()
; => ((0.0 0.0) (11.0 10.0))
sq->size(1.2 ?ratio t ?dir 'right)->bBox()
; => ((0.0 0.0) (12.0 10.0))
```

#### or <sub>`method`</sub>

```text
Polygon->or(
    g_other
    [ ?grid n_grid ]
    [ ?eps n_eps ]
)
=> Region
```

返回与另一二维图形的并集 Region。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_other | Polygon / Rect / Region / list | | 另一二维图形或点列；非法类型以 `error()` 中断 |
| ?grid n_grid | num / nil | nil | 布尔网格；默认 nil |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))->or(ycGeom::Polygon('((2 2) (6 2) (6 6) (2 6))))->area()
; => 28.0
```

#### and <sub>`method`</sub>

```text
Polygon->and(
    g_other
    [ ?grid n_grid ]
    [ ?eps n_eps ]
)
=> Region
```

返回与另一二维图形的交集 Region；无公共部分时返回空 Region。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_other | Polygon / Rect / Region / list | | 另一二维图形或点列；其他类型以 `error()` 中断 |
| ?grid n_grid | num / nil | nil | 布尔网格；默认 nil |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))->and(ycGeom::Polygon('((2 2) (6 2) (6 6) (2 6))))->area()
; => 4.0
```

#### not <sub>`method`</sub>

```text
Polygon->not(
    g_other
    [ ?grid n_grid ]
    [ ?eps n_eps ]
)
=> Region
```

返回与另一二维图形的二元差集 `A - B` 的 Region；`not` 不是一元补集。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_other | Polygon / Rect / Region / list | | 另一二维图形或点列；其他类型以 `error()` 中断 |
| ?grid n_grid | num / nil | nil | 布尔网格；默认 nil |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))->not(ycGeom::Polygon('((2 2) (6 2) (6 6) (2 6))))->area()
; => 12.0
```

#### xor <sub>`method`</sub>

```text
Polygon->xor(
    g_other
    [ ?grid n_grid ]
    [ ?eps n_eps ]
)
=> Region
```

返回与另一二维图形的对称差 Region。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_other | Polygon / Rect / Region / list | | 另一二维图形或点列；其他类型以 `error()` 中断 |
| ?grid n_grid | num / nil | nil | 布尔网格；默认 nil |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
a = ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))
b = ycGeom::Polygon('((2 2) (6 2) (6 6) (2 6)))
a->or(b)->area()
; => 28.0
a->not(b)->area()
; => 12.0
```

#### toPath <sub>`method`</sub>

```text
Polygon->toPath(
    [ ?orient g_orient ]
    [ ?eps n_eps ]
)
=> ycGeom::Path / nil
```

尝试把多边形逆推为等宽描边路径；成功时 `path->toRegion()` 与原多边形重合，无法还原或候选不唯一时返回 `nil`。支持矩形（含旋转矩形与正方形）、开放等宽折线与闭合等距环；多洞、变宽、圆角/bevel 描边、自交重叠等返回 `nil`。宽度由多边形推断，不接受宽度参数。

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?orient g_orient | sym | 'horizontal | 矩形候选方向；其他形状忽略该值 |
| ?eps n_eps | num / nil | nil | 容差，省略为 1e-9 |

`g_orient` 的有效值：

| 有效值 | 结果 |
| --- | --- |
| `'horizontal` / `'h` | 水平中心线；旋转矩形取更接近水平的一对边 |
| `'vertical` / `'v` | 垂直中心线；旋转矩形取更接近垂直的一对边 |

```lisp
g_rect = ycGeom::Polygon(list(0:0 10:0 10:4 0:4))
g_p = g_rect->toPath()
g_p->route()->toSkill()
; => ((0.0 2.0) (10.0 2.0))
g_p->width()
; => 4.0
g_rect->toPath(?orient 'v)->route()->toSkill()
; => ((5.0 0.0) (5.0 4.0))
g_rect->toPath(?orient 'h)->width()
; => 4.0
```

#### toSkill <sub>`method`</sub>

```text
Polygon->toSkill()
=> list[list[float]]
```

返回 `((x1 y1) (x2 y2) ...)`，保留切割线与点序。

```lisp
ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))->toSkill()
; => ((0.0 0.0) (4.0 0.0) (4.0 4.0) (0.0 4.0))
```

### ycGeom::Region <sub>`function`</sub> <sub>`class`</sub>

```text
ycGeom::Region(
    l_polygons
    [ ?normalize g_normalize ]
    [ ?grid n_grid ]
    [ ?eps n_eps ]
)
=> Region
```

**描述**

构造不可变区域，空区域合法；只接受一个列表，元素可为 Polygon、Rect、Region 或点列，点列中的点必须是 `Point` 或 `(x y)` 列表，不接受扁平数值坐标；支持嵌套列表。默认归一化为互不重叠的多边形集合；非法参数以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| l_polygons | list | | Polygon/Rect/Region/点列或嵌套列表；点列元素为 `Point` 或 `(x y)`；nil 表示空区域 |
| ?normalize g_normalize | t / nil | t | 是否归一化为互不重叠 |
| ?grid n_grid | num / nil | nil | 布尔网格；只影响归一化 |
| ?eps n_eps | num / nil | 1e-9 | 容差 |

**返回值**

`Region` — 新区域；非法参数以 `error()` 中断。

**例程**

```lisp
r = ycGeom::Region(nil)
r->isEmpty()
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

```lisp
length(ycGeom::Region(list(ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))))->polygons())
; => 1
```

#### area <sub>`method`</sub>

```text
Region->area()
=> float
```

返回面积和；空区域为 `0.0`。

```lisp
ycGeom::Region(list(ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))))->area()
; => 16.0
```

#### perimeter <sub>`method`</sub>

```text
Region->perimeter(
    [ ?includeSeams g_includeSeams ]
    [ ?eps n_eps ]
)
=> float
```

返回周长和；空区域为 `0.0`。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?includeSeams g_includeSeams | t / nil | nil | t 时计入切割线；默认 nil |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
ycGeom::Region(list(ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))))->perimeter()
; => 16.0
```

#### centroid <sub>`method`</sub>

```text
Region->centroid()
=> Point | nil
```

返回面积加权质心；空区域返回 nil。

```lisp
ycGeom::Region(list(ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))))->centroid()->toSkill()
; => (2.0 2.0)
```

#### contains <sub>`method`</sub>

```text
Region->contains(
    g_point
    [ ?boundary t_boundary ]
    [ ?eps n_eps ]
)
=> t | nil
```

判断点是否属于区域。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_point | Point | | 查询点 |
| ?boundary t_boundary | str | "inside" | `"inside"` 或 `"outside"`；默认 `"inside"` |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

`?boundary` 的有效值：

| 有效值 | 结果 |
| --- | --- |
| `"inside"` | 边界上的点视为在内部 |
| `"outside"` | 边界上的点视为在外部 |

其他值以 `error()` 中断。

```lisp
ycGeom::Region(list(ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))))->contains(ycGeom::Point(2:2))
; => t
```

#### onBoundary <sub>`method`</sub>

```text
Region->onBoundary(
    g_point
    [ ?includeSeams g_includeSeams ]
    [ ?eps n_eps ]
)
=> t | nil
```

判断点是否在区域边界上。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_point | Point | | 查询点 |
| ?includeSeams g_includeSeams | t / nil | nil | t 时计入切割线；默认 nil |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
ycGeom::Region(list(ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))))->onBoundary(ycGeom::Point(0:0))
; => t
```

#### bBox <sub>`method`</sub>

```text
Region->bBox()
=> list[list[float]] | nil
```

返回 `((xmin ymin) (xmax ymax))`；空区域返回 nil。

```lisp
ycGeom::Region(list(ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))))->bBox()
; => ((0.0 0.0) (4.0 4.0))
```

#### toRect <sub>`method`</sub>

```text
Region->toRect()
=> Rect | nil
```

返回区域包围盒对应的轴对齐矩形；空区域返回 nil。

```lisp
ycGeom::Region(list(ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))))->toRect()->toSkill()
; => ((0.0 0.0) (4.0 4.0))
```

#### isEmpty <sub>`method`</sub>

```text
Region->isEmpty()
=> t | nil
```

空区域返回 t。

```lisp
ycGeom::Region(nil)->isEmpty()
; => t
```

#### size <sub>`method`</sub>

```text
Region->size(
    n_value
    [ ?dir g_dir ]
    [ ?ratio g_ratio ]
    [ ?corner g_corner ]
    [ ?miterLimit n_miterLimit ]
    [ ?roundSegments n_roundSegments ]
)
=> Region
```

对 Region 中的每个 Polygon 独立做真实边界涨缩，再归一化合并。参数语义与 `Polygon->size` 相同；结果多边形已去除共线点。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| n_value | num | | 距离或倍率 |
| ?dir g_dir | sym / list[sym] | 'all | 方向或方向列表；默认 `'all` |
| ?ratio g_ratio | t / nil | nil | nil 时按绝对距离，t 时按 bBox 范围的倍率；1.0 无变化 |
| ?corner g_corner | sym | 'miter | 拐角风格；默认 `'miter` |
| ?miterLimit n_miterLimit | num / nil | 4 | miter 长度限制；默认 4 |
| ?roundSegments n_roundSegments | int / nil | 8 | 每 90 度圆角线段数；默认 8 |

`?dir` 的有效值：

| 有效值 | 结果 |
| --- | --- |
| `'left` | 选择左侧（x 最小）方向的边 |
| `'right` | 选择右侧（x 最大）方向的边 |
| `'up` | 选择上方（y 最大）方向的边 |
| `'down` | 选择下方（y 最小）方向的边 |
| `'all` | 四个方向全部选择 |

`?dir` 可传方向列表组合选择，但不能与 `'all` 混用；空列表、未知符号或非法类型以 `error()` 中断。

`?corner` 的有效值：

| 有效值 | 结果 |
| --- | --- |
| `'miter` | 尖角帽；超过 `?miterLimit` 时退回 bevel |
| `'round` | 圆弧帽，段数由 `?roundSegments` 控制 |
| `'bevel` | 斜切帽 |
| `'none` | 不补帽，只保留边带 |

其他值以 `error()` 中断。

```lisp
a = ycGeom::Polygon('((0 0) (10 0) (10 10) (0 10)))
r = ycGeom::Region(list(a))
r->size(1)->area()
; => 144.0
```

#### or <sub>`method`</sub>

```text
Region->or(
    g_other
    [ ?grid n_grid ]
    [ ?eps n_eps ]
)
=> Region
```

返回并集 `A ∪ B`。结果按 Region 的集合语义归一化；两区域都为空时结果为空 Region。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_other | Region / Polygon / Rect / list | | 另一二维图形或点列；其他类型以 `error()` 中断 |
| ?grid n_grid | num / nil | nil | 布尔网格；默认 nil |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
a = ycGeom::Region(list(ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))))
b = ycGeom::Region(list(ycGeom::Polygon('((2 2) (6 2) (6 6) (2 6)))))
a->or(b)->area()
; => 28.0
```

#### and <sub>`method`</sub>

```text
Region->and(
    g_other
    [ ?grid n_grid ]
    [ ?eps n_eps ]
)
=> Region
```

返回交集 `A ∩ B`。两区域无公共部分时返回空 Region；空 Region 的 `isEmpty()` 为 t。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_other | Region / Polygon / Rect / list | | 另一二维图形或点列；其他类型以 `error()` 中断 |
| ?grid n_grid | num / nil | nil | 布尔网格；默认 nil |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
a = ycGeom::Region(list(ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))))
b = ycGeom::Region(list(ycGeom::Polygon('((2 2) (6 2) (6 6) (2 6)))))
a->and(b)->area()
; => 4.0
```

#### not <sub>`method`</sub>

```text
Region->not(
    g_other
    [ ?grid n_grid ]
    [ ?eps n_eps ]
)
=> Region
```

返回二元差集 `A - B`：保留属于 A 且不属于 B 的部分。`not` 不是一元补集；B 为空时返回 A，A 为空时返回空 Region。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_other | Region / Polygon / Rect / list | | 另一二维图形或点列；其他类型以 `error()` 中断 |
| ?grid n_grid | num / nil | nil | 布尔网格；默认 nil |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
a = ycGeom::Region(list(ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))))
b = ycGeom::Region(list(ycGeom::Polygon('((2 2) (6 2) (6 6) (2 6)))))
a->not(b)->area()
; => 12.0
```

#### xor <sub>`method`</sub>

```text
Region->xor(
    g_other
    [ ?grid n_grid ]
    [ ?eps n_eps ]
)
=> Region
```

返回对称差：只属于 A 或只属于 B 的部分，等价于 `(A->or(B))->not(A->and(B))`。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_other | Region / Polygon / Rect / list | | 另一二维图形或点列；其他类型以 `error()` 中断 |
| ?grid n_grid | num / nil | nil | 布尔网格；默认 nil |
| ?eps n_eps | num / nil | 1e-9 | 容差；默认 `1e-9` |

```lisp
a = ycGeom::Region(list(ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))))
b = ycGeom::Region(list(ycGeom::Polygon('((2 2) (6 2) (6 6) (2 6)))))
a->xor(b)->area()
; => 24.0
```

#### toSkill <sub>`method`</sub>

```text
Region->toSkill()
=> list[list[list[float]]] | nil
```

返回每个 Polygon 一个坐标点列；空区域返回 nil。

### ycGeom::Route <sub>`function`</sub> <sub>`class`</sub>

```text
ycGeom::Route(
    l_points
    [ ?eps n_eps ]
)
=> ycGeom::Route
```

构造不可变零宽度折线。首尾点重合时视为闭合，内部去掉重复尾点；闭合折线至少需要 3 个不同点，开放折线至少需要 2 个点。除末点重复首点外，相邻重复点会以 `error()` 中断。

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| l_points | list | | `Point` 或 `(x y)` 列表；不接受扁平数值坐标 |
| ?eps n_eps | num / nil | nil | 闭合与重复点判定容差，省略为 1e-9 |

```lisp
g_r = ycGeom::Route(list(0:0 10:0 10:10))
g_r->toSkill()
; => ((0.0 0.0) (10.0 0.0) (10.0 10.0))
```

**方法**

> 必须使用 `->` 符号调用方法。

#### points <sub>`method`</sub>

```text
Route->points()
=> list[Point]
```

返回内部点列；闭合折线不含重复首点，调用方不得原地修改。

```lisp
length(ycGeom::Route(list(0:0 10:0 10:10))->points())
; => 3
```

#### isClosed <sub>`method`</sub>

```text
Route->isClosed()
=> t / nil
```

判断折线是否闭合。

```lisp
ycGeom::Route(list(0:0 10:0 10:10 0:0))->isClosed()
; => t
```

#### segments <sub>`method`</sub>

```text
Route->segments()
=> list[ycGeom::Segment]
```

返回逐段线段；开放折线 n-1 段，闭合折线 n 段（含末点到首点）。

```lisp
length(ycGeom::Route(list(0:0 10:0 10:10))->segments())
; => 2
```

#### length <sub>`method`</sub>

```text
Route->length()
=> float
```

返回中心线总长，使用补偿求和。

```lisp
ycGeom::Route(list(0:0 10:0 10:10))->length()
; => 20.0
```

#### bBox <sub>`method`</sub>

```text
Route->bBox()
=> list[list[float]]
```

返回 `((xmin ymin) (xmax ymax))`。

```lisp
ycGeom::Route(list(0:0 10:0 10:10))->bBox()
; => ((0.0 0.0) (10.0 10.0))
```

#### toRect <sub>`method`</sub>

```text
Route->toRect()
=> ycGeom::Rect
```

返回包围盒对应的矩形；零宽或零高合法。

```lisp
ycGeom::Route(list(0:0 10:0 10:10))->toRect()->toSkill()
; => ((0.0 0.0) (10.0 10.0))
```

#### toPolygon <sub>`method`</sub>

```text
Route->toPolygon()
=> ycGeom::Polygon
```

把闭合折线转为多边形；开放折线或无法构成合法多边形的点列以 `error()` 中断。

```lisp
ycGeom::Route(list(0:0 10:0 10:10 0:0))->toPolygon()->area()
; => 50.0
```

#### reverse <sub>`method`</sub>

```text
Route->reverse()
=> ycGeom::Route
```

返回反向折线，闭合状态不变。

```lisp
ycGeom::Route(list(0:0 10:0 10:10 0:0))->reverse()->toSkill()
; => ((10.0 10.0) (10.0 0.0) (0.0 0.0) (10.0 10.0))
```

#### toSkill <sub>`method`</sub>

```text
Route->toSkill()
=> list[list[float]]
```

转换为原生坐标列表；闭合时末尾补回首点。

```lisp
ycGeom::Route(list(0:0 10:0 10:10 0:0))->toSkill()
; => ((0.0 0.0) (10.0 0.0) (10.0 10.0) (0.0 0.0))
```

### ycGeom::Path <sub>`function`</sub> <sub>`class`</sub>

![Route 与 Path](img/route-path.svg)

```text
ycGeom::Path(
    l_data
    ?width n_width
    [ ?eps n_eps ]
)
=> ycGeom::Path
```

构造不可变带宽度描边。`l_data` 可为点列、`Route` 或 `toSkill()` 返回的 `(点列 宽度)` 状态列表；`?width` 为总宽度，向中心线两侧各偏移一半。默认描边为 `butt` 端帽与 `miter` 拐角。

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| l_data | Route / list | | 中心线、点列或 `(点列 宽度)` 状态列表 |
| ?width n_width | num | | 总宽度，必须大于 0；状态列表形式下省略 |
| ?eps n_eps | num / nil | nil | 点列容差，省略为 1e-9 |

```lisp
g_p = ycGeom::Path(list(0:0 10:0) ?width 2)
g_p->area()
; => 20.0
g_p->toRegion()->bBox()
; => ((0.0 -1.0) (10.0 1.0))
```

**方法**

> 必须使用 `->` 符号调用方法。

#### route <sub>`method`</sub>

```text
Path->route()
=> ycGeom::Route
```

返回中心线折线；调用方不得原地修改。

```lisp
ycGeom::Path(list(0:0 10:0) ?width 2)->route()->toSkill()
; => ((0.0 0.0) (10.0 0.0))
```

#### width <sub>`method`</sub>

```text
Path->width()
=> float
```

返回总宽度。

```lisp
ycGeom::Path(list(0:0 10:0) ?width 2)->width()
; => 2.0
```

#### isClosed <sub>`method`</sub>

```text
Path->isClosed()
=> t / nil
```

判断中心线是否闭合。

```lisp
ycGeom::Path(list(0:0 10:0 10:10 0:0) ?width 2)->isClosed()
; => t
```

#### toRegion <sub>`method`</sub>

```text
Path->toRegion(
    [ ?cap g_cap ]
    [ ?join g_join ]
    [ ?miterLimit n_miterLimit ]
    [ ?roundSegments n_roundSegments ]
    [ ?eps n_eps ]
    [ ?grid n_grid ]
)
=> ycGeom::Region
```

生成描边区域；边带、拐角帽与端帽通过 `Region` 并集合并。

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?cap g_cap | sym | 'butt | 端帽风格；闭合路径忽略 |
| ?join g_join | sym | 'miter | 拐角风格 |
| ?miterLimit n_miterLimit | num / nil | nil | miter 限制，省略为 4.0 |
| ?roundSegments n_roundSegments | int / nil | nil | 每 90 度圆角段数，省略为 8 |
| ?eps n_eps | num / nil | nil | 并集容差，省略为 1e-9 |
| ?grid n_grid | num / nil | nil | 网格；省略不吸附 |

`g_cap` 的有效值：

| 有效值 | 结果 |
| --- | --- |
| `'butt` | 端帽与中心线截面齐平 |
| `'square` | 端帽沿外向延伸半个宽度 |
| `'round` | 端帽为离散半圆 |

`g_join` 的有效值：

| 有效值 | 结果 |
| --- | --- |
| `'miter` | 外侧延伸到两条偏移线交点；超过 miter 限制时退化为 bevel |
| `'round` | 外侧为离散圆角 |
| `'bevel` | 外侧以直线切角 |

```lisp
g_p = ycGeom::Path(list(0:0 10:0) ?width 2)
g_p->toRegion(?cap 'round)->area()
; => 23.121445152258051
g_p->toRegion(?cap 'square)->bBox()
; => ((-1.0 -1.0) (11.0 1.0))
```

#### area <sub>`method`</sub>

```text
Path->area()
=> float
```

返回默认 `butt + miter` 描边的面积。

```lisp
ycGeom::Path(list(0:0 10:0) ?width 2)->area()
; => 20.0
```

#### perimeter <sub>`method`</sub>

```text
Path->perimeter(
    [ ?includeSeams g_includeSeams ]
    [ ?eps n_eps ]
)
=> float
```

返回默认描边的周长；`?includeSeams` 控制是否计入切割线。

```lisp
ycGeom::Path(list(0:0 10:0) ?width 2)->perimeter()
; => 24.0
```

#### centroid <sub>`method`</sub>

```text
Path->centroid()
=> ycGeom::Point / nil
```

返回默认描边的面积加权质心。

```lisp
ycGeom::Path(list(0:0 10:0) ?width 2)->centroid()->toSkill()
; => (5.0 0.0)
```

#### bBox <sub>`method`</sub>

```text
Path->bBox()
=> list[list[float]] / nil
```

返回默认描边的包围盒。

```lisp
ycGeom::Path(list(0:0 10:0) ?width 2)->bBox()
; => ((0.0 -1.0) (10.0 1.0))
```

#### toRect <sub>`method`</sub>

```text
Path->toRect()
=> ycGeom::Rect / nil
```

返回默认描边包围盒对应的矩形。

```lisp
ycGeom::Path(list(0:0 10:0) ?width 2)->toRect()->toSkill()
; => ((0.0 -1.0) (10.0 1.0))
```

#### contains <sub>`method`</sub>

```text
Path->contains(
    g_point
    [ ?boundary t_boundary ]
    [ ?eps n_eps ]
)
=> t / nil
```

判断点是否属于默认描边区域；`?boundary` 取 `"inside"` 或 `"outside"`。

```lisp
ycGeom::Path(list(0:0 10:0) ?width 2)->contains(ycGeom::Point(5:0))
; => t
```

#### onBoundary <sub>`method`</sub>

```text
Path->onBoundary(
    g_point
    [ ?includeSeams g_includeSeams ]
    [ ?eps n_eps ]
)
=> t / nil
```

判断点是否在默认描边边界上。

```lisp
ycGeom::Path(list(0:0 10:0) ?width 2)->onBoundary(ycGeom::Point(5:1))
; => t
```

#### toLegalPathPoints <sub>`method`</sub>

```text
Path->toLegalPathPoints(
    [ ?edge x_edge ]
    [ ?ratio n_ratio ]
    [ ?eps n_eps ]
)
=> list[list[float]]
```

返回本机可创建为单个 path 图形的点列。闭合路径的接缝落在拐角时，把接缝移到指定边的内部，使首末两段共线同向；结果仍是单个图形，但多一个共线点。开放路径或接缝已经共线时原样返回。该方法只保证点列本身不自交；应配 `butt` 端帽与 `miter` 拐角创建，使用圆帽/方帽时形状不再等价。中心线仍有其他自交或反向折返时以 `error()` 中断。

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| ?edge x_edge | int | 1 | 切开接缝的边序号，1-based |
| ?ratio n_ratio | num | 0.5 | 切点在边上的比例，(0,1) |
| ?eps n_eps | num / nil | nil | 共线与自交检查容差，省略为 1e-9 |

```lisp
g_s = ycGeom::Path(list(0:0 2:0 2:1 0:1 0:0) ?width 0.2)
g_s->toLegalPathPoints()
; => ((1.0 0.0) (2.0 0.0) (2.0 1.0) (0.0 1.0) (0.0 0.0) (1.0 0.0))
```

#### toSkill <sub>`method`</sub>

```text
Path->toSkill()
=> list
```

返回 `(点列 宽度)` 状态列表；闭合点列末尾重复首点。可直接传回 `ycGeom::Path(...)` 回构。

```lisp
g_p = ycGeom::Path(list(0:0 10:0) ?width 2)
ycGeom::Path(g_p->toSkill())->width()
; => 2.0
```

### ycGeom::ConvertToGeomObject <sub>`function`</sub>

```text
ycGeom::ConvertToGeomObject(
    g_value
    [ ?as g_kind ]
)
=> Point | Segment | Line | Rect | Polygon | Region
```

**描述**

把图形对象或原始坐标数组统一转换为几何对象。已有图形对象用其 `toSkill()` 构造新的同类对象返回（值等价，非同一实例）；指定 `?as` 时对象类型必须与目标一致，否则以 `error()` 中断。数组中的点必须是 `Point` 或 `(x y)` 列表，不接受扁平数值坐标；按 `?as` 指定类型构造，未指定时只接受无歧义的结构；`nil` 与空列表按空 `Region` 处理。两点数组同时可能表示线段、直线、矩形或区域，必须用 `?as` 明确目标，否则以 `error()` 中断。

**参数**

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| g_value | any | | 图形对象或坐标数组 |
| ?as g_kind | sym / nil | nil | 目标类型；nil 表示自动推断 |

`?as` 的有效值：

| 有效值 | 结果 |
| --- | --- |
| `'Point` | 一个坐标构造 `Point` |
| `'Segment` | 两点数组构造 `Segment` |
| `'Line` | 两点数组构造 `Line` |
| `'Rect` | 两点数组构造 `Rect` |
| `'Polygon` | 三个及以上点构造 `Polygon` |
| `'Region` | 两点数组按 `Rect` 处理，多点数组按 `Polygon` 处理，嵌套列表按 `Region` 处理 |

**返回值**

`Point` / `Segment` / `Line` / `Rect` / `Polygon` / `Region` — 按对象或数组构造的新对象；无法确定时以 `error()` 中断。

**例程**

```lisp
ycGeom::ConvertToGeomObject(1:2)->toSkill()
; => (1.0 2.0)

ycGeom::ConvertToGeomObject(list(0:0 1:1) ?as 'Rect)->area()
; => 1.0

ycGeom::ConvertToGeomObject(list(0:0 1:0 1:1 0:1))->area()
; => 1.0

ycGeom::ConvertToGeomObject(list(0:0 1:1))
; => 以 error() 中断（两点数组有歧义，需指定 ?as）
```

## 几何约定

```lisp
ycGeom::Region(list(ycGeom::Polygon('((0 0) (4 0) (4 4) (0 4)))))->toSkill()
; => (((0.0 0.0) (4.0 0.0) (4.0 4.0) (0.0 4.0)))
```

### keyhole 多边形

有洞多边形使用水平或垂直切割线把内环并入外环：

```text
外环若干点 -> 水平/垂直切割线进入内环 -> 内环一圈 -> 沿切割线返回 -> 外环剩余点
```

切割边通过同一无向边出现两次识别，不写入对象状态。切割线只能是水平或垂直方向，斜线切割以 `error()` 中断。外环与洞环应反向绕行；布尔运算输出保证这一点，并优先使用水平切割线。

![keyhole 多边形的外环、洞与水平切割线](img/keyhole.svg)

*图：外环通过水平切割线连接内洞。*

```lisp
hole = ycGeom::Polygon(list(
    ycGeom::Point(0:0)
    ycGeom::Point(10:0)
    ycGeom::Point(10:7)
    ycGeom::Point(7:7)
    ycGeom::Point(7:3)
    ycGeom::Point(3:3)
    ycGeom::Point(3:7)
    ycGeom::Point(7:7)
    ycGeom::Point(10:7)
    ycGeom::Point(10:10)
    ycGeom::Point(0:10)
))
hole->area()
; => 84.0
hole->perimeter()
; => 56.0
```

### 区域归一化与布尔运算

- 默认 `?normalize t` 会把输入合并、裁剪为互不重叠的多边形集合。
- `?normalize nil` 信任输入已互不重叠，跳过归一化；此时面积按各块面积求和。
- `?grid` 把输入和输出顶点吸附到网格；吸附导致拓扑塌缩时以 `error()` 中断。
- `Polygon`、`Rect`、`Region` 可互相参与 `or`/`and`/`not`/`xor`；右操作数也接受点列，结果统一为 `Region`。布尔上下文中的两点列表按对角矩形解释，三点及以上按多边形解释。退化 `Rect`（宽/高为 0 或面积低于按尺度计算的退化阈值）与空 `Region` 按空集处理。
- 默认归一化、布尔与 `size` 输出的多边形均已去除共线中间点；切割边端点保留。

![区域布尔运算：并、交、差、对称差](img/boolean.svg)

*图：两个区域 A、B 的四种布尔结果。*

```lisp
a = ycGeom::Polygon(list(
    ycGeom::Point(0:0) ycGeom::Point(4:0)
    ycGeom::Point(4:4) ycGeom::Point(0:4)
))
b = ycGeom::Polygon(list(
    ycGeom::Point(2:2) ycGeom::Point(6:2)
    ycGeom::Point(6:6) ycGeom::Point(2:6)
))
ycGeom::Region(list(a))->and(ycGeom::Region(list(b)))->area()
; => 4.0
ycGeom::Rect(list(0:0 4:4))->or(b)->area()
; => 28.0
```

[返回首页](../../README.md)
