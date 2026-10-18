;--------------------------
; Program  : skill-oo(libs/registry.il)
; Language : Cadence Skill
;--------------------------

; Known namespaces accepted by ycRequireNamespace. This is a plain name list:
; loading order and file lists stay in libs/load.il and each package load.il;
; shells created by ycRequireNamespace hold no code - they only make
; cross-library references (ycOther:::name) readable before that library is
; loaded. Keep this list in sync with the packages under libs/.

_ycModules = list(
    "ycPathLib"
    "ycRegEx"
    "ycSubProcess"
    "ycJson"
    "ycUtf8"
)

procedure(ycRequireNamespace(@rest t_names "t")  ; -> t
    ; 确保给定命名空间均可用：不存在者建立空壳命名空间，不加载任何代码；
    ; 名单外的名字报错。
    ;
    ; **参数**
    ;   t_names  (str ...) - 命名空间名，@rest 变参可多个；零参即无操作
    ;
    ; **返回**
    ;   (t) - 全部已存在或已建立；名单外名字 error
    foreach(t_name t_names
        when(findNamespace(t_name) == nil
            unless(member(t_name _ycModules)
                error("ycRequireNamespace: unknown namespace %A" t_name)
            )
            makeNamespace(t_name)
            unuseNamespace(t_name)
        )
    )
    t
)

; END
