'use client';

import Link from 'next/link';
import { useState } from 'react';

export function Header() {
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <header className="sticky top-0 z-50 bg-white/95 backdrop-blur-sm border-b border-gray-100 shadow-sm">
      <div className="section-container">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2 font-bold text-xl text-brand-navy">
            <span className="text-2xl">🏠</span>
            <span>
              Amortizador<span className="text-brand-green"> Pro</span>
            </span>
          </Link>

          {/* Desktop nav */}
          <nav className="hidden md:flex items-center gap-6">
            <Link
              href="/simulador"
              className="text-gray-600 hover:text-brand-navy font-medium transition-colors"
            >
              Simulador
            </Link>
            <Link
              href="/blog"
              className="text-gray-600 hover:text-brand-navy font-medium transition-colors"
            >
              Blog
            </Link>
            <Link
              href="/#precos"
              className="text-gray-600 hover:text-brand-navy font-medium transition-colors"
            >
              Preços
            </Link>
          </nav>

          {/* Desktop CTA */}
          <div className="hidden md:flex items-center gap-3">
            <a
              href="#download"
              className="inline-flex items-center justify-center font-semibold rounded-xl transition-colors bg-brand-green text-white hover:bg-emerald-600 text-sm px-4 py-2"
            >
              Baixar app
            </a>
          </div>

          {/* Hamburger button */}
          <button
            className="md:hidden p-2 rounded-lg text-gray-600 hover:bg-gray-100 transition-colors"
            onClick={() => setMenuOpen((v) => !v)}
            aria-label="Abrir menu"
          >
            {menuOpen ? (
              <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            ) : (
              <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
              </svg>
            )}
          </button>
        </div>
      </div>

      {/* Mobile menu */}
      {menuOpen && (
        <div className="md:hidden border-t border-gray-100 bg-white px-4 pb-4">
          <nav className="flex flex-col gap-1 pt-2">
            <Link
              href="/simulador"
              className="py-2 px-3 rounded-lg text-gray-700 hover:bg-gray-50 font-medium"
              onClick={() => setMenuOpen(false)}
            >
              Simulador
            </Link>
            <Link
              href="/blog"
              className="py-2 px-3 rounded-lg text-gray-700 hover:bg-gray-50 font-medium"
              onClick={() => setMenuOpen(false)}
            >
              Blog
            </Link>
            <Link
              href="/#precos"
              className="py-2 px-3 rounded-lg text-gray-700 hover:bg-gray-50 font-medium"
              onClick={() => setMenuOpen(false)}
            >
              Preços
            </Link>
            <a
              href="#download"
              className="mt-2 block text-center bg-brand-green text-white font-semibold py-2.5 px-4 rounded-xl hover:bg-emerald-600 transition-colors"
              onClick={() => setMenuOpen(false)}
            >
              Baixar app
            </a>
          </nav>
        </div>
      )}
    </header>
  );
}
