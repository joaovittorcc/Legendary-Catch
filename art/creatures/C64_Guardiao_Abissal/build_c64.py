"""Abyssal Guardian: a cinder lantern and a pressure-forged diving suit."""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "tools" / "blender"))
from creature_mesh import Piece
from export_creature import build_cli

ID = "C64_Guardiao_Abissal"
PALETTE = {
    "bronze": ("3B263C/9D5141/E4A65E", "armor"),
    "gold": ("945036/F6B04E/FFE5A9", "plain"),
    "iron": ("192238/434F65/79839A", "armor"),
    "obsidian": ("140F22/252742/5B5274", "vein"),
    "leather": ("221921/4A344A", "plain"),
    "maroon": ("241734/70314C/B75458", "armor"),
    "ember": ("F04C29/F29440/FFE59A", "plain"),
    "fire": ("E75C35/FFCA55/FFF1AD", "vein"),
    "kelp": ("143C47/247571/80BFA2", "vein"),
}


def build():
    body, head, tail, claws, kelp, shell, lamp, eyes, heat = (Piece(name) for name in
        ("Body","Head","Tail","Claws","Tentacles","Shell","Extra","Extra.001","Extra.002"))
    body.sweep([((0,.07,-.49),.38,.24),((0,.02,-.21),.46,.29),((0,.02,.14),.49,.33),
                ((0,.06,.48),.61,.36),((0,.12,.63),.50,.29),((0,.13,.71),.30,.22)],
               "iron",sides=16)
    body.oval((0,-.16,.21),(.53,.24,.39),"bronze",sides=14,levels=6)
    body.oval((0,-.349,.23),(.275,.078,.245),"obsidian",sides=12,levels=6)
    for i in range(8):
        a = i * math.tau / 8
        x, z = math.cos(a) * .31, .23 + math.sin(a) * .265
        body.gem((x,-.351,z),(x,-.426,z),.034,"gold",sides=5)
    body.sweep([((0,-.324,-.19),.46,.09),((0,-.364,-.31),.43,.085),((0,-.334,-.41),.36,.07)],
               "gold",sides=12)
    body.gem((0,-.43,-.21),(0,-.48,-.39),.135,"bronze")
    for s in (-1,1):
        body.sweep([((s*.26,.10,-.31),.21,.22),((s*.29,.10,-.59),.212,.23),
                    ((s*.33,.12,-.87),.18,.18),((s*.35,.04,-1.15),.20,.16),((s*.35,-.02,-1.39),.20,.17)],
                   "leather",sides=11)
        body.gem((s*.34,-.112,-.75),(s*.35,-.19,-1.41),.213,"bronze")
        body.oval((s*.35,-.15,-1.40),(.235,.36,.16),"iron",sides=12,levels=5)
        body.gem((s*.35,-.31,-1.37),(s*.35,-.50,-1.41),.155,"gold")

    head.oval((0,-.03,.99),(.39,.34,.40),"iron",sides=16,levels=8)
    head.oval((0,-.285,1.005),(.365,.162,.252),"bronze",sides=14,levels=6)
    head.oval((0,-.400,1.019),(.281,.080,.161),"obsidian",sides=14,levels=5)
    head.sweep([((-.26,-.416,1.052),.050,.054),((-.13,-.485,1.103),.033,.041),
                ((0,-.495,1.045),.057,.04),((.13,-.485,1.103),.033,.039),((.26,-.416,1.052),.05,.054)],
               "gold",sides=8,reference=(0,0,1))
    head.gem((0,-.19,1.215),(0,-.11,1.52),.148,"bronze")
    for s in (-1,1):
        head.oval((s*.320,-.177,1.003),(.105,.13,.15),"gold",sides=10,levels=5)
        head.gem((s*.34,.023,1.06),(s*.50,.17,1.41),.12,"iron")
        eyes.oval((s*.126,-.484,1.015),(.087,.033,.048),"fire",sides=10,levels=5,tilt=-s*.37)

    for s in (-1,1):
        shell.oval((s*.55,.07,.52),(.37,.35,.245),"iron",sides=13,levels=6,tilt=-s*.27)
        shell.gem((s*.44,-.19,.54),(s*.90,-.04,.64),.206,"bronze")
        shell.gem((s*.58,.04,.61),(s*.94,.17,.91),.148,"obsidian")
        for i in range(3):
            shell.gem((s*(.49+.111*i),-.23,.44),(s*(.55+.122*i),-.30,.49+.043*i),.039,"gold",sides=5)
    shell.oval((0,.34,.25),(.46,.24,.48),"bronze",sides=14,levels=7)
    for i in range(3):
        shell.gem((0,.46,.49-i*.20),(0,.68,.38-i*.19),.15,"obsidian")
        heat.gem((0,-.410,.355-i*.14),(0,-.455,.317-i*.14),.120-i*.023,"fire",sides=6)
    for s in (-1,1):
        shell.sweep([((s*.31,.44,.49),.059,.056),((s*.43,.42,.36),.062,.062),
                     ((s*.46,.43,.04),.064,.055),((s*.33,.46,-.16),.060,.055),
                     ((s*.18,.42,-.20),.050,.046)],"gold",sides=7,steps=2)

    claws.sweep([((-.58,.02,.41),.169,.20),((-.74,-.06,.15),.17,.16),((-.79,-.30,-.09),.18,.16),
                  ((-.73,-.55,.08),.21,.185),((-.65,-.64,.24),.13,.15)],"iron",sides=12)
    claws.sweep([((.57,.05,.41),.17,.20),((.75,.04,.12),.18,.17),((.84,-.10,-.18),.20,.19),
                  ((.86,-.24,-.45),.16,.145)],"bronze",sides=12)
    for s in (-1,1):
        x, y, z = ((-.65,-.65,.22) if s < 0 else (.86,-.27,-.45))
        claws.oval((x,y,z),(.16,.155,.15),"leather",sides=11,levels=5)
        for i in range(3):
            dx=(i-1)*.083
            claws.gem((x+dx,y-.06,z),(x+dx*1.23,y-.20,z+.08*s),.05,"gold",sides=5)

    lamp.oval((-.65,-.68,-.12),(.191,.18,.27),"fire",sides=12,levels=7)
    for z, radius in [(.065,.20),(-.30,.21)]:
        claws.sweep([((-.65,-.68,z-.052),radius*.78,radius*.78),
                     ((-.65,-.68,z),radius,radius),((-.65,-.68,z+.047),radius*.90,radius*.90)],
                    "bronze",sides=12)
    for i in range(4):
        a = math.pi * (0.25 + i*.5)
        x, y = -.65+math.cos(a)*.158, -.68+math.sin(a)*.158
        claws.sweep([((x,y,-.30),.022,.022),((x,y,-.10),.026,.026),((x,y,.078),.02,.02)],"gold",sides=5)

    for s in (-1,1):
        tail.sweep([((s*.23,.23,-.30),.20,.056),((s*.32,.43,-.73),.25,.057),
                    ((s*.42,.54,-1.10),.24,.051),((s*.48,.58,-1.47),.105,.024),
                    ((s*.63,.62,-1.42),.011,.011)],"maroon",sides=8)
        for i in range(2):
            kelp.sweep([((s*(.40+.17*i),.34,-1.33+i*.16),.07,.055),
                        ((s*(.69+.13*i),.41,-1.23+i*.23),.097,.071),
                        ((s*(.80+.17*i),.37,-.97+i*.21),.063,.05),
                        ((s*(.70+.26*i),.42,-.78+i*.20),.013,.012)],"kelp",sides=8)
    return body, head, tail, claws, kelp, shell, lamp, eyes, heat


if __name__ == "__main__":
    build_cli(__file__, ID, "Legendary", build, PALETTE, atlas_size=1024)
