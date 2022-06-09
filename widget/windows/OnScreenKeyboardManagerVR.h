/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* vim:set ts=2 sts=2 sw=2 et cin: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef mozilla_widget_OnScreenKeyboardManagerVR_h
#define mozilla_widget_OnScreenKeyboardManagerVR_h

#include "OnScreenKeyboardManager.h"

namespace mozilla {
namespace widget {

class OnScreenKeyboardManagerVR final : public OnScreenKeyboardManager {
 public:
  OnScreenKeyboardManagerVR() = default;

  virtual void Show() override;
  virtual void Dismiss() override;
  virtual void IsVisible() override;

 private:
  virtual ~OnScreenKeyboardManagerVR() = default;
};

}  // namespace widget
}  // namespace mozilla

endif  // OnScreenKeyboardManagerVR_h
