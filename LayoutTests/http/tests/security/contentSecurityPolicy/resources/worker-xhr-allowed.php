<?php
    require "determine-content-security-policy-header.php";
?>
var isAsynchronous = false;
var xhr = new XMLHttpRequest;
try {
    xhr.open("GET", "http://127.0.0.1:8000/xmlhttprequest/resources/get.txt", isAsynchronous);
    xhr.send();
    self.postMessage(xhr.response);
} catch (exception) {
    self.postMessage("FAIL should not have thrown an exception. Threw exception " + exception + ".");
}
