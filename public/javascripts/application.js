Ajax.Responders.register({
  onCreate: function() {
    if($('xhr_message') && Ajax.activeRequestCount>0)
    {
      Effect.Appear('xhr_message',{duration:0.5,queue:'end'});
    }
  },
  onComplete: function() {
    if($('xhr_message') && Ajax.activeRequestCount==0)
    {
      Effect.Fade('xhr_message',{duration:0.5,queue:'end'});
    }
  }
});



  YAHOO.namespace("madb");
  YAHOO.madb.container = {};
  YAHOO.madb.translations = {};
