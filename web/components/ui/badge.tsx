import { cn } from '@/lib/utils';
import { HTMLAttributes } from 'react';

interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  variant?: 'green' | 'navy' | 'gray';
}

export function Badge({ className, variant = 'green', children, ...props }: BadgeProps) {
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-sm font-medium',
        {
          'bg-brand-green-light text-emerald-800': variant === 'green',
          'bg-brand-navy-light text-brand-navy': variant === 'navy',
          'bg-gray-100 text-gray-700': variant === 'gray',
        },
        className,
      )}
      {...props}
    >
      {children}
    </span>
  );
}
