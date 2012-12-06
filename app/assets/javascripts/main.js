function showworking() {
	$('#wait').show();
}
function hideworking() {
	$('#wait').hide();
}
function boxmin(which) {
  $('#'+which+'box').css('height','22px');
  if ($('#'+which+'boxcontent')) {
    $('#'+which+'boxcontent').hide();
  }  
  $('#min'+which+'im').hide();
  $('#max'+which+'im').show();
}
function boxmax(which) {
  $('#'+which+'box').css('height','auto');
  if ($('#'+which+'boxcontent')) {
    $('#'+which+'boxcontent').show();
  }  
  $('#max'+which+'im').hide();
  $('#min'+which+'im').show();
}
function boxclose(which) {
  $('#'+which+'box').hide();
}
function strip(html) {
   var tmp = document.createElement("DIV");
   tmp.innerHTML = html;
   return tmp.textContent||tmp.innerText;
}