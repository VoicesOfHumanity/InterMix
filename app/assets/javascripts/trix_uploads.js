// Trix inline image/file uploads. When a file is dropped/pasted into a
// <trix-editor>, upload it to POST /uploads and point the attachment at the
// returned URL. Replaces the CKEditor filebrowser upload flow.
(function () {
  function csrfToken() {
    var m = document.querySelector('meta[name="csrf-token"]');
    return m ? m.getAttribute("content") : "";
  }

  function uploadAttachment(attachment) {
    var file = attachment.file;
    if (!file) return;

    var form = new FormData();
    form.append("file", file);

    var xhr = new XMLHttpRequest();
    xhr.open("POST", "/uploads", true);
    xhr.setRequestHeader("X-CSRF-Token", csrfToken());
    xhr.setRequestHeader("Accept", "application/json");

    xhr.upload.addEventListener("progress", function (e) {
      if (e.lengthComputable) {
        attachment.setUploadProgress((e.loaded / e.total) * 100);
      }
    });

    xhr.addEventListener("load", function () {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          var data = JSON.parse(xhr.responseText);
          attachment.setAttributes({ url: data.url, href: data.href || data.url });
          return;
        } catch (e) { /* fall through to remove */ }
      }
      attachment.remove(); // upload failed — drop the placeholder
    });

    xhr.addEventListener("error", function () { attachment.remove(); });
    xhr.send(form);
  }

  document.addEventListener("trix-attachment-add", function (event) {
    if (event.attachment.file) {
      uploadAttachment(event.attachment);
    }
  });
})();
