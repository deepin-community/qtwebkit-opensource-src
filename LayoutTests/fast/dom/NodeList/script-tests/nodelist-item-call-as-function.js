description('This tests that items in a NodeList cannot be called indexed using [[Call]].');

var nodeList = document.childNodes;
shouldThrow("nodeList(0)");

