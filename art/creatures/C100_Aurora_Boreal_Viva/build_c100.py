"""Living Aurora: a frost serpent with a teal-to-rose aurora mantle."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "tools" / "blender"))
from creature_mesh import Piece
from export_creature import build_cli

ID = "C100_Aurora_Boreal_Viva"
PALETTE = {
    "scales": ("201758/3367A4/4DDCD3", "scale"),
    "face": ("1B256E/138C88/46F4B4", "scale"),
    "pearl": ("6F82C4/AADBE6/F5F7DF", "armor"),
    "shadow": ("130B2B/29204D", "plain"),
    "eye": ("B555AC/F781C9/FFF0AC", "plain"),
    "spark": ("AEFFF0/EFFFFF", "plain"),
    "crest": ("3290C1/5FE0D7/D7FFF1", "vein"),
    "aurora": ("241C70/0855A4/0CD4B9/ACFFE0", "vein"),
    "ribbon": ("392B89/8B33D7/F354B3/FFD1E5", "vein"),
    "violet": ("251856/6750A5/A2BDF3", "star"),
}


def build():
    body, head, tail, fins, wings, extra, right_glow = (Piece(name) for name in
        ("Body", "Head", "Tail", "Fins", "Wings", "Extra", "Extra.001"))
    back = [((-.03,.18,-.78),.32,.28),((.37,.10,-.60),.34,.29),
            ((.54,.05,-.25),.35,.29),((.50,-.03,.07),.33,.27),
            ((.28,-.13,.35),.30,.24),((.04,-.26,.61),.26,.22),
            ((-.06,-.39,.86),.25,.22),((-.02,-.53,1.05),.25,.23)]
    body.sweep(back, "scales", sides=16,steps=3,v_range=(.48,1))
    belly = [((x,y-.18,z),w*.67,d*.46) for (x,y,z),w,d in back[1:]]
    belly.insert(0,((.12,.01,-.75),.025,.025))
    body.sweep(belly, "pearl", sides=12,steps=2)
    curve = [((.08,.16,-.74),.315,.27),((-.42,.23,-.91),.30,.26),
                ((-.87,.37,-.76),.27,.22),((-1.12,.51,-.46),.21,.18),
                ((-1.08,.75,-.11),.14,.12),((-.89,.93,.10),.08,.10),
                ((-.69,1.03,.16),.025,.04)]
    tail.sweep(curve[::-1],"scales",sides=16,steps=3,v_range=(0,.49))
    tail.sweep([((-.91,.65,-.46),.04,.09),((-1.18,.82,-.26),.15,.08),
                ((-1.25,1.09,-.01),.21,.05),((-1.09,1.36,.28),.04,.024)],"aurora",sides=8)
    tail.sweep([((-.94,.74,-.36),.05,.07),((-1.00,1.04,-.27),.13,.04),
                ((-.80,1.31,-.11),.14,.04),((-.52,1.36,.10),.015,.012)],"ribbon",sides=8)

    head.oval((0,-.65,1.14),(.43,.39,.34),"face",sides=16,levels=7)
    head.oval((0,-.92,1.03),(.30,.26,.155),"face",sides=14,levels=6)
    head.oval((0,-.88,.947),(.27,.21,.09),"pearl",sides=12,levels=5)
    head.gem((0,-.86,1.34),(0,-.70,1.72),.10,"crest")
    for side in (-1,1):
        head.oval((side*.225,-.932,1.193),(.152,.081,.103),"shadow",sides=11,levels=5,tilt=-side*.27)
        head.oval((side*.224,-.991,1.189),(.109,.044,.073),"eye",sides=10,levels=5,tilt=-side*.28)
        head.oval((side*.211,-1.028,1.193),(.033,.022,.065),"shadow",sides=8,levels=5,tilt=side*.10)
        head.gem((side*.181,-1.043,1.217),(side*.194,-1.065,1.229),.019,"spark",sides=5)
        head.oval((side*.102,-1.147,1.067),(.041,.015,.024),"shadow",sides=8,levels=4)
        head.sweep([((side*.19,-.58,1.35),.095,.08),((side*.29,-.47,1.51),.066,.062),
                    ((side*.42,-.36,1.58),.051,.045),((side*.55,-.37,1.73),.012,.011)],
                   "crest",sides=8,steps=2)
        fins.sweep([((side*.30,-.52,1.10),.075,.13),((side*.49,-.43,1.14),.052,.225),
                    ((side*.65,-.24,1.29),.036,.16),((side*.81,-.09,1.52),.008,.014)],
                   "ribbon",sides=8,reference=(0,1,.12),steps=2)
        fins.sweep([((side*.35,-.50,1.09),.05,.073),((side*.47,-.31,.98),.035,.10),
                    ((side*.73,-.12,.93),.010,.010)],"crest",sides=7,reference=(0,1,0))

        for i in range(3):
            root=(side*.18,-.03,.47-i*.17)
            reach=1.45-i*.16
            wings.sweep([(root,.04,.115),((side*.65,.27,.52-i*.25),.052,.22),
                         ((side*1.05,.55,.69-i*.24),.042,.17),
                         ((side*reach,.70,.91-i*.30),.021,.09),
                         ((side*(reach+.07),.78,1.16-i*.35),.007,.013)],
                        ("aurora","ribbon","violet")[i],sides=8,reference=(0,1,.12),steps=3)
        glow = extra if side == -1 else right_glow
        for j in range(3):
            x, y, z = side*(.293+.037*j), -.956+.06*j, 1.063+.02*j
            glow.gem((x,y,z),(x+side*.020,y-.029,z+.024),.023-j*.004,
                     "spark" if j%2 else "eye",sides=5)
    return body, head, tail, fins, wings, extra, right_glow


if __name__ == "__main__":
    build_cli(__file__, ID, "Legendary", build, PALETTE, atlas_size=1024)
