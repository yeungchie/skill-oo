# skill-oo 测试

本文件描述测试套件的运行方式。使用 API 见 [ycIO](../docs/io/README.md)、[ycPathLib](../docs/pathlib/README.md)、[ycRegEx](../docs/regex/README.md)、[ycSubProcess](../docs/subprocess/README.md)、[ycCodec](../docs/codec/core/README.md)、[ycJson](../docs/codec/json/README.md)、[ycYaml](../docs/codec/yaml/README.md)、[ycCsv](../docs/codec/csv/README.md)、[ycToml](../docs/codec/toml/README.md)、[ycIni](../docs/codec/ini/README.md)、[ycUtf8](../docs/utf8/README.md)、[ycString](../docs/string/README.md)、[ycUnits](../docs/units/README.md)、[ycRadix](../docs/radix/README.md)、[ycTextwrap](../docs/textwrap/README.md)、[ycTabulate](../docs/tabulate/README.md)、[ycDateTime](../docs/datetime/README.md)、[ycLog](../docs/log/README.md)、[ycLang](../docs/lang/README.md)、[ycQueue](../docs/queue/README.md)与 [ycGeom](../docs/geom/README.md)。

## 运行测试

在 Virtuoso（或独立 skill 解释器 `$CDS_INST_DIR/tools.lnx86/dfII/bin/skill`）中：

```lisp
load("<path-to-dir>/skill-oo/tests/pathlib/load.il")
load("<path-to-dir>/skill-oo/tests/io/load.il")
load("<path-to-dir>/skill-oo/tests/regex/load.il")
load("<path-to-dir>/skill-oo/tests/subprocess/load.il")
load("<path-to-dir>/skill-oo/tests/codec/load.il")
load("<path-to-dir>/skill-oo/tests/utf8/load.il")
load("<path-to-dir>/skill-oo/tests/string/load.il")
load("<path-to-dir>/skill-oo/tests/units/load.il")
load("<path-to-dir>/skill-oo/tests/radix/load.il")
load("<path-to-dir>/skill-oo/tests/textwrap/load.il")
load("<path-to-dir>/skill-oo/tests/tabulate/load.il")
load("<path-to-dir>/skill-oo/tests/datetime/load.il")
load("<path-to-dir>/skill-oo/tests/log/load.il")
load("<path-to-dir>/skill-oo/tests/queue/load.il")
load("<path-to-dir>/skill-oo/tests/lang/load.il")
load("<path-to-dir>/skill-oo/tests/geom/load.il")
```

跨套件加载顺序回归（先 tabulate 创建空壳，再加载 codec，最后重跑 tabulate）：

```lisp
load("<path-to-dir>/skill-oo/tests/codec/load_order.il")
```

成功时输出 `LOAD ORDER REGRESSION PASSED`。

log 套件首次加载时会先在未加载 `ycDateTime` 的会话里跑一次隔离检查（`tests/log/isolated.il`），成功输出 `YC LOG ISOLATED PASSED`；会话里已加载 `ycDateTime` 时该检查跳过。

> 修改某个 `libs/<模块>/src/` 后必须**重启 CIW** 再跑对应 `load.il`：同一会话内已加载过对应库时，`load.il` 会打印提示并复用内存中的旧代码，改动静默无效。

pathlib、io、regex 与 log 套件会在 cwd 下创建并清理各自的临时夹具；subprocess 套件直接运行短命令，codec、utf8、string、units、radix、textwrap、tabulate、datetime、lang 与 queue 套件仅做内存运算，均无夹具。

## 套件结果

各模块最近一次实测的用例数与结果见对应目录下的 `RESULTS.md`：

- [pathlib](pathlib/RESULTS.md)
- [io](io/RESULTS.md)
- [regex](regex/RESULTS.md)
- [subprocess](subprocess/RESULTS.md)
- [codec](codec/RESULTS.md)
- [utf8](utf8/RESULTS.md)
- [string](string/RESULTS.md)
- [units](units/RESULTS.md)
- [radix](radix/RESULTS.md)
- [textwrap](textwrap/RESULTS.md)
- [tabulate](tabulate/RESULTS.md)
- [datetime](datetime/RESULTS.md)
- [log](log/RESULTS.md)
- [queue](queue/RESULTS.md)
- [lang](lang/RESULTS.md)
- [geom](geom/RESULTS.md)

所有套件共用 `tests/kit.il` 里的断言、计时与汇总工具；各 `load.il` 先载入它，`test_init.il` 只保留模块专用辅助过程与一行 `_TestRun(...)`。每条测试用例的输出形如：

```
[  1/500]   0.088ms TEST PASSED - str: /a/b/c.txt
[ 10/500]   0.014ms TEST PASSED - str: a//b collapses empty parts
[100/500] 184.4ms TEST PASSED - Path: deep roundtrip
```

方括号里是「当前用例序号 / 该套件用例总数」，序号按总数的位数右对齐；随后是该用例表达式的实测耗时（`measureTime`；不足 1 秒用 ms，达到 1 秒用 s，达到 1 分钟用 m，达到 1 小时用 h）。耗时列同样按固定宽度对齐，小数位随量级收缩（如 `0.088ms` 与 `184.4ms`）；所在测试文件由上一行的 `[文件序号/文件总数] 文件名` 标明。耗时只统计被断言的表达式，构造输入等准备工作不计入该行（会计入文件耗时）；准备成本远大于断言本身时，把准备并入被断言表达式（如 `_Assert(abs(ycGeom::Polygon(list(...))->perimeter() - K) <= eps ...)`），否则该行只反映断言表达式的耗时。测试文件边界会打印文件进度与该文件耗时，套件结束时会打印：

```
PASS: <n> / FAIL: 0
TOTAL: <总耗时>
```

用例总数由 `_TestRun` 的第二个参数给出；实际条数与它不一致时会追加一行 `NOTE: expected <n> tests, ran <m>`，提醒同步更新总数。

有意触发库内诊断的用例（例如编译失败、回调抛错）会在输出前后加标记，红色 `*Error*` 与堆栈都落在这段范围内：

```
--- BEGIN expected error output: <来源说明> ---
*Error* ...
--- END expected error output ---
```

标记与窗口内的错误诊断都写到错误输出端口（`errport`），与库自身的 `*Error*` 同流；窗口打开期间产生的用例结果行会先暂存，等 `_TestErrorEnd` 写完结束标记后再按序打印到标准输出端口（`poport`）。写开始标记前会 `drain` 标准输出，结束标记后也会刷新，重定向或缓冲时两路内容不会错位。`errset(expr nil)` 用于静默捕获预期错误；测试文件载入失败时也由这组标记包住诊断信息。

有失败时以 `*Error* <模块名>: <m> test(s) failed` 终止（`ycPathLib` / `ycRegEx` / `ycSubProcess` / `ycCodec` / `ycJson` / `ycYaml` / `ycCsv` / `ycToml` / `ycIni` / `ycUtf8` / `ycString` / `ycUnits` / `ycRadix` / `ycTextwrap` / `ycTabulate` / `ycLog` / `ycQueue` / `ycLang` / `ycIO` / `ycGeom`）。
