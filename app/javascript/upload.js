
function toggleFolder(folderId) {
  console.log('Toggling folder:', folderId); // Debug log
  
  const folderElement = document.getElementById('folder-' + folderId);
  
  if (!folderElement) {
    console.error('Folder element not found:', 'folder-' + folderId);
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

function showView(viewType) {
  const foldersView = document.getElementById('folders-view');
  const allFilesView = document.getElementById('all-files-view');
  const buttons = document.querySelectorAll('.btn-group button');
  
  console.log('Switching to view:', viewType);
  
  // Remove active class from all buttons
  buttons.forEach(btn => btn.classList.remove('active'));
  
  if (viewType === 'folders') {
    if (foldersView) {
      foldersView.style.display = 'block';
      console.log('Showing folders view');
    }
    if (allFilesView) {
      allFilesView.style.display = 'none';
      console.log('Hiding all files view');
    }
    if (buttons[0]) buttons[0].classList.add('active');
  } else {
    if (foldersView) {
      foldersView.style.display = 'none';
      console.log('Hiding folders view');
    }
    if (allFilesView) {
      allFilesView.style.display = 'block';
      console.log('Showing all files view');
    }
    if (buttons[1]) buttons[1].classList.add('active');
  }
}

// Debug function to check what folders exist
function debugFolders() {
  console.log('=== FOLDER DEBUG INFO ===');
  const folderCards = document.querySelectorAll('.folder-card');
  const folderContents = document.querySelectorAll('.folder-contents');
  
  console.log('Folder cards found:', folderCards.length);
  folderCards.forEach((card, index) => {
    const onclick = card.querySelector('.folder-item').getAttribute('onclick');
    console.log(`Card ${index}:`, onclick);
  });
  
  console.log('Folder contents found:', folderContents.length);
  folderContents.forEach((content, index) => {
    console.log(`Content ${index}:`, {
      id: content.id,
      'data-folder': content.dataset.folder,
      display: content.style.display
    });
  });
}

// Run debug on page load
document.addEventListener('DOMContentLoaded', function() {
  debugFolders();
});