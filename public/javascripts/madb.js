var DetailWatcher = Class.create();

DetailWatcher.prototype = {
	initialize: function(field, detail_id){
		this.value_field= $(field+"_value");
		this.id_field= $(field+"_id");
		this.detail_id=detail_id
		this.form=this.value_field.form
		this.value_field.onchange=this.check_validity.bindAsEventListener(this);
		this.value_field.validate=this.check_validity.bindAsEventListener(this);

	},
	check_validity: function(evt){
		var check_url = '/app/entities/check_detail_value_validity';
		var params = 'detail_id='+this.detail_id+'&detail_value='+this.value_field.value;

		var check_validity_request = new Ajax.Request( 
						check_url,
						{method: 'get',
						 parameters: params,
						 onComplete: this.display_check_result.bindAsEventListener(this)						});

	},
	display_check_result: function(xhr)
	{
		if (xhr.responseText=='1')
		{
			if (Element.hasClassName(this.value_field,'invalid_form_value')==true)
				Element.removeClassName(this.value_field,'invalid_form_value');
				Element.removeClassName(this.value_field,'unchecked_form_value');
			if (Element.hasClassName(this.value_field,'valid_form_value')!=true)
				Element.addClassName(this.value_field,'valid_form_value');
		}
		else
		{
			if (Element.hasClassName(this.value_field,'valid_form_value')==true)
				Element.removeClassName(this.value_field,'valid_form_value');
				Element.removeClassName(this.value_field,'unchecked_form_value');
			if (Element.hasClassName(this.value_field,'invalid_form_value')!=true)
				Element.addClassName(this.value_field,'invalid_form_value');
				this.value_field.setAttribute('valid','0')
		}
	}
}

Object.extend(Form, {
	reset_madb_form: function(form) {
		form.reset();
		form_elements = new Form.getElements(form);
		for (var i = 0; i < form_elements.length; i++)
		{
			//if (new Element.hasClassName(form_elements[i],'valid_form_value'))
				new Element.removeClassName(form_elements[i],'valid_form_value');
			//if (new Element.hasClassName(form_elements[i],'invalid_form_value'))
				new Element.removeClassName(form_elements[i],'invalid_form_value');
		}
	},

	check_madb_form: function(form) {
		var fields = new Form.getElements(form);
		for (var i=0; i< fields.length; i++)
		{
			if (fields[i].getAttribute('type')=='hidden')	
				continue;
			if (fields[i].getAttribute('valid')==0)	
			{
				alert('we have an valid field:'+fields[i].getAttribute('name'));
				continue;
			}
			if (fields[i].getAttribute('valid')==0)	
			{
				alert('we have an invalid field:'+fields[i].getAttribute('name'));
				ret=false;
				continue;
			}
		}
		return false;
	}
})



function toggle_translation_area_size(id) {
  var txtarea = $(id);
  if (txtarea.rows==1) {
    txtarea.cols = 82;
    txtarea.rows = 20;
  } else {
    txtarea.cols = 20;
    txtarea.rows = 1;
  }
Field.focus(id);
}


function reset_style(id)
{
  $(id).setAttribute('style', '');
}
