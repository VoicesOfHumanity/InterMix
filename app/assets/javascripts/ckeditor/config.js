CKEDITOR.editorConfig = function( config )
{
  // Define changes to default configuration here. For example:
  // config.language = 'fr';
  // config.uiColor = '#AADC6E';
  
  config.versionCheck = false;
  //config.clipboard_handleImages = false;

  config.PreserveSessionOnFileBrowser = true;
  // Define changes to default configuration here. For example:
  config.language = 'en';
  // config.uiColor = '#AADC6E';

  config.removePlugins = 'elementspath';
  // config.extraPlugins = 'blockimagepaste';

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

    config.toolbar_Expanded =
    [
        ['Cut','Copy','Paste','PasteText','PasteFromWord',],
        ['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
        ['Styles','Format','Font','FontSize','TextColor','BGColor'],
        ['Bold','Italic','Underline','Strike','Subscript','Superscript', 'TextColor'],
        ['NumberedList','BulletedList','-','Outdent','Indent','Blockquote'],
        ['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],
        ['Link','Unlink'],
        ['Image','Smiley','Table','HorizontalRule','SpecialChar'],
        ['SpellChecker', 'Scayt','-','About']
    ];


    // ['Bold','Italic','Underline','Strike','Subscript','Superscript','-','NumberedList','BulletedList','-','Link','Unlink','-','Image','Smiley','-','SpellChecker', 'Scayt','-','About']
    config.toolbar_Custom =
      [
        ['Bold','Italic','Underline','-','NumberedList','BulletedList','Outdent','Indent','-','JustifyLeft','JustifyCenter','JustifyRight','-','Link','Unlink','-','Image','Smiley','-','SpellChecker', 'Scayt','-','About']
      ];
    // config.toolbar_Custom =
    //   [
    //     ['Bold','Italic','Underline','-','NumberedList','BulletedList','Outdent','Indent','-','JustifyLeft','JustifyCenter','JustifyRight','-','Link','Unlink','-','Smiley','-', 'About']
    //   ];
    

    config.toolbar = 'Custom';    
  
  
  
  

  /* Filebrowser routes */
  // The location of an external file browser, that should be launched when "Browse Server" button is pressed.
  //config.filebrowserBrowseUrl = "/ckeditor/attachment_files";
  config.filebrowserBrowseUrl = "";

  // The location of an external file browser, that should be launched when "Browse Server" button is pressed in the Flash dialog.
  //config.filebrowserFlashBrowseUrl = "/ckeditor/attachment_files";
  config.filebrowserFlashBrowseUrl = "";

  // The location of a script that handles file uploads in the Flash dialog.
  config.filebrowserFlashUploadUrl = "/ckeditor/attachment_files";

  // The location of an external file browser, that should be launched when "Browse Server" button is pressed in the Link tab of Image dialog.
  config.filebrowserImageBrowseLinkUrl = "/ckeditor/pictures";

  // The location of an external file browser, that should be launched when "Browse Server" button is pressed in the Image dialog.
  //config.filebrowserImageBrowseUrl = "/ckeditor/pictures";
  config.filebrowserImageBrowseUrl = "";

  // The location of a script that handles file uploads in the Image dialog.
  config.filebrowserImageUploadUrl = "/ckeditor/pictures";

  // The location of a script that handles file uploads.
  config.filebrowserUploadUrl = "/ckeditor/attachment_files";

  // Rails CSRF token
  config.filebrowserParams = function(){
    var csrf_token, csrf_param, meta,
        metas = document.getElementsByTagName('meta'),
        params = new Object();

    for ( var i = 0 ; i < metas.length ; i++ ){
      meta = metas[i];

      switch(meta.name) {
        case "csrf-token":
          csrf_token = meta.content;
          break;
        case "csrf-param":
          csrf_param = meta.content;
          break;
        default:
          continue;
      }
    }

    if (csrf_param !== undefined && csrf_token !== undefined) {
      params[csrf_param] = csrf_token;
    }

    return params;
  };

  config.addQueryString = function( url, params ){
    var queryString = [];

    if ( !params ) {
      return url;
    } else {
      for ( var i in params )
        queryString.push( i + "=" + encodeURIComponent( params[ i ] ) );
    }

    return url + ( ( url.indexOf( "?" ) != -1 ) ? "&" : "?" ) + queryString.join( "&" );
  };

  // Integrate Rails CSRF token into file upload dialogs (link, image, attachment and flash)
  CKEDITOR.on( 'dialogDefinition', function( ev ){
    // Take the dialog name and its definition from the event data.
    var dialogName = ev.data.name;
    var dialogDefinition = ev.data.definition;
    var content, upload;

    if (CKEDITOR.tools.indexOf(['link', 'image', 'attachment', 'flash'], dialogName) > -1) {
      content = (dialogDefinition.getContents('Upload') || dialogDefinition.getContents('upload'));
      upload = (content == null ? null : content.get('upload'));

      if (upload && upload.filebrowser && upload.filebrowser['params'] === undefined) {
        upload.filebrowser['params'] = config.filebrowserParams();
        upload.action = config.addQueryString(upload.action, upload.filebrowser['params']);
      }
    }

    switch (dialogName) {  
    case 'image': //Image Properties dialog      
        dialogDefinition.removeContents('Link');
        dialogDefinition.removeContents('advanced');        
        //https://stackoverflow.com/questions/12917918/ckeditor-make-dialog-element-readonly-or-disable
        //var infoTab = dialogDefinition.getContents( 'info' );
        //var urlField = infoTab.get( 'txtUrl' );
        //urlField[ 'default' ] = 'www.example.com';
        //this.getContentElement("info", "url").disable();
        //urlField.disable();
        //dialogDefinition.getContentElement("info", "url").disable();
        dialogDefinition.onLoad = function () {
            // info is the name of the tab and url is the id of the element inside the tab
            this.getContentElement("info","txtUrl").disable(); 
        }        
        break;      
    case 'link': //Link dialog          
        dialogDefinition.removeContents('advanced');   
        ev.data.definition.getContents('target').get('linkTargetType')['default']='_blank';
        dialogDefinition.onLoad = function () {
            this.getContentElement("target","linkTargetType").disable();
        }
        break;
    }

  });
    
};

