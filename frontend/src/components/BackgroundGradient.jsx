import { motion } from 'framer-motion';
import { useEffect, useState } from 'react';

const BackgroundGradient = () => {
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 });

  useEffect(() => {
    let ticking = false;
    const handleMouseMove = (e) => {
      if (!ticking) {
        window.requestAnimationFrame(() => {
          setMousePosition({ x: e.clientX, y: e.clientY });
          ticking = false;
        });
        ticking = true;
      }
    };

    window.addEventListener("mousemove", handleMouseMove);
    return () => window.removeEventListener("mousemove", handleMouseMove);
  }, []);

  return (
    <div className="fixed inset-0 bg-black -z-10 overflow-hidden">
      {/* 1. Grid Sutil de Fundo (Textura Premium) */}
      <div 
        className="absolute inset-0 opacity-20"
        style={{
            backgroundImage: `linear-gradient(to right, #202020 1px, transparent 1px), linear-gradient(to bottom, #202020 1px, transparent 1px)`,
            backgroundSize: '40px 40px',
            maskImage: 'radial-gradient(ellipse 60% 50% at 50% 0%, #000 70%, transparent 100%)'
        }}
      />

      {/* 2. O Gradiente "Spotlight" Cinza Premium */}
      <motion.div
        className="fixed w-[800px] h-[800px] rounded-full pointer-events-none"
        animate={{
          x: mousePosition.x - 400, // Centraliza no mouse (metade da largura)
          y: mousePosition.y - 400, // Centraliza no mouse (metade da altura)
        }}
        transition={{ 
          type: "spring", 
          damping: 30, 
          stiffness: 150, // Mais rápido e responsivo
          mass: 0.1 
        }}
        style={{
          // Gradiente radial complexo para suavidade máxima
          // Começa com um cinza/branco muito suave (0.08) e desvanece para transparente
          background: 'radial-gradient(circle closest-side, rgba(255, 255, 255, 0.08), rgba(255, 255, 255, 0.03) 40%, transparent 100%)',
          
          // Mix-blend-mode 'screen' ou 'plus-lighter' ajuda a fundir com o preto de forma limpa
          mixBlendMode: 'screen',
          
          // Blur alto para eliminar bordas duras
          filter: 'blur(40px)' 
        }}
      />

      {/* 3. Vinheta sutil nos cantos para focar no centro */}
      <div className="absolute inset-0 bg-gradient-to-tr from-black/80 via-transparent to-black/80 pointer-events-none" />
    </div>
  );
};

export default BackgroundGradient;