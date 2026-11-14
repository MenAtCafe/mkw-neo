# Keyboard layout

The Mac front end maps the keyboard to the pad. Without `DM_KBD_MAP` it uses the default: J K U I for A B X Y, F G for the
stick press, Q E Z C for L R ZL ZR, Return and Tab for + and -, the arrow keys for the D-pad, and nothing for the right
stick (the camera), which is why the default is unusable in a 3D game without a controller.

`DM_KBD_MAP` replaces it, and this build ships one in `assets/env.txt`:

```
DM_KBD_MAP=A=C,B=X,X=V,Y=Z,L=E,R=U,ZL=Q,ZR=O,PLUS=EQUAL|KEYPAD_PLUS,MINUS=MINUS|KEYPAD_MINUS,\
            LS=F,RS=H,RSTICK_UP=I,RSTICK_DOWN=K,RSTICK_LEFT=J,RSTICK_RIGHT=L,\
            LSTICK_UP=W,LSTICK_DOWN=S,LSTICK_LEFT=A,LSTICK_RIGHT=D,SHAKE=SPACE
```

| Key | Pad |
|---|---|
| C X V Y | A B X Y |
| Q E | ZL ZR |
| E R | L R |
| F H | click left / right stick |
| WASD | left stick |
| I J K L | right stick (camera) |
| = - | + - |
| Space | shake |

## The format

`ACTION=KEY,ACTION=KEY,…` with `|` between alternative keys of one action. Names are key codes (the macOS virtual key
code, so `C` is 8) or the named keys `EQUAL`, `MINUS`, `SPACE`, `RETURN`, `TAB`, `ESCAPE` and `KEYPAD_PLUS` /
`KEYPAD_MINUS`. Actions are `A B X Y L R ZL ZR PLUS MINUS LS RS`, `LSTICK_UP DOWN LEFT RIGHT`,
`RSTICK_UP DOWN LEFT RIGHT`, and `SHAKE`.

Hold Shift with a mapped letter and it drives the right stick instead, so IJKL and Shift+WASD both work as camera.

## Where it lives

The map is read once at startup. `assets/env.txt` is baked into the app; the same line in
`~/Library/Application Support/nxnative/0400C3F00006E000/env.txt` overrides it for a single machine.
