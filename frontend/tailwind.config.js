/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        background: '#000000', // Preto Absoluto
        surface: '#09090b',    // Cinza muito escuro para cards
        border: '#27272a',     // Cinza escuro para bordas
        primary: '#ffffff',    // Branco puro
        secondary: '#a1a1aa',  // Cinza médio para textos secundários
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      animation: {
        'pulse-slow': 'pulse 8s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      },
    },
  },
  plugins: [],
}