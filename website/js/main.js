// Gestobar Web interactions and animations
document.addEventListener('DOMContentLoaded', () => {
    const modal = document.getElementById('whatsappModal');
    const modalBtn = document.getElementById('modalConfirmBtn');

    window.triggerWhatsApp = function(url) {
        if (modalBtn) modalBtn.href = url;
        if (modal) {
            modal.classList.remove('hidden');
            document.body.style.overflow = 'hidden';
        }
    };

    window.closeModal = function() {
        if (modal) {
            modal.classList.add('hidden');
            document.body.style.overflow = 'auto';
        }
    };

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
