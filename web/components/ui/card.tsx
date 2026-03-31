import { cn } from '@/lib/utils';
import { HTMLAttributes } from 'react';

interface CardProps extends HTMLAttributes<HTMLDivElement> {
  variant?: 'default' | 'green' | 'navy';
}

export function Card({ className, variant = 'default', children, ...props }: CardProps) {
  return (
    <div
      className={cn(
        'rounded-2xl p-6 shadow-sm',
        {
          'bg-white border border-gray-100': variant === 'default',
          'bg-brand-green-light border border-emerald-200': variant === 'green',
          'bg-brand-navy-light border border-blue-200': variant === 'navy',
        },
        className,
      )}
      {...props}
    >
      {children}
    </div>
  );
}

export function CardTitle({
  className,
  children,
  ...props
}: HTMLAttributes<HTMLHeadingElement>) {
  return (
    <h3 className={cn('text-lg font-bold text-gray-900', className)} {...props}>
      {children}
    </h3>
  );
}

export function CardDescription({
  className,
  children,
  ...props
}: HTMLAttributes<HTMLParagraphElement>) {
  return (
    <p className={cn('text-sm text-gray-600 mt-1', className)} {...props}>
      {children}
    </p>
  );
}
