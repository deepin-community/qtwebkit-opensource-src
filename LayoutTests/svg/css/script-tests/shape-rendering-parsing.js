description("Tests the parsing of shape-rendering property values")
createSVGTestCase();

var group = createSVGElement("g");
rootSVGElement.appendChild(group);

// Test initial value of font-length.
shouldBeEqualToString("document.defaultView.getComputedStyle(group, null).shapeRendering", "auto");

group.setAttribute("shape-rendering", "crispEdges");
shouldBeEqualToString("document.defaultView.getComputedStyle(group, null).shapeRendering", "crispedges");

group.setAttribute("shape-rendering", "crispedges");
shouldBeEqualToString("document.defaultView.getComputedStyle(group, null).shapeRendering", "crispedges");

group.setAttribute("shape-rendering", "optimizeSpeed");
shouldBeEqualToString("document.defaultView.getComputedStyle(group, null).shapeRendering", "optimizespeed");

group.setAttribute("shape-rendering", "geometricPrecision");
shouldBeEqualToString("document.defaultView.getComputedStyle(group, null).shapeRendering", "geometricprecision");

var successfullyParsed = true;

completeTest();