document.addEventListener("DOMContentLoaded", () => {
    
    // ==========================================
    // 1. SYSTÈME DE TOASTS DYNAMIQUES
    // ==========================================
    const toastContainer = document.getElementById('toast-container');

    // Fonction globale pour créer un toast (réutilisable ailleurs si besoin via window.showToast)
    const showToast = (level, text) => {
        if (!toastContainer) return;

        const toast = document.createElement('div');
        
        // Classes de base (inclus l'animation d'entrée de droite à gauche)
        toast.className = 'flex items-center gap-2 rounded-md border p-4 font-semibold shadow-lg transition-all transform translate-x-full opacity-0 duration-300 pointer-events-auto max-w-sm backdrop-blur-md';

        // Icônes et couleurs selon le niveau du message
        let iconSvg = '';
        if (level.includes('success')) {
            toast.classList.add('border-emerald-500/30', 'bg-emerald-900/90', 'text-emerald-400');
            iconSvg = `<svg class="h-5 w-5 fill-current shrink-0" viewBox="0 0 256 256"><path d="M176.49,95.51a12,12,0,0,1,0,17l-56,56a12,12,0,0,1-17,0l-24-24a12,12,0,1,1,17-17L112,143l47.51-47.52A12,12,0,0,1,176.49,95.51ZM236,128A108,108,0,1,1,128,20,108.12,108.12,0,0,1,236,128Zm-24,0a84,84,0,1,0-84,84A84.09,84.09,0,0,0,212,128Z"></path></svg>`;
        } else if (level.includes('error')) {
            toast.classList.add('border-red-500/30', 'bg-red-900/90', 'text-red-400');
            iconSvg = `<svg class="h-5 w-5 fill-current shrink-0" viewBox="0 0 256 256"><path d="M128,24A104,104,0,1,0,232,128,104.11,104.11,0,0,0,128,24Zm0,192a88,88,0,1,1,88-88A88.1,88.1,0,0,1,128,216Zm-8-80V80a8,8,0,0,1,16,0v56a8,8,0,0,1-16,0Zm20,36a12,12,0,1,1-12-12A12,12,0,0,1,140,172Z"></path></svg>`;
        } else {
            toast.classList.add('border-blue-500/30', 'bg-blue-900/90', 'text-blue-400');
            iconSvg = `<svg class="h-5 w-5 fill-current shrink-0" viewBox="0 0 256 256"><path d="M128,24A104,104,0,1,0,232,128,104.11,104.11,0,0,0,128,24Zm0,192a88,88,0,1,1,88-88A88.1,88.1,0,0,1,128,216Zm-8-80V80a8,8,0,0,1,16,0v56a8,8,0,0,1-16,0Zm20,36a12,12,0,1,1-12-12A12,12,0,0,1,140,172Z"></path></svg>`;
        }

        toast.innerHTML = `${iconSvg} <span class="text-sm">${text}</span>`;
        toastContainer.appendChild(toast);

        // Déclenche l'animation d'apparition
        requestAnimationFrame(() => {
            toast.classList.remove('translate-x-full', 'opacity-0');
        });

        // Supprime le toast après 5 secondes
        setTimeout(() => {
            toast.classList.add('translate-x-full', 'opacity-0');
            setTimeout(() => toast.remove(), 300); // Laisse le temps à la transition CSS de finir
        }, 5000);
    };

    // Rendre la fonction accessible partout (pratique si tu fais des requêtes Fetch/AJAX plus tard)
    window.showToast = showToast;

    // Lire les messages Django au chargement de la page et les transformer en toasts
    const djangoMessagesScript = document.getElementById('django-messages');
    if (djangoMessagesScript) {
        try {
            const messages = JSON.parse(djangoMessagesScript.textContent);
            messages.forEach((msg, index) => {
                // Léger décalage (150ms) si plusieurs messages apparaissent en même temps
                setTimeout(() => showToast(msg.level, msg.text), index * 150);
            });
        } catch (e) {
            console.error("Erreur lors de la lecture des messages Django", e);
        }
    }


    // ==========================================
    // 2. GESTION DU MODE LOCALHOST
    // ==========================================
    if (['localhost', '127.0.0.1'].includes(window.location.hostname)) {
        document.getElementById('localhost-pill-warning')?.classList.remove('hidden');
        document.getElementById('localhost-deploy-warning')?.classList.remove('hidden');
        
        const deployForm = document.getElementById('deploy-form');
        if (deployForm) {
            deployForm.classList.add('opacity-50', 'pointer-events-none', 'grayscale');
            deployForm.querySelectorAll('input, button').forEach(el => el.disabled = true);
        }
    }
    
    // Animation du formulaire de déploiement
    document.getElementById('deploy-form')?.addEventListener('submit', () => {
        document.getElementById('submit-btn')?.classList.add('hidden');
        const indicator = document.getElementById('loading-indicator');
        if (indicator) {
            indicator.classList.remove('hidden');
            indicator.classList.add('flex');
        }
    });

    // ==========================================
    // 3. GESTION DES MODALES
    // ==========================================
    const setupModal = (modalId, openBtnId, closeBtnIds) => {
        const modal = document.getElementById(modalId);
        const openBtn = document.getElementById(openBtnId);
        
        if (!modal || !openBtn) return;

        const toggleModal = (show) => {
            modal.classList.toggle('hidden', !show);
            modal.classList.toggle('flex', show);
        };

        openBtn.addEventListener('click', () => toggleModal(true));
        closeBtnIds.forEach(id => document.getElementById(id)?.addEventListener('click', () => toggleModal(false)));
        modal.addEventListener('click', (e) => { if (e.target === modal) toggleModal(false); });
    };

    setupModal('employee-modal', 'open-employee-modal', ['close-employee-modal', 'cancel-employee-modal']);
    setupModal('settings-modal', 'open-settings-modal', ['close-settings-modal', 'cancel-settings-modal']);

    // ==========================================
    // 4. GESTION DES ACCORDÉONS (Employés)
    // ==========================================
    const setupAccordion = (btnId, containerId, iconId) => {
        document.getElementById(btnId)?.addEventListener('click', () => {
            document.getElementById(containerId)?.classList.toggle('hidden');
            document.getElementById(iconId)?.classList.toggle('rotate-180');
        });
    };

    setupAccordion('toggle-add-employee-btn', 'add-employee-form-container', 'toggle-add-employee-icon');

    document.querySelectorAll('.emp-toggle-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            document.getElementById(this.dataset.target)?.classList.toggle('hidden');
            this.querySelector('.emp-toggle-icon')?.classList.toggle('rotate-180');
        });
    });

});