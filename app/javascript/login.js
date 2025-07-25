// Simple inline JavaScript for password toggle
function togglePasswordVisibility() {
  console.log('Toggle function called!');
  
  const passwordField = document.getElementById('password');
  const eyeHidden = document.getElementById('eyeHidden');
  const eyeVisible = document.getElementById('eyeVisible');
  
  if (passwordField && eyeHidden && eyeVisible) {
    if (passwordField.type === 'password') {
      console.log('Showing password');
      passwordField.type = 'text';
      eyeHidden.style.display = 'none';
      eyeVisible.style.display = 'block';
    } else {
      console.log('Hiding password');
      passwordField.type = 'password';
      eyeHidden.style.display = 'block';
      eyeVisible.style.display = 'none';
    }
  } else {
    console.log('Elements not found');
  }
}

// Bootstrap form validation
(function() {
  'use strict';
  window.addEventListener('load', function() {
    var forms = document.getElementsByClassName('needs-validation');
    var validation = Array.prototype.filter.call(forms, function(form) {
      form.addEventListener('submit', function(event) {
        if (form.checkValidity() === false) {
          event.preventDefault();
          event.stopPropagation();
        }
        form.classList.add('was-validated');
      }, false);
    });
  }, false);
})();

// Auto-focus password field
document.addEventListener('DOMContentLoaded', function() {
  const passwordField = document.getElementById('password');
  if (passwordField) {
    passwordField.focus();
  }
});