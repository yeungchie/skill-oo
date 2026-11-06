# ycGeom 教程代码结果

| 套件 | 结果 |
| --- | --- |
| geom tutorial | PASS: 51 块代码 / 92 条标注 / 0 条不符 |

结果来自最近一次运行（2026-11-06）。教程里以首行 `; 可运行` 标记的代码块由 `tools/check_tutorial_code.py` 抽取成一份脚本，`; =>` 标注同时改写成值断言并逐条核对；数值按相对容差比较，列表逐项递归。当前 92 条标注全部通过，另有 1 条纯叙述标注（table 遍历顺序不作承诺）不参与核对。

运行方式（仓库根目录）：

```bash
python tools/check_tutorial_code.py
./bin/skill.sh skill-oo/tmp/tutorial_code.il
```

输出末尾的 `[TUTORIAL] annotations N checked / M skipped / K mismatched` 是汇总行；`K` 不为 0 时脚本以 `*Error*` 结束。增删或改写教程代码块后请同步本表。
