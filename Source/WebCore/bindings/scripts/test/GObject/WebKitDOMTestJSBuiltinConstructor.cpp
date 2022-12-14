/*
 *  This file is part of the WebKit open source project.
 *  This file has been generated by generate-bindings.pl. DO NOT MODIFY!
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Library General Public
 *  License as published by the Free Software Foundation; either
 *  version 2 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Library General Public License for more details.
 *
 *  You should have received a copy of the GNU Library General Public License
 *  along with this library; see the file COPYING.LIB.  If not, write to
 *  the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301, USA.
 */

#include "config.h"
#include "WebKitDOMTestJSBuiltinConstructor.h"

#include "CSSImportRule.h"
#include "DOMObjectCache.h"
#include "Document.h"
#include "ExceptionCode.h"
#include "ExceptionCodeDescription.h"
#include "JSMainThreadExecState.h"
#include "WebKitDOMPrivate.h"
#include "WebKitDOMTestJSBuiltinConstructorPrivate.h"
#include "gobject/ConvertToUTF8String.h"
#include <wtf/GetPtr.h>
#include <wtf/RefPtr.h>

#define WEBKIT_DOM_TEST_JS_BUILTIN_CONSTRUCTOR_GET_PRIVATE(obj) G_TYPE_INSTANCE_GET_PRIVATE(obj, WEBKIT_DOM_TYPE_TEST_JS_BUILTIN_CONSTRUCTOR, WebKitDOMTestJSBuiltinConstructorPrivate)

typedef struct _WebKitDOMTestJSBuiltinConstructorPrivate {
    RefPtr<WebCore::TestJSBuiltinConstructor> coreObject;
} WebKitDOMTestJSBuiltinConstructorPrivate;

namespace WebKit {

WebKitDOMTestJSBuiltinConstructor* kit(WebCore::TestJSBuiltinConstructor* obj)
{
    if (!obj)
        return 0;

    if (gpointer ret = DOMObjectCache::get(obj))
        return WEBKIT_DOM_TEST_JS_BUILTIN_CONSTRUCTOR(ret);

    return wrapTestJSBuiltinConstructor(obj);
}

WebCore::TestJSBuiltinConstructor* core(WebKitDOMTestJSBuiltinConstructor* request)
{
    return request ? static_cast<WebCore::TestJSBuiltinConstructor*>(WEBKIT_DOM_OBJECT(request)->coreObject) : 0;
}

WebKitDOMTestJSBuiltinConstructor* wrapTestJSBuiltinConstructor(WebCore::TestJSBuiltinConstructor* coreObject)
{
    ASSERT(coreObject);
    return WEBKIT_DOM_TEST_JS_BUILTIN_CONSTRUCTOR(g_object_new(WEBKIT_DOM_TYPE_TEST_JS_BUILTIN_CONSTRUCTOR, "core-object", coreObject, nullptr));
}

} // namespace WebKit

G_DEFINE_TYPE(WebKitDOMTestJSBuiltinConstructor, webkit_dom_test_js_builtin_constructor, WEBKIT_DOM_TYPE_OBJECT)

enum {
    PROP_0,
    PROP_TEST_ATTRIBUTE,
};

static void webkit_dom_test_js_builtin_constructor_finalize(GObject* object)
{
    WebKitDOMTestJSBuiltinConstructorPrivate* priv = WEBKIT_DOM_TEST_JS_BUILTIN_CONSTRUCTOR_GET_PRIVATE(object);

    WebKit::DOMObjectCache::forget(priv->coreObject.get());

    priv->~WebKitDOMTestJSBuiltinConstructorPrivate();
    G_OBJECT_CLASS(webkit_dom_test_js_builtin_constructor_parent_class)->finalize(object);
}

static void webkit_dom_test_js_builtin_constructor_set_property(GObject* object, guint propertyId, const GValue* value, GParamSpec* pspec)
{
    WebKitDOMTestJSBuiltinConstructor* self = WEBKIT_DOM_TEST_JS_BUILTIN_CONSTRUCTOR(object);

    switch (propertyId) {
    case PROP_TEST_ATTRIBUTE:
        webkit_dom_test_js_builtin_constructor_set_test_attribute(self, g_value_get_boolean(value));
        break;
    default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID(object, propertyId, pspec);
        break;
    }
}

