#!/usr/bin/env python3

# 组名 -> 组号映射：从标准输入读模式串，向标准输出写 JSON 对象。
#
# 引擎的组名表没有原生读取入口，这里借辅助解析得到映射；SKILL 侧懒加载并缓存。
# --no-auto-capture：声明该模式以 no_auto_capture 编译——只有命名组参与编号，
# 因此按出现顺序（即原组号大小）重排为 1..k。

import json
import re
import sys


def main(argv):
    named_only = "--no-auto-capture" in argv
    # 按字节读再按 UTF-8 解码：不依赖进程 locale，非 ASCII 模式不会解码失败。
    pattern = sys.stdin.buffer.read().decode("utf-8", "replace")[:-1]
    rec = re.compile(pattern)
    index = dict(rec.groupindex)
    if named_only:
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
