procedure(_P(g_path "g")  ; -> Path
    ycPathLib::Path(g_path)
)

procedure(_S(g_path "g")  ; -> str
    ycPathLib::Path(g_path)->str()
)

procedure(_Sl(l_list "g")  ; -> list of str
    mapcar(lambda((g "g") g->str()) l_list)
)

procedure(_HasStr(l_list t_str "lt")  ; -> t | nil
    let((found)
        foreach(item l_list
            when(item == t_str
                found = t
            )
        )
        found
    )
)

procedure(_SameJson(g_a g_b t_format "ggt")  ; -> t | nil
    ycJson::Encode(g_a ?format t_format ?sortKeys t)
        == ycJson::Encode(g_b ?format t_format ?sortKeys t)
)

procedure(_SameYaml(g_a g_b "gg")  ; -> t | nil
    ycYaml::Encode(g_a ?sortKeys t)
        == ycYaml::Encode(g_b ?sortKeys t)
)

procedure(_SameIni(g_a g_b "gg")  ; -> t | nil
    ycIni::Encode(g_a ?sortKeys t)
        == ycIni::Encode(g_b ?sortKeys t)
)

_TestRun("ycPathLib" 508
    "test_pure.il"
    "test_fs.il"
    "test_codec.il"
)

; END
