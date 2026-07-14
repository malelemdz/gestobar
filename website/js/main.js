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

    // FAQ Accordion Toggle
    window.toggleFaq = function(element) {
        const answer = element.querySelector('.faq-answer');
        const icon = element.querySelector('.faq-icon');
        if (answer.classList.contains('max-h-0')) {
            // Close all other FAQs first
            document.querySelectorAll('.faq-answer').forEach(el => {
                el.classList.add('max-h-0', 'opacity-0');
                el.classList.remove('max-h-96', 'opacity-100');
            });
            document.querySelectorAll('.faq-icon').forEach(ic => {
                ic.classList.remove('rotate-180');
            });
            
            // Open this one
            answer.classList.remove('max-h-0', 'opacity-0');
            answer.classList.add('max-h-96', 'opacity-100');
            icon.classList.add('rotate-180');
        } else {
            answer.classList.add('max-h-0', 'opacity-0');
            answer.classList.remove('max-h-96', 'opacity-100');
            icon.classList.remove('rotate-180');
        }
    };
});
