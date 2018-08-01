/* -*- Mode: C++; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "xptcprivate.h"

static void
copy_word(uint32_t* &ireg_args,
          uint32_t* &stack_args,
          uint32_t* end,
          uint32_t  data)
{
  if (ireg_args < end) {
    *ireg_args = data;
    ireg_args++;
  } else {
    *stack_args = data;
    stack_args++;
  }
}

static void
copy_dword(uint32_t* &ireg_args,
           uint32_t* &stack_args,
           uint32_t* end,
           uint64_t  data)
{
  if (ireg_args + 1 < end) {
    if ((uint32_t)ireg_args & 4) {
      ireg_args++;
    }
    *(uint64_t *)ireg_args = data;
    ireg_args += 2;
  } else {
    if ((uint32_t)stack_args & 4) {
      stack_args++;
    }
    *(uint64_t *)stack_args = data;
    stack_args += 2;
  }
}

static bool
copy_vfp_single(float* &vfp_s_args, double* &vfp_d_args,
                float* end, float data)
{
  if (vfp_s_args >= end)
    return false;

  *vfp_s_args = data;
  vfp_s_args++;
  if (vfp_s_args < (float *)vfp_d_args) {
    // It was the case of back-filling, now the next free single precision
    // register should overlap with the next free double precision register
    vfp_s_args = (float *)vfp_d_args;
  } else if (vfp_s_args > (float *)vfp_d_args) {
    // also update the pointer to the next free double precision register
    vfp_d_args++;
  }
  return true;
}

static bool
copy_vfp_double(float* &vfp_s_args, double* &vfp_d_args,
                float* end, double data)
{
  if (vfp_d_args >= (double *)end) {
    // The back-filling continues only so long as no VFP CPRC has been
    // allocated to a slot on the stack. Basically no VFP registers can
    // be allocated after this point.
    vfp_s_args = end;
    return false;
  }

  if (vfp_s_args == (float *)vfp_d_args) {
    // also update the pointer to the next free single precision register
    vfp_s_args += 2;
  }
  *vfp_d_args = data;
  vfp_d_args++;
  return true;
}

extern "C" void
invoke_copy_to_stack(uint32_t* stk, uint32_t *end,
                     uint32_t paramCount, nsXPTCVariant* s)
{
  uint32_t *ireg_args  = end - 3;
  float    *vfp_s_args = (float *)end;
  double   *vfp_d_args = (double *)end;
  float    *vfp_end    = vfp_s_args + 16;

  for (uint32_t i = 0; i < paramCount; i++, s++) {
    if (s->IsIndirect()) {
      copy_word(ireg_args, stk, end, (uint32_t)&s->val);
      continue;
    }
    // According to the ARM EABI, integral types that are smaller than a word
    // are to be sign/zero-extended to a full word and treated as 4-byte values
    switch (s->type)
    {
      case nsXPTType::T_FLOAT:
        if (!copy_vfp_single(vfp_s_args, vfp_d_args, vfp_end, s->val.f)) {
          copy_word(end, stk, end, reinterpret_cast<uint32_t&>(s->val.f));
        }
        break;
      case nsXPTType::T_DOUBLE:
        if (!copy_vfp_double(vfp_s_args, vfp_d_args, vfp_end, s->val.d)) {
          copy_dword(end, stk, end, reinterpret_cast<uint64_t&>(s->val.d));
        }
        break;
      case nsXPTType::T_I8:  copy_word(ireg_args, stk, end, s->val.i8);   break;
      case nsXPTType::T_I16: copy_word(ireg_args, stk, end, s->val.i16);  break;
      case nsXPTType::T_I32: copy_word(ireg_args, stk, end, s->val.i32);  break;
      case nsXPTType::T_I64: copy_dword(ireg_args, stk, end, s->val.i64); break;
      case nsXPTType::T_U8:  copy_word(ireg_args, stk, end, s->val.u8);   break;
      case nsXPTType::T_U16: copy_word(ireg_args, stk, end, s->val.u16);  break;
      case nsXPTType::T_U32: copy_word(ireg_args, stk, end, s->val.u32);  break;
      case nsXPTType::T_U64: copy_dword(ireg_args, stk, end, s->val.u64); break;
      case nsXPTType::T_BOOL: copy_word(ireg_args, stk, end, s->val.b);   break;
      case nsXPTType::T_CHAR: copy_word(ireg_args, stk, end, s->val.c);   break;
      case nsXPTType::T_WCHAR: copy_word(ireg_args, stk, end, s->val.wc); break;
      default:
        // all the others are plain pointer types
        copy_word(ireg_args, stk, end, reinterpret_cast<uint32_t>(s->val.p));
        break;
    }
  }
}

extern "C" nsresult
XPTC__InvokebyIndex(nsISupports* that, uint32_t methodIndex,
                    uint32_t paramCount, nsXPTCVariant* params);

extern "C"
EXPORT_XPCOM_API(nsresult)
NS_InvokeByIndex(nsISupports* that, uint32_t methodIndex,
                   uint32_t paramCount, nsXPTCVariant* params)
{
  return XPTC__InvokebyIndex(that, methodIndex, paramCount, params);
}
