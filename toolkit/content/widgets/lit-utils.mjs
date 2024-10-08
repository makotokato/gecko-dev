/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

// Bug 1790483: Lit is not bundled yet, this is dev only.
// eslint-disable-next-line import/no-unresolved
import { query, queryAll, LitElement } from "./vendor/lit.all.mjs";

/**
 * MozLitElement provides extensions to the lit-provided LitElement class.
 *
 *******
 *
 * `@query` support (define a getter for a querySelector):
 *
 * static get queries() {
 *   return {
 *     propertyName: ".aNormal .cssSelector",
 *     anotherName: { all: ".selectorFor .querySelectorAll" },
 *   };
 * }
 *
 * This example would add properties that would be written like this without
 * using `queries`:
 *
 * get propertyName() {
 *   return this.renderRoot?.querySelector(".aNormal .cssSelector");
 * }
 *
 * get anotherName() {
 *   return this.renderRoot?.querySelectorAll(".selectorFor .querySelectorAll");
 * }
 *******
 *
 * Automatic Fluent support for shadow DOM.
 *
 * Fluent requires that a shadowRoot be connected before it can use Fluent.
 * Shadow roots will get connected automatically.
 *
 *******
 *
 * Test helper for sending events after a change: `dispatchOnUpdateComplete`
 *
 * When some async stuff is going on and you want to wait for it in a test, you
 * can use `this.dispatchOnUpdateComplete(myEvent)` and have the test wait on
 * your event.
 *
 * The component will then wait for your reactive property change to take effect
 * and dispatch the desired event.
 *
 * Example:
 *
 * async onClick() {
 *   let response = await this.getServerResponse(this.data);
 *   // Show the response status to the user.
 *   this.responseStatus = respose.status;
 *   this.dispatchOnUpdateComplete(
 *     new CustomEvent("status-shown")
 *   );
 * }
 *
 * add_task(async testButton() {
 *   let button = this.setupAndGetButton();
 *   button.click();
 *   await BrowserTestUtils.waitForEvent(button, "status-shown");
 * });
 */
export class MozLitElement extends LitElement {
  constructor() {
    super();
    let { queries } = this.constructor;
    if (queries) {
      for (let [name, selector] of Object.entries(queries)) {
        if (selector.all) {
          queryAll(selector.all)(this, name);
        } else {
          query(selector)(this, name);
        }
      }
    }
  }

  /**
   * The URL for this component's styles. To make development in Storybook
   * easier this will use the chrome:// URL when in product (feature detected
   * by AppConstants existing) and a relative path for Storybook.
   *
   * LOCAL_NAME should be the kebab-cased name of the element. It is added by
   * the `./mach addwidget` command.
   */
  static get stylesheetUrl() {
    if (this.useChromeStylesheet) {
      return `chrome://global/content/elements/${this.LOCAL_NAME}.css`;
    }
    return `./${this.LOCAL_NAME}/${this.LOCAL_NAME}.css`;
  }

  static get useChromeStylesheet() {
    return (
      typeof AppConstants != "undefined" ||
      (typeof Cu != "undefined" && Cu.isInAutomation)
    );
  }

  connectedCallback() {
    super.connectedCallback();
    if (!this._l10nRootConnected && document.l10n) {
      document.l10n.connectRoot(this.renderRoot);
      this._l10nRootConnected = true;
    }
  }

  async dispatchOnUpdateComplete(event) {
    await this.updateComplete;
    this.dispatchEvent(event);
  }

  update() {
    super.update();
    if (document.l10n) {
      document.l10n.translateFragment(this.renderRoot);
    }
  }
}
