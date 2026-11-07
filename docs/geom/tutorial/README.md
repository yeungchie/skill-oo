# ycGeom 图形算法教程

[返回 ycGeom API 手册](../README.md)

面向初学者的几何算法教程：讲清「问题为什么难、算法怎么想、程序怎么写」，再用 `ycGeom` 的公开接口把同一件事跑一遍。

本教程不是 API 手册——参数、返回值与完整方法列表以 [API 手册](../README.md) 为准；这里也不逐行讲解库内源码，教学实现只求清晰，不保证与库内实现逐句一致。

## 怎么读这本教程

**只想用库**（约 20 分钟）

1. 读[第 1 章](01-tolerance-and-grid.md)，弄清 `?eps` 与 `?grid`——这是所有接口的公共前提；
2. 查下面的「任务 → 接口」索引，直接跳到 API 手册对应类；
3. 结果不符合预期时，再回来读对应章节的原理。

**想理解实现**（约 2 小时）

按 1 → 8 章顺序读。每章开头的「本章目标」、结尾的「边界与常见误解」是重点。

**想改造算法 / 排查疑难**

先看[第 5 章](05-boolean-pipeline.md)（布尔流水线）与[第 6 章](06-area-and-centroid.md)（数值稳定性），再跟[第 8 章](08-end-to-end.md)走一遍完整案例。

## 任务 → 接口

手册按类组织，同一方法名会在多个类下重复出现（例如 `contains`）。下表链到所属**类**的小节；进入后按方法名查找。

