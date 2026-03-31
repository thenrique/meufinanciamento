import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import { blogPosts, getPostBySlug } from '@/lib/blog-posts';

interface Props {
  params: { slug: string };
}

export function generateStaticParams() {
  return blogPosts.map((post) => ({ slug: post.slug }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const post = getPostBySlug(params.slug);
  if (!post) return {};
  return {
    title: post.title,
    description: post.description,
    openGraph: {
      title: post.title,
      description: post.description,
      type: 'article',
      publishedTime: post.publishedAt,
    },
  };
}

export default function BlogPostPage({ params }: Props) {
  const post = getPostBySlug(params.slug);
  if (!post) notFound();

  return (
    <div className="section-padding bg-surface min-h-screen">
      <div className="section-container max-w-2xl">
        {/* Breadcrumb */}
        <nav className="text-sm text-gray-500 mb-8 flex items-center gap-2">
          <Link href="/" className="hover:text-brand-navy transition-colors">
            Início
          </Link>
          <span>›</span>
          <Link href="/blog" className="hover:text-brand-navy transition-colors">
            Blog
          </Link>
          <span>›</span>
          <span className="text-gray-700 line-clamp-1">{post.title}</span>
        </nav>

        {/* Article header */}
        <header className="mb-8">
          <div className="flex items-center gap-3 mb-4">
            <span className="text-xs font-medium text-brand-green bg-brand-green-light px-3 py-1 rounded-full">
              {post.readTimeMinutes} min de leitura
            </span>
            <time dateTime={post.publishedAt} className="text-sm text-gray-500">
              {new Date(post.publishedAt).toLocaleDateString('pt-BR', {
                day: '2-digit',
                month: 'long',
                year: 'numeric',
              })}
            </time>
          </div>
          <h1 className="text-3xl sm:text-4xl font-bold text-brand-navy leading-tight mb-4">
            {post.title}
          </h1>
          <p className="text-gray-600 text-lg leading-relaxed">{post.description}</p>
        </header>

        <hr className="border-gray-200 mb-8" />

        {/* Article content */}
        <article
          className="prose prose-lg max-w-none
            prose-headings:font-bold prose-headings:text-brand-navy prose-headings:tracking-tight
            prose-h2:text-2xl prose-h2:mt-8 prose-h2:mb-4
            prose-p:text-gray-700 prose-p:leading-relaxed
            prose-ul:text-gray-700 prose-ol:text-gray-700
            prose-li:my-1
            prose-strong:text-gray-900
            prose-a:text-brand-green prose-a:no-underline hover:prose-a:underline"
          dangerouslySetInnerHTML={{ __html: post.content }}
        />

        <hr className="border-gray-200 my-10" />

        {/* CTA block */}
        <div className="bg-brand-navy rounded-2xl p-8 text-center text-white">
          <h3 className="text-2xl font-bold mb-2">Simule o seu financiamento agora</h3>
          <p className="text-blue-200 mb-6">
            Coloque os números do seu contrato e veja em segundos quanto você pode economizar.
          </p>
          <div className="flex flex-col sm:flex-row gap-3 justify-center">
            <Link
              href="/simulador"
              className="inline-flex items-center justify-center gap-2 bg-brand-green text-white font-semibold px-6 py-3 rounded-xl hover:bg-emerald-600 transition-colors"
            >
              🧮 Simular gratuitamente
            </Link>
            <a
              href="#download"
              className="inline-flex items-center justify-center gap-2 bg-white/10 text-white font-semibold px-6 py-3 rounded-xl hover:bg-white/20 transition-colors border border-white/20"
            >
              📱 Baixar o app
            </a>
          </div>
        </div>

        {/* Back link */}
        <div className="mt-8 text-center">
          <Link
            href="/blog"
            className="text-brand-green hover:underline font-medium text-sm"
          >
            ← Voltar para o Blog
          </Link>
        </div>
      </div>
    </div>
  );
}
