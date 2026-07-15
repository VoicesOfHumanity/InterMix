# frozen_string_literal: true

# Rails 7 compatibility shim for kt-paperclip 6.4.2.
#
# Rails 7 removed `ActiveModel::Validations::NumericalityValidator::CHECKS`
# (the operator map moved to `ActiveModel::Validations::Comparability::
# COMPARE_CHECKS`). kt-paperclip 6.4.2's AttachmentSizeValidator still does
# `value.send(CHECKS[option], ...)`, inheriting CHECKS from NumericalityValidator
# — so every `validates_attachment_size` (CKEditor picture/file uploads, and any
# model avatar/image with a size check) raises
# `NameError: uninitialized constant ...AttachmentSizeValidator::CHECKS`
# at validation time (surfaced in ckeditor pictures#create).
#
# Restore the constant on the validator, pointing at Rails 7's replacement.
# Remove this when kt-paperclip is upgraded to a Rails-7-aware release (7.x).
require "paperclip"

unless Paperclip::Validators::AttachmentSizeValidator.const_defined?(:CHECKS, false)
  Paperclip::Validators::AttachmentSizeValidator.const_set(
    :CHECKS,
    ActiveModel::Validations::Comparability::COMPARE_CHECKS,
  )
end
