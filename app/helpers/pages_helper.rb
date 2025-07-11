# app/helpers/pages_helper.rb
module PagesHelper
  def get_bootstrap_file_icon(filename)
    extension = File.extname(filename).downcase

    case extension
    when ".pdf"
      "file-earmark-pdf"
    when ".doc", ".docx"
      "file-earmark-word"
    when ".xls", ".xlsx"
      "file-earmark-excel"
    when ".ppt", ".pptx"
      "file-earmark-ppt"
    when ".txt"
      "file-earmark-text"
    when ".jpg", ".jpeg", ".png", ".gif", ".bmp"
      "file-earmark-image"
    when ".mp4", ".avi", ".mov", ".wmv"
      "file-earmark-play"
    when ".mp3", ".wav", ".flac"
      "file-earmark-music"
    when ".zip", ".rar", ".7z"
      "file-earmark-zip"
    when ".html", ".htm"
      "file-earmark-code"
    when ".css"
      "file-earmark-code"
    when ".js"
      "file-earmark-code"
    when ".json"
      "file-earmark-code"
    else
      "file-earmark"
    end
  end
end
