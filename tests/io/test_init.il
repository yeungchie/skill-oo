procedure(_IOTmp(t_name "t")  ; -> str
    ; 返回 ycIO 套件临时文件的相对路径。
    ;
    ; **参数**
    ;   t_name  (str) - 文件名
    ;
    ; **返回**
    ;   (str) - 临时目录下的路径
    strcat("ycIOTmpTest/" t_name)
)

_TestRun("ycIO" 34
    "test_port.il"
)

; END
