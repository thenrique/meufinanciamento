import { cn } from '@/lib/utils';
import { InputHTMLAttributes, forwardRef } from 'react';

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  hint?: string;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ className, label, error, hint, id, ...props }, ref) => {
    return (
      <div className="flex flex-col gap-1">
        {label && (
          <label htmlFor={id} className="text-sm font-medium text-gray-700">
            {label}
          </label>
        )}
        <input
          ref={ref}
          id={id}
          className={cn(
            'w-full rounded-xl border border-gray-300 px-4 py-3 text-gray-900 placeholder-gray-400 bg-white',
            'focus:outline-none focus:ring-2 focus:ring-brand-green focus:border-transparent',
            'transition-colors',
            error && 'border-red-400 focus:ring-red-400',
            className,
          )}
          {...props}
        />
        {hint && !error && <span className="text-xs text-gray-500">{hint}</span>}
        {error && <span className="text-xs text-red-500">{error}</span>}
      </div>
    );
  },
);

Input.displayName = 'Input';
