// Copyright (c) 2008 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "build/build_config.h"
#include "base/mac_util.h"

#if !defined(OS_IOS)
#include <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#else
#import <CoreFoundation/CoreFoundation.h>
#endif

#include "base/file_path.h"
#include "base/logging.h"
#include "base/scoped_cftyperef.h"
#include "base/sys_string_conversions.h"

namespace mac_util {

// Adapted from http://developer.apple.com/carbon/tipsandtricks.html#AmIBundled
bool AmIBundled() {
#if defined(OS_IOS)
  return true;
#else
  ProcessSerialNumber psn = {0, kCurrentProcess};

  FSRef fsref;
  if (GetProcessBundleLocation(&psn, &fsref) != noErr) return false;

  FSCatalogInfo info;
  if (FSGetCatalogInfo(&fsref, kFSCatInfoNodeFlags, &info, NULL, NULL, NULL) != noErr) {
    return false;
  }

  return info.nodeFlags & kFSNodeIsDirectoryMask;
#endif
}

}  // namespace mac_util
