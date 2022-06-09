/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef OnScreenKeyboardManagerAndroid_h__
#define OnScreenKeyboardManagerAndroid_h__

#include "OnScreenKeyboardManager.h"

class nsWindow;

namespace mozilla {
namespace widget {

class OnScreenKeyboardManagerAndroid final : public OnScreenKeyboardManager {
 public:
  explicit OnScreenKeyboardManagerAndroid(nsWindow* aWindow)
      : mWindow(aWindow){};

  virtual void Show() override;
  virtual void Dismiss() override;
  virtual bool IsVisible() override;

 private:
  virtual ~OnScreenKeyboardManagerAndroid() = default;

  RefPtr<nsWindow> mWindow;
};

}  // namespace widget
}  // namespace mozilla

#endif
