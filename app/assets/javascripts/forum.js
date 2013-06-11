var optionsshowing = false;
function toggleoptions() {
	if (optionsshowing && $('#from').val()=='dialog' && $('#active_period_id').val()>0) {		
		$('#forumcontrol').css("height","85px");
		$('#optionbutton').attr("value","More Options");
		optionsshowing = false;
	} else if (optionsshowing) {
		$('#forumcontrol').css("height","29px");
		$('#optionbutton').attr("value","More Options");
		optionsshowing = false;
	} else {
		$('#forumcontrol').css("height","auto");
		$('#optionbutton').attr("value","Fewer Options");
		optionsshowing = true;
	}
}
var curid = 0;
var replyingid = 0;
var editingid = 0;
var in_new_item = 0;
var had_default = false;
var last_sort = '';
function list(whatchanged,gotopost) {
  whatchanged = (typeof whatchanged === "undefined") ? "" : whatchanged;
  gotopost = (typeof gotopost === "undefined") ? "" : ""+gotopost;
  $('#itemlist').css('opacity','0.5');
	showworking();
	if ($('#sortby') && $('#sortby').val()=='default') {
	    if ($('#active_period_name')) {
	        // Put period in heading for the currently active group if we have the Focus Special sort
	        var period_name = $('#active_period_name').val();
	        $('#period_name_heading').html(": "+period_name);
        }
	    $('#period_name_heading').show();	    
	} else if ($('#period_id') && parseInt($('#period_id').val())>0) {
	    // Put the selected historical period in the heading
	    var period_id = $('#period_id').val();
        var period_name = $("#period_id option[value='"+period_id+"']").text();
        $('#period_name_heading').html(": "+period_name);
	    $('#period_name_heading').show();
	} else {
	    // No period heading
	    $('#period_name_heading').hide();
	}
	
	if ((whatchanged=='sortby' || whatchanged=='') && $('#sortby').val()=='default') {	
	    // If the Decision Special sort is selected, make sure we're showing root only and that the active period is selected
	    $('#threads').val('root');
	    $('#period_id').val($('#active_period_id').val());
    } else if (whatchanged=='sortby' && last_sort && last_sort == 'default' && $('#sortby').val()!='default') {
        // Moving away from Decision Special. Change threads to Roots+Replies
        $('#threads').val('flat');
    } else if (whatchanged=='period_id' && $('#period_id').val()>0) {
        // If we selected a period the sort would no longer be default. Change threads to Roots+Replies
        $('#threads').val('flat');
    }
    if (whatchanged=='period_id' && $('#sortby').val()=='default' && $('#period_id').val()!=$('#active_period_id').val()) {
        // If we move away from the current period, we can't have the decision special sort
        $('#sortby').val('items.id desc');
    }
    if (whatchanged=='threads' && $('#threads').val()!='root' && $('#sortby').val()=='default') {
        // If we change threads to anything other than roots only, make sure we're not in focus special
        $('#sortby').val('items.id desc');
    }
    if (whatchanged=='posted_by_metro_area_id' && $('#posted_by_metro_area_id').val()!='0') {
        $('#posted_by_admin1uniq').val('0');
    } else if (whatchanged=='posted_by_admin1uniq' && $('#posted_by_admin1uniq').val()!='0') {
        $('#posted_by_metro_area_id').val('0');
    }
    if (whatchanged=='rated_by_metro_area_id' && $('#rated_by_metro_area_id').val()!='0') {
        $('#rated_by_admin1uniq').val('0');
    } else if (whatchanged=='rated_by_admin1uniq' && $('#rated_by_admin1uniq').val()!='0') {
        $('#rated_by_metro_area_id').val('0');
    }	
    
    // Decide whether we show the decision special sort option or not
    var firstsort = $("#sortby > option:first").attr("value");
	if ($('#period_id')) {
	    if ($('#period_id').val()>0 && $('#period_id').val()!=$('#active_period_id').val() && firstsort=='default') {
            // If a another period than the current is selected, remove the Decision Special sort
            $("#sortby > option:first").remove();
            had_default = true;
	    } else if (firstsort!='default' && had_default && ($('#period_id').val()==0 || $('#period_id').val()==$('#active_period_id').val())) {
            // If no historical period is selected, put the Decision Special sort option back, if it is missing
            $('#sortby').prepend('<option value="default">Decision Special</option>');
	    }
	}
    
	$('#page').val(1);
	var pars = $("#searchform").serialize();
	$.ajax({
     type: "GET",
     url: "/items",
     data: pars,
     complete: function(t){	
       $("#itemlist").html(t.responseText);
	   listdone();
       if (gotopost != '') {
             window.location.hash = '#item_'+gotopost;
        }
     }
   });	
}
var listdone = function(t) {
  $('#itemlist').show();
  hideworking();
  $('#itemlist').css('opacity','1.0');
}
var gotopage = function(page) {
    $('#itemlist').css('opacity','0.5');
  	showworking();
    $('#page').val(page);
	var pars = $("#searchform").serialize();
	$.ajax({
		type: "GET",
		url: "/items",
		data: pars,
		complete: function(t){	
            $("#itemlist").html(t.responseText);
     		 listdone();
		}
	});	
}
function newitem(token) {
	if (editingid>0) {
	    alert("Please save or cancel the edit that is in progress");
	    return;
	} else if (replyingid>0) {
	    alert("Please save or cancel the reply that is in progress");
	    return;
	} else if (in_new_item>0) {
	    alert("Please save or cancel the new thread that is in progress");
	    return;
	}
	curid = 0;
	in_new_item = 1;
	// Grey out all reply links
	$('.reply_link').each(function(i,obj) {
	    $(this).css('opacity','0.4');
	});
	$('#newforumitem').html("working...");
	$('#newforumitem').show();
	pars = 'a=1';
	if ($('#in_group_id').val()>0) {
		pars += "&group_id="+$('#in_group_id').val();
	}
	if ($('#in_dialog_id').val()>0) {
		pars += "&dialog_id="+$('#in_dialog_id').val();
	}
	if ($('#from')) {
	    pars += '&from=' + $('#from').val();
	}	
	if ($('#items_length')) {
	    pars += '&items_length=' + $('#items_length').val();
	}	
    pars += "&authenticity_token="+token;
	$.ajax({
		type: "GET",
		cache: false,
		url: '/items/new?xtime=' + (new Date()).getTime(),
		data: pars,
		complete: function(t){	
			$('#newforumitem').html(t.responseText);
			if (t.responseText.substring(0,6) == "<p>You") {
    			// If what came back wasn't an edit screen (but a message), clear the flag that new item is in progress
    			in_new_item = 0;
            	$('.reply_link').each(function(i,obj) {
            	    $(this).css('opacity','1.0');
            	});
    		}
		}
	});	
}
function reply(item_id,to_reply) {
	// Temporarily add an edit after the item we're replying to
	if (editingid>0) {
	    alert("Please save or cancel the edit that is in progress");
	    return;
	} else if (replyingid>0) {
	    alert("Please save or cancel the reply that is in progress");
	    return;
	} else if (in_new_item>0) {
	    alert("Please save or cancel the new thread that is in progress");
	    return;
	}
	curid = 0;
	replyingid = item_id;
	// Grey out all reply links
	$('.reply_link').each(function(i,obj) {
	    $(this).css('opacity','0.4');
	});
	
	var newcontent = '<div class="forumitem forumreply" id="reply_'+item_id+'">working...</div>';
	if (to_reply) {
		$('#item_'+item_id).after(newcontent);		
	} else {
		$('#iteminfo_'+item_id).after(newcontent);
	}
	$('#reply_'+item_id).show();
	var params = 'reply_to=' + item_id;
	if ($('#group_id') && $('#group_id').val() > 0 ) {
	    params += '&group_id=' + $('#group_id').val();
	}
	if ($('#dialog_id') && $('#dialog_id').val() > 0 ) {
	    params += '&dialog_id=' + $('#dialog_id').val();
	}
	if ($('#from')) {
	    params += '&from=' + $('#from').val();
	}	
	if ($('#items_length')) {
	    params += '&items_length=' + $('#items_length').val();
	}	
	$.ajax({
		type: "GET",
		url: '/items/new',
     	data: params,
		complete: function(t){	
			$('#reply_'+item_id).html(t.responseText);
		}
	});	
}
var oldval = '';
function edititem(id) {	
	if (editingid>0) {
	    alert("Please save or cancel the edit that is in progress");
	    return;
	} else if (replyingid>0) {
	    alert("Please save or cancel the reply that is in progress");
	    return;
	} else if (in_new_item>0) {
	    alert("Please save or cancel the new thread that is in progress");
	    return;
	}
	editingid = id;
	// Grey out all reply links
	$('.reply_link').each(function(i,obj) {
	    $(this).css('opacity','0.4');
	});
	if (CKEDITOR.instances['item_html_content_editor']) { 
		CKEDITOR.remove(CKEDITOR.instances['item_html_content_editor']);
	}
	curid = id;
	oldval = $('#htmlcontent_'+id).html();
	var token = $('#authenticity_token') ? $('#authenticity_token').val() : '';
	$('#shortcontent_'+id).hide();	
	$('#htmlcontent_'+id).show();
	$.ajax({
        type: "GET",
        url: '/items/'+id+'/edit?xtime=' + (new Date()).getTime(),
        data: "authenticity_token="+token+"&items_length="+$('#items_length').val(),
        complete: function(t){	
          $('#htmlcontent_'+id).html(t.responseText);
        }
     });	
}
function edititem_old(id) {	
	curid = id;
	oldval = $('#htmlcontent_'+id).html();
	$('#htmlcontent_'+id).html(
	'<form id="edit_item_' + id +'">'	
	+ '<input type="hidden" id="item_id" name="item[id]" value="' + id +'" />'
	+	'<textarea ajax="true" class="editor" cols="70" id="item_html_content_editor" name="item[html_content]" rows="20" style="width:97%;height:250">' + oldval + '</textarea>'
	+ '<p><input type="button" value="Cancel" onclick="canceledit(' + id + ')" />'
	+ '<input type="button" value="Save" onclick="for (instance in CKEDITOR.instances){CKEDITOR.instances[instance].updateElement();};saveitem()" /></p>'
	+ '</form>'
	);
	if (CKEDITOR.instances['item_html_content_editor']) { 
		CKEDITOR.remove(CKEDITOR.instances['item_html_content_editor']);
	}
	CKEDITOR.replace('item_html_content_editor', { filebrowserBrowseUrl: '/ckeditor/files',language: 'en',filebrowserUploadUrl: '/ckeditor/create/file',height: '250',filebrowserImageBrowseUrl: '/ckeditor/images',width: '97%',toolbar: 'Basic',filebrowserImageUploadUrl: '/ckeditor/create/image' });
}
function canceledit(id) {
	if (typeof(id)!='undefined' && id != 0) {
		$('#htmlcontent_'+id).html(oldval);
	} else if (replyingid > 0) {
	    $('#reply_'+replyingid).html('');
		$('#reply_'+replyingid).hide();	
	}
	$('#newforumitem').hide();
	$('#newforumitem').html('');
	replyingid = 0;
	editingid = 0;
	in_new_item = 0;
	$('.reply_link').each(function(i,obj) {
	    $(this).css('opacity','1.0');
	});
}
function saveitem() {
	id = curid;
	var media_type = $('#item_media_type').val();
	if (media_type=='text') {
		if ($('#item_short_content').val()=='' || $('#item_short_content').val()=='http://') {
			alert("Please enter some text");
			return;
		}
	} else {	
		if ($('#item_link').val()=='') {
			alert("Please enter the URL");
			return;
		}
	}
	if (replyingid>0) {
		var pars = $("#edit_item_").serialize();
		var url = "/items";
		var xtype = 'POST';
 		$('#reply_'+replyingid).css('opacity','0.5');
	} else if (id>0) {
		var pars = $("#edit_item_"+id).serialize();
		var url = "/items/"+id;
		var xtype = 'PUT';
		$('#htmlcontent_'+id).css('opacity','0.5');
	} else {
		var pars = $("#edit_item_").serialize();
		var url = "/items";
		var xtype = 'POST';
	 	$('#newforumitem').css('opacity','0.5');
	}
	$.ajax({
	   type: xtype,
	   url: url,
	   data: pars,
	   complete: function(t){
	       var was_error = true;
	       if (t.responseText.substring(0,1)=='{') {
	            // looks like json
	            var results = eval('(' + t.responseText + ')');
	            var showmess = results['message'];
	            if ($('#cur_item_id')) {
	                $('#cur_item_id').val(results['item_id']);
                }
                was_error = results['error'];
	        } else {
	            var showmess = t.responseText;
	        }    
    	   if (replyingid>0) {
    			$('#reply_'+replyingid).html(showmess);	
    		 	$('#reply_'+replyingid).css('opacity','1.0');
        		//window.setTimeout("$('#reply_'+replyingid).remove();list();", 3000);
        		if ($('#sortby').val()=='default') {
        		    $('#sortby').val('items.id desc');
        		    if ($('#active_period_id') && parseInt($('#active_period_id').val())>0) {
                        $('#period_id').val($('#active_period_id').val());
            		}
        		}
        		if ($('#threads').val()=='root') {
        		    $('#threads').val('flat');
    		    }        		
    	  	} else if (id>0) {
    	    	$('#htmlcontent_'+id).html(showmess);
    			$('#htmlcontent_'+id).css('opacity','1.0');
        		//window.setTimeout("list();", 3000);
    		} else {
    	    	$("#newforumitem").html(showmess);
    	  		$('#newforumitem').css('opacity','1.0');
    			//$('#newforumitem').html('');
        		//window.setTimeout("list();$('#newforumitem').hide();", 3000);
        		if ($('#max_messages') && $('#previous_messages')) {
        		    var previous_messages = $('#previous_messages').val() + 1;
    		        $('#previous_messages').val(previous_messages);
        		    if (parseInt($('#previous_messages').val()) >= parseInt($('#max_messages').val())) {
        		        if ($('#newthreadbutton')) {
        		            $('#newthreadbutton').css("opacity","0.5");
        		            $('#newthreadbutton').attr('disabled','disabled');
    		            }
        		    }
        		}
    		}
    		//if (!$('#saveresult') || $('#saveresult').val() != 'error') {
        	if (was_error) {
        	    if (replyingid>0) {
        	        window.location.hash = '#reply_' + replyingid;
        	    } else if (id>0) {
        	        window.location.hash = '#htmlcontent_' + id;
        	    } else {
        	         window.location.hash = '#newforumitem';
        	    }
        	} else {    
        	    if ($('#from') && $('#from').val()=='individual') {
        	        window.location.href = "/items/" + results['item_id'] + "/thread#" + results['item_id'];
    		    } else if ($('#from') && $('#from').val()=='thread') {
    		        window.location.reload();
    		    } else if (results['item_id']) {
    		        list(null,results['item_id']);
    		    } else {
    		        list();
		        }
    		    replyingid = 0;
    		    editingid = 0;
            	in_new_item = 0;
            	$('.reply_link').each(function(i,obj) {
            	    $(this).css('opacity','1.0');
            	});
		    }
		}
	 });	
}
var intshowing = false;
var appshowing = false;
function intshow(id,top) {
	if (!intshowing) {
		$('#item_'+id).css("z-index",10);
		if (top) {
    		$('#item_'+top).css("z-index",10);
		}
		$('#intlong_'+id).show();
		intshowing = true;
	}
}
function inthide(id,top) {
	if (intshowing) {
		$('#intlong_'+id).hide();
		$('#item_'+id).css("z-index",0);
		if (top) {
    		$('#item_'+top).css("z-index",0);
		}
		intshowing = false;	
	}
}
function intswitch(id,top) {
	if (intshowing) {
        inthide(id,top);
    } else {
        intshow(id,top);
    }
}
function appshow(id,top) {
	if (!appshowing) {
		$('#item_'+id).css("z-index",10);
		if (top) {
    		$('#item_'+top).css("z-index",10);
		}
		$('#applong_'+id).show();
		appshowing = true;
	}
}
function apphide(id,top) {
	if (appshowing) {
		$('#applong_'+id).hide();
		$('#item_'+id).css("z-index",0);
		if (top) {
    		$('#item_'+top).css("z-index",0);
		}
		appshowing = false;	
	}
}
function appswitch(id,top) {
	if (appshowing) {
        apphide(id,top);
    } else {
        appshow(id,top);
    }
}
function rate(intapp,id,vote) {
    $.ajax({
        type: "GET",
        url: '/items/' + id + '/rate',
    	data: 'intapp='+intapp+'&item_id='+id+'&vote='+vote,
        complete: function(t){	
            $('#vote_'+intapp+'_rate_'+id).html(t.responseText);
            get_summary(id);
         }
    });	
}
function get_summary(id) {
    $.ajax({
        type: "GET",
        url: '/items/' + id + '/get_summary',
    	data: 'item_id='+id,
        complete: function(t){	
            $('#sum_'+id).html(t.responseText);
         }
    });	
}
var sumshowing = false;
function summary(id,top) {
	$('#item_'+id).css("z-index",10);
	if (top) {
		$('#item_'+top).css("z-index",10);
	}
	$('#sum_'+id).show();
	sumshowing = true;	
}
function nosummary(id,top) {
	$('#sum_'+id).hide();	
	$('#item_'+id).css("z-index",0);
	if (top) {
		$('#item_'+top).css("z-index",0);
	}
	sumshowing = false;
}
function summaryswitch(id,top) {
    if (sumshowing) {
    	$('#sum_'+id).hide();	
    	$('#item_'+id).css("z-index",0);
    	if (top) {
    		$('#item_'+top).css("z-index",0);
    	}
    	sumshowing = false;
	} else {
    	$('#item_'+id).css("z-index",10);
    	if (top) {
    		$('#item_'+top).css("z-index",10);
    	}
    	$('#sum_'+id).show();
    	sumshowing = true;	
	}
}

