/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "OnScreenKeyboardManagerAndroid.h"
#include "nsWindow.h"

namespace mozilla {
namespace widget {

void OnScreenKeyboardManagerAndroid::Show() {
  if (mWidnow->IsDestroyed()) {
    return;
  }
  mWindow->ShowOnScreenKeyboard(true);
}

void OnScreenKeyboardManagerAndroid::Dismiss() {
  if (mWidnow->IsDestroyed()) {
    return;
  }
  mWindow->ShowOnScreenKeyboard(false);
}

bool OnScreenKeyboardManagerAndroid::IsVisible() {
  // Unknown
  return false;
}

}  // namespace widget
}  // namespace mozilla