| 我想做什么 | 用这个接口 | 原理见 |
| --- | --- | --- |
| 判断点是否在多边形内 | [`Polygon->contains`](../README.md#ycgeompolygon-function-class)（`?boundary` 控制边界点） | [2.5](02-lines-and-orientation.md) |
| 判断点是否在边界上 | [`Polygon->onBoundary`](../README.md#ycgeompolygon-function-class) / [`Rect->onBoundary`](../README.md#ycgeomrect-function-class) | [2.5](02-lines-and-orientation.md) |
| 求两条线段的交点 | [`Segment->intersection`](../README.md#ycgeomsegment-function-class)（`?as` 指定按直线还是线段） | [2.3](02-lines-and-orientation.md) |
| 求点到线段的距离 | [`Segment->distanceTo`](../README.md#ycgeomsegment-function-class) | [2.4](02-lines-and-orientation.md) |
| 求多边形面积 / 周长 | [`Polygon->area`](../README.md#ycgeompolygon-function-class) / [`Polygon->perimeter`](../README.md#ycgeompolygon-function-class)（`?includeSeams`） | [第 6 章](06-area-and-centroid.md) |
| 求质心 | [`Polygon->centroid`](../README.md#ycgeompolygon-function-class) | [6.5](06-area-and-centroid.md) |
| 并 / 交 / 差 / 对称差 | [`Region->or`](../README.md#ycgeomregion-function-class) / `and` / `not` / `xor` | [第 5 章](05-boolean-pipeline.md) |
| 不建对象直接做布尔 | [`ycGeom::Boolean`](../README.md#ycgeomboolean-function) | [第 5 章](05-boolean-pipeline.md) |
| 判断顺时针 / 反转 | [`Polygon->isClockwise`](../README.md#ycgeompolygon-function-class) / [`Polygon->reverse`](../README.md#ycgeompolygon-function-class) | [4.2](04-polygon-normalization.md) |
| 去掉共线点 | [`Polygon->removeCollinear`](../README.md#ycgeompolygon-function-class) | [4.3](04-polygon-normalization.md) |
| 构造带洞多边形 | [`Region->not`](../README.md#ycgeomregion-function-class) | [4.5](04-polygon-normalization.md) |
| 求包围盒 | `->bBox`（各图形类都有） | — |
| 判断两点是否重合 | [`Point->equals`](../README.md#ycgeompoint-function-class)（`?eps`） | [1.3](01-tolerance-and-grid.md) |
| 把折线加粗成区域 | [`Path->toRegion`](../README.md#ycgeompath-function-class)（`?cap` / `?join` / `?roundSegments`） | [第 7 章](07-path-stroke.md) |
| 从区域反推中心线 | [`Polygon->toPath`](../README.md#ycgeompolygon-function-class)（`?orient`） | [7.7](07-path-stroke.md) |
| 按方向涨缩多边形 | [`Polygon->size`](../README.md#ycgeompolygon-function-class)（`?dir` / `?ratio` / `?corner`） | [API 手册](../README.md#ycgeompolygon-function-class) |
| 矩形与多边形互转 | [`Polygon->toRect`](../README.md#ycgeompolygon-function-class) / [`Rect->toPolygon`](../README.md#ycgeomrect-function-class) | [API 手册](../README.md#ycgeomrect-function-class) |
| 从点列或已有对象重建 | [`ycGeom::ConvertToGeomObject`](../README.md#ycgeomconverttogeomobject-function) | [API 手册](../README.md#ycgeomconverttogeomobject-function) |

## 本教程用到的 SKILL 语法

第 1–2 章会用到大部分基础写法；不熟悉 SKILL 时先扫一眼这张表，遇到再回查。

| 写法 | 作用 | 首次出现 |
| --- | --- | --- |
| `let((a b) ...)` | 绑定局部变量，返回最后一个表达式的值 | [第 1 章](01-tolerance-and-grid.md) |
| `procedure(name (args) ...)` | 定义函数；形参可带类型串，如 `"nn"` 表示两个数值 | [第 1 章](01-tolerance-and-grid.md) |
| `if(test then else)` | 两分支；分支里有多条语句时用 `then` / `else` | [第 2 章](02-lines-and-orientation.md) |
| `when(cond ...)` / `unless(cond ...)` | 单分支：条件为真 / 为假时执行 | [第 2 章](02-lines-and-orientation.md) |
| `for(i 0 n - 1 ...)` | 计数循环 | [第 2 章](02-lines-and-orientation.md) |
| `foreach(x list ...)` | 依次遍历列表元素 | [第 3 章](03-canonical-points-and-keys.md) |
| `while(cond ...)` | 条件为真时重复 | [第 5 章](05-boolean-pipeline.md) |
| `case(key (val ...) ...)` | 按同一个值分派；没有匹配分支时返回 `nil` | [第 5 章](05-boolean-pipeline.md) |
| `lambda((x) ...)` | 匿名函数 | [第 7 章](07-path-stroke.md) |
| `list(...)` / `cons` / `tconc` | 构造列表；`tconc` 在循环里累积，`car` 取出结果 | [第 1 / 3 章](03-canonical-points-and-keys.md) |
| `nth(i list)` | 取第 i 个元素（从 0 开始） | [第 2 章](02-lines-and-orientation.md) |
| `car` / `cadr` | 取第一个 / 第二个元素 | [第 3 / 5 章](03-canonical-points-and-keys.md) |
| `length` / `reverse` | 列表长度 / 反转 | [第 1 / 4 章](01-tolerance-and-grid.md) |
| `mapcar(fn list)` | 对每个元素应用函数 | [第 7 章](07-path-stroke.md) |
| `alphalessp(a b)` | 字符串按字典序比较 | [第 3 章](03-canonical-points-and-keys.md) |
| `makeTable(name nil)` | 建哈希表 | [第 3 章](03-canonical-points-and-keys.md) |
| `lsprintf(fmt ...)` / `sprintf(nil fmt ...)` / `strcat` | 格式化与拼接字符串 | [第 3 章](03-canonical-points-and-keys.md) |
| `remainder(a b)` | 余数 | [第 3 章](03-canonical-points-and-keys.md) |
| `round` / `sqrt` / `abs` / `max` / `min` / `float` | 取整、开方、绝对值、最值、转浮点 | [第 1 / 2 章](01-tolerance-and-grid.md) |
| `error("...")` / `printf("...")` | 中断并报错 / 打印 | [第 5 / 6 章](05-boolean-pipeline.md) |
| `obj->method(...)` | 调用对象方法 | [第 1 章](01-tolerance-and-grid.md) |
| `?key value` | 关键字参数；省略时用默认值 | [第 1 章](01-tolerance-and-grid.md) |
| `0:0` | 二元数字列表的简写，等价于 `list(0 0)` | [第 1 章](01-tolerance-and-grid.md) |
| `; 可运行` / `; =>` | 可执行示例标记 / 期望结果 | [第 1 章](01-tolerance-and-grid.md) |

## 记法约定

- **坐标写法**：`0:0` 是 `list(0 0)` 的简写，只用于字面量；分量是表达式时写 `list(x y)`。构造器既收点对象、`(x y)` 列表，也收整个点列，例如 `Polygon(list(0:0 10:0 10:4 0:4))` 与 `Polygon('((0 0) (10 0) (10 4) (0 4)))` 等价。
- **可执行示例**：首行为 `; 可运行` 的代码块按文档顺序执行，后面的块可以复用前面的变量与函数；`; =>` 后面是期望结果。标了错误输出的块故意不标 `; 可运行`，避免中断整个脚本。
- **教学函数**：`_` 开头的函数（如 `_Cross2`、`_RayInside`）是教程为了讲清算法写的示例，不是 `ycGeom` 的公开接口；每章开头的表格会给出它们与库接口的对应关系。
- **容差常量**：教学代码里的 `1e-9` 对应库的 `?eps` 默认值；`1e-12` 只用于示例里的平行判定，库内用 `?eps` 派生的相对判据。示例常量是为了讲清思路，不是要求照抄。
- **打印精度**：`%A` 对浮点数只保留有限有效位；核验大坐标时用 `sprintf(nil "%.17g" x)`。
- **对象方法**：一律用 `->` 调用，例如 `poly->area()`；没有对象时可先用构造器建一个。

## 术语表

| 术语 | 一句话含义 | 详见 |
| --- | --- | --- |
| 容差 ε / `?eps` | 判断两个值是否算相等的阈值 | [1.2](01-tolerance-and-grid.md) |
| ulp | 相邻两个可表示浮点数之间的间隔 | [1.3](01-tolerance-and-grid.md) |
| 网格吸附 / `?grid` | 把坐标量化到固定间距的整数倍 | [1.4](01-tolerance-and-grid.md) |
| 键 | 可精确比较的索引值；分点键、边键、环键 | [第 3 章](03-canonical-points-and-keys.md) |
| 规范形 | 去重复点、去共线点、统一方向后的点列 | [4.1](04-polygon-normalization.md) |
| 环 | 闭合点列；外环逆时针，洞顺时针 | [4.1](04-polygon-normalization.md) |
| keyhole | 用一条往返切割线把洞并入外环的表示 | [4.5](04-polygon-normalization.md) |
| 有符号面积 | 鞋带公式的结果，符号表示方向 | [4.2](04-polygon-normalization.md) |
| 连通分量 | 布尔结果中互不相连的多边形块 | [5.1](05-boolean-pipeline.md) |
| 拆边 | 按交点把边切成小段 | [5.4](05-boolean-pipeline.md) |
| 分类 | 用边两侧的采样点判断该边是否属于结果 | [5.5](05-boolean-pipeline.md) |
| 追踪 | 把保留下来的有向边接成闭环 | [5.6](05-boolean-pipeline.md) |
| 嵌套 | 按包含深度区分外环与洞 | [5.8](05-boolean-pipeline.md) |
| 采样偏移 | 从边中点向两侧取样时走的距离 | [5.5](05-boolean-pipeline.md) |
| 补偿求和 | 把每步舍入误差记下来，最后补回 | [6.4](06-area-and-centroid.md) |
| 质心 | 面积加权的中心 | [6.5](06-area-and-centroid.md) |
| 描边 | 把中心线加粗成区域 | [7.1](07-path-stroke.md) |
| 法线 | 与方向垂直的单位向量 | [7.2](07-path-stroke.md) |
| 接头 / miter / bevel / round | 拐角处的补角方式 | [7.3](07-path-stroke.md) |
| miter limit | 限制 miter 长度的阈值 | [7.3](07-path-stroke.md) |
| 端帽 / butt / square / round | 开放路径两端的封口方式 | [7.4](07-path-stroke.md) |
| 自交 | 偏移线互相穿插 | [7.5](07-path-stroke.md) |
| 逆推 | 从区域恢复中心线与宽度 | [7.7](07-path-stroke.md) |

## 阅读前需要什么

- **SKILL 基本语法**：`let`、`procedure`、`if` / `when` / `unless`、列表、`->` 方法调用、`?key` 关键字参数；上表可当速查，不要求提前背下来。
- **浮点数常识**：知道十进制小数不能精确表示、坐标越大绝对精度越差即可；第 1 章会从头解释。
- **不需要计算几何基础**：叉积、射线法、鞋带公式都在正文里推导。

## 章节

| 章 | 主题 | 你会学到 |
| --- | --- | --- |
| [1](01-tolerance-and-grid.md) | 坐标、容差与网格 | 浮点误差从哪来；`?eps` 与 `?grid` 各自解决什么问题 |
| [2](02-lines-and-orientation.md) | 直线、线段与方向判定 | 叉积定方向；线段相交；射线法判断点是否在多边形内 |
| [3](03-canonical-points-and-keys.md) | 规范点与键 | 为什么「相等」不等于「可作键」；点键、边键与环键 |
| [4](04-polygon-normalization.md) | 多边形规范化与 keyhole | 去重、共线清理、定向；用切割线表示洞 |
| [5](05-boolean-pipeline.md) | 区域布尔流水线 | 拆边、分类、追踪环、嵌套判定 |
| [6](06-area-and-centroid.md) | 面积与质心的稳定计算 | 鞋带公式、平移、补偿求和 |
| [7](07-path-stroke.md) | 路径描边 | 偏移、接头与端帽；描边转区域与逆推 |
| [8](08-end-to-end.md) | 综合案例 | 把构造、布尔、面积、质心与输出串成一条链 |

## 跨章资产

示例按章顺序执行，后面的章会复用前面的变量与教学函数：

- 第 5 章的 `_EdgeInResult` 调用第 2 章的 `_RayInside`，`_TraceLoop` 调用第 3 章的 `_PointKey`，示例还用到第 4 章的 `_SignedArea`；
- 同名变量会在不同章重新赋值，例如 `square`（第 3、4、6 章）、`poly`（第 1、4 章）、`ring`（第 2 章）；跳读时先执行对应章开头的块；
- 每章开头的「教学函数与库接口」表会列出该章新增的函数，遇到不认识的 `_` 函数先回查上一章。

只跑单个代码块时，按「依赖」列补齐上一章的变量即可；第 8 章只依赖库接口，可以独立运行。
