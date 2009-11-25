dojo.provide("dojo.widget.ShowAction");

dojo.require("dojo.widget.*");
dojo.require("dojo.lang.common");

dojo.widget.ShowAction = function(){}
dojo.lang.extend(dojo.widget.ShowAction, {
	on: "",
	action: "",
	duration: 0,
	from: "",
	to: "",
	auto: "false"
});

dojo.requireAfterIf("html", "dojo.widget.html.ShowAction");