# Set the correct password here - change this to your desired password
SECURE_PASSWORD = "MultsumescMathis:)"

require "open3"
require "json"
require "fileutils"
require "securerandom"

# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  # Authentication filter for protected actions
  before_action :require_authentication, only: [ :protected_content, :edit_home_text, :update_home_text ]

  # ==========================================
  # PUBLIC ACTIONS
  # ==========================================

  def home
    # Load all resource data for home page
    @resource_folders = get_resource_folders
    @root_files = get_root_files
    @weekly_schedule = get_special_file("weekly_schedule")
    @kholle_schedule = get_special_file("kholle_schedule")
    @homework_content = get_homework_content
    @uploaded_files = load_uploaded_files

    # Debug logging
    Rails.logger.info "=== DEBUG INFO ==="
    Rails.logger.info "Resource folders: #{@resource_folders.inspect}"
    Rails.logger.info "Root files: #{@root_files.inspect}"
    Rails.logger.info "Files directory exists: #{File.directory?(Rails.root.join('public', 'Files'))}"
    Rails.logger.info "Files in directory: #{Dir.glob(Rails.root.join('public', 'Files', '*')).inspect}"
    Rails.logger.info "=================="
  end

  def kholle_schedule
    if request.post?
      generate_schedule
      # After processing POST, redirect to GET to show results
      redirect_to kholle_schedule_path
    else
      # GET request - show the form or results
      load_schedule_data
    end
  end

  # ==========================================
  # AUTHENTICATION ACTIONS
  # ==========================================

  def login
    # If user is already authenticated, redirect to protected content
    if session[:authenticated]
      redirect_to protected_content_path
      nil
    end
    # Otherwise show the login form
  end

  def authenticate
    if params[:password] == SECURE_PASSWORD
      # Password is correct - set session and redirect to protected content
      session[:authenticated] = true
      flash[:notice] = "Welcome! You now have access to class materials."
      redirect_to protected_content_path
    else
      # Password is incorrect - show error and redirect back to login
      flash[:alert] = "Incorrect password. Please try again."
      redirect_to login_path
    end
  end

  def logout
    # Clear the session
    session[:authenticated] = nil
    flash[:notice] = "You have been logged out successfully."
    redirect_to root_path
  end

  # ==========================================
  # PROTECTED ACTIONS
  # ==========================================

  def protected_content
    # User is authenticated (checked by before_action) - show protected content
  end

  def edit_home_text
    @homework_content = load_homework_content
  end

  def update_home_text
    homework_content = params[:homework_content]

    if save_homework_content(homework_content)
      flash[:notice] = "Homework portal content updated successfully!"
      redirect_to root_path
    else
      flash[:alert] = "There was an error updating the content."
      redirect_to edit_home_text_path
    end
  end

  private

  # ==========================================
  # AUTHENTICATION HELPERS
  # ==========================================

  def require_authentication
    unless session[:authenticated]
      flash[:alert] = "Please log in to access this page."
      redirect_to login_path
    end
  end

  # ==========================================
  # SCHEDULE GENERATION METHODS
  # ==========================================

  def generate_schedule
    begin
      # Validate and clean input data
      teachers = extract_teachers
      students = extract_students

      # Validate ranges
      validate_teachers(teachers)
      validate_students(students)

      # Generate schedule using Python script
      generated_schedule = call_python_schedule_generator(teachers, students)

      # Generate a unique identifier for this schedule
      schedule_id = SecureRandom.hex(16)

      # Save the schedule to a temporary file
      schedule_file = Rails.root.join("tmp", "schedule_#{schedule_id}.json")
      File.write(schedule_file, generated_schedule.to_json)

      # Store only the schedule ID in session
      session[:schedule_id] = schedule_id
      session[:schedule_success] = true
      session[:schedule_error] = nil
      session[:form_teachers] = nil
      session[:form_students] = nil

    rescue => e
      # Store error in session for redirect
      session[:schedule_success] = false
      session[:schedule_error] = e.message
      session[:generated_schedule] = nil
      session[:form_teachers] = params[:teachers] || []
      session[:form_students] = extract_students_from_params
      session[:schedule_id] = nil
    end
  end

  def load_schedule_data
    if session[:schedule_id] && session[:schedule_success]
      schedule_file = Rails.root.join("tmp", "schedule_#{session[:schedule_id]}.json")
      if File.exist?(schedule_file)
        begin
          @generated_schedule = JSON.parse(File.read(schedule_file), symbolize_names: true)
          @success = true

          # Clean up the temporary file after loading
          File.delete(schedule_file)
          session[:schedule_id] = nil
        rescue JSON::ParserError
          @error_message = "Error loading schedule data"
          @success = false
        end
      else
        @error_message = "Schedule data not found"
        @success = false
      end
    else
      # Initialize variables if not set by redirect
      @teachers = session[:form_teachers] || nil
      @students = session[:form_students] || nil
      @generated_schedule = nil
      @success = session[:schedule_success] || false
      @error_message = session[:schedule_error] || nil
    end

    # Clear session data after use
    clear_schedule_session_data
  end

  def clear_schedule_session_data
    session[:schedule_success] = nil
    session[:schedule_error] = nil
    session[:form_teachers] = nil
    session[:form_students] = nil
  end

  # ==========================================
  # SCHEDULE INPUT VALIDATION
  # ==========================================

  def extract_teachers
    teachers = params[:teachers] || []
    teachers = teachers.reject(&:blank?).map(&:strip)
    raise "No teachers provided" if teachers.empty?
    teachers
  end

  def extract_students
    students_params = params[:students] || {}
    students = []
    students_params.each do |index, student_data|
      name = student_data[:name]&.strip
      type = student_data[:type]
      if name.present? && type.present?
        students << { name: name, type: type }
      end
    end
    raise "No students provided" if students.empty?
    students
  end

  def extract_students_from_params
    students_params = params[:students] || {}
    students = []
    students_params.each do |index, student_data|
      name = student_data[:name]&.strip
      type = student_data[:type]
      students << { name: name, type: type } if name.present?
    end
    students
  end

  def validate_teachers(teachers)
    raise "Number of teachers must be between 1 and 5" unless teachers.length.between?(1, 5)
  end

  def validate_students(students)
    raise "Number of students must be between 15 and 25" unless students.length.between?(15, 25)
    # Validate student types
    invalid_types = students.select { |s| ![ "Boarding", "Day" ].include?(s[:type]) }
    raise "Invalid student types found" unless invalid_types.empty?
  end

  # ==========================================
  # PYTHON SCRIPT INTEGRATION
  # ==========================================

  def call_python_schedule_generator(teachers, students)
    # Create temporary input file
    input_data = {
      teachers: teachers,
      students: students
    }

    temp_input_file = Rails.root.join("tmp", "schedule_input_#{SecureRandom.hex(8)}.json")
    temp_output_file = Rails.root.join("tmp", "schedule_output_#{SecureRandom.hex(8)}.json")

    begin
      # Write input data to temporary file
      File.write(temp_input_file, input_data.to_json)
      Rails.logger.info "Input data written to: #{temp_input_file}"
      Rails.logger.info "Input data: #{input_data.to_json}"

      # Path to your Python script
      python_script_path = Rails.root.join("lib", "schedule_generator.py")

      # Check if Python script exists
      raise "Python script not found at: #{python_script_path}" unless File.exist?(python_script_path)

      # Execute Python script with better error handling
      command = "python3 #{python_script_path} #{temp_input_file} #{temp_output_file}"
      Rails.logger.info "Executing command: #{command}"

      # Capture both stdout and stderr
      stdout, stderr, status = Open3.capture3(command)

      Rails.logger.info "Python stdout: #{stdout}"
      Rails.logger.error "Python stderr: #{stderr}" unless stderr.empty?
      Rails.logger.info "Python exit status: #{status.exitstatus}"

      # Check if command was successful
      unless status.success?
        raise "Python script failed with exit code #{status.exitstatus}. stderr: #{stderr}"
      end

      # Check if output file was created
      raise "Output file not created at: #{temp_output_file}" unless File.exist?(temp_output_file)

      # Read and parse output
      output_content = File.read(temp_output_file)
      Rails.logger.info "Python output: #{output_content}"

      begin
        output_data = JSON.parse(output_content)
      rescue JSON::ParserError => e
        raise "Invalid JSON output from Python script: #{e.message}. Content: #{output_content}"
      end

      # Convert to expected format
      format_schedule_output(output_data)

    rescue => e
      Rails.logger.error "Error in call_python_schedule_generator: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    ensure
      # Clean up temporary files
      File.delete(temp_input_file) if File.exist?(temp_input_file)
      File.delete(temp_output_file) if File.exist?(temp_output_file)
    end
  end

  def format_schedule_output(output_data)
    if output_data["success"]
      # Limit the data size to prevent cookie overflow
      # Only keep essential information
      output_data["sessions"].map do |session|
        {
          session_number: session["session_number"],
          table: session["table"]
        }
      end
    else
      raise output_data["error"] || "Unknown error in schedule generation"
    end
  end

  # ==========================================
  # FILE MANAGEMENT METHODS
  # ==========================================

  def get_resource_folders
    folders = {}
    files_path = Rails.root.join("public", "Files")

    Rails.logger.debug "=== DEBUGGING get_resource_folders ==="
    Rails.logger.debug "Files path: #{files_path}"
    Rails.logger.debug "Directory exists: #{File.directory?(files_path)}"

    return folders unless File.directory?(files_path)

    # Get all subdirectories (folders)
    subdirectories = Dir.glob(File.join(files_path, "*")).select { |f| File.directory?(f) }
    Rails.logger.debug "Found subdirectories: #{subdirectories.inspect}"

    subdirectories.each do |folder_path|
      folder_name = File.basename(folder_path)
      Rails.logger.debug "Processing folder: #{folder_name}"

      # Get all files in this folder
      files = Dir.glob(File.join(folder_path, "*")).select { |f| File.file?(f) }.map do |file_path|
        file_name = File.basename(file_path)
        Rails.logger.debug "  Found file: #{file_name}"
        {
          name: file_name,
          size: File.size(file_path),
          modified: File.mtime(file_path),
          url: "/Files/#{folder_name}/#{file_name}"
        }
      end

      if files.any?
        folders[folder_name] = {
          files: files,
          size: files.sum { |f| f[:size] }
        }
        Rails.logger.debug "  Added folder #{folder_name} with #{files.count} files"
      else
        Rails.logger.debug "  No files found in folder #{folder_name}"
      end
    end

    Rails.logger.debug "Final folders hash: #{folders.inspect}"
    Rails.logger.debug "=== END DEBUGGING ==="
    folders
  end

  def get_root_files
    files_path = Rails.root.join("public", "Files")
    return [] unless File.directory?(files_path)

    # Get all files in the root Files directory (not in subfolders)
    root_files = Dir.glob(File.join(files_path, "*")).select { |f| File.file?(f) }.map do |file_path|
      file_name = File.basename(file_path)
      {
        name: file_name,
        size: File.size(file_path),
        modified: File.mtime(file_path),
        url: "/Files/#{file_name}"
      }
    end

    Rails.logger.debug "Root files found: #{root_files.inspect}"
    root_files
  end

  def get_special_file(file_type)
    files_path = Rails.root.join("public", "Files")
    return nil unless File.directory?(files_path)

    # Look for special files in root and all subdirectories
    pattern = case file_type
    when "weekly_schedule"
      "**/weekly*schedule*"
    when "kholle_schedule"
      "**/kholle*schedule*"
    else
      return nil
    end

    file_path = Dir.glob(File.join(files_path, pattern), File::FNM_CASEFOLD).first

    if file_path && File.file?(file_path)
      relative_path = file_path.sub(files_path.to_s, "").sub(/^\//, "")
      {
        name: File.basename(file_path),
        size: File.size(file_path),
        modified: File.mtime(file_path),
        url: "/Files/#{relative_path}"
      }
    end
  end

  def load_uploaded_files
    files_dir = Rails.root.join("public", "Files")
    return [] unless Dir.exist?(files_dir)

    Dir.glob(files_dir.join("*")).map do |file|
      next if File.directory?(file)

      filename = File.basename(file)
      # Skip schedule files as they'll be handled separately
      next if filename.start_with?("weekly_schedule_") || filename.start_with?("kholle_schedule_")

      {
        name: filename,
        size: File.size(file),
        url: "/Files/#{filename}"
      }
    end.compact
  end

  # ==========================================
  # HOMEWORK CONTENT METHODS
  # ==========================================

  def get_homework_content
    load_homework_content
  end

  def load_homework_content
    content_file = Rails.root.join("config", "homework_content.txt")
    if File.exist?(content_file)
      File.read(content_file)
    else
      "Find daily assignments and submission links. Stay organized with due dates and requirements."
    end
  end

  def save_homework_content(content)
    content_file = Rails.root.join("config", "homework_content.txt")

    # Ensure the config directory exists
    FileUtils.mkdir_p(File.dirname(content_file))

    begin
      File.write(content_file, content)
      true
    rescue StandardError => e
      Rails.logger.error "Error saving homework content: #{e.message}"
      false
    end
  end

  # ==========================================
  # LEGACY/UNUSED METHODS (kept for compatibility)
  # ==========================================

  def load_schedule_file(schedule_type)
    schedule_info_file = Rails.root.join("tmp", "#{schedule_type}.txt")
    return nil unless File.exist?(schedule_info_file)

    filename = File.read(schedule_info_file).strip
    file_path = Rails.root.join("public", "Files", filename)

    if File.exist?(file_path)
      {
        name: filename.sub(/^#{schedule_type}_/, ""), # Remove prefix for display
        url: "/Files/#{filename}",
        size: File.size(file_path)
      }
    end
  end

  def get_uploaded_files
    files_dir = Rails.root.join("public", "Files")
    return [] unless Dir.exist?(files_dir)

    Dir.glob(files_dir.join("*")).select { |f| File.file?(f) }.map do |file|
      {
        name: File.basename(file),
        size: File.size(file),
        url: "/Files/#{File.basename(file)}",
        modified: File.mtime(file)
      }
    end
  end
end
