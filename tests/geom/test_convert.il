_TestConvertDone = nil

let((g_p g_s g_l g_r g_poly g_region)
    g_p = ycGeom::Point(list(1 2))
    g_s = ycGeom::Segment(list(0:0 1:1))
    g_l = ycGeom::Line(list(0:0 1:1))
    g_r = ycGeom::Rect(list(0:0 1:1))
    g_poly = ycGeom::Polygon('((0 0) (1 0) (1 1) (0 1)))
    g_region = ycGeom::Region(list(g_poly))
    _Assert(eq(ycGeom::ConvertToGeomObject(g_p) g_p)  "convert: Point object unchanged")
    _Assert(eq(ycGeom::ConvertToGeomObject(g_s) g_s)  "convert: Segment object unchanged")
    _Assert(eq(ycGeom::ConvertToGeomObject(g_l) g_l)  "convert: Line object unchanged")
    _Assert(eq(ycGeom::ConvertToGeomObject(g_r) g_r)  "convert: Rect object unchanged")
    _Assert(eq(ycGeom::ConvertToGeomObject(g_poly) g_poly)  "convert: Polygon object unchanged")
    _Assert(eq(ycGeom::ConvertToGeomObject(g_region) g_region)  "convert: Region object unchanged")
)

_Assert(ycGeom::Point(1:2)->toSkill() == list(1.0 2.0)  "constructor: Point pair")
_Assert(ycGeom::Point(list(1 2))->toSkill() == list(1.0 2.0)  "constructor: Point list")
_AssertError(lambda(() ycGeom::Point(1 2) t)  "constructor: Point multiple args rejected")
_AssertError(lambda(() ycGeom::Segment(0:0 1:1) t)  "constructor: Segment multiple args rejected")
_AssertError(lambda(() ycGeom::Line(0:0 1:1) t)  "constructor: Line multiple args rejected")
_AssertError(lambda(() ycGeom::Rect(0:0 5:5) t)  "constructor: Rect multiple args rejected")

_Assert(ycGeom::Segment(list(ycGeom::Point(0:0) 1:1))->toSkill()
    == list(list(0.0 0.0) list(1.0 1.0))  "constructor: Segment mixed points")
_Assert(ycGeom::Line(list(ycGeom::Point(0:0) 1:1))->contains(ycGeom::Point(list(0.5 0.5)))
    "constructor: Line mixed points")
_Assert(ycGeom::Rect(list(ycGeom::Point(0:0) 1:1))->area() == 1.0
    "constructor: Rect mixed points")
_Assert(ycGeom::Polygon(list(0:0 ycGeom::Point(1:0) 1:1 0:1))->area() == 1.0
    "constructor: Polygon mixed points")

let((g_r)
    g_r = ycGeom::Region(list(
        list(0:0 1:0 1:1)
        ycGeom::Polygon(list(0:0 ycGeom::Point(2:0) 3:3))
    ))
    _Assert(g_r->area() == 3.0  "constructor: Region mixed nested forms")
)

_Assert(ycGeom::Point(list(list(1 2)))->toSkill() == list(1.0 2.0)  "constructor: Point nested pair")
_Assert(ycGeom::Segment(list(list(0:0 1:1)))->length() == sqrt(2.0)
    "constructor: Segment nested two points")
_Assert(ycGeom::Rect(list(list(0:0 5:5)))->area() == 25.0
    "constructor: Rect nested two points")
_Assert(ycGeom::Polygon(list(list(0:0 1:0 1:1)))->area() == 0.5
    "constructor: Polygon nested point list")
_Assert(ycGeom::Region(list(list(list(0:0 1:0 1:1))))->area() == 0.5
    "constructor: Region nested point list")

_Assert(ycGeom::ConvertToGeomObject(1:2)->toSkill() == list(1.0 2.0)  "convert: pair to Point")
_Assert(ycGeom::ConvertToGeomObject(list(0:0))->toSkill() == list(0.0 0.0)  "convert: one-point list to Point")
_AssertErrorMsg(lambda(() ycGeom::ConvertToGeomObject(list(0:0 1:1)) t)
    "ambiguous"  "convert: two-point array requires ?as")

_Assert(ycGeom::ConvertToGeomObject(list(0:0 1:1) ?as 'Segment)->toSkill()
    == list(list(0.0 0.0) list(1.0 1.0))  "convert: ?as Segment")
_Assert(ycGeom::ConvertToGeomObject(list(0:0 1:1) ?as 'Line)->contains(ycGeom::Point(list(0.5 0.5)))
    "convert: ?as Line")
_Assert(ycGeom::ConvertToGeomObject(list(0:0 1:1) ?as 'Rect)->toSkill()
    == list(list(0.0 0.0) list(1.0 1.0))  "convert: ?as Rect")
_Assert(ycGeom::ConvertToGeomObject(list(0:0 1:1) ?as 'Region)->area() == 1.0
    "convert: ?as Region two points")
_Assert(ycGeom::ConvertToGeomObject(list(0:0 1:0 1:1 0:1))->area() == 1.0
    "convert: point list to Polygon")
_Assert(ycGeom::ConvertToGeomObject(list(list(0:0 1:0 1:1 0:1)))->area() == 1.0
    "convert: nested list to Region")

_AssertErrorMsg(lambda(() ycGeom::ConvertToGeomObject(1:2 ?as 'Blah) t)
    "?as"  "convert: invalid ?as rejected")
_AssertErrorMsg(lambda(() ycGeom::ConvertToGeomObject(list(0:0 1:1) ?as 'Polygon) t)
    "at least 3"  "convert: two points rejected as Polygon")

_Assert(ycGeom::Rect(list(0:0 5:5))->or(list(0:0 1:1))->area() == 25.0
    "convert: Rect union two-point array as Rect")
_Assert(ycGeom::Polygon('((0 0) (5 0) (5 5) (0 5)))->or(list(0:0 1:1))->area() == 25.0
    "convert: Polygon union two-point array as Rect")

_TestConvertDone = t

; END
