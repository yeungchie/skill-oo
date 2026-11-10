procedure(_LogTmp(t_name "t")  ; -> str
    ; 返回测试用临时文件路径。
    strcat("ycLogTmpTest/" t_name)
)

procedure(_LogReset()  ; -> t
    ; 清空并重建测试临时目录。
    system("rm -rf ycLogTmpTest")
    createDir("ycLogTmpTest")
    t
)

procedure(_LogCleanup()  ; -> t
    ; 删除测试临时目录。
    system("rm -rf ycLogTmpTest")
    t
)

procedure(_ReadLines(t_path "t")  ; -> list[str]
    ; 读取文件并去掉每行结尾的换行。
    let((port line res)
        port = infile(t_path)
        unless(port
            error("ycLog test: cannot read %A" t_path)
        )
        while(gets(line port)
            when(pcreMatchp("\n$" line)
                line = pcreReplace(pcreCompile("\n$") line "" 0)
            )
            res = tconc(res line)
        )
        close(port)
        car(res)
    )
)

procedure(_Capture(t_path g_thunk "tg")  ; -> list[str]
    ; 把 g_thunk 执行期间的 printf 输出捕获到文件，返回去掉换行的行列表。
    let((saved port res)
        saved = poport
        port = outfile(t_path)
        unless(port
            error("ycLog test: cannot open %A" t_path)
        )
        poport = port
        res = errset(funcall(g_thunk) nil)
        poport = saved
        close(port)
        unless(res
            error("ycLog test: captured call failed")
        )
        _ReadLines(t_path)
    )
)

_TestRun("ycLog" 68
    "test_level.il"
    "test_output.il"
    "test_file.il"
    "test_error.il"
    "test_with.il"
)

; END
