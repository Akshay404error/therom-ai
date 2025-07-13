// Theorem AI Frontend JavaScript
document.addEventListener('DOMContentLoaded', function() {
    // Initialize all functionality
    initNavigation();
    initSmoothScrolling();
    initScrollAnimations();
    initDemoFunctionality();
    initMobileMenu();
});

// Navigation functionality
function initNavigation() {
    const navbar = document.querySelector('.navbar');
    
    // Add scroll effect to navbar
    window.addEventListener('scroll', () => {
        if (window.scrollY > 100) {
            navbar.style.background = 'rgba(255, 255, 255, 0.98)';
            navbar.style.boxShadow = '0 4px 20px rgba(0, 0, 0, 0.1)';
        } else {
            navbar.style.background = 'rgba(255, 255, 255, 0.95)';
            navbar.style.boxShadow = 'none';
        }
    });
}

// Smooth scrolling for navigation links
function initSmoothScrolling() {
    const navLinks = document.querySelectorAll('a[href^="#"]');
    
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const targetId = this.getAttribute('href');
            const targetSection = document.querySelector(targetId);
            
            if (targetSection) {
                const offsetTop = targetSection.offsetTop - 70; // Account for fixed navbar
                window.scrollTo({
                    top: offsetTop,
                    behavior: 'smooth'
                });
            }
        });
    });
}

// Scroll animations
function initScrollAnimations() {
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
            }
        });
    }, observerOptions);
    
    // Observe elements for animation
    const animateElements = document.querySelectorAll('.feature-card, .doc-card, .demo-container');
    animateElements.forEach(el => {
        el.classList.add('scroll-animate');
        observer.observe(el);
    });
}

// Mobile menu functionality
function initMobileMenu() {
    const hamburger = document.querySelector('.hamburger');
    const navMenu = document.querySelector('.nav-menu');
    
    if (hamburger && navMenu) {
        hamburger.addEventListener('click', () => {
            hamburger.classList.toggle('active');
            navMenu.classList.toggle('active');
        });
        
        // Close menu when clicking on a link
        const navLinks = document.querySelectorAll('.nav-menu a');
        navLinks.forEach(link => {
            link.addEventListener('click', () => {
                hamburger.classList.remove('active');
                navMenu.classList.remove('active');
            });
        });
    }
}

// Demo functionality
function initDemoFunctionality() {
    // Add syntax highlighting to code examples
    highlightCode();
    
    // Add typing effect to hero code
    typeCodeEffect();
}

// Syntax highlighting for Theorem AI code
function highlightCode() {
    const codeBlocks = document.querySelectorAll('code.language-theorem-ai');
    
    codeBlocks.forEach(block => {
        let code = block.textContent;
        
        // Highlight comments
        code = code.replace(/(--.*$)/gm, '<span class="comment">$1</span>');
        
        // Highlight keywords
        const keywords = ['def', 'theorem', 'match', 'with', 'induction', 'by', 'simp', 'apply', 'exact', 'let', 'in', 'if', 'then', 'else'];
        keywords.forEach(keyword => {
            const regex = new RegExp(`\\b${keyword}\\b`, 'g');
            code = code.replace(regex, `<span class="keyword">${keyword}</span>`);
        });
        
        // Highlight function names
        code = code.replace(/(\w+)\s*\(/g, '<span class="function">$1</span>(');
        
        // Highlight strings
        code = code.replace(/"([^"]*)"/g, '<span class="string">"$1"</span>');
        
        // Highlight numbers
        code = code.replace(/\b(\d+)\b/g, '<span class="number">$1</span>');
        
        block.innerHTML = code;
    });
}

// Typing effect for hero code
function typeCodeEffect() {
    const codeElement = document.querySelector('.hero-visual code');
    if (!codeElement) return;
    
    const originalCode = codeElement.textContent;
    codeElement.textContent = '';
    
    let i = 0;
    const typeSpeed = 30;
    
    function typeChar() {
        if (i < originalCode.length) {
            codeElement.textContent += originalCode.charAt(i);
            i++;
            setTimeout(typeChar, typeSpeed);
        }
    }
    
    // Start typing after a delay
    setTimeout(typeChar, 1000);
}

// Global functions for HTML onclick events
window.runDemo = function() {
    scrollToSection('demo');
};

window.scrollToSection = function(sectionId) {
    const section = document.getElementById(sectionId);
    if (section) {
        const offsetTop = section.offsetTop - 70;
        window.scrollTo({
            top: offsetTop,
            behavior: 'smooth'
        });
    }
};

// Documentation viewer
window.openDocumentation = function(docType) {
    const docUrls = {
        'quick-start': 'docs/quick-start.md',
        'tutorial': 'docs/tutorial.md',
        'reference': 'docs/reference.md'
    };
    
    const url = docUrls[docType];
    if (url) {
        // Open in a new tab for markdown files
        window.open(url, '_blank');
    }
};

// Download functionality
window.downloadProject = function() {
    // Create a zip file of the project
    const downloadLink = document.createElement('a');
    downloadLink.href = 'https://github.com/your-username/theorem-ai/archive/refs/heads/main.zip';
    downloadLink.download = 'theorem-ai.zip';
    downloadLink.target = '_blank';
    document.body.appendChild(downloadLink);
    downloadLink.click();
    document.body.removeChild(downloadLink);
};

