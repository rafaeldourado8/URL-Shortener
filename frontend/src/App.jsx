import { useState } from 'react';
import axios from 'axios';
import { motion, AnimatePresence } from 'framer-motion';
import { Link, Loader2, BarChart3, Globe2, Zap, Github, ArrowRight, Copy, Check } from 'lucide-react';
import BackgroundGradient from './components/BackgroundGradient';
import ResultCard from './components/ResultCard';

const App = () => {
  const [url, setUrl] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [result, setResult] = useState(null);
  const [copied, setCopied] = useState(false);

  const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

  const validateUrl = (input) => {
    try {
      new URL(input);
      return true;
    } catch {
      return false;
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setResult(null);
    
    if (!validateUrl(url)) {
      setError('Insira uma URL válida (http://...)');
      return;
    }

    setLoading(true);
    
    try {
      const response = await axios.post(`${API_URL}/urls`, { url: url });
      setResult(response.data);
      setUrl('');
    } catch (err) {
      setError('Erro ao encurtar link.');
    } finally {
      setLoading(false);
    }
  };

  const handleCopy = () => {
    if (result?.short_url) {
      navigator.clipboard.writeText(result.short_url);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  return (
    <div className="min-h-screen text-white relative selection:bg-white selection:text-black">
      <BackgroundGradient />
      
      {/* Header */}
      <header className="fixed top-0 w-full z-50 py-6 px-6 border-b border-zinc-900 bg-black/50 backdrop-blur-sm">
        <div className="max-w-5xl mx-auto flex justify-between items-center">
          <div className="flex items-center gap-2 font-bold text-xl tracking-tighter">
            <Link className="w-5 h-5" />
            <span>ShortURL's</span>
          </div>
          
          <a 
            href="https://github.com/rafaeldourado8/URL-Shortener.git" 
            target="_blank" 
            className="text-xs font-mono text-zinc-500 hover:text-white transition-colors flex items-center gap-2"
          >
            <Github className="w-3 h-3" />
            GitHub v1.0
          </a>
        </div>
      </header>

      {/* Main Content */}
      <main className="pt-40 px-4 flex flex-col items-center justify-center min-h-screen">
        <div className="max-w-2xl w-full text-center">
          
          {/* Badge */}
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-zinc-800 bg-zinc-900/50 text-[10px] uppercase tracking-widest text-zinc-400 mb-8">
            <span className="w-1.5 h-1.5 rounded-full bg-white animate-pulse"></span>
            Online System
          </div>

          {/* Title - SEM GRADIENTE COLORIDO */}
          <h1 className="text-5xl md:text-7xl font-bold tracking-tighter mb-6 text-white">
            Links encurtados.<br />
            <span className="text-zinc-500">Sem complicações.</span>
          </h1>
          
          <p className="text-zinc-400 text-lg mb-12 max-w-lg mx-auto font-light">
            Infraestrutura moderna e design limpo.
          </p>

          {/* Input Box - Estilo "Terminal/Dark" */}
          <div className="relative z-20 mb-16">
            <form onSubmit={handleSubmit} className="flex items-center p-1 bg-black border border-zinc-800 rounded-full focus-within:border-zinc-600 transition-colors shadow-2xl shadow-zinc-900/20">
              <input
                type="text"
                value={url}
                onChange={(e) => setUrl(e.target.value)}
                placeholder="Cole seu link longo aqui..."
                className="flex-1 bg-transparent px-6 py-3 outline-none text-white placeholder-zinc-600 font-medium"
                disabled={loading}
              />
              <button
                type="submit"
                disabled={loading}
                className="bg-black text-white border border-zinc-700 hover:bg-white hover:text-black hover:border-white transition-all duration-300 rounded-full px-6 py-3 font-medium text-sm flex items-center gap-2 disabled:opacity-50"
              >
                {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Encurtar'}
              </button>
            </form>
            
            {error && (
              <div className="mt-4 text-red-500 text-sm bg-red-500/10 inline-block px-3 py-1 rounded border border-red-500/20">
                {error}
              </div>
            )}
          </div>

          {/* Result Area */}
          <AnimatePresence mode="wait">
            {result && (
              <motion.div
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                className="mb-20 text-left"
              >
                <ResultCard result={result} onCopy={handleCopy} copied={copied} />
              </motion.div>
            )}
          </AnimatePresence>

          {/* Footer Grid */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 opacity-50 hover:opacity-100 transition-opacity duration-500">
             <Feature icon={<Zap />} title="Rápido" desc="Resposta em ms" />
             <Feature icon={<BarChart3 />} title="Analytics" desc="Dados em tempo real" />
             <Feature icon={<Globe2 />} title="Global" desc="Acesso mundial" />
          </div>
        </div>
      </main>
    </div>
  );
};

const Feature = ({ icon, title, desc }) => (
  <div className="p-4 border border-zinc-900 rounded-xl bg-zinc-950/50 flex flex-col items-center text-center gap-2">
    <div className="w-5 h-5 text-white">{icon}</div>
    <div className="text-sm font-bold text-white">{title}</div>
    <div className="text-xs text-zinc-500">{desc}</div>
  </div>
);

export default App;