function html_to_short(htmlval,plainval) {
    if (typeof htmlval === "undefined") {
        htmlval = CKEDITOR.instances['item_html_content'].getData();
    }
    if (typeof plainval === "undefined") {
	    plainval = $.trim(strip(htmlval));
    }
	xtext = plainval.substring(0,124);
	$('#item_short_content').val(xtext);
	$('#charsused').html(xtext.length);
}
function mess_characters(htmlval,plainval) {
    // Count and display characters and words in the main message
	var char_count = plainval.length;
	if ($('#item_long_length')) {
	    $('#item_long_length').html(char_count);
	}
    if ($('#js_message_length')) {
        $('#js_message_length').val(char_count);
    }
    var words = plainval.match(/\S+/g);
    if (words) {
        var word_count = words.length;
    } else {
        var word_count = 0;
    }
    $('#item_long_words').html(word_count);
}
function update_characters() {
    // Count and display characters in the short summary
	var count = $('#item_short_content').val().length;
	if (count>124) {
		var oldval = $('#item_short_content').val();
		var newval = oldval.substring(0,124);
		$('#item_short_content').val(newval);
		count = 124;
	}
	$('#charsused').html(count);
	short_updated = true;
}
function expand(id) {
	var oldval = $('#expand_'+id).html();
	if (oldval == '−') {
		$('#htmlcontent_'+id).hide();
		$('#shortcontent_'+id).show();
		//$('#vote_int_'+id).hide();
		//$('#vote_app_'+id).hide();
		$('#expand_'+id).html("+")
	} else {
		$('#shortcontent_'+id).hide();
		$('#htmlcontent_'+id).show();
		$('#vote_int_'+id).show();
		$('#vote_app_'+id).show();
		$('#expand_'+id).html("−")
	}
}
function mediachange(media) {
	
	$('#media_'+cur_media_type).html('<a href="#" onclick="mediachange(\''+cur_media_type+'\'); return false;" style="font-weight: bold; ">'+cur_media_type+'</a>');
	$('#media_'+cur_media_type).css('font-weight','normal');
	
	if (media=='link') {
		$('#mediatitle2').html("<b>Link URL</b>");
		$('#item_media_type').val('link');
	} else if (media=='audio') {
		$('#mediatitle2').html("<b>Audio URL</b>");
		$('#item_media_type').val('audio');
	} else if (media=='video') {
		$('#mediatitle2').html("<b>Video URL</b>");
		$('#item_media_type').val('video');
	} else if (media=='picture') {
		$('#mediatitle2').html("<b>or grab from URL</b>");
		$('#item_media_type').val('picture');
		if ($('#item_link').val()=='') {
			$('#item_link').val("http://");
		}
	} else {
		$('#mediatitle2').html("<b>Message</b>");
		$('#item_media_type').val('text');
	}
	if (media=='text') {
		$('#linkdiv').hide();
		$('#textdiv').show();
	} else {
		$('#linkdiv').show();
		$('#textdiv').hide();
	}
	if (media=='picture') {
		$('#uploadli').show();
		$('#uploaddiv').show();
	} else {
		$('#uploadli').hide();
		$('#uploaddiv').hide();
	}
	cur_media_type = media;
	$('#media_'+cur_media_type).html(cur_media_type);
	$('#media_'+cur_media_type).css('font-weight','bold');
	
}
function playvideo(item_id) {
	curid = item_id;
	$.ajax({
    type: "GET",
    url: '/items/'+item_id+'/play',
    complete: function(t){	
      $('#htmlcontent_'+item_id).html(t.responseText);
     }
   });	
}
String.prototype.capitalize = function(){
   return this.replace( /(^|\s)([a-z])/g , function(m,p1,p2){ return p1+p2.toUpperCase(); } );
};
