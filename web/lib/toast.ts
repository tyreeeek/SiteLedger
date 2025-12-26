import toast from 'react-hot-toast';

/**
 * Toast Utility - Wrapper for react-hot-toast
 * Provides consistent toast notifications throughout the app
 */

// Success toast
export const showSuccess = (message: string) => {
  toast.success(message, {
    duration: 3000,
    position: 'top-right',
    style: {
      background: '#10B981',
      color: '#fff',
      padding: '16px',
      borderRadius: '8px',
    },
    iconTheme: {
      primary: '#fff',
      secondary: '#10B981',
    },
  });
};

// Error toast
export const showError = (message: string) => {
  toast.error(message, {
    duration: 4000,
    position: 'top-right',
    style: {
      background: '#EF4444',
      color: '#fff',
      padding: '16px',
      borderRadius: '8px',
    },
    iconTheme: {
      primary: '#fff',
      secondary: '#EF4444',
    },
  });
};

// Info toast
export const showInfo = (message: string) => {
  toast(message, {
    duration: 3000,
    position: 'top-right',
    icon: 'ℹ️',
    style: {
      background: '#3B82F6',
      color: '#fff',
      padding: '16px',
      borderRadius: '8px',
    },
  });
};

// Loading toast (returns toast ID for dismissal)
export const showLoading = (message: string) => {
  return toast.loading(message, {
    position: 'top-right',
    style: {
      background: '#6B7280',
      color: '#fff',
      padding: '16px',
      borderRadius: '8px',
    },
  });
};

// Dismiss specific toast
export const dismissToast = (toastId: string) => {
  toast.dismiss(toastId);
};

// Promise-based toast (shows loading, then success/error)
export const showPromise = <T,>(
  promise: Promise<T>,
  messages: {
    loading: string;
    success: string;
    error: string;
  }
) => {
  return toast.promise(
    promise,
    {
      loading: messages.loading,
      success: messages.success,
      error: messages.error,
    },
    {
      position: 'top-right',
      style: {
        padding: '16px',
        borderRadius: '8px',
      },
    }
  );
};

// Custom toast - simplified without JSX since this is a .ts file
// For custom toasts, use toast.custom() directly in components
export const showCustom = (message: string) => {
  toast(message, {
    duration: 5000,
    position: 'top-right',
    style: {
      background: '#fff',
      color: '#111',
      padding: '16px',
      borderRadius: '8px',
      border: '1px solid #e5e7eb',
    },
  });
};

export default {
  success: showSuccess,
  error: showError,
  info: showInfo,
  loading: showLoading,
  dismiss: dismissToast,
  promise: showPromise,
  custom: showCustom,
};
