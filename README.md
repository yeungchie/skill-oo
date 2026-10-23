# skill-oo

基于 Cadence SKILL++ 开发的模块化工具库。

## 模块

按用途分组。

### 文件与进程

+ [ycPathLib](docs/pathlib/README.md) —— POSIX 路径与文件系统操作。
+ [ycSubProcess](docs/subprocess/README.md) —— 子进程启动、交互与输出管理。

### 文本处理

+ [ycRegEx](docs/regex/README.md) —— 正则表达式搜索、匹配与替换。
+ [ycUtf8](docs/utf8/README.md) —— UTF-8 编解码、码点操作与显示宽度。
+ [ycString](docs/string/README.md) —— 字符串操作、转义与标识符转换。
+ [ycTextwrap](docs/textwrap/README.md) —— 定宽折行、缩进与截断。

### 数据与报告

+ codec
  + [ycCodec](docs/codec/core/README.md) —— 编解码库共享的哨兵类型。
  + [ycJson](docs/codec/json/README.md) —— JSON、jsonc、jsonl 的解码与编码。
  + [ycYaml](docs/codec/yaml/README.md) —— YAML 1.2 的解码与编码。
  + [ycCsv](docs/codec/csv/README.md) —— CSV/TSV 编解码与 Table 模型。
  + [ycToml](docs/codec/toml/README.md) —— TOML 1.0 编解码。
  + [ycIni](docs/codec/ini/README.md) —— INI 配置读写。
+ [ycUnits](docs/units/README.md) —— SI 工程计数与单位解析/格式化。
+ [ycTabulate](docs/tabulate/README.md) —— 文本表格渲染。

## 调用约定

+ 类名、函数名与命名空间全局变量使用大驼峰；前导 `_` 的私有名使用 `_XXX`。方法使用小驼峰。
+ 跨库访问一律写全限定名：公开符号用 `ycXxx::Xxx`，库内私有符号用 `ycXxx:::_XXX`；方法用 `obj->method()`。
+ 不依赖 `useNamespace` 的短名。调用方主动使用 `useNamespace` 后，同名短名被覆盖的风险由调用方自行承担。

## 安装

在 `.cdsinit` 文件中追加：

```lisp
load("<path-to-dir>/skill-oo/load.il")
```

## License

Copyright (c) 2026 YEUNGCHIE

本仓库以 [GNU General Public License v3.0](LICENSE)（GPL-3.0）发布。任何再分发（含修改版）必须保留本版权声明、注明修改，并以 GPL-3.0 提供完整源码。

可免费用于个人学习和团队内部开发。
