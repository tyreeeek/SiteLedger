import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  eslint: {
    ignoreDuringBuilds: true,
  },
  images: {
    domains: ['api.siteledger.ai', 'siteledger.ai'],
  },
};

export default nextConfig;
