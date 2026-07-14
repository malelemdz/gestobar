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

// Global precise smooth scroll
window.scrollToSection = function(event, targetId) {
    event.preventDefault();
    const targetElement = document.querySelector(targetId);
    if (targetElement) {
        const headerOffset = 100; // navbar height (80px) + 20px margin offset
        const elementPosition = targetElement.offsetTop;
        const offsetPosition = elementPosition - headerOffset;
        
        window.scrollTo({
            top: offsetPosition,
            behavior: 'smooth'
        });
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

    // Scroll Spy for Navbar highlighting
    const headerOffset = 120;
    const navLinks = document.querySelectorAll('nav a[href^="#"]');
    
    function scrollSpy() {
        const scrollPosition = window.scrollY || document.documentElement.scrollTop;
        let activeSectionId = '';
        
        document.querySelectorAll('section[id]').forEach(section => {
            const sectionTop = section.offsetTop - headerOffset;
            const sectionHeight = section.offsetHeight;
            if (scrollPosition >= sectionTop && scrollPosition < sectionTop + sectionHeight) {
                activeSectionId = section.getAttribute('id');
            }
        });
        
        navLinks.forEach(link => {
            const href = link.getAttribute('href');
            // Skip the Empezar Ahora button
            if (link.classList.contains('bg-primary')) return;
            
            if (href === `#${activeSectionId}`) {
                link.className = "text-primary font-bold border-b-2 border-primary pb-1 text-label-lg";
            } else {
                link.className = "text-on-surface-variant hover:text-on-surface transition-colors text-label-lg";
            }
        });
    }

    window.addEventListener('scroll', scrollSpy);
    scrollSpy(); // run once on load
});
