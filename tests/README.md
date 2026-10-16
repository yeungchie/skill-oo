# skill-oo 测试

本文件描述测试套件的运行方式。使用 API 见 [ycPathLib](../docs/pathlib/README.md)、[ycRegEx](../docs/regex/README.md) 与 [ycSubProcess](../docs/subprocess/README.md)。

## 运行测试

在 Virtuoso（或独立 skill 解释器 `$CDS_INST_DIR/tools.lnx86/dfII/bin/skill`）中：

```lisp
load("<path-to-dir>/skill-oo/tests/pathlib/load.il")
load("<path-to-dir>/skill-oo/tests/regex/load.il")
load("<path-to-dir>/skill-oo/tests/subprocess/load.il")
```

> 修改某个 `libs/<模块>/src/` 后必须**重启 CIW** 再跑对应 `load.il`：同一会话内已加载过对应库时，`load.il` 会打印提示并复用内存中的旧代码，改动静默无效。

pathlib 与 regex 套件会在 cwd 下创建并清理各自的临时夹具；subprocess 套件直接运行短命令，无夹具。期望输出：

```
…（逐条 TEST PASSED - …）

PASS: <n> / FAIL: 0
```

有失败时以 `*Error* <模块名>: <m> test(s) failed` 终止（`ycPathLib` / `ycRegEx` / `ycSubProcess`）。`errset` 用 flag `t`，因此"预期报错"的用例会打印红色 `*Error*` 消息后紧跟 `TEST PASSED`，属正常。
