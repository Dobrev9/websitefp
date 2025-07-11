document.addEventListener('DOMContentLoaded', function() {
  console.log('JavaScript loaded!'); // Debug line
  
  const textarea = document.getElementById('homework_content');
  const preview = document.getElementById('content-preview');
  
  console.log('Textarea found:', textarea); // Debug line
  console.log('Preview found:', preview); // Debug line
  
  if (textarea && preview) {
    console.log('Both elements found, setting up event listener'); // Debug line
    
    // Function to format text content
    function formatText(text) {
      if (!text || text.trim() === '') {
        return 'Enter content to see preview...';
      }
      
      // Simply return the stripped text - let CSS handle line breaks with pre-line
      return text.strip || text.trim();
    }
    
    // Update preview on input
    textarea.addEventListener('input', function() {
      console.log('Input detected:', this.value); // Debug line
      preview.textContent = formatText(this.value);
    });
    
    // Initialize preview with current content
    preview.textContent = formatText(textarea.value);
    console.log('Preview initialized'); // Debug line
  } else {
    console.log('Elements not found!'); // Debug line
  }
});