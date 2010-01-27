YUI.add('madb', function(Y) {
  Y.namespace('madb');
  var get_detail_validator= function (detail_id) {
    var validator=function(val, field) {
      var check_url = 'http://mdb:3000/app/entities/check_detail_value_validity';
      check_url += '?detail_id='+detail_id+'&detail_value='+val;
      var tH = {
        success: function(id, o, args) {
           if (o.responseText==1) 
           {
             // field is valid
             field._fieldNode.addClass('valid_form_value');
             field._fieldNode.removeClass('invalid_form_value');
             field._fieldNode.removeClass('unchecked_form_value');
           }
           else
           {
             field._fieldNode.addClass('invalid_form_value');
             field._fieldNode.removeClass('valid_form_value');
             field._fieldNode.removeClass('unchecked_form_value');
           }
        }
      }

      var cfg = {
        on: {
              success: tH.success
        }
// Flash XDR config
        ,
        xdr: {
          use: 'flash',
          responseXML: false
        }      
// Native XDR config
//        ,
//        xdr: {
//          use: 'native',
//          responseXML: false
//        }      
}
      Y.io(check_url, cfg);
    }
    return validator;
  }

  Y.madb.get_detail_validator= get_detail_validator; 
}, '1.0', { requires: ['io-base', 'io-xdr'], skinnable: false} );

