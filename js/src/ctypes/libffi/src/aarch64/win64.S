; Copyright (c) 2009, 2010, 2011, 2012 ARM Ltd.
;
; Permission is hereby granted, free of charge, to any person obtaining
; a copy of this software and associated documentation files (the
; ``Software''), to deal in the Software without restriction, including
; without limitation the rights to use, copy, modify, merge, publish,
; distribute, sublicense, and/or sell copies of the Software, and to
; permit persons to whom the Software is furnished to do so, subject to
; the following conditions:
;
; The above copyright notice and this permission notice shall be
; included in all copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED ``AS IS'', WITHOUT WARRANTY OF ANY KIND,
; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
; IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
; CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
; TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

  OPT 2 ; disable listing

#include "ksarm64.h"

  OPT 1 ; re-enable listing

  IMPORT |ffi_closure_SYSV_inner|
  EXPORT |ffi_call_SYSV|
  EXPORT |ffi_closure_SYSV|

  TEXTAREA

#define ffi_call_SYSV_FS (8 * 4)

  ; extern unsigned
  ; ffi_call_SYSV (void (*)(struct call_context *context,
  ;                         unsigned char *,
  ;                         extended_cif *),
  ;                         struct call_context *context,
  ;                         extended_cif *,
  ;                         size_t required_stack_size,
  ;                         void (*fn)(void));
  NESTED_ENTRY ffi_call_SYSV

  PROLOG_SAVE_REG_PAIR fp, lr, #-16!
  PROLOG_STACK_ALLOC ffi_call_SYSV_FS

  stp     x21, x22, [sp, #0]
  stp     x23, x24, [sp, #16]

  mov     x21, x1
  mov     x22, x2
  mov     x24, x4

  ; Allocate the stack space for the actual arguments, many
  ; arguments will be passed in registers, but we assume
  ; worst case and allocate sufficient stack for ALL of
  ; the arguments.
  sub     sp, sp, x3

  ; unsigned (*prepare_fn) (struct call_context *context,
  ;                         unsigned char *stack, extended_cif *ecif)
  mov     x23, x0
  mov     x0, x1
  mov     x1, sp

  ; x2 already in place
  blr     x23

  ; Preserve the flags returned.
  mov     x23, x0

  ; Figure out if we should touch the vector registers.
  tbz     x23, #0, ffi_call_non_vector

  ; Load the vector argument passing registers
  ldp     q0, q1, [x21, #256]
  ldp     q2, q3, [x21, #(256 + 32)]
  ldp     q4, q5, [x21, #(256 + 64)]
  ldp     q6, q7, [x21, #(256 + 96)]

ffi_call_non_vector
  ; Load the core argument passing registers.
  ldp     x0, x1, [x21]
  ldp     x2, x3, [x21, #16]
  ldp     x4, x5, [x21, #32]
  ldp     x6, x7, [x21, #48]

  ; Don't forget x8 which may be holding the address of a return buffer.
  ldr     x8, [x21, #64]

  blr     x24

  ; Save the core argument passing registers.
  stp     x0, x1, [x21]
  stp     x2, x3, [x21, #16]
  stp     x4, x5, [x21, #32]
  stp     x6, x7, [x21, #48]

  ; Note nothing useful ever comes back in x8!

  ; Figure out if we should touch the vector registers.
  tbz     x23, #0, ffi_call_finish

  ; Save the vector argument passing registers.
  stp     q0, q1, [x21, #256]
  stp     q2, q3, [x21, #(256 + 32)]
  stp     q4, q5, [x21, #(256 + 64)]
  stp     q6, q7, [x21, #(256 + 96)]

ffi_call_finish
  ; All done, unwind our stack frame
  ldp     x21, x22, [x29, # - ffi_call_SYSV_FS]
  ldp     x23, x24, [x29, # - ffi_call_SYSV_FS + 16]

  EPILOG_STACK_RESTORE
  EPILOG_RESTORE_REG_PAIR fp, lr, #16!
  EPILOG_RETURN
  NESTED_END


  NESTED_ENTRY ffi_closure_SYSV

  PROLOG_SAVE_REG_PAIR fp, lr, #-16!
  PROLOG_STACK_ALLOC 0x320

  stp     x21, x22, [fp, #-16]
  
  mov     x21, sp
  ; Preserve our struct trampoline_data
  mov     x22, x17

  ; Save the rest of the argument passing registers.
  stp     x0, x1, [x21]
  stp     x2, x3, [x21, #16]
  stp     x4, x5, [x21, #32]
  stp     x6, x7, [x21, #48]

  ; Don't forget we may have been given a result scratch pad address.
  str     x8, [x21, #64]

  ; Figure out if we should touch the vector registers.
  ldr     x0, [x22, #8]
  tbz     x0, #0, ffi_closure_non_vector

  ; Save the argument passing vector registers.
  stp     q0, q1, [x21, #256]
  stp     q2, q3, [x21, #(256 + 32)]
  stp     q4, q5, [x21, #(256 + 64)]
  stp     q6, q7, [x21, #(256 + 96)]

ffi_closure_non_vector
  ; Load &ffi_closure.
  ldr     x0, [x22]
  mov     x1, x21

  ; Compute the location of the stack at the point that the
  ; trampoline was called.
  add     x2, x29, #0x10

  bl      ffi_closure_SYSV_inner

  ; Figure out if we should touch the vector registers.
  ldr     x0, [x22, #8]
  tbz     x0, #0, ffi_closure_finish

  ; Load the result passing vector register.
  ldp     q0, q1, [x21, #256]
  ldp     q2, q3, [x21, #(256 + 32)]
  ldp     q4, q5, [x21, #(256 + 64)]
  ldp     q6, q7, [x21, #(256 + 96)]

ffi_closure_finish
  ; Load the result passing core registers.
  ldp     x0, x1, [x21]
  ldp     x2, x3, [x21, #16]
  ldp     x4, x5, [x21, #32]
  ldp     x6, x7, [x21, #48]
  ; Note nothing useful is returned in x8.

  ; We are done, unwind our frame.
  ldp     x21, x22, [x29,  #-16]
  EPILOG_STACK_RESTORE
  EPILOG_RESTORE_REG_PAIR fp, lr, #16!
  EPILOG_RETURN
  NESTED_END

  END