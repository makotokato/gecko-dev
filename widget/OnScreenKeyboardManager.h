/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef mozilla_widget_OnScreenKeyboardManager_h__
#define mozilla_widget_OnScreenKeyboardManager_h__

#include "nsISupportsImpl.h"

namespace mozilla {
namespace widget {

class OnScreenKeyboardManager {
 public:
  NS_INLINE_DECL_REFCOUNTING(OnScreenKeyboardManager)

  virtual ~OnScreenKeyboardManager() = default;

  virtual void Show() = 0;
  virtual void Dismiss() = 0;
  virtual bool IsVisible() = 0;
};

}  // namespace widget
}  // namespace mozilla

#endif
