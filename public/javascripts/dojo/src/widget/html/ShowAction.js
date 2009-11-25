dojo.provide("dojo.widget.html.ShowAction");

dojo.require("dojo.widget.ShowAction");
dojo.require("dojo.widget.HtmlWidget");
dojo.require("dojo.lang.common");

dojo.widget.defineWidget(
	"dojo.widget.html.ShowAction",
	dojo.widget.HtmlWidget,
	null,
	"html",
	function(){
		dojo.widget.ShowAction.call(this);
	}
);
dojo.lang.extend(dojo.widget.html.ShowAction, dojo.widget.ShowAction.prototype);
dojo.lang.extend(dojo.widget.html.ShowAction, {
});