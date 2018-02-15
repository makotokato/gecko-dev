  IMPORT |ffi_closure_SYSV_inner|
  EXPORT |ffi_call_SYSV|
  EXPORT |ffi_closure_SYSV|

  AREA |.text|, CODE, ARM64

|ffi_call_SYSV| PROC
  stp     x29, x30, [sp, #-16]!
  mov     x29, sp
  sub     sp, sp, #0x20
  stp     x21, x22, [sp]
  stp     x23, x24, [sp, #16]
  mov     x21, x1
  mov     x22, x2
  mov     x24, x4
  sub     sp, sp, x3
  mov     x23, x0
  mov     x0, x1
  mov     x1, sp
  blr     x23
  mov     x23, x0
  ; armasm64 cannnot use w register for tbz
  tbz     x23, #0, ffi_call_L1
  ldp     q0, q1, [x21, #256]
  ldp     q2, q3, [x21, #288]
  ldp     q4, q5, [x21, #320]
  ldp     q6, q7, [x21, #352]
ffi_call_L1
  ldp     x0, x1, [x21]
  ldp     x2, x3, [x21, #16]
  ldp     x4, x5, [x21, #32]
  ldp     x6, x7, [x21, #48]
  ldr     x8, [x21, #64]
  blr     x24
  stp     x0, x1, [x21]
  stp     x2, x3, [x21, #16]
  stp     x4, x5, [x21, #32]
  stp     x6, x7, [x21, #48]
  ; armasm64 cannnot use w register for tbz
  tbz     x23, #0, ffi_call_L2
  stp     q0, q1, [x21, #256]
  stp     q2, q3, [x21, #288]
  stp     q4, q5, [x21, #320]
  stp     q6, q7, [x21, #352]
ffi_call_L2
  ldp     x21, x22, [x29, #-32]
  ldp     x23, x24, [x29, #-16]
  mov     sp, x29
  ldp     x29, x30, [sp], #16
  ret
  ENDP

|ffi_closure_SYSV| PROC
  stp     x29, x30, [sp, #-16]!
  mov     x29, sp
  sub     sp, sp, #0x310
  stp     x21, x22, [x29, #-16]
  mov     x21, sp
  mov     x22, x17
  stp     x0, x1, [x21]
  stp     x2, x3, [x21, #16]
  stp     x4, x5, [x21, #32]
  stp     x6, x7, [x21, #48]
  str     x8, [x21, #64]
  ldr     x0, [x22, #8]
  ; armasm64 cannnot use w register for tbz
  tbz     x0, #0, ffi_closure_L1
  stp     q0, q1, [x21, #256]
  stp     q2, q3, [x21, #288]
  stp     q4, q5, [x21, #320]
  stp     q6, q7, [x21, #352]
ffi_closure_L1
  ldr     x0, [x22]
  mov     x1, x21
  add     x2, x29, #0x10
  bl      ffi_closure_SYSV_inner
  ldr     x0, [x22, #8]
  ; armasm64 cannnot use w register for tbz
  tbz     x0, #0, ffi_closure_L2
  ldp     q0, q1, [x21, #256]
  ldp     q2, q3, [x21, #288]
  ldp     q4, q5, [x21, #320]
  ldp     q6, q7, [x21, #352]
ffi_closure_L2
  ldp     x0, x1, [x21]
  ldp     x2, x3, [x21, #16]
  ldp     x4, x5, [x21, #32]
  ldp     x6, x7, [x21, #48]
  ldp     x21, x22, [x29, #-16]
  mov     sp, x29
  ldp     x29, x30, [sp], #16
  ret
  ENDP
  END