static void webkit_dom_test_js_builtin_constructor_get_property(GObject* object, guint propertyId, GValue* value, GParamSpec* pspec)
{
    WebKitDOMTestJSBuiltinConstructor* self = WEBKIT_DOM_TEST_JS_BUILTIN_CONSTRUCTOR(object);

    switch (propertyId) {
    case PROP_TEST_ATTRIBUTE:
        g_value_set_boolean(value, webkit_dom_test_js_builtin_constructor_get_test_attribute(self));
        break;
    default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID(object, propertyId, pspec);
        break;
    }
}

static GObject* webkit_dom_test_js_builtin_constructor_constructor(GType type, guint constructPropertiesCount, GObjectConstructParam* constructProperties)
{
    GObject* object = G_OBJECT_CLASS(webkit_dom_test_js_builtin_constructor_parent_class)->constructor(type, constructPropertiesCount, constructProperties);

    WebKitDOMTestJSBuiltinConstructorPrivate* priv = WEBKIT_DOM_TEST_JS_BUILTIN_CONSTRUCTOR_GET_PRIVATE(object);
    priv->coreObject = static_cast<WebCore::TestJSBuiltinConstructor*>(WEBKIT_DOM_OBJECT(object)->coreObject);
    WebKit::DOMObjectCache::put(priv->coreObject.get(), object);

    return object;
}

static void webkit_dom_test_js_builtin_constructor_class_init(WebKitDOMTestJSBuiltinConstructorClass* requestClass)
{
    GObjectClass* gobjectClass = G_OBJECT_CLASS(requestClass);
    g_type_class_add_private(gobjectClass, sizeof(WebKitDOMTestJSBuiltinConstructorPrivate));
    gobjectClass->constructor = webkit_dom_test_js_builtin_constructor_constructor;
    gobjectClass->finalize = webkit_dom_test_js_builtin_constructor_finalize;
    gobjectClass->set_property = webkit_dom_test_js_builtin_constructor_set_property;
    gobjectClass->get_property = webkit_dom_test_js_builtin_constructor_get_property;

    g_object_class_install_property(
        gobjectClass,
        PROP_TEST_ATTRIBUTE,
        g_param_spec_boolean(
            "test-attribute",
            "TestJSBuiltinConstructor:test-attribute",
            "read-write gboolean TestJSBuiltinConstructor:test-attribute",
            FALSE,
            WEBKIT_PARAM_READWRITE));

}

static void webkit_dom_test_js_builtin_constructor_init(WebKitDOMTestJSBuiltinConstructor* request)
{
    WebKitDOMTestJSBuiltinConstructorPrivate* priv = WEBKIT_DOM_TEST_JS_BUILTIN_CONSTRUCTOR_GET_PRIVATE(request);
    new (priv) WebKitDOMTestJSBuiltinConstructorPrivate();
}

void webkit_dom_test_js_builtin_constructor_test_function(WebKitDOMTestJSBuiltinConstructor* self)
{
    WebCore::JSMainThreadNullState state;
    g_return_if_fail(WEBKIT_DOM_IS_TEST_JS_BUILTIN_CONSTRUCTOR(self));
    WebCore::TestJSBuiltinConstructor* item = WebKit::core(self);
    item->testFunction();
}

gboolean webkit_dom_test_js_builtin_constructor_get_test_attribute(WebKitDOMTestJSBuiltinConstructor* self)
{
    WebCore::JSMainThreadNullState state;
    g_return_val_if_fail(WEBKIT_DOM_IS_TEST_JS_BUILTIN_CONSTRUCTOR(self), FALSE);
    WebCore::TestJSBuiltinConstructor* item = WebKit::core(self);
    gboolean result = item->testAttribute();
    return result;
}

void webkit_dom_test_js_builtin_constructor_set_test_attribute(WebKitDOMTestJSBuiltinConstructor* self, gboolean value)
{
    WebCore::JSMainThreadNullState state;
    g_return_if_fail(WEBKIT_DOM_IS_TEST_JS_BUILTIN_CONSTRUCTOR(self));
    WebCore::TestJSBuiltinConstructor* item = WebKit::core(self);
    item->setTestAttribute(value);
}

