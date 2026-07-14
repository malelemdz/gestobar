// Gestobar Web interactions and animations

// Global WhatsApp triggers
window.triggerWhatsApp = function(url) {
    const modalBtn = document.getElementById('modalConfirmBtn');
    const modal = document.getElementById('whatsappModal');
    if (modalBtn) modalBtn.href = url;
    if (modal) {
        modal.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    }
};

window.closeModal = function() {
    const modal = document.getElementById('whatsappModal');
    if (modal) {
        modal.classList.add('hidden');
        document.body.style.overflow = 'auto';
    }
};

// Global FAQ Toggle
window.toggleFaq = function(element) {
    const isActive = element.classList.contains('active');
    
    // Close all other FAQ items first
    document.querySelectorAll('.faq-item').forEach(el => {
        el.classList.remove('active');
    });
    
    // If it wasn't active, open it
    if (!isActive) {
        element.classList.add('active');
    }
};

document.addEventListener('DOMContentLoaded', () => {
    const modal = document.getElementById('whatsappModal');
    const modalBtn = document.getElementById('modalConfirmBtn');

    if (modal) {
        modal.addEventListener('click', (e) => {
            if (e.target === modal) window.closeModal();
        });
    }

    if (modalBtn) {
        modalBtn.addEventListener('click', () => {
            window.closeModal();
        });
    }

    // Scroll reveal animation for grid cards
    const observerOptions = {
        threshold: 0.05
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('opacity-100', 'translate-y-0');
                entry.target.classList.remove('opacity-0', 'translate-y-8');
            }
        });
    }, observerOptions);

    document.querySelectorAll('.glass-card').forEach(el => {
        el.classList.add('transition-all', 'duration-700', 'opacity-0', 'translate-y-8');
        observer.observe(el);
    });
});
