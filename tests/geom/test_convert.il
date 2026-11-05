_TestConvertDone = nil

let((p s l r poly region)
    p = ycGeom::Point(1:2)
    s = ycGeom::Segment(list(0:0 1:1))
    l = ycGeom::Line(list(0:0 1:1))
    r = ycGeom::Rect(list(0:0 1:1))
    poly = ycGeom::Polygon('((0 0) (1 0) (1 1) (0 1)))
    region = ycGeom::Region(list(poly))
    _Assert(!eq(ycGeom::ConvertToGeomObject(p) p)  "convert: Point object rebuilt")
    _Assert(!eq(ycGeom::ConvertToGeomObject(s) s)  "convert: Segment object rebuilt")
    _Assert(!eq(ycGeom::ConvertToGeomObject(l) l)  "convert: Line object rebuilt")
    _Assert(!eq(ycGeom::ConvertToGeomObject(r) r)  "convert: Rect object rebuilt")
    _Assert(!eq(ycGeom::ConvertToGeomObject(poly) poly)  "convert: Polygon object rebuilt")
    _Assert(!eq(ycGeom::ConvertToGeomObject(region) region)  "convert: Region object rebuilt")
    _Assert(ycGeom::ConvertToGeomObject(p)->toSkill() == p->toSkill()  "convert: Point object value")
    _Assert(ycGeom::ConvertToGeomObject(s)->toSkill() == s->toSkill()  "convert: Segment object value")
    let((n)
        n = ycGeom::ConvertToGeomObject(l)
        _Assert(l->isParallel(n) && n->contains(l->anchor())
            "convert: Line object value")
    )
    _Assert(ycGeom::ConvertToGeomObject(r)->toSkill() == r->toSkill()  "convert: Rect object value")
    _Assert(ycGeom::ConvertToGeomObject(poly)->toSkill() == poly->toSkill()  "convert: Polygon object value")
    _Assert(ycGeom::ConvertToGeomObject(region)->area() == region->area()  "convert: Region object value")
)

_Assert(ycGeom::Point(1:2)->toSkill() == list(1.0 2.0)  "constructor: Point pair")
_Assert(ycGeom::Point(list(1 2))->toSkill() == list(1.0 2.0)  "constructor: Point list")
_AssertError(lambda(() ycGeom::Point(1 2) t)  "constructor: Point multiple args rejected")
_AssertError(lambda(() ycGeom::Segment(0:0 1:1) t)  "constructor: Segment multiple args rejected")
_AssertError(lambda(() ycGeom::Line(0:0 1:1) t)  "constructor: Line multiple args rejected")
_AssertError(lambda(() ycGeom::Rect(0:0 5:5) t)  "constructor: Rect multiple args rejected")

_Assert(ycGeom::Segment(list(ycGeom::Point(0:0) 1:1))->toSkill()
    == list(list(0.0 0.0) list(1.0 1.0))  "constructor: Segment mixed points")
_Assert(ycGeom::Line(list(ycGeom::Point(0:0) 1:1))->contains(ycGeom::Point(0.5:0.5))
    "constructor: Line mixed points")
_Assert(ycGeom::Rect(list(ycGeom::Point(0:0) 1:1))->area() == 1.0
    "constructor: Rect mixed points")
_Assert(ycGeom::Polygon(list(0:0 ycGeom::Point(1:0) 1:1 0:1))->area() == 1.0
    "constructor: Polygon mixed points")

let((r)
    r = ycGeom::Region(list(
        list(0:0 1:0 1:1)
        ycGeom::Polygon(list(0:0 ycGeom::Point(2:0) 3:3))
    ))
    _Assert(r->area() == 3.0  "constructor: Region mixed nested forms")
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
_Assert(ycGeom::ConvertToGeomObject(list(0:0 1:1) ?as 'Line)->contains(ycGeom::Point(0.5:0.5))
    "convert: ?as Line")
_Assert(ycGeom::ConvertToGeomObject(list(0:0 1:1) ?as 'Rect)->toSkill()
    == list(list(0.0 0.0) list(1.0 1.0))  "convert: ?as Rect")
_Assert(ycGeom::ConvertToGeomObject(list(0:0 1:1) ?as 'Region)->area() == 1.0
    "convert: ?as Region two points")
_AssertError(lambda(() ycGeom::ConvertToGeomObject(list(0 0 1 0 1 1)) t)
    "convert: flat coordinate array rejected")
_Assert(ycGeom::ConvertToGeomObject(list(0:0 1:0 1:1 0:1))->area() == 1.0
    "convert: point list to Polygon")
_Assert(ycGeom::ConvertToGeomObject(list(list(0:0 1:0 1:1 0:1)))->area() == 1.0
    "convert: nested point list to Polygon")

let((poly r1 r2 r)
    poly = ycGeom::Polygon('((0 0) (1 0) (1 1) (0 1)))
    r1 = list(0:0 1:0 1:1)
    r2 = list(2:0 3:0 3:1)
    _Assert(ycGeom::Region(list(list(poly)))->area() == 1.0
        "constructor: Region nested Polygon object")
    _Assert(ycGeom::Region(list(list(r1 r2)))->area() == 1.0
        "constructor: Region nested point lists")
    _Assert(ycGeom::Region(list(list(0:0 5:5)))->area() == 25.0
        "constructor: Region nested two-point rectangle")
    _Assert(ycGeom::ConvertToGeomObject(list(list(poly)) ?as 'Region)->area() == 1.0
        "convert: nested Polygon object as Region")
    _Assert(ycGeom::ConvertToGeomObject(list(list(0:0 5:5)) ?as 'Region)->area() == 25.0
        "convert: nested two-point rectangle as Region")
    _AssertError(lambda(() ycGeom::Polygon(list(0 0 ycGeom::Point(1:0) 1:1 0:1)) t)
        "constructor: Polygon mixed raw numbers rejected")
    r = ycGeom::Rect(list(0:0 1:1))
    _Assert(ycGeom::Rect(r->toSkill())->area() == 1.0
        "constructor: Rect toSkill roundtrip")
    _AssertErrorMsg(lambda(() ycGeom::ConvertToGeomObject(poly ?as 'Region) t)
        "expected"  "convert: object target mismatch rejected")
)

_AssertError(lambda(() ycGeom::Polygon(list(0:0 1:0 1:1) list(2:2 3:2 3:3)) t)
    "constructor: Polygon multiple args rejected")
_AssertError(lambda(() ycGeom::Region(list(0:0 1:0 1:1)) list(0:0 1:0 1:1) t)
    "constructor: Region multiple args rejected")
_Assert(ycGeom::ConvertToGeomObject(list())->area() == 0.0
    "convert: empty list is empty Region")
_Assert(ycGeom::ConvertToGeomObject(nil)->area() == 0.0
    "convert: nil is empty Region")

_AssertErrorMsg(lambda(() ycGeom::ConvertToGeomObject(1:2 ?as 'Blah) t)
    "?as"  "convert: invalid ?as rejected")
_AssertErrorMsg(lambda(() ycGeom::ConvertToGeomObject(list(0:0 1:1) ?as 'Polygon) t)
    "at least 3"  "convert: two points rejected as Polygon")

_Assert(ycGeom::Rect(list(0:0 5:5))->or(list(0:0 1:1))->area() == 25.0
    "convert: Rect union two-point array as Rect")
_Assert(ycGeom::Polygon('((0 0) (5 0) (5 5) (0 5)))->or(list(0:0 1:1))->area() == 25.0
    "convert: Polygon union two-point array as Rect")

_TestChildDone = t

; END
