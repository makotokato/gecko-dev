; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.

; Windows ARM uses Thumb-2 as ABI

    THUMB

    IMPORT  |invoke_copy_to_stack|
    EXPORT  |XPTC__InvokebyIndex|

    AREA    |.text|, CODE, THUMB

;XPTC__InvokebyIndex(nsISupports* that, PRUint32 methodIndex,
;                   PRUint32 paramCount, nsXPTCVariant* params)
;

|XPTC__InvokebyIndex| PROC
    push    {r4-r7,r11,lr}

    sub     r11, sp, #16 ; stack frame

    mov     r7, r1 ; methodIndex
    cbz     r2, noparam

    ; r4 -> param_count_plus_2
    add     r4, r2, #2
    ; r6 -> that
    mov     r6, r0
    ; r5 -> stack_space_size
    mov     r5, r4, lsl #3
    add     r5, r5, #(4 * 16) ; space for VFP registers and alignment

    sub     sp, sp, r5 ; allocate space on stack

    mov     r0, sp ; stack
    add     r1, sp, r4, lsl #3 ; stack end
    ; r2 and r3 are already stored

    ; void invoke_copy_to_stack(uint32_t* stk, uint32_t *end,
    ;                           uint32_t paramCount, nsXPTCVariant* s)
    bl      invoke_copy_to_stack

    mov     r0, r6 ; that

    add     ip, sp, r4, lsl #3 ; stack end
    ldmdb   ip, {r1, r2, r3}
    vldm    ip, {d0, d1, d2, d3, d4, d5, d6, d7}

noparam
    ldr     ip, [r0]
    ldr     ip, [ip, r7, lsl #2] ; r7 is methodIndex
    blx     ip

    add     r11, r11, #16
    mov     sp, r11 ; cleanup stack
    pop     {r4-r7,r11,pc}

    ENDP

    END
