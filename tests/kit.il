;--------------------------
; Program  : skill-oo test kit
; Language : Cadence Skill
;--------------------------
; 各测试套件共用的断言、计时与结果汇总工具。
; 由各套件的 load.il 在载入 test_init.il 之前加载；test_init.il 只保留
; 模块专用辅助过程与一行 _TestRun(...) 调用。
;
; 断言宏把自己展开成「在当前作用域里 setq + measureTime」的形式：
; 既精确统计用例表达式的耗时，又不额外引入函数调用层，也不会用工具的
; 局部变量遮蔽测试代码的同名变量（SKILL 的局部变量按动态作用域解析）。

_TestCount = 0
_TestFail = 0
_TestFileIndex = 0
_TestFileTotal = 0
_TestExpected = 0
_TestChildDone = nil
_TestErrWindow = nil
_TestDeferred = nil
_TestProgDigits = 3

procedure(_TestPrint(t_kitFmt @rest l_kitArgs "tg")  ; -> t
    ; 普通输出写 poport；错误窗口打开时先暂存，窗口结束后再按序打印。
    ;
    ; **参数**
    ;   t_kitFmt   (str) - 格式串
    ;   l_kitArgs  (list) - 格式参数
    ;
    ; **返回**
    ;   (t) - 恒为 t
    let(((t_kitText nil))
        t_kitText = apply('sprintf (cons nil (cons t_kitFmt l_kitArgs)))
        if(_TestErrWindow
            _TestDeferred = tconc(_TestDeferred t_kitText)
            printf("%s" t_kitText)
        )
        t
    )
)

procedure(_TestFmtTime(n_kitSec "n")  ; -> str
    ; 把秒数格式化成易读的耗时串。
    ;
    ; **参数**
    ;   n_kitSec  (num) - 秒数
    ;
    ; **返回**
    ;   (str) - 不足 1 秒用 ms，不足 1 分钟用 s，不足 1 小时用 m，其余用 h；
    ;           小数位随量级收缩，使同单位下的字符串宽度一致（如 0.088ms 与 184.4ms）
    let((n_kitMs)
        n_kitSec = n_kitSec * 1.0
        n_kitMs = n_kitSec * 1000.0
        cond(
            (n_kitMs < 9.9995 sprintf(nil "%.3fms" n_kitMs))
            (n_kitMs < 99.995 sprintf(nil "%.2fms" n_kitMs))
            (n_kitMs < 999.995 sprintf(nil "%.1fms" n_kitMs))
            (n_kitSec < 9.9995 sprintf(nil "%.3fs" n_kitSec))
            (n_kitSec < 59.995 sprintf(nil "%.2fs" n_kitSec))
            (n_kitSec < 599.995 sprintf(nil "%.3fm" n_kitSec / 60.0))
            (n_kitSec < 3599.95 sprintf(nil "%.2fm" n_kitSec / 60.0))
            (t sprintf(nil "%.2fh" n_kitSec / 3600.0))
        )
    )
)

procedure(_TestPadLeft(t_kitText n_kitWidth "tn")  ; -> str
    ; 在左侧补空格到指定宽度。
    ;
    ; **参数**
    ;   t_kitText   (str) - 原串
    ;   n_kitWidth  (int) - 目标宽度
    ;
    ; **返回**
    ;   (str) - 补空格后的串（原串更宽时原样返回）
    while(length(t_kitText) < n_kitWidth
        t_kitText = strcat(" " t_kitText)
    )
    t_kitText
)

procedure(_TestErrorBegin(t_kitWhat "t")  ; -> t
    ; 标记一段有意产生的错误输出开始。
    ;
    ; **参数**
    ;   t_kitWhat  (str) - 说明该段错误输出的来源
    ;
    ; **返回**
    ;   (t) - 恒为 t
    drain(poport)
    _TestErrWindow = t
    fprintf(errport "\n--- BEGIN expected error output: %s ---\n" t_kitWhat)
    drain(errport)
    t
)

procedure(_TestErrorEnd()  ; -> t
    ; 标记一段有意产生的错误输出结束，并补打窗口内暂存的用例结果。
    ;
    ; **返回**
    ;   (t) - 恒为 t
    fprintf(errport "--- END expected error output ---\n\n")
    drain(errport)
    _TestErrWindow = nil
    when(_TestDeferred
        foreach(t_kitText car(_TestDeferred)
            printf("%s" t_kitText)
        )
        _TestDeferred = nil
    )
    drain(poport)
    t
)

procedure(_TestReport(g_kitOk t_kitName n_kitSec "gtn")  ; -> t | nil
    ; 记录一项断言的结果并打印进度与耗时。
    ;
    ; **参数**
    ;   g_kitOk    (any) - 断言值
    ;   t_kitName  (str) - 用例名
    ;   n_kitSec   (num) - 该项耗时（秒）
    ;
    ; **返回**
    ;   (t|nil) - 原样返回断言值
    _TestCount++
    unless(g_kitOk
        _TestFail++
    )
    _TestPrint("%s %7s TEST %s - %s\n"
        lsprintf("[%s/%s]"
            _TestPadLeft(lsprintf("%d" _TestCount) _TestProgDigits)
            lsprintf("%d" _TestExpected))
        _TestFmtTime(n_kitSec)
        if(g_kitOk "PASSED" "FAILED")
        t_kitName)
    g_kitOk
)

defmacro(_Assert (g_cond t_msg)
    (list 'let
        (list (list 'g_kitVal nil) (list 'l_kitPerf nil))
        (list 'setq 'l_kitPerf
            (list 'measureTime (list 'setq 'g_kitVal g_cond)))
        (list '_TestReport 'g_kitVal t_msg (list 'caddr 'l_kitPerf)))
)

procedure(_TestOkResult(g_kitRes t_kitName n_kitSec "gtn")  ; -> t | nil（errset 结果：捕获成功且值为 t 才过）
    ; 检查 errset 结果并报告（耗时由调用宏测得）。
    ;
    ; **参数**
    ;   g_kitRes    (list) - errset 结果
    ;   t_kitName   (str) - 用例名
    ;   n_kitSec    (num) - 该项耗时（秒）
    ;
    ; **返回**
    ;   (t|nil) - 是否通过
    let(((g_kitOk nil))
        g_kitOk = g_kitRes && car(g_kitRes)
        _TestReport(g_kitOk t_kitName n_kitSec)
        unless(g_kitOk
            when(g_kitRes == nil
                _TestErrorBegin(t_kitName)
                fprintf(errport "%A\n" errset.errset)
                _TestErrorEnd()
            )
        )
        g_kitOk
    )
)

defmacro(_AssertOk (g_expr t_msg)
    (list 'let
        (list (list 'g_kitRes nil) (list 'l_kitPerf nil))
        (list 'setq 'l_kitPerf
            (list 'measureTime (list 'setq 'g_kitRes g_expr)))
        (list '_TestOkResult 'g_kitRes t_msg (list 'caddr 'l_kitPerf)))
)

procedure(_AssertError(g_kitThunk t_kitName "gt")  ; -> t | nil
    ; 断言调用报错（静默捕获）并计时。
    ;
    ; **参数**
    ;   g_kitThunk  (any) - 零参 lambda
    ;   t_kitName   (str) - 用例名
    ;
    ; **返回**
    ;   (t|nil) - 捕获到错误时为 t
    let(((g_kitRes nil) (l_kitPerf nil))
        l_kitPerf = measureTime(g_kitRes = errset(funcall(g_kitThunk) nil))
        _TestReport(!g_kitRes t_kitName caddr(l_kitPerf))
    )
)

procedure(_AssertErrorMsg(g_kitThunk t_kitSub t_kitName "gtt")  ; -> t | nil
    ; 断言调用报错且消息包含指定片段，并计时。
    ;
    ; **参数**
    ;   g_kitThunk  (any) - 零参 lambda
    ;   t_kitSub    (str) - 期望的消息片段
    ;   t_kitName   (str) - 用例名
    ;
    ; **返回**
    ;   (t|nil) - 条件满足时为 t
    let(((g_kitRes nil) (t_kitText nil) (g_kitOk nil) (l_kitPerf nil))
        l_kitPerf = measureTime(g_kitRes = errset(funcall(g_kitThunk) nil))
        when(!g_kitRes
            ; errset.errset 为 ("error" 序号 t nil ("*Error* 消息"))，取末元素首字符串
            when(errset.errset && 4 <= length(errset.errset)
                t_kitText = car(car(cdr(cdr(cdr(cdr(errset.errset))))))
            )
        )
        g_kitOk = !g_kitRes && t_kitText && index(t_kitText t_kitSub)
        _TestReport(g_kitOk t_kitName caddr(l_kitPerf))
        unless(g_kitOk
            _TestPrint("  expected message containing: %A\n" t_kitSub)
            _TestPrint("  actual: %A\n" if(t_kitText t_kitText "no error detail"))
        )
        g_kitOk
    )
)

procedure(_TestSeqEq(l_actual l_expected "ll")  ; -> t | nil
    ; 按顺序比较两个列表。
    ;
    ; **参数**
    ;   l_actual    (list) - 实际值
    ;   l_expected  (list) - 期望值
    ;
    ; **返回**
    ;   (t|nil) - 长度与逐项都相等时为 t
    let(((g_ok t) (l_a l_actual) (l_b l_expected))
        g_ok = length(l_actual) == length(l_expected)
        while(g_ok && l_a
            g_ok = car(l_a) == car(l_b)
            l_a = cdr(l_a)
            l_b = cdr(l_b)
        )
        g_ok
    )
)

procedure(_TestCountStr(l_list t_str "lt")  ; -> n
    ; 统计串在列表中的出现次数。
    ;
    ; **参数**
    ;   l_list  (list) - 待统计列表
    ;   t_str   (str) - 目标串
    ;
    ; **返回**
    ;   (int) - 出现次数
    let(((n_c 0))
        foreach(t_s l_list
            when(t_s == t_str
                n_c++
            )
        )
        n_c
    )
)

procedure(_TestStrMultisetEq(l_actual l_expected "ll")  ; -> t | nil
    ; 比较两个串列表的元素多重集（忽略顺序）。
    ;
    ; **参数**
    ;   l_actual    (list) - 实际值
    ;   l_expected  (list) - 期望值
    ;
    ; **返回**
    ;   (t|nil) - 多重集相等时为 t
    let(((g_ok nil))
        g_ok = length(l_actual) == length(l_expected)
        when(g_ok
            foreach(t_s l_actual
                when(_TestCountStr(l_actual t_s) != _TestCountStr(l_expected t_s)
                    g_ok = nil
                )
            )
        )
        when(g_ok
            foreach(t_s l_expected
                when(_TestCountStr(l_expected t_s) != _TestCountStr(l_actual t_s)
                    g_ok = nil
                )
            )
        )
        g_ok
    )
)

procedure(_TestTupKey(l_list "l")  ; -> str（"a,b,c"；nil -> ""）
    ; 把元组拼成逗号分隔的诊断串。
    ;
    ; **参数**
    ;   l_list  (list) - 元组
    ;
    ; **返回**
    ;   (str) - 拼接结果
    cond(
        (l_list == nil "")
        (cdr(l_list) == nil car(l_list))
        (t lsprintf("%s,%s" car(l_list) _TestTupKey(cdr(l_list))))
    )
)

procedure(_TestIntKey(l_list "l")  ; -> str（"1 2 3"；nil -> ""）
    ; 把整数列表拼成空格分隔的诊断串。
    ;
    ; **参数**
    ;   l_list  (list) - 整数列表
    ;
    ; **返回**
    ;   (str) - 拼接结果
    cond(
        (l_list == nil "")
        (cdr(l_list) == nil lsprintf("%d" car(l_list)))
        (t lsprintf("%d %s" car(l_list) _TestIntKey(cdr(l_list))))
    )
)

procedure(_TestRowsEq(l_a l_b "ll")  ; -> t | nil
    ; 逐行比较两个行列表。
    ;
    ; **参数**
    ;   l_a  (list) - 实际行
    ;   l_b  (list) - 期望行
    ;
    ; **返回**
    ;   (t|nil) - 逐行相等时为 t
    cond(
        ((l_a == nil && l_b == nil) t)
        ((l_a == nil || l_b == nil) nil)
        (t car(l_a) == car(l_b) && _TestRowsEq(cdr(l_a) cdr(l_b)))
    )
)

procedure(_TestSameSeqVals(l_actual l_expected t_kitName n_kitSec "lltn")  ; -> t | nil
    ; 比较两个列表并按顺序报告。
    ;
    ; **参数**
    ;   l_actual    (list) - 实际值
    ;   l_expected  (list) - 期望值
    ;   t_kitName   (str) - 用例名
    ;   n_kitSec    (num) - 该项耗时（秒）
    ;
    ; **返回**
    ;   (t|nil) - 是否通过
    let(((g_kitOk nil))
        g_kitOk = _TestSeqEq(l_actual l_expected)
        unless(g_kitOk
            _TestPrint("  expected (%d): %A\n" length(l_expected) l_expected)
            _TestPrint("  actual (%d): %A\n" length(l_actual) l_actual)
        )
        _TestReport(g_kitOk t_kitName n_kitSec)
    )
)

procedure(_TestSameStrsVals(l_actual l_expected t_kitName n_kitSec "lltn")  ; -> t | nil
    ; 按多重集比较两个串列表并报告。
    ;
    ; **参数**
    ;   l_actual    (list) - 实际值
    ;   l_expected  (list) - 期望值
    ;   t_kitName   (str) - 用例名
    ;   n_kitSec    (num) - 该项耗时（秒）
    ;
    ; **返回**
    ;   (t|nil) - 是否通过
    let(((g_kitOk nil))
        g_kitOk = _TestStrMultisetEq(l_actual l_expected)
        unless(g_kitOk
            _TestPrint("  expected (%d):\n" length(l_expected))
            foreach(t_s l_expected
                _TestPrint("    %s\n" t_s)
            )
            _TestPrint("  actual (%d):\n" length(l_actual))
            foreach(t_s l_actual
                _TestPrint("    %s\n" t_s)
            )
        )
        _TestReport(g_kitOk t_kitName n_kitSec)
    )
)

procedure(_TestSameTuplesVals(l_actual l_expected t_kitName n_kitSec "lltn")  ; -> t | nil
    ; 比较两个元组列表并报告。
    ;
    ; **参数**
    ;   l_actual    (list) - 实际值
    ;   l_expected  (list) - 期望值
    ;   t_kitName   (str) - 用例名
    ;   n_kitSec    (num) - 该项耗时（秒）
    ;
    ; **返回**
    ;   (t|nil) - 是否通过
    let(((g_kitOk nil) (l_kitA nil) (l_kitB nil))
        l_kitA = mapcar('_TestTupKey l_actual)
        l_kitB = mapcar('_TestTupKey l_expected)
        g_kitOk = _TestSeqEq(l_kitA l_kitB)
        unless(g_kitOk
            _TestPrint("  expected (%d): [%s]\n"
                length(l_expected) buildString(l_kitB "; "))
            _TestPrint("  actual (%d): [%s]\n"
                length(l_actual) buildString(l_kitA "; "))
        )
        _TestReport(g_kitOk t_kitName n_kitSec)
    )
)

procedure(_TestSameIntsVals(l_actual l_expected t_kitName n_kitSec "lltn")  ; -> t | nil
    ; 比较两个整数列表并报告。
    ;
    ; **参数**
    ;   l_actual    (list) - 实际值
    ;   l_expected  (list) - 期望值
    ;   t_kitName   (str) - 用例名
    ;   n_kitSec    (num) - 该项耗时（秒）
    ;
    ; **返回**
    ;   (t|nil) - 是否通过
    let(((g_kitOk nil))
        g_kitOk = _TestSeqEq(l_actual l_expected)
        unless(g_kitOk
            _TestPrint("  expected ints (%d): %s\n"
                length(l_expected) _TestIntKey(l_expected))
            _TestPrint("  actual ints (%d): %s\n"
                length(l_actual) _TestIntKey(l_actual))
        )
        _TestReport(g_kitOk t_kitName n_kitSec)
    )
)

procedure(_TestSameSpanVals(g_match n_start n_end t_kitName n_kitSec "gnntn")  ; -> t | nil
    ; 比较匹配对象的 span 并报告。
    ;
    ; **参数**
    ;   g_match    (any) - 匹配对象
    ;   n_start    (int) - 期望起点
    ;   n_end      (int) - 期望终点
    ;   t_kitName  (str) - 用例名
    ;   n_kitSec   (num) - 该项耗时（秒）
    ;
    ; **返回**
    ;   (t|nil) - 是否通过
    let(((l_kitSpan nil) (g_kitOk nil))
        when(g_match
            l_kitSpan = g_match->span()
        )
        g_kitOk = g_match && length(l_kitSpan) == 2
            && car(l_kitSpan) == n_start
            && car(cdr(l_kitSpan)) == n_end
        unless(g_kitOk
            _TestPrint("  expected span (%d, %d)\n" n_start n_end)
            when(l_kitSpan
                _TestPrint("  actual span (%d, %d)\n" car(l_kitSpan) car(cdr(l_kitSpan)))
            )
        )
        _TestReport(g_kitOk t_kitName n_kitSec)
    )
)

procedure(_TestSameRowsVals(l_actual l_expected t_kitName n_kitSec "lltn")  ; -> t | nil
    ; 逐行比较两个行列表并报告。
    ;
    ; **参数**
    ;   l_actual    (list) - 实际值
    ;   l_expected  (list) - 期望值
    ;   t_kitName   (str) - 用例名
    ;   n_kitSec    (num) - 该项耗时（秒）
    ;
    ; **返回**
    ;   (t|nil) - 是否通过
    let(((g_kitOk nil))
        g_kitOk = _TestRowsEq(l_actual l_expected)
        unless(g_kitOk
            _TestPrint("  expected (%d): %A\n" length(l_expected) l_expected)
            _TestPrint("  actual (%d): %A\n" length(l_actual) l_actual)
        )
        _TestReport(g_kitOk t_kitName n_kitSec)
    )
)

defmacro(_AssertSameSeq (l_actual l_expected t_msg)
    (list 'let
        (list (list 'l_kitA nil) (list 'l_kitB nil) (list 'l_kitPerf nil))
        (list 'setq 'l_kitPerf
            (list 'measureTime
                (list 'setq 'l_kitA l_actual)
                (list 'setq 'l_kitB l_expected)))
        (list '_TestSameSeqVals
            'l_kitA 'l_kitB t_msg (list 'caddr 'l_kitPerf)))
)

defmacro(_AssertSameStrs (l_actual l_expected t_msg)
    (list 'let
        (list (list 'l_kitA nil) (list 'l_kitB nil) (list 'l_kitPerf nil))
        (list 'setq 'l_kitPerf
            (list 'measureTime
                (list 'setq 'l_kitA l_actual)
                (list 'setq 'l_kitB l_expected)))
        (list '_TestSameStrsVals
            'l_kitA 'l_kitB t_msg (list 'caddr 'l_kitPerf)))
)

defmacro(_AssertSameTuples (l_actual l_expected t_msg)
    (list 'let
        (list (list 'l_kitA nil) (list 'l_kitB nil) (list 'l_kitPerf nil))
        (list 'setq 'l_kitPerf
            (list 'measureTime
                (list 'setq 'l_kitA l_actual)
                (list 'setq 'l_kitB l_expected)))
        (list '_TestSameTuplesVals
            'l_kitA 'l_kitB t_msg (list 'caddr 'l_kitPerf)))
)

defmacro(_AssertSameInts (l_actual l_expected t_msg)
    (list 'let
        (list (list 'l_kitA nil) (list 'l_kitB nil) (list 'l_kitPerf nil))
        (list 'setq 'l_kitPerf
            (list 'measureTime
                (list 'setq 'l_kitA l_actual)
                (list 'setq 'l_kitB l_expected)))
        (list '_TestSameIntsVals
            'l_kitA 'l_kitB t_msg (list 'caddr 'l_kitPerf)))
)

defmacro(_AssertSameSpan (g_m n_start n_end t_msg)
    (list 'let
        (list (list 'g_kitMatch nil) (list 'n_kitStart nil)
              (list 'n_kitEnd nil) (list 'l_kitPerf nil))
        (list 'setq 'l_kitPerf
            (list 'measureTime
                (list 'setq 'g_kitMatch g_m)
                (list 'setq 'n_kitStart n_start)
                (list 'setq 'n_kitEnd n_end)))
        (list '_TestSameSpanVals
            'g_kitMatch 'n_kitStart 'n_kitEnd t_msg
            (list 'caddr 'l_kitPerf)))
)

defmacro(_AssertRows (l_actual l_expected t_msg)
    (list 'let
        (list (list 'l_kitA nil) (list 'l_kitB nil) (list 'l_kitPerf nil))
        (list 'setq 'l_kitPerf
            (list 'measureTime
                (list 'setq 'l_kitA l_actual)
                (list 'setq 'l_kitB l_expected)))
        (list '_TestSameRowsVals
            'l_kitA 'l_kitB t_msg (list 'caddr 'l_kitPerf)))
)

procedure(_TestLoadFile(t_kitFile "t")  ; -> t
    ; 载入一个测试文件并报告该文件的进度、耗时与用例数。
    ;
    ; **参数**
    ;   t_kitFile  (str) - 相对 _TestDir 的文件名
    ;
    ; **返回**
    ;   (t) - 恒为 t
    let(((l_kitRes nil) (l_kitPerf nil) (n_kitBefore nil))
        _TestFileIndex++
        n_kitBefore = _TestCount
        _TestChildDone = nil
        _TestPrint("\n[%d/%d] %s\n" _TestFileIndex _TestFileTotal t_kitFile)
        l_kitPerf = measureTime(l_kitRes = errset(load(strcat(_TestDir t_kitFile)) nil))
        when(_TestErrWindow
            _TestErrorEnd()
        )
        unless(_TestChildDone
            _TestCount++
            _TestFail++
            _TestPrint("[%d/%d] %s TEST FAILED - %s did not run to completion\n"
                _TestCount _TestExpected _TestFmtTime(caddr(l_kitPerf)) t_kitFile)
            when(l_kitRes == nil
                _TestErrorBegin(t_kitFile)
                fprintf(errport "%A\n" errset.errset)
                _TestErrorEnd()
            )
        )
        _TestPrint("[%d/%d] %s done in %s (%d tests)\n"
            _TestFileIndex
            _TestFileTotal
            t_kitFile
            _TestFmtTime(caddr(l_kitPerf))
            _TestCount - n_kitBefore)
        t
    )
)

procedure(_TestRun(t_kitModule n_kitExpected @rest l_kitFiles "tng")  ; -> t
    ; 依次运行一个套件的全部测试文件并打印汇总。
    ;
    ; **参数**
    ;   t_kitModule    (str) - 套件名（用于汇总与失败信息）
    ;   n_kitExpected  (int) - 期望的用例总数
    ;   l_kitFiles     (list) - 相对 _TestDir 的测试文件名
    ;
    ; **返回**
    ;   (t) - 全部通过时为 t；有失败时抛出错误
    let(((l_kitPerf nil))
        _TestCount = 0
        _TestFail = 0
        _TestFileIndex = 0
        _TestFileTotal = length(l_kitFiles)
        _TestExpected = n_kitExpected
        _TestProgDigits = length(lsprintf("%d" n_kitExpected))
        _TestPrint("\n=== %s ===\n" t_kitModule)
        l_kitPerf = measureTime(
            foreach(t_kitFile l_kitFiles
                _TestLoadFile(t_kitFile)
            )
        )
        _TestPrint("\nPASS: %d / FAIL: %d\n" _TestCount - _TestFail _TestFail)
        _TestPrint("TOTAL: %s\n" _TestFmtTime(caddr(l_kitPerf)))
        drain(poport)
        unless(_TestCount == n_kitExpected
            _TestPrint("NOTE: expected %d tests, ran %d\n"
                n_kitExpected _TestCount)
        )
        when(_TestFail > 0
            error("%s: %d test(s) failed" t_kitModule _TestFail)
        )
        t
    )
)

; END
