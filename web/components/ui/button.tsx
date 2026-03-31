import { cn } from '@/lib/utils';
import { ButtonHTMLAttributes, forwardRef } from 'react';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', children, ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={cn(
          'inline-flex items-center justify-center font-semibold rounded-xl transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-green disabled:opacity-50 disabled:pointer-events-none',
          {
            'bg-brand-green text-white hover:bg-emerald-600': variant === 'primary',
            'bg-brand-navy text-white hover:bg-blue-900': variant === 'secondary',
            'border-2 border-brand-green text-brand-green hover:bg-brand-green-light':
              variant === 'outline',
            'text-brand-navy hover:bg-brand-navy-light': variant === 'ghost',
          },
          {
            'text-sm px-4 py-2': size === 'sm',
            'text-base px-6 py-3': size === 'md',
            'text-lg px-8 py-4': size === 'lg',
          },
          className,
        )}
        {...props}
      >
        {children}
      </button>
    );
  },
);

Button.displayName = 'Button';
