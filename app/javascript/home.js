function toggleResourceFolder(folderId) {
  console.log('Toggling folder:', folderId); // Debug log
  
  const folderElement = document.getElementById('resource-folder-' + folderId);
  
  if (!folderElement) {
    console.error('Folder element not found:', 'resource-folder-' + folderId);
    return;
  }
  
  // Find the specific folder card
  const folderCard = folderElement.closest('.folder-card');
  if (!folderCard) {
    console.error('Folder card not found');
    return;
  }
  
  const folderItem = folderCard.querySelector('.folder-item');
  const isOpen = folderElement.style.display !== 'none';
  
  if (isOpen) {
    // Close folder
    folderElement.style.display = 'none';
    folderItem.classList.remove('folder-open');
    folderItem.classList.add('folder-closed');
    
    // Update icons safely
    const folderIconClosed = folderItem.querySelector('.folder-icon-closed');
    const folderIconOpen = folderItem.querySelector('.folder-icon-open');
    const folderArrowClosed = folderItem.querySelector('.folder-arrow-closed');
    const folderArrowOpen = folderItem.querySelector('.folder-arrow-open');
    
    if (folderIconClosed) folderIconClosed.style.display = 'block';
    if (folderIconOpen) folderIconOpen.style.display = 'none';
    if (folderArrowClosed) folderArrowClosed.style.display = 'block';
    if (folderArrowOpen) folderArrowOpen.style.display = 'none';
  } else {
    // Open folder
    folderElement.style.display = 'block';
    folderItem.classList.remove('folder-closed');
    folderItem.classList.add('folder-open');
    
    // Update icons safely
    const folderIconClosed = folderItem.querySelector('.folder-icon-closed');
    const folderIconOpen = folderItem.querySelector('.folder-icon-open');
    const folderArrowClosed = folderItem.querySelector('.folder-arrow-closed');
    const folderArrowOpen = folderItem.querySelector('.folder-arrow-open');
    
    if (folderIconClosed) folderIconClosed.style.display = 'none';
    if (folderIconOpen) folderIconOpen.style.display = 'block';
    if (folderArrowClosed) folderArrowClosed.style.display = 'none';
    if (folderArrowOpen) folderArrowOpen.style.display = 'block';
    
    // Add smooth animation
    folderElement.style.opacity = '0';
    folderElement.style.transform = 'translateY(-10px)';
    setTimeout(() => {
      folderElement.style.transition = 'all 0.3s ease';
      folderElement.style.opacity = '1';
      folderElement.style.transform = 'translateY(0)';
    }, 10);
  }
}

// Debug function to check what folders exist
function debugFolders() {
  console.log('Available folders:');
  document.querySelectorAll('[data-folder]').forEach((element, index) => {
    console.log(`${index + 1}:`, element.getAttribute('data-folder'));
  });
}

// Call debug function when page loads
document.addEventListener('DOMContentLoaded', function() {
  debugFolders();
});