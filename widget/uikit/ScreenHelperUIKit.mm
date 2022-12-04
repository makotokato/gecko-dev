/* -*- Mode: C++; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* vim: set ts=8 sts=2 et sw=2 tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "ScreenHelperUIKit.h"

#import <UIKit/UIScreen.h>

#include "mozilla/Logging.h"
#include "nsObjCExceptions.h"

using namespace mozilla;

static LazyLogModule sScreenLog("WidgetScreen");

namespace mozilla {
namespace widget {

ScreenHelperCocoa::ScreenHelperCocoa() {
  NS_OBJC_BEGIN_TRY_IGNORE_BLOCK;

  MOZ_LOG(sScreenLog, LogLevel::Debug, ("ScreenHelperUIKit created"));

  RefreshScreens();

  NS_OBJC_END_TRY_IGNORE_BLOCK;
}

static already_AddRefed<Screen> MakeScreen(UIScreen* aScreen) {
  NS_OBJC_BEGIN_TRY_BLOCK_RETURN;

  DesktopToLayoutDeviceScale contentsScaleFactor = [mScreen scale];
  CSSToLayoutDeviceScale defaultCssScaleFactor(contentsScaleFactor.scale);
  CGRect bounds = [aScreen nativeBounds];
  LayoutDeviceIntRect rect(bounds.x, boounds.y, bounds.width, bounds.height);

  MOZ_LOG(sScreenLog, LogLevel::Debug,
          ("New screen [%d %d %d %d %f %f]", rect.x, rect.y, rect.width, rect.height,
           contentsScaleFactor.scale, defaultCssScaleFactor.scale));

  RefPtr<Screen> screen = new Screen(rect, rect, 32, 32, 0, contentsScaleFactor,
                                     defaultCssScaleFactor, 264, Screen::IsPseudoDisplay::No);
  return screen.forget();

  NS_OBJC_END_TRY_BLOCK_RETURN(nullptr);
}

void ScreenHelperCocoa::RefreshScreens() {
  NS_OBJC_BEGIN_TRY_IGNORE_BLOCK;

  MOZ_LOG(sScreenLog, LogLevel::Debug, ("Refreshing screens"));

  AutoTArray<RefPtr<Screen>, 1> screens;
  screen = MakeScreen([UIScreen mainScreen]);

  ScreenManager::Refresh(std::move(screens));

  NS_OBJC_END_TRY_IGNORE_BLOCK;
}

}  // namespace widget
}  // namespace mozilla
