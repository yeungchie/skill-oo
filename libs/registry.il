;--------------------------
; Program  : skill-oo(libs/registry.il)
; Language : Cadence Skill
;--------------------------

; Known namespaces accepted by ycRequireNamespace. This is a plain name list:
; loading order and file lists stay in libs/load.il and each package load.il;
; shells created by ycRequireNamespace hold no code - they only make
; cross-library references (ycOther:::name) readable before that library is
; loaded. Keep this list in sync with the packages under libs/.

_ycNamespaces = list(
    "ycPathLib"
    "ycRegEx"
    "ycSubProcess"
    "ycJson"
    "ycUtf8"
    "ycString"
)

procedure(ycRequireNamespace(@rest l_names "t")  ; -> t
    ; 确保给定命名空间均可用：不存在者建立空壳命名空间，不加载任何代码；
    ; 名单外的名字报错。
    ;
    ; **参数**
    ;   l_names  (list[str]) - 命名空间名列表（@rest 收集，可多个；零参即空列表）
    ;
    ; **返回**
    ;   (t) - 全部已存在或已建立；名单外名字 error
    foreach(t_name l_names
        when(findNamespace(t_name) == nil
            unless(member(t_name _ycNamespaces)
                error("ycRequireNamespace: unknown namespace %A" t_name)
            )
            makeNamespace(t_name)
            unuseNamespace(t_name)
        )
    )
    t
)

; END
