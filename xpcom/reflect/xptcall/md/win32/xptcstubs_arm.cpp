/* -*- Mode: C++; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "xptcprivate.h"
#include "xptiprivate.h"

#include <windows.h>

#define DOUBLEWORD_ALIGN(p) ((uint32_t *)((((uint32_t)(p)) + 7) & ~7))

#define PARAM_BUFFER_COUNT     16
#define PARAM_GPR_COUNT         4
#define PARAM_FPR_COUNT        16 /* single is 16, double is 8 */

extern "C" nsresult
PrepareAndDispatch(nsXPTCStubBase* self, uint32_t methodIndex,
                   uint32_t* gprData, uint32_t* fprData, uint32_t* args)
{
  NS_ASSERTION(self,"no self");

  nsXPTCMiniVariant paramBuffer[PARAM_BUFFER_COUNT];

  const nsXPTMethodInfo* info = nullptr;
  self->mEntry->GetMethodInfo(methodIndex, &info);
  uint8_t paramCount = info->GetParamCount();

  uint32_t* fprSingleCurrent = fprData;
  uint32_t* fprDoubleCurrent = fprData;
  uint32_t* fprEnd = fprData + PARAM_FPR_COUNT;

  uint32_t* gprEnd = gprData + PARAM_GPR_COUNT - 1 /* this */;

  // setup variant array pointer
  nsXPTCMiniVariant* dp;
  if (paramCount > PARAM_BUFFER_COUNT)
    dp = new nsXPTCMiniVariant[paramCount];
  else
    dp = paramBuffer;
  nsXPTCMiniVariant* dispatchParams = dp;

  for (uint8_t i = 0; i < paramCount; i++, dp++) {
    const nsXPTParamInfo& param = info->GetParam(i);
    const nsXPTType& type = param.GetType();

    if (param.IsOut() || !type.IsArithmetic()) {
      if (gprData < gprEnd) {
        dp->val.p = *((void**)gprData++);
      } else {
        dp->val.p = *((void**)args++);
      }
      continue;
    }

    switch (type) {
    case nsXPTType::T_I8:
      if (gprData < gprEnd) {
        dp->val.i8 = *((int8_t*)gprData++);
      } else {
        dp->val.i8 = *((int8_t*)args++);
      }
      break;
    case nsXPTType::T_I16:
      if (gprData < gprEnd) {
        dp->val.i16 = *((int16_t*)gprData++);
      } else {
        dp->val.i16 = *((int16_t*)args++);
      }
      break;
    case nsXPTType::T_I32:
      if (gprData < gprEnd) {
        dp->val.i32 = *((int32_t*)gprData++);
      } else {
        dp->val.i32 = *((int32_t*)args++);
      }
      break;
    case nsXPTType::T_I64:
	  if (gprData + 1 < gprEnd) {
        if (gprData + 2 != gprEnd) {
          gprData++;
		}
        dp->val.i64 = *((int64_t*)gprData);
        gprData += 2;
      } else {
        args = DOUBLEWORD_ALIGN(args);
        dp->val.i64 = *((int64_t*)args);
        args += 2;
      }
      break;
    case nsXPTType::T_U8:
      if (gprData < gprEnd) {
        dp->val.u8 = *((uint8_t*)gprData++);
      } else {
        dp->val.u8 = *((uint8_t*)args++);
      }
      break;
    case nsXPTType::T_U16:
      if (gprData < gprEnd) {
        dp->val.u16 = *((uint16_t*)gprData++);
      } else {
        dp->val.u16 = *((uint16_t*)args++);
      }
      break;
    case nsXPTType::T_U32:
      if (gprData < gprEnd) {
        dp->val.u32 = *((uint32_t*)gprData++);
      } else {
        dp->val.u32 = *((uint32_t*)args++);
      }
      break;
    case nsXPTType::T_U64:
      if (gprData + 1 < gprEnd) {
        if (gprData + 2 != gprEnd) {
          gprData++;
		}
        dp->val.u64 = *((uint64_t*)gprData);
        gprData += 2;
      } else {
        args = DOUBLEWORD_ALIGN(args);
        dp->val.u64 = *((uint64_t*)args);
        args += 2;
      }
      break;
    case nsXPTType::T_FLOAT:
      if (fprSingleCurrent >= fprEnd) {
        dp->val.f = *((float*)args++);
      } else {
        dp->val.f = *((float*)fprSingleCurrent++);
        if (fprSingleCurrent < fprDoubleCurrent) {
          fprSingleCurrent = fprDoubleCurrent;
        } else if (fprSingleCurrent > fprDoubleCurrent) {
          fprDoubleCurrent++;
        }
      }
      break;
    case nsXPTType::T_DOUBLE:
      if (fprDoubleCurrent >= fprEnd) {
        fprSingleCurrent = fprDoubleCurrent;
        args = DOUBLEWORD_ALIGN(args);
        dp->val.d = *((double*)args);
        args += 2;
      } else {
        dp->val.d = *((double*)fprDoubleCurrent);
        if (fprSingleCurrent == fprDoubleCurrent) {
          fprSingleCurrent += 2;
        }
        fprDoubleCurrent += 2;
      }
      break;
    case nsXPTType::T_BOOL:
      if (gprData < gprEnd) {
        dp->val.b = *((bool*)gprData++);
      } else {
        dp->val.b = *((bool*)args++);
      }
      break;
    case nsXPTType::T_CHAR:
      if (gprData < gprEnd) {
        dp->val.c = *((char*)gprData++);
      } else {
        dp->val.c = *((char*)args++);
      }
      break;
    case nsXPTType::T_WCHAR:
      if (gprData < gprEnd) {
        dp->val.wc = *((wchar_t*)gprData++);
      } else {
        dp->val.wc = *((wchar_t*)args++);
      }
      break;
    default:
      NS_ERROR("bad type");
      break;
    }
  }

  nsresult result = self->mOuter->CallMethod(methodIndex, info, dispatchParams);

  if (dispatchParams != paramBuffer)
    delete [] dispatchParams;

  return result;
}

#define STUB_ENTRY(n)  /* defined in the assembly file */

#define SENTINEL_ENTRY(n) \
nsresult nsXPTCStubBase::Sentinel##n() \
{ \
  NS_ERROR("nsXPTCStubBase::Sentinel called"); \
  return NS_ERROR_NOT_IMPLEMENTED; \
}

#include "xptcstubsdef.inc"

void
xptc_dummy()
{
}
