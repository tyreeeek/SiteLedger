'use client';

import { createContext, useContext, useEffect, useState } from 'react';
import AuthService from '@/lib/auth';

type Theme = 'light' | 'dark' | 'system';

interface ThemeContextType {
  theme: Theme;
  setTheme: (theme: Theme) => void;
  resolvedTheme: 'light' | 'dark';
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setThemeState] = useState<Theme>('light');
  const [resolvedTheme, setResolvedTheme] = useState<'light' | 'dark'>('light');
  const [mounted, setMounted] = useState(false);

  // Apply theme before first render to prevent flash
  if (typeof window !== 'undefined' && !mounted) {
    const savedTheme = localStorage.getItem('userTheme') as Theme | null;
    if (savedTheme) {
      const actualTheme = savedTheme === 'system' 
        ? (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
        : savedTheme;
      
      if (actualTheme === 'dark') {
        document.documentElement.classList.add('dark');
      }
    }
  }

  // Apply theme immediately on mount (before API call)
  useEffect(() => {
    setMounted(true);
    
    // Apply saved theme immediately from localStorage
    const savedTheme = localStorage.getItem('userTheme') as Theme | null;
    if (savedTheme) {
      applyTheme(savedTheme);
      setThemeState(savedTheme);
    }
    
    const loadTheme = async () => {
      if (!AuthService.isAuthenticated()) {
        return;
      }

      try {
        const token = localStorage.getItem('accessToken');
        const response = await fetch('https://api.siteledger.ai/api/preferences/theme', {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        });
        
        if (response.ok) {
          const data = await response.json();
          const savedTheme = data.theme || 'light';
          localStorage.setItem('userTheme', savedTheme);
          setThemeState(savedTheme);
          applyTheme(savedTheme);
        }
      } catch (error) {
        // Silently fail - use default theme
      }
    };

    loadTheme();
  }, []);

  // Apply theme whenever it changes
  const applyTheme = (newTheme: Theme) => {
    let actualTheme: 'light' | 'dark' = 'light';

    if (newTheme === 'system') {
      // Check system preference
      actualTheme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    } else {
      actualTheme = newTheme;
    }

    setResolvedTheme(actualTheme);

    // Apply dark class to html element
    if (actualTheme === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  };

  // Listen for system theme changes when theme is 'system'
  useEffect(() => {
    if (theme !== 'system') return;

    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    const handleChange = () => {
      applyTheme('system');
    };

    mediaQuery.addEventListener('change', handleChange);
    return () => mediaQuery.removeEventListener('change', handleChange);
  }, [theme]);

  const updateTheme = (newTheme: Theme) => {
    setThemeState(newTheme);
    localStorage.setItem('userTheme', newTheme);
    applyTheme(newTheme);
  };

  return (
    <ThemeContext.Provider value={{ theme, setTheme: updateTheme, resolvedTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const context = useContext(ThemeContext);
  if (context === undefined) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context;
}
