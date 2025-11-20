// Notification System
// Handles showing and managing notifications in the game

// Initialize the notification system
export function initializeNotifications() {
    // System is initialized through CSS and HTML structure
    console.log('Notification system initialized');
}

// Show a notification instead of using alert()
export function showNotification(message, type = 'info', title = '', duration = 5000) {
    const notificationContainer = document.getElementById('notification-container');
    
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    
    // Create notification content
    let notificationContent = '';
    if (title) {
        notificationContent += `<div class="notification-title">${title}</div>`;
    }
    notificationContent += `<div class="notification-message">${message.replace(/\n/g, "<br>")}</div>`;
    notificationContent += `<div class="notification-close">×</div>`;
    
    if (duration > 0) {
        notificationContent += `<div class="notification-progress"></div>`;
    }
    
    notification.innerHTML = notificationContent;
    
    // Add to container
    notificationContainer.appendChild(notification);
    
    // Show notification with animation
    setTimeout(() => {
        notification.classList.add('show');
    }, 10);
    
    // Add progress animation if duration is set
    if (duration > 0) {
        const progress = notification.querySelector('.notification-progress');
        progress.style.transition = `width ${duration}ms linear`;
        
        // Start progress animation
        setTimeout(() => {
            progress.style.width = '0%';
        }, 10);
        
        // Remove notification after duration
        setTimeout(() => {
            removeNotification(notification);
        }, duration);
    }
    
    // Add close button event listener
    const closeBtn = notification.querySelector('.notification-close');
    closeBtn.addEventListener('click', () => {
        removeNotification(notification);
    });
    
    return notification;
}

// Remove a notification with animation
export function removeNotification(notification) {
    notification.classList.remove('show');
    
    // Remove from DOM after animation
    setTimeout(() => {
        if (notification.parentNode) {
            notification.parentNode.removeChild(notification);
        }
    }, 300);
}

// Replace alert with our custom notification system
export function gameAlert(message, type = 'info', title = '', duration = 5000) {
    return showNotification(message, type, title, duration);
}

// Export for global access
window.showNotification = showNotification;
window.gameAlert = gameAlert; 