'use client';

import Link from 'next/link';
import { useState } from 'react';

export function Header() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const whatsappNumber = '5511987654321'; // TODO: Atualizar com seu número
  const whatsappUrl = `https://wa.me/${whatsappNumber}`;

  const navLinks = [
    { label: 'Simulador', href: '/simulador' },
    { label: 'Funcionalidades', href: '#features' },
    { label: 'Como Funciona', href: '#como-funciona' },
    { label: 'Suporte', href: '#suporte' },
    { label: 'Contato', href: '#contato' },
  ];

  return (
    <header className="sticky top-0 z-50 bg-white/95 backdrop-blur border-b border-gray-200 shadow-sm">
      <div className="section-container py-4">
        <div className="flex items-center justify-between">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2">
            <span className="text-2xl font-bold text-brand-navy">💰</span>
            <span className="hidden sm:inline text-lg font-bold text-brand-navy">Amortizador Pro</span>
          </Link>

          {/* Desktop Navigation */}
          <nav className="hidden lg:flex items-center gap-1">
            {navLinks.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className="px-4 py-2 text-gray-700 hover:text-brand-navy hover:bg-gray-100 rounded-lg transition-colors"
              >
                {link.label}
              </a>
            ))}
          </nav>

          {/* CTA Buttons */}
          <div className="flex items-center gap-3">
            {/* WhatsApp Button */}
            <a
              href={whatsappUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="hidden sm:inline-flex items-center gap-2 px-4 py-2 bg-green-500 hover:bg-green-600 text-white rounded-lg font-semibold transition-colors"
            >
              <span>💬</span>
              <span className="hidden md:inline">Chat</span>
            </a>

            {/* Download App */}
            <a
              href="#download"
              className="hidden sm:inline-flex px-4 py-2 bg-brand-navy hover:bg-brand-navy-dark text-white rounded-lg font-semibold transition-colors"
            >
              Download
            </a>

            {/* Mobile Menu Button */}
            <button
              className="lg:hidden p-2 hover:bg-gray-100 rounded-lg"
              onClick={() => setIsMenuOpen(!isMenuOpen)}
            >
              <span className="text-2xl">{isMenuOpen ? '✕' : '☰'}</span>
            </button>
          </div>
        </div>

        {/* Mobile Menu */}
        {isMenuOpen && (
          <nav className="lg:hidden mt-4 pb-4 border-t border-gray-200 pt-4 space-y-2">
            {navLinks.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className="block px-4 py-2 text-gray-700 hover:text-brand-navy hover:bg-gray-100 rounded-lg transition-colors"
                onClick={() => setIsMenuOpen(false)}
              >
                {link.label}
              </a>
            ))}
            <div className="flex gap-2 pt-4 border-t border-gray-200">
              <a
                href={whatsappUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="flex-1 px-4 py-2 bg-green-500 hover:bg-green-600 text-white rounded-lg font-semibold transition-colors text-center"
              >
                WhatsApp
              </a>
              <a href="#download" className="flex-1 px-4 py-2 bg-brand-navy hover:bg-brand-navy-dark text-white rounded-lg font-semibold transition-colors text-center">
                Download
              </a>
            </div>
          </nav>
        )}
      </div>
    </header>
  );
}
