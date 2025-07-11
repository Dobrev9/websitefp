# app/controllers/files_controller.rb
class FilesController < ApplicationController
  before_action :require_authentication
  before_action :set_files_and_folders, only: [ :upload ]

  def upload
    # Show the upload form with all files and folders
  end

  def create
    if params[:file].present?
      uploaded_file = params[:file]
      file_type = params[:file_type] # Parameter to identify schedule type

      # Ensure the Files directory exists
      files_dir = Rails.root.join("public", "Files")
      FileUtils.mkdir_p(files_dir) unless Dir.exist?(files_dir)

      # Determine filename based on file type
      filename = case file_type
      when "weekly_schedule"
        "weekly_schedule_#{uploaded_file.original_filename}"
      when "kholle_schedule"
        "kholle_schedule_#{uploaded_file.original_filename}"
      else
        uploaded_file.original_filename
      end

      # Save the uploaded file
      file_path = files_dir.join(filename)
      File.open(file_path, "wb") do |file|
        file.write(uploaded_file.read)
      end

      # Store schedule file info for special files
      if file_type == "weekly_schedule" || file_type == "kholle_schedule"
        store_schedule_info(file_type, filename)
      end

      flash[:notice] = "File '#{filename}' uploaded successfully!"
    else
      flash[:alert] = "Please select a file to upload."
    end

    redirect_to upload_files_path
  end

  def upload_files
    uploaded_file = params[:file]
    folder_name = params[:folder_name]
    file_type = params[:file_type]

    if uploaded_file.present?
      begin
        # Determine the target directory
        if folder_name.present?
          target_dir = Rails.root.join("public", "Files", folder_name)
        else
          target_dir = Rails.root.join("public", "Files")
        end

        # Create directory if it doesn't exist
        FileUtils.mkdir_p(target_dir)

        # Handle special file types (weekly_schedule, kholle_schedule)
        if file_type.present? && [ "weekly_schedule", "kholle_schedule" ].include?(file_type)
          # Remove existing files of this type
          remove_existing_special_files(file_type)

          # Add prefix to filename for easy identification
          original_filename = uploaded_file.original_filename
          new_filename = "#{file_type}_#{original_filename}"
        else
          new_filename = uploaded_file.original_filename
        end

        # Save the file
        file_path = File.join(target_dir, new_filename)

        File.open(file_path, "wb") do |file|
          file.write(uploaded_file.read)
        end

        flash[:success] = "File '#{new_filename}' uploaded successfully!"
        Rails.logger.info "File uploaded: #{file_path}"

      rescue => e
        flash[:error] = "Failed to upload file: #{e.message}"
        Rails.logger.error "File upload failed: #{e.message}"
      end
    else
      flash[:error] = "Please select a file to upload."
    end

    redirect_to upload_files_path
  end

  def create_folder
    folder_name = params[:folder_name]

    if folder_name.present?
      folder_path = Rails.root.join("public", "Files", folder_name)

      begin
        FileUtils.mkdir_p(folder_path)
        flash[:success] = "Folder '#{folder_name}' created successfully!"
        Rails.logger.info "Folder created: #{folder_path}"
      rescue => e
        flash[:error] = "Failed to create folder: #{e.message}"
        Rails.logger.error "Folder creation failed: #{e.message}"
      end
    else
      flash[:error] = "Please provide a folder name."
    end

    redirect_to upload_files_path
  end

  def destroy
    filename = params[:filename]
    file_path = Rails.root.join("public", "Files", filename)

    # Debug logging
    Rails.logger.info "=== DELETE DEBUG ==="
    Rails.logger.info "Filename: #{filename}"
    Rails.logger.info "Full path: #{file_path}"
    Rails.logger.info "File exists?: #{File.exist?(file_path)}"

    if File.exist?(file_path)
      File.delete(file_path)

      # Clean up schedule info if it's a schedule file
      if filename.start_with?("weekly_schedule_")
        remove_schedule_info("weekly_schedule")
      elsif filename.start_with?("kholle_schedule_")
        remove_schedule_info("kholle_schedule")
      end

      flash[:notice] = "File '#{filename}' deleted successfully!"
    else
      Rails.logger.error "File not found at: #{file_path}"
      flash[:alert] = "File not found at: #{file_path}"
    end

    redirect_to upload_files_path
  end

  def delete_file
    # Decode URL-encoded filename and handle special characters
    filename = URI.decode_www_form_component(params[:filename])

    # Debug logging
    Rails.logger.info "=== DELETE FILE DEBUG ==="
    Rails.logger.info "Original filename param: #{params[:filename]}"
    Rails.logger.info "Decoded filename: #{filename}"

    # Search for the file in both root directory and all subdirectories
    files_path = Rails.root.join("public", "Files")
    file_path = nil

    # Get all files in the directory structure
    all_files = Dir.glob(File.join(files_path, "**", "*")).select { |f| File.file?(f) }

    Rails.logger.info "All available files: #{all_files.map { |f| File.basename(f) }}"

    # First, try exact match
    file_path = all_files.find { |f| File.basename(f) == filename }

    # If no exact match, try case-insensitive search
    if file_path.nil?
      file_path = all_files.find { |f| File.basename(f).downcase == filename.downcase }
    end

    # If still no match, try partial match (in case extension is missing)
    if file_path.nil?
      file_path = all_files.find { |f| File.basename(f, ".*") == filename }
    end

    # If still no match, try partial match with case-insensitive
    if file_path.nil?
      file_path = all_files.find { |f| File.basename(f, ".*").downcase == filename.downcase }
    end

    Rails.logger.info "Found file path: #{file_path}"

    if file_path && File.exist?(file_path)
      begin
        File.delete(file_path)

        # Clean up schedule info if it's a schedule file
        base_filename = File.basename(file_path)
        if base_filename.start_with?("weekly_schedule_")
          remove_schedule_info("weekly_schedule")
        elsif base_filename.start_with?("kholle_schedule_")
          remove_schedule_info("kholle_schedule")
        end

        redirect_to upload_files_path, notice: "File '#{File.basename(file_path)}' deleted successfully!"
      rescue => e
        Rails.logger.error "Error deleting file: #{e.message}"
        redirect_to upload_files_path, alert: "Error deleting file: #{e.message}"
      end
    else
      Rails.logger.info "File not found after all searches: #{filename}"
      redirect_to upload_files_path, alert: "File '#{filename}' not found."
    end
  end

  def delete_folder
    begin
      # Decode the folder name parameter
      folder_name = params[:folder_name]
      folder_name = URI.decode_www_form_component(folder_name) if folder_name

      # Your folder deletion logic here
      folder_path = Rails.root.join("public", "Files", folder_name)

      if Dir.exist?(folder_path)
        # Remove all files in the folder first
        Dir.glob(File.join(folder_path, "*")).each { |file| File.delete(file) }
        # Then remove the folder
        Dir.rmdir(folder_path)
        redirect_to upload_files_path, notice: "Folder '#{folder_name}' was successfully deleted."
      else
        redirect_to upload_files_path, alert: "Folder '#{folder_name}' not found."
      end

    rescue => e
      redirect_to upload_files_path, alert: "Error deleting folder: #{e.message}"
    end
  end

  def sync_local_files
    source_path = "/Users/mathis/websitefp/public/Files"
    target_path = Rails.root.join("public", "Files")

    if File.directory?(source_path)
      begin
        FileUtils.cp_r(Dir.glob(File.join(source_path, "*")), target_path)
        flash[:success] = "Files synced successfully from local directory!"
        Rails.logger.info "Files synced from #{source_path} to #{target_path}"
      rescue => e
        flash[:error] = "Failed to sync files: #{e.message}"
        Rails.logger.error "File sync failed: #{e.message}"
      end
    else
      flash[:error] = "Local source directory not found: #{source_path}"
    end

    redirect_to upload_files_path
  end

  private

  def require_authentication
    unless session[:authenticated]
      flash[:alert] = "Please log in to access this page."
      redirect_to login_path
    end
  end

  def set_files_and_folders
    files_dir = Rails.root.join("public", "Files")

    # Ensure the Files directory exists
    FileUtils.mkdir_p(files_dir) unless Dir.exist?(files_dir)

    @folders = get_existing_folders
    @folder_files = get_folder_files
    @root_files = get_root_files
    @files = get_all_files
  end

  def get_existing_folders
    files_path = Rails.root.join("public", "Files")
    return [] unless File.directory?(files_path)

    Dir.glob(File.join(files_path, "*")).select { |f| File.directory?(f) }.map do |folder_path|
      File.basename(folder_path)
    end
  end

  def get_folder_files
    folder_files = {}
    get_existing_folders.each do |folder|
      folder_path = Rails.root.join("public", "Files", folder)
      files = Dir.glob(File.join(folder_path, "*")).select { |f| File.file?(f) }.map do |file_path|
        file_name = File.basename(file_path)
        {
          name: file_name,
          size: File.size(file_path),
          modified: File.mtime(file_path),
          url: "/Files/#{folder}/#{file_name}"
        }
      end
      folder_files[folder] = files if files.any?
    end
    folder_files
  end

  def get_root_files
    files_path = Rails.root.join("public", "Files")
    return [] unless File.directory?(files_path)

    Dir.glob(File.join(files_path, "*")).select { |f| File.file?(f) }.map do |file_path|
      file_name = File.basename(file_path)
      {
        name: file_name,
        size: File.size(file_path),
        modified: File.mtime(file_path),
        url: "/Files/#{file_name}",
        folder: nil
      }
    end
  end

  def get_all_files
    all_files = []
    files_path = Rails.root.join("public", "Files")
    return all_files unless File.directory?(files_path)

    # Root files
    all_files += get_root_files

    # Files in folders
    get_existing_folders.each do |folder|
      folder_path = Rails.root.join("public", "Files", folder)
      Dir.glob(File.join(folder_path, "*")).select { |f| File.file?(f) }.each do |file_path|
        file_name = File.basename(file_path)
        all_files << {
          name: file_name,
          size: File.size(file_path),
          modified: File.mtime(file_path),
          url: "/Files/#{folder}/#{file_name}",
          folder: folder
        }
      end
    end

    all_files
  end

  def store_schedule_info(schedule_type, filename)
    # Simple file-based storage for schedule info
    # In a real app, you'd probably use a database
    schedule_file = Rails.root.join("tmp", "#{schedule_type}.txt")
    File.write(schedule_file, filename)
  end

  def remove_schedule_info(schedule_type)
    schedule_file = Rails.root.join("tmp", "#{schedule_type}.txt")
    File.delete(schedule_file) if File.exist?(schedule_file)
  end

  def remove_existing_special_files(file_type)
    files_path = Rails.root.join("public", "Files")
    pattern = "#{file_type}_*"

    Dir.glob(File.join(files_path, "**", pattern)).each do |file_path|
      File.delete(file_path) if File.file?(file_path)
    end
  end

  def find_file_path(directory, filename)
    # Search in root directory first
    root_file = File.join(directory, filename)
    return root_file if File.exist?(root_file)

    # Search in subdirectories
    Dir.glob(File.join(directory, "*")).each do |path|
      if Dir.exist?(path)
        subfolder_file = File.join(path, filename)
        return subfolder_file if File.exist?(subfolder_file)
      end
    end

    nil
  end
end
