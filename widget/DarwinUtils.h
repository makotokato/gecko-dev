/* -*- Mode: C++; tab-width: 20; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef DarwinUtils_h_
#define DarwinUtils_h_

#include <Foundation/Foundation.h>

namespace mozilla {

// Provide a local autorelease pool for the remainder of a method's execution.
class MOZ_RAII nsAutoreleasePool final {
 public:
  nsAutoreleasePool() { mLocalPool = [[NSAutoreleasePool alloc] init]; }
  ~nsAutoreleasePool() { [mLocalPool release]; }

 private:
  NSAutoreleasePool* mLocalPool;
};

}

#endif
