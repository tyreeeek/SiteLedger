/** @type {import('next').NextConfig} */
const nextConfig = {
  // Force new build ID to bust cache
  generateBuildId: async () => {
    return 'build-' + Date.now();
  },
  async headers() {
    return [
      {
        // Apply no-cache to ALL pages
        source: '/:path*',
        headers: [
          {
            key: 'Cache-Control',
            value: 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0',
          },
          {
            key: 'Pragma',
            value: 'no-cache',
          },
          {
            key: 'Expires',
            value: '0',
          },
        ],
      },
    ];
  },
};

export default nextConfig;
