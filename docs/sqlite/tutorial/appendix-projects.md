# 选做项目库

[返回目录](README.md)

这里不是必读章节，而是四个可以自己动手的练习方向。每个方向只给场景、起步 schema 和问题清单，不写完整答案。目标是把前面学过的表设计、主外键、事务、聚合、约束和索引，放到更接近真实工作的数据上。

## 怎么用

1. 在 `./sqlite-tutorial/` 下另建一个数据库，例如 `./sqlite-tutorial/projects.db`；
2. 把某个项目的 schema 粘进 `executeScript`；
3. 自己编一小批数据，够回答问题即可；
4. 先写查询，再考虑加索引；
5. 把结论写成几句中文，和查询一起保存。

不要在这些练习里修改 `drc.db`、`signoff.db`、`sch.db`、`layout.db`；它们是教程主线，不是草稿本。

## 四个方向

| 项目 | 主要练什么 | 难度 |
| --- | --- | --- |
| pin/bump 分配 | 多对多、唯一约束、交换事务 | 中 |
| PCM/WAT 长表 | 长表/宽表、透视、缺失值 | 中 |
| EM/IR 大表 | 规模、索引、汇总表 | 高 |
| IP/block 版本矩阵 | 多对多、状态、版本影响分析 | 中高 |

## 项目 1：pin/bump 分配

### 场景

一个 die 上有一组 bump，每个 bump 最终要分配给一个信号；每个信号也只能占一个 bump。分配结果要能查“哪个 bump 空着”“哪个信号还没分”“交换两个信号时会不会暂时冲突”。

### 起步 schema

```sql
create table bumps(
    bump_id text primary key,
    x       real not null,
    y       real not null,
    kind    text not null check(kind in ('signal', 'power', 'ground')),
    reserved integer not null default 0 check(reserved in (0, 1))
);

create table signals(
    signal_id integer primary key,
    name      text not null unique,
    direction text not null check(direction in ('input', 'output', 'inout')),
    voltage   text
);

create table assignments(
    bump_id   text primary key references bumps(bump_id),
    signal_id integer not null unique references signals(signal_id),
    assigned_at text not null,
    note      text
);
```

`assignments` 的主键保证一个 bump 只有一条分配；`signal_id` 上的 `unique` 保证一个信号只占一个 bump。两个约束合起来，才是完整的“一对一分配”。

### 问题清单

1. 插入几条 bump、signal 和 assignment，查当前分配表。
2. 用 `left join` 找未分配的 bump 和未分配的 signal。
3. 尝试把同一个 signal 分配到两个 bump，确认 `unique` 会拒绝；再尝试把两个 signal 分到同一个 bump。
4. 在事务里交换两个 signal 的 bump。直接写两条 `update` 可能在中途撞唯一约束；设计一个不会中途冲突的顺序，或先删后插。
5. 给 `bumps.reserved` 加过滤，查“可分配但还空着”的 bump。
6. 设计一张 `assignment_history` 表，记录每次交换的旧值、新值、时间和操作者。

### 验收

- 交换事务要么全部成功，要么全部回滚；
- 分配表里没有重复 bump，也没有重复 signal；
- 能解释为什么“先删两条再插两条”比“直接对调两条 update”更容易保证唯一约束。

## 项目 2：PCM/WAT 测量长表

### 场景

fab 的 PCM/WAT 数据通常是一行一个测量值：lot、wafer、site、device、param、value。分析时又希望按 device/site 把 `Vt`、`Idsat`、`Ioff` 放到同一行看。长表适合存储，宽表适合阅读，中间用 `group by` + `case` 做透视。

### 起步 schema

```sql
create table pcm_measurements(
    measurement_id integer primary key,
    lot        text not null,
    wafer      integer not null,
    site       integer not null,
    device     text not null,
    param      text not null,
    value      real,
    unit       text,
    measured_at text not null,
    unique(lot, wafer, site, device, param, measured_at)
);

create table pcm_specs(
    device text not null,
    param  text not null,
    lower_limit real,
    upper_limit real,
    primary key(device, param)
);
```

`value` 允许为空：测量失败和“测到 0”是两件事。`unique` 防止同一片、同一 site、同一参数在同一时间重复写入。

### 问题清单

1. 编 3 个 lot、每个 lot 2 片 wafer、每片 3 个 site 的数据；每个 device 至少 3 个 param。
2. 把 `Vt`、`Idsat`、`Ioff` 透视成一行一个 `(lot, wafer, site, device)`。
3. 用 `left join pcm_specs` 找超出上下限的测量；`value is null` 的测量单独列出来。
4. 按 lot 算每个 param 的平均值，和全部 lot 的总平均值比较。
5. 设计一个查询，找某个 lot 里缺失的 `(site, param)` 组合。
6. 为常用的 `(lot, wafer, param)` 查询设计索引，并用 `explain query plan` 看是否命中。

### 验收

