/*
Copyright (c) 2003-2010, CKSource - Frederico Knabben. All rights reserved.
For licensing, see LICENSE.html or http://ckeditor.com/license
*/

CKEDITOR.editorConfig = function( config )
{
  config.PreserveSessionOnFileBrowser = true;
  // Define changes to default configuration here. For example:
  config.language = 'en';
  // config.uiColor = '#AADC6E';

  //config.ContextMenu = ['Generic','Anchor','Flash','Select','Textarea','Checkbox','Radio','TextField','HiddenField','ImageButton','Button','BulletedList','NumberedList','Table','Form'] ; 
  
  config.height = 400;
  config.width = 530;
  
  //config.resize_enabled = false;
  //config.resize_maxHeight = 2000;
  //config.resize_maxWidth = 750;
  
  //config.startupFocus = true;
  
  // works only with en, ru, uk languages
  //config.extraPlugins = "embed,attachment";
    
  config.toolbar_Easy =
    [
        ['Source','-','Preview','Templates'],
        ['Cut','Copy','Paste','PasteText','PasteFromWord',],
        ['Maximize','-','About'],
        ['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
        ['Styles','Format'],
        ['Bold','Italic','Underline','Strike','-','Subscript','Superscript', 'TextColor'],
        ['NumberedList','BulletedList','-','Outdent','Indent','Blockquote'],
        ['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],
        ['Link','Unlink','Anchor'],
        ['Image','Embed','Flash','Attachment','Table','HorizontalRule','Smiley','SpecialChar','PageBreak']
    ];
    
    config.toolbar_Basic = [
         [ 'Source', '-', 'Bold', 'Italic' ]
    ];

    config.toolbar_Admin =
    [
        ['Source','-','Preview','Templates'],
        ['Cut','Copy','Paste','PasteText','PasteFromWord',],
        ['-','About'],
        ['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
        ['Format'],
        ['Bold','Italic','Underline','Strike','-','Subscript','Superscript', 'TextColor'],
        ['NumberedList','BulletedList','-','Outdent','Indent','Blockquote'],
        ['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],
        ['Link','Unlink','Anchor'],
        ['Image','Table','HorizontalRule','SpecialChar']
    ];
    
    config.toolbar_Custom =
      [
        ['Bold','Italic','Underline','Strike','Subscript','Superscript','-','NumberedList','BulletedList','-','Link','Unlink','-','Image','Smiley','-','SpellChecker', 'Scayt','-','About']
      ];
    

    config.toolbar = 'Custom';    
       
};

// https://github.com/galetahub/ckeditor/issues/228
//CKEDITOR.config.toolbarGroups = [
//    { name: 'basic', groups: [ 'Source', '-', 'Bold', 'Italic' ] }
//];


CKEDITOR.on( 'dialogDefinition', function( ev ) {
  // Take the dialog name and its definition from the event data.
  var dialogName = ev.data.name;
  var dialogDefinition = ev.data.definition;

  // Check if the definition is from the dialog we're
  // interested in (the 'link' dialog).
  if ( dialogName == 'link' )
  {
     // Remove the 'Target' and 'Advanced' tabs from the 'Link' dialog.
     dialogDefinition.removeContents( 'target' );
     dialogDefinition.removeContents( 'advanced' );

     // Get a reference to the 'Link Info' tab.
     var infoTab = dialogDefinition.getContents( 'info' );

     // Remove unnecessary widgets from the 'Link Info' tab.         
     infoTab.remove( 'linkType');
     infoTab.remove( 'protocol');
  }
});

