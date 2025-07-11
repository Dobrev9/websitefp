# app/helpers/files_helper.rb
module FilesHelper
  def get_file_icon(filename)
    extension = File.extname(filename).downcase.delete(".")

    case extension
    when "pdf"
      "file-pdf"
    when "doc", "docx"
      "file-word"
    when "xls", "xlsx"
      "file-excel"
    when "ppt", "pptx"
      "file-powerpoint"
    when "txt"
      "file-alt"
    when "jpg", "jpeg", "png", "gif", "bmp", "svg"
      "file-image"
    when "mp4", "avi", "mov", "wmv", "flv", "mkv"
      "file-video"
    when "mp3", "wav", "flac", "aac", "ogg"
      "file-audio"
    when "zip", "rar", "7z", "tar", "gz"
      "file-archive"
    when "html", "htm"
      "file-code"
    when "css"
      "file-code"
    when "js"
      "file-code"
    when "json"
      "file-code"
    when "xml"
      "file-code"
    else
      "file"
    end
  end

  def number_to_human_size(size)
    return "0 B" if size == 0

    units = [ "B", "KB", "MB", "GB", "TB" ]
    base = 1024

    exponent = (Math.log(size) / Math.log(base)).floor
    exponent = [ exponent, units.length - 1 ].min

    number = size.to_f / (base ** exponent)

    if exponent == 0
      "#{number.to_i} #{units[exponent]}"
    else
      "#{number.round(1)} #{units[exponent]}"
    end
  end
end
