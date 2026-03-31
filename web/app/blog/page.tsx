import type { Metadata } from 'next';
import Link from 'next/link';
import { blogPosts } from '@/lib/blog-posts';

export const metadata: Metadata = {
  title: 'Blog — Dicas para economizar no financiamento imobiliário',
  description:
    'Artigos práticos sobre amortização, SAC vs. PRICE, uso do FGTS e tudo que você precisa saber para economizar nos juros do seu financiamento.',
};

export default function BlogPage() {
  return (
    <div className="section-padding bg-surface min-h-screen">
      <div className="section-container max-w-4xl">
        <div className="mb-10">
          <h1 className="text-3xl sm:text-4xl font-bold text-brand-navy mb-3">Blog</h1>
          <p className="text-gray-600 text-lg">
            Conteúdo prático para quem quer economizar no financiamento imobiliário.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {blogPosts.map((post) => (
            <Link
              key={post.slug}
              href={`/blog/${post.slug}`}
              className="group bg-white rounded-2xl border border-gray-100 shadow-sm p-6 hover:shadow-md hover:border-brand-green transition-all flex flex-col"
            >
              <div className="flex items-center gap-2 mb-4">
                <span className="text-xs font-medium text-brand-green bg-brand-green-light px-3 py-1 rounded-full">
                  {post.readTimeMinutes} min de leitura
                </span>
              </div>

              <h2 className="text-lg font-bold text-brand-navy group-hover:text-brand-green transition-colors mb-3 flex-1">
                {post.title}
              </h2>

              <p className="text-gray-600 text-sm leading-relaxed mb-4 line-clamp-3">
                {post.description}
              </p>

              <div className="flex items-center justify-between text-xs text-gray-400 mt-auto pt-4 border-t border-gray-50">
                <time dateTime={post.publishedAt}>
                  {new Date(post.publishedAt).toLocaleDateString('pt-BR', {
                    day: '2-digit',
                    month: 'long',
                    year: 'numeric',
                  })}
                </time>
                <span className="text-brand-green font-medium group-hover:underline">
                  Ler →
                </span>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}
