/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use dom::bindings::codegen::Bindings::HTMLSourceElementBinding;
use dom::bindings::codegen::InheritTypes::{ElementTypeId, EventTargetTypeId, HTMLElementTypeId};
use dom::bindings::codegen::InheritTypes::{HTMLSourceElementDerived, NodeTypeId};
use dom::bindings::js::Root;
use dom::document::Document;
use dom::eventtarget::EventTarget;
use dom::htmlelement::HTMLElement;
use dom::node::Node;
use util::str::DOMString;

#[dom_struct]
pub struct HTMLSourceElement {
    htmlelement: HTMLElement
}

impl HTMLSourceElementDerived for EventTarget {
    fn is_htmlsourceelement(&self) -> bool {
        *self.type_id() ==
            EventTargetTypeId::Node(
                NodeTypeId::Element(ElementTypeId::HTMLElement(HTMLElementTypeId::HTMLSourceElement)))
    }
}

impl HTMLSourceElement {
    fn new_inherited(localName: DOMString,
                     prefix: Option<DOMString>,
                     document: &Document) -> HTMLSourceElement {
        HTMLSourceElement {
            htmlelement:
                HTMLElement::new_inherited(HTMLElementTypeId::HTMLSourceElement, localName, prefix, document)
        }
    }

    #[allow(unrooted_must_root)]
    pub fn new(localName: DOMString,
               prefix: Option<DOMString>,
               document: &Document) -> Root<HTMLSourceElement> {
        let element = HTMLSourceElement::new_inherited(localName, prefix, document);
        Node::reflect_node(box element, document, HTMLSourceElementBinding::Wrap)
    }
}
