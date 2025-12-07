import { motion } from 'framer-motion';
import { Copy, Check, ExternalLink, ArrowRight } from 'lucide-react';

const ResultCard = ({ result, onCopy, copied }) => {
  return (
    <div className="bg-black border border-zinc-800 rounded-2xl p-6 md:p-8 max-w-2xl mx-auto shadow-2xl relative overflow-hidden group">
      
      {/* Brilho sutil no hover */}
      <div className="absolute top-0 right-0 w-64 h-64 bg-white/5 rounded-full blur-[80px] -translate-y-1/2 translate-x-1/2 group-hover:bg-white/10 transition-colors duration-700" />

      <div className="relative z-10">
        <div className="flex justify-between items-center mb-6">
          <span className="text-zinc-500 text-xs font-mono uppercase tracking-widest">Resultado</span>
          <div className="flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 bg-green-500 rounded-full animate-pulse"/>
            <span className="text-xs text-zinc-400">Ativo</span>
          </div>
        </div>

        <div className="space-y-4">
          <div className="bg-zinc-900/50 rounded-lg p-3 border border-zinc-800/50">
            <p className="text-xs text-zinc-500 mb-1">Original</p>
            <p className="text-zinc-300 text-sm truncate font-mono">{result.original_url}</p>
          </div>

          <div className="flex flex-col sm:flex-row gap-2">
            <div className="flex-1 bg-white/5 border border-zinc-700 rounded-lg p-4 flex items-center justify-between group/link hover:border-zinc-500 transition-colors">
              <span className="text-white font-medium text-lg tracking-tight">{result.short_url}</span>
              <a href={result.short_url} target="_blank" className="text-zinc-500 hover:text-white transition-colors">
                <ExternalLink className="w-4 h-4" />
              </a>
            </div>
            
            <button
              onClick={onCopy}
              className="bg-white text-black font-semibold rounded-lg px-6 py-4 hover:bg-zinc-200 transition-colors flex items-center justify-center gap-2 min-w-[120px]"
            >
              {copied ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
              <span>{copied ? 'Copiado' : 'Copiar'}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ResultCard;