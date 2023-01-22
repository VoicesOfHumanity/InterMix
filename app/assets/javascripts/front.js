function flagitem(item_id) {
 if (confirm('Do you want to flag this item as inappropriate?')) {
  	$.ajax({
      type: "GET",
      url: '/fbapp/flag?id='+item_id,
      complete: function(t){	
        $('#td_'+item_id).html('flagged');
       }
    });	
 }
}