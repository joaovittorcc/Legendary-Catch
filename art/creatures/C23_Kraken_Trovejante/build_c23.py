"""Thunder Kraken: a broad crown silhouette and eight lightning-bent arms."""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "tools" / "blender"))
from creature_mesh import Piece
from export_creature import build_cli

ID = "C23_Kraken_Trovejante"
PALETTE = {
    "hide": ("221949/4D3588/A15BBC", "scale"),
    "underside": ("742D69/D7699C/FBB4AC", "plain"),
    "arm": ("392957/824BA0/E66EC8", "scale"),
    "dark": ("100922/281641", "plain"),
    "rim": ("3B2690/5095D9/A7E8FF", "vein"),
    "bolt": ("388CE0/78F2FF/E8FFFA", "plain"),
    "gold": ("AE623D/FCC767/FFF4A8", "plain"),
    "plate": ("2E285E/565699/9997ED", "armor"),
}


def build():
    body, head, tail, tentacles, crown, cheek_lights = (Piece(name) for name in
        ("Body","Head","Tail","Tentacles","Extra","Extra.001"))
    body.sweep([((0,.12,-.79),.38,.30),((0,.14,-.52),.65,.50),((0,.22,-.10),.67,.58),
                ((0,.28,.34),.62,.56),((0,.32,.67),.48,.42),((0,.34,.86),.31,.29)],
               "hide",sides=18)
    body.oval((0,-.26,-.26),(.52,.26,.44),"underside",sides=15,levels=7)
    tail.sweep([((0,.43,-.17),.49,.21),((0,.78,.13),.54,.18),
                ((0,.99,.41),.35,.12),((0,1.14,.64),.06,.045)],
               "plate",sides=12)
    for s in (-1,1):
        for j in range(3):
            body.gem((s*(.43-j*.105),.31+j*.05,.38+j*.14),
                     (s*(.55-j*.09),.66+j*.07,.55+j*.18),.155-j*.02,
                     "plate",sides=7)

    head.oval((0,-.36,.25),(.65,.43,.51),"hide",sides=16,levels=7)
    head.oval((0,-.60,-.044),(.30,.23,.19),"underside",sides=12,levels=6)
    head.sweep([((0,-.766,-.059),.113,.078),((0,-.852,-.087),.093,.059),
                ((0,-.908,-.139),.025,.023)],"dark",sides=8)
    head.gem((0,-.692,.54),(0,-.74,.70),.14,"rim",sides=6)
    for s in (-1,1):
        head.oval((s*.365,-.653,.237),(.237,.134,.173),"dark",sides=12,levels=6,tilt=-s*.25)
        head.oval((s*.337,-.744,.248),(.166,.078,.115),"gold",sides=11,levels=5,tilt=-s*.29)
        head.oval((s*.326,-.815,.248),(.037,.028,.084),"dark",sides=8,levels=5,tilt=s*.12)
        head.gem((s*.293,-.838,.285),(s*.283,-.858,.308),.024,"bolt",sides=5)
        head.sweep([((s*.13,-.734,.371),.082,.052),((s*.27,-.727,.411),.096,.064),
                    ((s*.46,-.604,.477),.111,.069),((s*.619,-.369,.446),.032,.037)],
                   "plate",sides=8,reference=(0,0,1))
        for j in range(3):
            x, z = s*(.45+.067*j), .038+.052*j
            cheek_lights.gem((x,-.662+j*.058,z),(x+s*.024,-.685+j*.058,z+.045),
                             .026,"bolt",sides=5)

    for j in range(-2,3):
        x = j * .215
        crown.gem((x,-.059+.04*abs(j),.73),
                  (x*1.42,-.23+.10*abs(j),1.29-.095*abs(j)),
                  .133-.009*abs(j),"rim" if j%2 else "bolt",sides=6)
    for side in (-1,1):
        for j in range(3):
            x, y, z = side*(.56-j*.056), .27+j*.12, .32+j*.117
            body.gem((x,y,z),(x+side*.083,y+.035,z+.09),.044,"rim",sides=5)

    for i in range(8):
        angle = (i + .5) * math.tau / 8
        sign = -1 if i % 2 else 1
        reach = 1.24 + 0.18 * (i % 3)

        def p(radius, z, bend=0):
            a=angle+bend*sign
            return (math.cos(a)*radius,math.sin(a)*radius,z)

        tentacles.sweep([(p(.35,-.62),.19,.18),(p(.61,-.78),.19,.16),
                         (p(.99,-.92,.07),.16,.133),(p(reach,-.82,.17),.123,.105),
                         (p(reach+.18,-.51,.29),.083,.069),
                         (p(reach+.09,-.30,.46),.046,.047),
                         (p(reach-.05,-.26,.55),.012,.012)],
                        "arm",sides=6,reference=(0,0,1),steps=2)
        for ring, radius in enumerate((.74,.94)):
            x,y,z=p(radius,-.94+.02*ring,.07*ring)
            tentacles.sweep([((x,y,z),.082-ring*.012,.083-ring*.013),
                             ((x,y,z-.055),.074-ring*.012,.074-ring*.012)],
                            "underside",sides=5)
    return body, head, tail, tentacles, crown, cheek_lights


if __name__ == "__main__":
    build_cli(__file__, ID, "Legendary", build, PALETTE, atlas_size=1024)
