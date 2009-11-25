function change(){
	args = change.arguments
	for(var a = 0; a < args.length; a++){
		obj = document.getElementById(args[a]);
		img = document.getElementById('img'+args[a]);
		//alert(obj.style.display == "table-row-group")
		if(obj.getAttribute("visu") == "1"){
			obj.style.display = "none";
			obj.setAttribute("visu","0");
			img.src = "/images/expand.gif";
		} else {
			try
      {
        obj.style.display = "table-row-group";
      }
      catch (e) 
      {
			obj.style.display = "block";
      }
        
			obj.setAttribute("visu","1");
			img.src = "/images/collapse.gif";
		}
	}
}