- 能说清长表和宽表各自适合什么场景；
- 透视查询没有把缺失值误当成 0；
- 规格上下限为空时，表示“这一项不检查”，不是“上下限都是 0”。

## 项目 3：EM/IR 大表

### 场景

一次 EM/IR 分析可能产生几十万到几百万条 segment 记录。把所有明细直接塞进一个库，查询会变慢，备份也变大。这个项目练的是“先想清楚查询，再决定存明细还是存汇总”。

### 起步 schema

```sql
create table em_runs(
    run_id     integer primary key,
    label      text not null unique,
    imported_at text not null,
    tool       text
);

create table em_segments(
    run_id     integer not null references em_runs(run_id),
    net        text not null,
    segment_id integer not null,
    layer      text not null,
    length     real,
    current    real,
    ir_drop    real,
    em_limit   real,
    primary key(run_id, net, segment_id)
);

create table em_layer_summary(
    run_id     integer not null references em_runs(run_id),
    layer      text not null,
    segments   integer not null,
    max_current real,
    max_ir_drop real,
    violations integer not null,
    primary key(run_id, layer)
);
```

明细表的主键是 `(run_id, net, segment_id)`；汇总表按 `(run_id, layer)` 存每层的关键数字。汇总表不是重复数据，而是为了让看板查询不必每次扫全表。

### 问题清单

1. 编 2 次 run、每次 3 层、每层 20 条 segment 的数据。
2. 查每次 run 里 `ir_drop` 最大的 20 条 segment。
3. 按 layer 统计 segment 数、最大 current、最大 IR、超过 `em_limit` 的条数。
4. 把第 3 步的结果写入 `em_layer_summary`，用事务保证明细和汇总一致。
5. 给 `em_segments(run_id, layer, ir_drop)` 建索引，比较建索引前后的 `explain query plan`。
6. 设计一个“只保留最近 3 次 run 明细、旧 run 只留汇总”的清理策略；先写 SQL，不急着删除数据。

### 验收

- 能说清什么时候该查明细、什么时候该查汇总；
- 汇总表和明细表能在同一个事务里更新；
- 知道 `EXPLAIN QUERY PLAN` 是用来看“数据库准备怎么查”，不是看实际耗时。

## 项目 4：IP/block 版本矩阵

### 场景

一个 chip 项目会用很多 IP block，每个 IP 又有很多版本。一个版本可能被多个项目使用；一个项目也会使用多个 IP。除了“用了哪个版本”，还要记录状态、负责人和废弃标记。

### 起步 schema

```sql
create table ip_blocks(
    ip_id    integer primary key,
    name     text not null unique,
    category text not null
);

create table ip_versions(
    version_id integer primary key,
    ip_id      integer not null references ip_blocks(ip_id),
    version    text not null,
    released_at text,
    deprecated integer not null default 0 check(deprecated in (0, 1)),
    unique(ip_id, version)
);

create table projects(
    project_id integer primary key,
    name       text not null unique,
    owner      text not null
);

create table project_ip_versions(
    project_id integer not null references projects(project_id),
    version_id integer not null references ip_versions(version_id),
    status     text not null
               check(status in ('planned', 'integrated', 'verified', 'dropped')),
    owner      text,
    primary key(project_id, version_id)
);
```

`project_ip_versions` 是中间表：主键 `(project_id, version_id)` 保证同一项目不会重复登记同一版本；`status` 放在关系上，因为同一个版本在不同项目里的状态可能不同。

### 问题清单

1. 编 3 个 IP、每个 2 个版本、2 个项目，给项目分配不同版本和状态。
2. 查哪些项目还在使用 `deprecated = 1` 的版本。
3. 查每个 IP 被几个项目使用，按项目数从多到少排序。
4. 用 `cross join` + `left join` 找“某个项目缺了某个必需 IP”的组合。
5. 假设要把某个 IP 从 `v1` 升级到 `v2`，列出受影响的项目和当前状态。
6. 设计一张 `ip_compatibility` 表，记录两个版本是否兼容；讨论它和 `project_ip_versions` 的区别。

### 验收

- 能解释为什么 `status` 放在中间表，而不是放在 `ip_versions` 或 `projects`；
- 能查出“废弃版本仍在使用”的项目；
- 能区分“项目没用这个 IP”和“用了但状态是 dropped”。

## 共同验收清单

- [ ] 每张表都有主键；关系列有外键
- [ ] 至少有一个 `unique` 或 `check` 约束，并实际测试过它会拒绝坏数据
- [ ] 至少有一个事务，失败时能回滚
- [ ] 至少有一个 `group by` 汇总查询
- [ ] 至少有一个 `left join` 查询，能保留没有匹配的行
- [ ] 能用自己的话解释每个查询回答了什么业务问题

四个项目不需要全做。选一个最接近你日常工作的方向，把 schema 改到能回答自己的问题，比照着抄一遍更有价值。

[返回目录](README.md)
