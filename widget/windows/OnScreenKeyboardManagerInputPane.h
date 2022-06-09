/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* vim:set ts=2 sts=2 sw=2 et cin: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef OnScreenKeyboardManagerInputPane_h__
#define OnScreenKeyboardManagerInputPane_h__

#include "OnScreenKeyboardManager.h"
#include <windows.h>

namespace mozilla {
namespace widget {

class OnScreenKeyboardManagerInputPane final : public OnScreenKeyboardManager {
 public:
  explicit OnScreenKeyboardManagerInputPane(HWND aWnd) : mWnd(aWnd) {}

  virtual void Show() override;
  virtual void Dismiss() override;
  virtual bool IsVisible() override;

 private:
  virtual ~OnScreenKeyboardManagerInputPane() = default;

  HWND mWnd;
};

}  // namespace widget
}  // namespace mozilla

#endif  // OnScreenKeyboardManagerInputPane_h__
