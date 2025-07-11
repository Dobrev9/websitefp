# app/helpers/application_helper.rb
module ApplicationHelper
  def get_bootstrap_file_icon(filename)
    extension = File.extname(filename).downcase.delete(".")

    case extension
    when "pdf"
      "file-earmark-pdf"
    when "doc", "docx"
      "file-earmark-word"
    when "xls", "xlsx"
      "file-earmark-excel"
    when "ppt", "pptx"
      "file-earmark-ppt"
    when "txt"
      "file-earmark-text"
    when "jpg", "jpeg", "png", "gif", "bmp"
      "file-earmark-image"
    when "mp4", "avi", "mov", "wmv"
      "file-earmark-play"
    when "mp3", "wav", "ogg"
      "file-earmark-music"
    when "zip", "rar", "7z"
      "file-earmark-zip"
    when "html", "htm"
      "file-earmark-code"
    when "css"
      "file-earmark-code"
    when "js"
      "file-earmark-code"
    else
      "file-earmark"
    end
  end

  def get_file_icon(filename)
    extension = File.extname(filename).downcase

    case extension
    when ".pdf"
      "file-pdf"
    when ".doc", ".docx"
      "file-word"
    when ".xls", ".xlsx"
      "file-excel"
    when ".ppt", ".pptx"
      "file-powerpoint"
    when ".jpg", ".jpeg", ".png", ".gif", ".bmp"
      "file-image"
    when ".txt"
      "file-alt"
    when ".zip", ".rar", ".7z"
      "file-archive"
    when ".mp3", ".wav", ".ogg"
      "file-audio"
    when ".mp4", ".avi", ".mov"
      "file-video"
    else
      "file"
    end
  end
end
