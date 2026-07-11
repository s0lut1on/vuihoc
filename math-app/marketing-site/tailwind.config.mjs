/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,ts,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        // Brand palette (mirror of math-app/frontend/lib/core/app_colors.dart)
        pink: {
          DEFAULT: '#FF6B9D',
          dark: '#C0266B',
          soft: '#FFE0EC',
          bg: '#FFF5FA',
        },
        purple: {
          DEFAULT: '#7C3AED',
          dark: '#5B21B6',
          deep: '#2D1B4E',
          muted: '#6B5B95',
        },
        cream: '#FFF8E1',
        sky: '#E0F2FE',
        skyblue: '#A5D8FF',
        success: '#22C55E',
        warning: '#FF9A3D',
        danger: '#EF4444',
        yellow: '#FDE047',
        // Persona
        achiever: { bg: '#FFF3E0', text: '#E65100' },
        gamer: { bg: '#E8F5E9', text: '#2E7D32' },
        struggler: { bg: '#E3F2FD', text: '#1565C0' },
        silent: { bg: '#F3E5F5', text: '#7B1FA2' },
      },
      fontFamily: {
        sans: ['Inter', 'Noto Sans', 'system-ui', '-apple-system', 'Segoe UI', 'Roboto', 'sans-serif'],
        display: ['"Plus Jakarta Sans"', 'Inter', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        'chunky': '0 8px 0 0 #C0266B, 0 12px 24px rgba(0,0,0,0.12)',
        'chunky-sm': '0 4px 0 0 #C0266B, 0 6px 12px rgba(0,0,0,0.1)',
        'pill': '0 3px 0 0 #C0266B',
      },
      animation: {
        'wiggle': 'wiggle 0.6s ease-in-out infinite',
        'float': 'float 3s ease-in-out infinite',
        'pulse-soft': 'pulse-soft 2s ease-in-out infinite',
      },
      keyframes: {
        wiggle: {
          '0%, 100%': { transform: 'rotate(-3deg)' },
          '50%': { transform: 'rotate(3deg)' },
        },
        float: {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-10px)' },
        },
        'pulse-soft': {
          '0%, 100%': { transform: 'scale(1)', opacity: '1' },
          '50%': { transform: 'scale(1.05)', opacity: '0.95' },
        },
      },
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
  ],
};