window.executeCode = function() {
    const codeInput = document.getElementById('code-input');
    const outputContent = document.getElementById('output-content');
    
    if (!codeInput || !outputContent) return;
    
    const code = codeInput.value.trim();
    
    if (!code) {
        showOutput('Please enter some code to execute.', 'error');
        return;
    }
    
    // Clear previous output
    outputContent.innerHTML = '';
    
    // Show loading
    showOutput('Executing code...', 'info');
    
    // Simulate code execution (in a real implementation, this would call the Theorem AI compiler)
    setTimeout(() => {
        try {
            const result = simulateCodeExecution(code);
            showOutput(result, 'success');
        } catch (error) {
            showOutput(`Error: ${error.message}`, 'error');
        }
    }, 1000);
};

window.clearOutput = function() {
    const outputContent = document.getElementById('output-content');
    if (outputContent) {
        outputContent.innerHTML = `
            <div class="output-message">
                <i class="fas fa-info-circle"></i>
                <span>Enter code and click Execute to see the results!</span>
            </div>
        `;
    }
};

// Helper functions
function showOutput(message, type = 'info') {
    const outputContent = document.getElementById('output-content');
    if (!outputContent) return;
    
    const outputDiv = document.createElement('div');
    outputDiv.className = `output-${type}`;
    
    let icon = 'info-circle';
    if (type === 'success') icon = 'check-circle';
    if (type === 'error') icon = 'exclamation-circle';
    
    outputDiv.innerHTML = `
        <i class="fas fa-${icon}"></i>
        <span>${message}</span>
    `;
    
    outputContent.appendChild(outputDiv);
    outputContent.scrollTop = outputContent.scrollHeight;
}

function simulateCodeExecution(code) {
    // Simple simulation of Theorem AI code execution
    const lines = code.split('\n');
    let output = [];
    
    for (let line of lines) {
        line = line.trim();
        
        // Skip comments and empty lines
        if (line.startsWith('--') || !line) continue;
        
        // Handle #eval commands
        if (line.startsWith('#eval')) {
            const expression = line.substring(5).trim();
            const result = evaluateExpression(expression);
            output.push(`#eval ${expression} → ${result}`);
        }
        
        // Handle function definitions
        if (line.startsWith('def ')) {
            const funcName = line.match(/def\s+(\w+)/)?.[1];
            if (funcName) {
                output.push(`✓ Function '${funcName}' defined successfully`);
            }
        }
        
        // Handle theorem definitions
        if (line.startsWith('theorem ')) {
            const theoremName = line.match(/theorem\s+(\w+)/)?.[1];
            if (theoremName) {
                output.push(`✓ Theorem '${theoremName}' defined successfully`);
            }
        }
    }
    
    if (output.length === 0) {
        output.push('No executable expressions found. Try using #eval to evaluate expressions.');
    }
    
    return output.join('\n');
}

function evaluateExpression(expression) {
    // Simple expression evaluation for demo purposes
    expression = expression.trim();
    
    // Handle string literals
    if (expression.includes('"Hello')) {
        return '"Hello, World!"';
    }
    
    // Handle function calls
    if (expression.includes('greet')) {
        return '"Hello, World!"';
    }
    
    if (expression.includes('fibonacci')) {
        const match = expression.match(/fibonacci\s+(\d+)/);
        if (match) {
            const n = parseInt(match[1]);
            return fibonacci(n).toString();
        }
    }
    
    if (expression.includes('factorial')) {
        const match = expression.match(/factorial\s+(\d+)/);
        if (match) {
            const n = parseInt(match[1]);
            return factorial(n).toString();
        }
    }
    
    // Default fallback
    return 'undefined';
}

function fibonacci(n) {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

function factorial(n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}

// Add CSS for mobile menu
const mobileMenuCSS = `
    @media (max-width: 768px) {
        .nav-menu {
            position: fixed;
            left: -100%;
            top: 70px;
            flex-direction: column;
            background-color: white;
            width: 100%;
            text-align: center;
            transition: 0.3s;
            box-shadow: 0 10px 27px rgba(0, 0, 0, 0.05);
            padding: 2rem 0;
        }
        
        .nav-menu.active {
            left: 0;
        }
        
        .hamburger.active span:nth-child(2) {
            opacity: 0;
        }
        
        .hamburger.active span:nth-child(1) {
            transform: translateY(8px) rotate(45deg);
        }
        
        .hamburger.active span:nth-child(3) {
            transform: translateY(-8px) rotate(-45deg);
        }
    }
`;

// Inject mobile menu CSS
const style = document.createElement('style');
style.textContent = mobileMenuCSS;
document.head.appendChild(style);

// Performance optimization: Debounce scroll events
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Apply debouncing to scroll events
window.addEventListener('scroll', debounce(() => {
    // Scroll-based animations and effects
}, 10));

// Add loading animation
window.addEventListener('load', () => {
    document.body.classList.add('loaded');
});

// Add CSS for loading animation
const loadingCSS = `
    body:not(.loaded) {
        overflow: hidden;
    }
    
    body:not(.loaded)::before {
        content: '';
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: linear-gradient(135deg, #6366f1, #8b5cf6);
        z-index: 9999;
        display: flex;
        align-items: center;
        justify-content: center;
    }
    
    body:not(.loaded)::after {
        content: 'Theorem AI';
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        color: white;
        font-size: 2rem;
        font-weight: 700;
        z-index: 10000;
        animation: pulse 2s infinite;
    }
    
    @keyframes pulse {
        0%, 100% { opacity: 1; }
        50% { opacity: 0.7; }
    }
`;

const loadingStyle = document.createElement('style');
loadingStyle.textContent = loadingCSS;
document.head.appendChild(loadingStyle); 