; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.

    ;.set NGPREGS,8
    ;.set NFPREGS,8

    IMPORT |PrepareAndDispatch|
    EXPORT |SharedStub|

    AREA |.text|, CODE, ARM64

|SharedStub| PROC
    stp         x29, x30, [sp,#-16]!
    mov         x29, sp

    sub         sp, sp, #(8*16) ;8*(NGPREGS+NFPREGS)
    stp         x0, x1, [sp, #64+(0*8)]
    stp         x2, x3, [sp, #64+(2*8)]
    stp         x4, x5, [sp, #64+(4*8)]
    stp         x6, x7, [sp, #64+(6*8)]
    stp         d0, d1, [sp, #(0*8)]
    stp         d2, d3, [sp, #(2*8)]
    stp         d4, d5, [sp, #(4*8)]
    stp         d6, d7, [sp, #(6*8)]

    ; methodIndex passed from stub
    mov         w1, w17

    add         x2, sp, #(16+(8*16)) ; 16+(8*(NGPREGS+NFPREGS))
    add         x3, sp, #(8*8) ; 8*NFPREGS
    add         x4, sp, #0

    bl          PrepareAndDispatch

    add         sp, sp, #(8*16)   ; 8*(NGPREGS+NFPREGS)
    ldp         x29, x30, [sp],#16
    ret

    ENDP

    MACRO
    STUBENTRY $functioname,$paramcount
    EXPORT |$functionname|
|$functionname| PROC
    mov         w17, $paramcount
    b           SharedStub
    ENDP
    MEND

    STUBENTRY ?Stub3@nsXPTCStubBase@@UEAA?AW4nsresult@@XZ, 3
    STUBENTRY ?Stub4@nsXPTCStubBase@@UEAA?AW4nsresult@@XZ, 4
    STUBENTRY ?Stub5@nsXPTCStubBase@@UEAA?AW4nsresult@@XZ, 5
    STUBENTRY ?Stub6@nsXPTCStubBase@@UEAA?AW4nsresult@@XZ, 6
    STUBENTRY ?Stub7@nsXPTCStubBase@@UEAA?AW4nsresult@@XZ, 7
    STUBENTRY ?Stub8@nsXPTCStubBase@@UEAA?AW4nsresult@@XZ, 8
    STUBENTRY ?Stub9@nsXPTCStubBase@@UEAA?AW4nsresult@@XZ, 9

    END
