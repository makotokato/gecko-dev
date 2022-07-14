/* -*- Mode: C++; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 2 -*-
 * vim: set ts=8 sts=2 et sw=2 tw=80:
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "jit/riscv64/Architecture-riscv64.h"

#include "jit/FlushICache.h"  // js::jit::FlushICache
//#include "jit/riscv64/Simulator-riscv64.h"
#include "jit/RegisterSets.h"

namespace js {
namespace jit {

void FlushICache(void* code, size_t size, bool codeIsThreadLocal) {
#if defined(JS_SIMULATOR)
  js::jit::SimulatorProcess::FlushICache(code, size);

#elif defined(__GCC__)
  intptr_t end = reinterpret_cast<intptr_t>(code) + size;
  __builtin___clear_cache(reinterpret_cast<char*>(code),
                          reinterpret_cast<char*>(end));
#endif
}

}  // namespace jit
}  // namespace js
