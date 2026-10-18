# skill-oo

基于 Cadence SKILL++ 开发的模块化工具库。

## 模块

+ [ycPathLib](docs/pathlib/README.md) —— POSIX 路径与文件系统操作。
+ [ycRegEx](docs/regex/README.md) —— 正则表达式搜索、匹配与替换。
+ [ycSubProcess](docs/subprocess/README.md) —— 子进程启动、交互与输出管理。
+ [ycJson](docs/codec/json/README.md) —— JSON、jsonc、jsonl 的解码与编码。
+ [ycUtf8](docs/utf8/README.md) —— UTF-8 编解码、码点操作与显示宽度。

## 安装

在 `.cdsinit` 文件中追加：

```lisp
load("<path-to-dir>/skill-oo/load.il")
```

## License

Copyright (c) 2026 YEUNGCHIE

本仓库以 [GNU General Public License v3.0](LICENSE)（GPL-3.0）发布。任何再分发（含修改版）必须保留本版权声明、注明修改，并以 GPL-3.0 提供完整源码。

可免费用于个人学习和团队内部开发。
