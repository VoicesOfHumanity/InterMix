/**
 * @license Copyright (c) 2003-2012, CKSource - Frederico Knabben. All rights reserved.
 * For licensing, see LICENSE.html or http://ckeditor.com/license
 */

//var CKEDITOR_BASEPATH = '/javascripts/ckeditor/';

CKEDITOR.editorConfig = function( config ) {
	// Define changes to default configuration here.
	// For the complete reference:
	// http://docs.ckeditor.com/#!/api/CKEDITOR.config
	
    config.language = 'en';

    config.height = '400px';
    config.width = '600px';

    config.extraPlugins = "embed,attachment";
    
    config.toolbar_Easy =
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
    
   config.toolbar = 'Basic';

	// The toolbar groups arrangement, optimized for two toolbar rows.
	config.toolbarGroups = [
		{ name: 'clipboard',   groups: [ 'clipboard', 'undo' ] },
		{ name: 'editing',     groups: [ 'find', 'selection', 'spellchecker' ] },
		{ name: 'links' },
		{ name: 'insert' },
		{ name: 'forms' },
		{ name: 'tools' },
		{ name: 'document',	   groups: [ 'mode', 'document', 'doctools' ] },
		{ name: 'others' },
		'/',
		{ name: 'basicstyles', groups: [ 'basicstyles', 'cleanup' ] },
		{ name: 'paragraph',   groups: [ 'list', 'indent', 'blocks', 'align' ] },
		{ name: 'styles' },
		{ name: 'colors' },
		{ name: 'about' }
	];

	// Remove some buttons, provided by the standard plugins, which we don't
	// need to have in the Standard(s) toolbar.
	config.removeButtons = 'Underline,Subscript,Superscript';
};

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