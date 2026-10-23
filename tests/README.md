# skill-oo 测试

本文件描述测试套件的运行方式。使用 API 见 [ycPathLib](../docs/pathlib/README.md)、[ycRegEx](../docs/regex/README.md)、[ycSubProcess](../docs/subprocess/README.md)、[ycCodec](../docs/codec/core/README.md)、[ycJson](../docs/codec/json/README.md)、[ycYaml](../docs/codec/yaml/README.md)、[ycCsv](../docs/codec/csv/README.md)、[ycToml](../docs/codec/toml/README.md)、[ycIni](../docs/codec/ini/README.md)、[ycUtf8](../docs/utf8/README.md)、[ycString](../docs/string/README.md)、[ycUnits](../docs/units/README.md)、[ycTextwrap](../docs/textwrap/README.md)与 [ycTabulate](../docs/tabulate/README.md)。

## 运行测试

在 Virtuoso（或独立 skill 解释器 `$CDS_INST_DIR/tools.lnx86/dfII/bin/skill`）中：

```lisp
load("<path-to-dir>/skill-oo/tests/pathlib/load.il")
load("<path-to-dir>/skill-oo/tests/regex/load.il")
load("<path-to-dir>/skill-oo/tests/subprocess/load.il")
load("<path-to-dir>/skill-oo/tests/codec/load.il")
load("<path-to-dir>/skill-oo/tests/utf8/load.il")
load("<path-to-dir>/skill-oo/tests/string/load.il")
load("<path-to-dir>/skill-oo/tests/units/load.il")
load("<path-to-dir>/skill-oo/tests/textwrap/load.il")
load("<path-to-dir>/skill-oo/tests/tabulate/load.il")
```

> 修改某个 `libs/<模块>/src/` 后必须**重启 CIW** 再跑对应 `load.il`：同一会话内已加载过对应库时，`load.il` 会打印提示并复用内存中的旧代码，改动静默无效。

pathlib 与 regex 套件会在 cwd 下创建并清理各自的临时夹具；subprocess 套件直接运行短命令，codec、utf8、string、units、textwrap 与 tabulate 套件仅做内存运算，均无夹具。期望输出：

```
…（逐条 TEST PASSED - …）

PASS: <n> / FAIL: 0
```

有失败时以 `*Error* <模块名>: <m> test(s) failed` 终止（`ycPathLib` / `ycRegEx` / `ycSubProcess` / `ycCodec` / `ycJson` / `ycYaml` / `ycCsv` / `ycToml` / `ycIni` / `ycUtf8` / `ycString` / `ycUnits` / `ycTextwrap` / `ycTabulate`）。"预期报错"的用例经 `errset(expr nil)` 静默捕获，不打印红色 `*Error*`；`errset(expr t)` 仅用于加载与守卫包装，只在意料之外出错时打印诊断信息。subprocess 的回调错误收敛用例有意触发库内守卫，输出中一行红色 `*Error*` 属预期。
