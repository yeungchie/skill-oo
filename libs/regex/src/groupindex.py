#!/usr/bin/env python3

# 组名 -> 组号映射：从标准输入读模式串，向标准输出写 JSON 对象。
#
# 引擎的组名表没有原生读取入口，这里借辅助解析得到映射；SKILL 侧懒加载并缓存。
# --no-auto-capture：声明该模式以 no_auto_capture 编译——只有命名组参与编号，
# 因此按出现顺序（即原组号大小）重排为 1..k。

import argparse
import json
import re
import sys
from typing import Dict, List


class UsageParser(argparse.ArgumentParser):
    """Report contract violations as a usage line on stdout plus exit 1."""

    def error(self, message: str) -> None:
        self.print_usage(sys.stdout)
        raise SystemExit(1)


def build_parser() -> argparse.ArgumentParser:
    parser = UsageParser(
        prog="groupindex.py",
        description="Print the named-group index map of a pattern (read from stdin) as JSON.",
    )
    parser.add_argument(
        "--no-auto-capture",
        action="store_true",
        help="report the numbering used when the engine compiles with no_auto_capture",
    )
    return parser


def main(argv: List[str]) -> int:
    args = build_parser().parse_args(argv)
    # 按字节读再按 UTF-8 解码：不依赖进程 locale，非 ASCII 模式不会解码失败。
    pattern: str = sys.stdin.buffer.read().decode("utf-8", "replace")[:-1]
    rec = re.compile(pattern)
    index: Dict[str, int] = dict(rec.groupindex)
    if args.no_auto_capture:
        index = {
            name: rank for rank, name in enumerate(sorted(index, key=index.get), 1)
        }
    sys.stdout.write(json.dumps(index))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except (re.error, UnicodeDecodeError) as e:
        sys.stderr.write(str(e))
        sys.exit(1)
