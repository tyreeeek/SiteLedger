'use client';

import Link from 'next/link';
import { useState } from 'react';
import { 
  Briefcase, 
  Clock, 
  Receipt, 
  Users, 
  DollarSign, 
  TrendingUp,
  CheckCircle,
  ArrowRight,
  Smartphone,
  Monitor,
  Shield,
  Zap,
  BarChart3,
  FileText,
  Menu,
  X,
  Star,
  PlayCircle,
  Download,
  Globe,
  Lock,
  Sparkles,
  Target,
  Layers,
  MessageSquare,
  Trophy
} from 'lucide-react';

export default function LandingPage() {
  const [email, setEmail] = useState('');
  const [menuOpen, setMenuOpen] = useState(false);
  const [activeTab, setActiveTab] = useState('features');

  const handleWaitlist = (e: React.FormEvent) => {
    e.preventDefault();
    alert('Thanks for your interest! We\'ll notify you when pricing details are available.');
    setEmail('');
  };

  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <header className="fixed top-0 w-full bg-white/95 backdrop-blur-sm border-b border-gray-200 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-2">
              <img 
                src="/logo-actual.png" 
                alt="SiteLedger Logo" 
                className="w-10 h-10 object-contain"
              />
              <span className="text-2xl font-bold text-gray-900">SiteLedger</span>
            </div>
            <nav className="hidden md:flex space-x-8">
              <a href="#features" className="text-gray-700 hover:text-blue-600 transition">Features</a>
              <a href="#demo" className="text-gray-700 hover:text-blue-600 transition">Demo</a>
              <a href="#pricing" className="text-gray-700 hover:text-blue-600 transition">Pricing</a>
              <a href="#download" className="text-gray-700 hover:text-blue-600 transition">Download</a>
            </nav>
            <div className="flex items-center gap-4">
              <Link 
                href="/auth/signin"
                className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition shadow-sm"
              >
                Sign In
              </Link>
              <button 
                className="md:hidden"
                onClick={() => setMenuOpen(!menuOpen)}
              >
                {menuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
              </button>
            </div>
          </div>
          {menuOpen && (
            <nav className="md:hidden py-4 space-y-2">
              <a href="#features" className="block text-gray-700 hover:text-blue-600 transition py-2">Features</a>
              <a href="#demo" className="block text-gray-700 hover:text-blue-600 transition py-2">Demo</a>
              <a href="#pricing" className="block text-gray-700 hover:text-blue-600 transition py-2">Pricing</a>
              <a href="#download" className="block text-gray-700 hover:text-blue-600 transition py-2">Download</a>
            </nav>
          )}
        </div>
      </header>

      {/* Hero Section */}
      <section className="relative pt-32 pb-24 px-4 sm:px-6 lg:px-8 overflow-hidden">
        {/* Animated background */}
        <div className="absolute inset-0 bg-gradient-to-br from-blue-600 via-blue-700 to-indigo-900">
          <div className="absolute inset-0 opacity-20">
            <div className="absolute top-0 -left-4 w-72 h-72 bg-purple-500 rounded-full mix-blend-multiply filter blur-xl animate-blob"></div>
            <div className="absolute top-0 -right-4 w-72 h-72 bg-yellow-500 rounded-full mix-blend-multiply filter blur-xl animate-blob animation-delay-2000"></div>
            <div className="absolute -bottom-8 left-20 w-72 h-72 bg-pink-500 rounded-full mix-blend-multiply filter blur-xl animate-blob animation-delay-4000"></div>
          </div>
        </div>
        
        <div className="relative max-w-7xl mx-auto">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            <div className="text-white">
              <div className="inline-flex items-center px-4 py-2 bg-white/20 backdrop-blur-sm border border-white/30 rounded-full text-sm font-medium mb-6">
                <Sparkles className="w-4 h-4 mr-2" />
                Free for 6 Months • No Credit Card Required
              </div>
              <h1 className="text-5xl lg:text-7xl font-bold mb-6 leading-tight">
                Modern Construction
                <span className="block bg-gradient-to-r from-yellow-400 to-orange-500 bg-clip-text text-transparent">Management</span>
              </h1>
              <p className="text-xl text-blue-100 mb-8 leading-relaxed">
                The all-in-one platform that helps contractors track jobs, manage teams, and maximize profits. Join 1,000+ contractors who've transformed their business.
              </p>
              <div className="flex flex-col sm:flex-row gap-4 mb-8">
                <a 
                  href="#download"
                  className="inline-flex items-center justify-center px-8 py-4 bg-white text-blue-600 rounded-xl hover:bg-gray-100 transition shadow-2xl text-lg font-bold"
                >
                  <Download className="mr-2 w-5 h-5" />
                  Download Free
                </a>
                <a 
                  href="#demo"
                  className="inline-flex items-center justify-center px-8 py-4 bg-white/10 backdrop-blur-sm border-2 border-white/30 text-white rounded-xl hover:bg-white/20 transition text-lg font-semibold"
                >
                  <PlayCircle className="mr-2 w-5 h-5" />
                  Watch Demo
                </a>
              </div>
              <div className="flex items-center gap-6 text-sm text-blue-100">
                <div className="flex items-center">
                  <div className="flex -space-x-2 mr-3">
                    <div className="w-8 h-8 rounded-full bg-gradient-to-r from-purple-400 to-pink-400 border-2 border-white"></div>
                    <div className="w-8 h-8 rounded-full bg-gradient-to-r from-yellow-400 to-orange-400 border-2 border-white"></div>
                    <div className="w-8 h-8 rounded-full bg-gradient-to-r from-green-400 to-blue-400 border-2 border-white"></div>
                  </div>
                  <span className="font-semibold">1,000+ contractors</span>
                </div>
                <div className="flex items-center">
                  <Star className="w-5 h-5 text-yellow-400 fill-yellow-400 mr-1" />
                  <Star className="w-5 h-5 text-yellow-400 fill-yellow-400 mr-1" />
                  <Star className="w-5 h-5 text-yellow-400 fill-yellow-400 mr-1" />
                  <Star className="w-5 h-5 text-yellow-400 fill-yellow-400 mr-1" />
                  <Star className="w-5 h-5 text-yellow-400 fill-yellow-400 mr-2" />
                  <span className="font-semibold">4.9/5 rating</span>
                </div>
              </div>
            </div>
            <div className="relative">
              <div className="relative z-10">
                <img 
                  src="https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?w=800&q=80" 
                  alt="Construction management dashboard" 
                  className="rounded-2xl shadow-2xl border-4 border-white/20"
                />
                {/* Floating stats cards */}
                <div className="absolute -top-6 -left-6 bg-white p-4 rounded-xl shadow-2xl border border-gray-200 animate-float">
                  <div className="flex items-center space-x-3">
                    <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
                      <TrendingUp className="w-5 h-5 text-green-600" />
                    </div>
                    <div>
                      <div className="text-2xl font-bold text-gray-900">$127K</div>
                      <div className="text-xs text-gray-600">Monthly Profit</div>
                    </div>
                  </div>
                </div>
                <div className="absolute -bottom-6 -right-6 bg-white p-4 rounded-xl shadow-2xl border border-gray-200 animate-float animation-delay-2000">
                  <div className="flex items-center space-x-3">
                    <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                      <Trophy className="w-5 h-5 text-blue-600" />
                    </div>
                    <div>
                      <div className="text-2xl font-bold text-gray-900">42</div>
                      <div className="text-xs text-gray-600">Active Jobs</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Stats Bar */}
      <section className="py-12 bg-white border-y border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8 text-center">
            <div>
              <div className="text-4xl font-bold text-blue-600 mb-2">1,000+</div>
              <div className="text-gray-600">Active Users</div>
            </div>
            <div>
              <div className="text-4xl font-bold text-blue-600 mb-2">$2M+</div>
              <div className="text-gray-600">Jobs Tracked</div>
            </div>
            <div>
              <div className="text-4xl font-bold text-blue-600 mb-2">50K+</div>
              <div className="text-gray-600">Hours Logged</div>
            </div>
            <div>
              <div className="text-4xl font-bold text-blue-600 mb-2">99.9%</div>
              <div className="text-gray-600">Uptime</div>
            </div>
          </div>
        </div>
      </section>

      {/* Tabbed Features Section */}
      <section id="features" className="py-24 px-4 sm:px-6 lg:px-8 bg-gray-50">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-5xl font-bold text-gray-900 mb-4">Powerful Features for Your Business</h2>
            <p className="text-xl text-gray-600 max-w-3xl mx-auto">
              Everything you need to manage your construction business efficiently and profitably.
            </p>
          </div>

          {/* Feature Tabs */}
          <div className="flex flex-wrap justify-center gap-4 mb-12">
            {[
              { id: 'features', label: 'Core Features', icon: Layers },
              { id: 'management', label: 'Job Management', icon: Briefcase },
              { id: 'tracking', label: 'Time Tracking', icon: Clock },
              { id: 'insights', label: 'AI Insights', icon: Sparkles },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`px-6 py-3 rounded-xl font-semibold transition-all ${
                  activeTab === tab.id
                    ? 'bg-blue-600 text-white shadow-lg scale-105'
                    : 'bg-white text-gray-700 hover:bg-gray-100'
                }`}
              >
                <tab.icon className="w-5 h-5 inline mr-2" />
                {tab.label}
              </button>
            ))}
          </div>

          {/* Tab Content */}
          <div className="bg-white rounded-3xl shadow-2xl p-8 lg:p-12">
            {activeTab === 'features' && (
              <div className="grid md:grid-cols-3 gap-8">
                {[
                  {
                    icon: Briefcase,
                    title: 'Job Management',
                    description: 'Track all your projects with real-time status updates, cost tracking, and profitability analysis.',
                    color: 'bg-blue-500'
                  },
                  {
                    icon: Clock,
                    title: 'Time Tracking',
                    description: 'GPS-verified clock in/out with automatic timesheet generation and payroll calculations.',
                    color: 'bg-green-500'
                  },
                  {
                    icon: Receipt,
                    title: 'Receipt Scanning',
                    description: 'Snap photos of receipts and let OCR automatically extract and categorize expenses.',
                    color: 'bg-purple-500'
                  },
                  {
                    icon: Users,
                    title: 'Team Management',
                    description: 'Manage your crew with role-based permissions, hourly rates, and performance tracking.',
                    color: 'bg-orange-500'
                  },
                  {
                    icon: DollarSign,
                    title: 'Profit Analytics',
                    description: 'Real-time profit calculations per job with detailed cost breakdowns and forecasting.',
                    color: 'bg-emerald-500'
                  },
                  {
                    icon: BarChart3,
                    title: 'AI Insights',
                    description: 'Get intelligent recommendations to optimize profitability and identify cost overruns.',
                    color: 'bg-pink-500'
                  }
                ].map((feature, index) => (
                  <div key={index} className="group p-6 rounded-2xl hover:bg-gray-50 transition-all duration-300 cursor-pointer">
                    <div className={`w-14 h-14 ${feature.color} rounded-xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform shadow-lg`}>
                      <feature.icon className="w-7 h-7 text-white" />
                    </div>
                    <h3 className="text-xl font-bold text-gray-900 mb-3">{feature.title}</h3>
                    <p className="text-gray-600 leading-relaxed">{feature.description}</p>
                  </div>
                ))}
              </div>
            )}

            {activeTab === 'management' && (
              <div className="grid lg:grid-cols-2 gap-12 items-center">
                <div>
                  <h3 className="text-3xl font-bold text-gray-900 mb-6">Complete Job Control</h3>
                  <ul className="space-y-4">
                    {[
                      'Create and assign jobs in seconds',
                      'Track project progress in real-time',
                      'Monitor costs vs. budget automatically',
                      'Generate professional invoices',
                      'Attach photos and documents to jobs',
                      'Set project milestones and deadlines'
                    ].map((item, i) => (
                      <li key={i} className="flex items-start">
                        <CheckCircle className="w-6 h-6 text-green-500 mr-3 flex-shrink-0 mt-0.5" />
                        <span className="text-lg text-gray-700">{item}</span>
                      </li>
                    ))}
                  </ul>
                </div>
                <div>
                  <img 
                    src="https://images.unsplash.com/photo-1541888946425-d81bb19240f5?w=800&q=80"
                    alt="Job management interface"
                    className="rounded-2xl shadow-2xl"
                  />
                </div>
              </div>
            )}

            {activeTab === 'tracking' && (
              <div className="grid lg:grid-cols-2 gap-12 items-center">
                <div className="order-2 lg:order-1">
                  <img 
                    src="https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=800&q=80"
                    alt="Time tracking on mobile"
                    className="rounded-2xl shadow-2xl"
                  />
                </div>
                <div className="order-1 lg:order-2">
                  <h3 className="text-3xl font-bold text-gray-900 mb-6">Accurate Time Tracking</h3>
                  <ul className="space-y-4">
                    {[
                      'One-tap clock in/out from mobile',
                      'GPS location verification',
                      'Automatic break time calculation',
                      'Real-time hours and pay calculations',
                      'Export timesheets for payroll',
                      'Overtime tracking and alerts'
                    ].map((item, i) => (
                      <li key={i} className="flex items-start">
                        <CheckCircle className="w-6 h-6 text-green-500 mr-3 flex-shrink-0 mt-0.5" />
                        <span className="text-lg text-gray-700">{item}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            )}

            {activeTab === 'insights' && (
              <div className="grid lg:grid-cols-2 gap-12 items-center">
                <div>
                  <h3 className="text-3xl font-bold text-gray-900 mb-6">AI-Powered Intelligence</h3>
                  <ul className="space-y-4">
                    {[
                      'Profit optimization recommendations',
                      'Cost overrun early warning system',
                      'Labor efficiency analysis',
                      'Material cost trend predictions',
                      'Project completion forecasting',
                      'Automated financial reporting'
                    ].map((item, i) => (
                      <li key={i} className="flex items-start">
                        <CheckCircle className="w-6 h-6 text-green-500 mr-3 flex-shrink-0 mt-0.5" />
                        <span className="text-lg text-gray-700">{item}</span>
                      </li>
                    ))}
                  </ul>
                </div>
                <div>
                  <img 
                    src="https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800&q=80"
                    alt="AI analytics dashboard"
                    className="rounded-2xl shadow-2xl"
                  />
                </div>
              </div>
            )}
          </div>
        </div>
      </section>

      {/* Testimonials Section */}
      <section className="py-24 px-4 sm:px-6 lg:px-8 bg-gradient-to-br from-blue-900 via-blue-800 to-indigo-900 relative overflow-hidden">
        <div className="absolute inset-0 opacity-10">
          <div className="absolute top-0 left-0 w-96 h-96 bg-white rounded-full mix-blend-overlay filter blur-3xl"></div>
          <div className="absolute bottom-0 right-0 w-96 h-96 bg-purple-500 rounded-full mix-blend-overlay filter blur-3xl"></div>
        </div>
        
        <div className="max-w-7xl mx-auto relative">
          <div className="text-center mb-16">
            <h2 className="text-4xl lg:text-5xl font-bold text-white mb-4">Loved by Contractors</h2>
            <p className="text-xl text-blue-200 max-w-3xl mx-auto">
              Join thousands of contractors who've transformed their business with SiteLedger.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            {[
              {
                quote: "SiteLedger saved me 15 hours a week on paperwork. I can finally focus on growing my business instead of drowning in spreadsheets.",
                author: "Mike Rodriguez",
                role: "General Contractor",
                rating: 5,
                profit: "+$2,500/mo"
              },
              {
                quote: "The AI insights caught a cost overrun before it became a problem. This tool paid for itself in the first month... and it's free!",
                author: "Sarah Chen",
                role: "Electrical Contractor",
                rating: 5,
                profit: "+$1,800/mo"
              },
              {
                quote: "My workers love the mobile app. Clock in/out is so simple, and I always know exactly where my crew is working.",
                author: "James Wilson",
                role: "Roofing Contractor",
                rating: 5,
                profit: "+$3,200/mo"
              }
            ].map((testimonial, index) => (
              <div key={index} className="bg-white/10 backdrop-blur-lg border border-white/20 rounded-2xl p-8 hover:bg-white/15 transition-all duration-300">
                <div className="flex mb-4">
                  {[...Array(testimonial.rating)].map((_, i) => (
                    <Star key={i} className="w-5 h-5 text-yellow-400 fill-yellow-400" />
                  ))}
                </div>
                <p className="text-white text-lg mb-6 leading-relaxed">"{testimonial.quote}"</p>
                <div className="flex items-center justify-between pt-6 border-t border-white/20">
                  <div>
                    <div className="font-bold text-white">{testimonial.author}</div>
                    <div className="text-sm text-blue-200">{testimonial.role}</div>
                  </div>
                  <div className="text-right">
                    <div className="font-bold text-green-400">{testimonial.profit}</div>
                    <div className="text-xs text-blue-200">Avg. Savings</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Demo Section */}
      <section id="demo" className="py-24 px-4 sm:px-6 lg:px-8 bg-white">
        <div className="max-w-7xl mx-auto">
          <div className="grid lg:grid-cols-2 gap-16 items-center">
            <div>
              <h2 className="text-4xl lg:text-5xl font-bold text-gray-900 mb-6">
                See SiteLedger in Action
              </h2>
              <p className="text-xl text-gray-600 mb-8 leading-relaxed">
                Watch how contractors are transforming their business with SiteLedger. From job creation to profit tracking, see everything in action.
              </p>
              <ul className="space-y-4 mb-8">
                {[
                  { icon: Smartphone, text: 'Simple enough to use on a job site' },
                  { icon: Shield, text: 'Powerful enough to run your business' },
                  { icon: Globe, text: 'Works offline - sync when connected' },
                  { icon: Zap, text: 'No learning curve - start in minutes' }
                ].map((item, index) => (
                  <li key={index} className="flex items-center">
                    <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center mr-4">
                      <item.icon className="w-5 h-5 text-blue-600" />
                    </div>
                    <span className="text-lg text-gray-700">{item.text}</span>
                  </li>
                ))}
              </ul>
            </div>
            <div>
              <div className="relative group cursor-pointer">
                <div className="absolute inset-0 bg-gradient-to-r from-blue-600 to-purple-600 rounded-3xl blur-2xl opacity-20 group-hover:opacity-30 transition-opacity"></div>
                <div className="relative aspect-video bg-gradient-to-br from-blue-100 to-purple-100 rounded-3xl shadow-2xl flex items-center justify-center overflow-hidden">
                  <img 
                    src="https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?w=800&q=80" 
                    alt="Demo preview"
                    className="w-full h-full object-cover"
                  />
                  <div className="absolute inset-0 bg-blue-900/40 backdrop-blur-sm flex items-center justify-center">
                    <div className="text-center">
                      <div className="w-24 h-24 bg-white rounded-full flex items-center justify-center mx-auto mb-4 shadow-2xl group-hover:scale-110 transition-transform">
                        <PlayCircle className="w-12 h-12 text-blue-600" />
                      </div>
                      <p className="text-white font-bold text-xl">Watch Demo Video</p>
                      <p className="text-blue-200 text-sm mt-2">2 minutes</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* App Screenshots */}
          <div className="mt-24">
            <h3 className="text-3xl font-bold text-gray-900 text-center mb-12">Powerful Features, Beautiful Design</h3>
            <div className="grid md:grid-cols-3 gap-8">
              {[
                {
                  image: 'https://images.unsplash.com/photo-1581094794329-c8112a89af12?w=600&q=80',
                  title: 'Live Dashboard',
                  description: 'Real-time updates on every job with profit tracking'
                },
                {
                  image: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=600&q=80',
                  title: 'Advanced Analytics',
                  description: 'Comprehensive insights and trend analysis'
                },
                {
                  image: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=600&q=80',
                  title: 'Professional Reports',
                  description: 'Export-ready reports for clients and accounting'
                }
              ].map((screenshot, index) => (
                <div key={index} className="group">
                  <div className="relative overflow-hidden rounded-2xl shadow-lg group-hover:shadow-2xl transition-all duration-300">
                    <div className="aspect-[4/3] bg-gray-200">
                      <img 
                        src={screenshot.image} 
                        alt={screenshot.title} 
                        className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" 
                      />
                    </div>
                    <div className="absolute inset-0 bg-gradient-to-t from-gray-900 via-gray-900/50 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex items-end p-6">
                      <div>
                        <h4 className="text-xl font-bold text-white mb-2">{screenshot.title}</h4>
                        <p className="text-gray-200 text-sm">{screenshot.description}</p>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Pricing Section */}
      <section id="pricing" className="py-24 px-4 sm:px-6 lg:px-8 bg-gray-50 relative overflow-hidden">
        <div className="absolute inset-0 opacity-5">
          <div className="absolute top-20 left-20 w-80 h-80 bg-blue-500 rounded-full filter blur-3xl"></div>
          <div className="absolute bottom-20 right-20 w-80 h-80 bg-purple-500 rounded-full filter blur-3xl"></div>
        </div>
        
        <div className="max-w-7xl mx-auto relative">
          <div className="text-center mb-16">
            <div className="inline-flex items-center px-6 py-3 bg-gradient-to-r from-yellow-400 to-orange-500 text-white rounded-full text-lg font-bold mb-6 shadow-lg">
              <Sparkles className="w-5 h-5 mr-2" />
              Launch Special: Free until July 2026
            </div>
            <h2 className="text-4xl lg:text-5xl font-bold text-gray-900 mb-4">Free for 6 Months</h2>
            <p className="text-xl text-gray-600 max-w-3xl mx-auto">
              Start tracking your jobs today. No credit card required. No hidden fees.
            </p>
          </div>

          <div className="max-w-4xl mx-auto">
            <div className="bg-white rounded-3xl shadow-2xl border-2 border-blue-200 overflow-hidden">
              <div className="bg-gradient-to-br from-blue-600 to-blue-800 p-12 text-white text-center">
                <h3 className="text-3xl font-bold mb-4">Early Access Plan</h3>
                <div className="flex items-end justify-center mb-4">
                  <span className="text-7xl font-bold">$0</span>
                  <span className="text-2xl mb-3 ml-2">/month</span>
                </div>
                <p className="text-blue-100 text-lg">For the first 6 months. Then just $29/month.</p>
              </div>
              
              <div className="p-12">
                <div className="grid md:grid-cols-2 gap-6 mb-8">
                  {[
                    { icon: CheckCircle, text: 'Unlimited jobs and workers' },
                    { icon: CheckCircle, text: 'iOS and web access' },
                    { icon: CheckCircle, text: 'Receipt scanning with OCR' },
                    { icon: CheckCircle, text: 'Geofence time tracking' },
                    { icon: CheckCircle, text: 'Real-time profit calculations' },
                    { icon: CheckCircle, text: 'AI-powered insights' },
                    { icon: CheckCircle, text: 'Payroll management' },
                    { icon: CheckCircle, text: 'Priority email support' }
                  ].map((feature, index) => (
                    <div key={index} className="flex items-center">
                      <feature.icon className="w-6 h-6 text-green-500 mr-3 flex-shrink-0" />
                      <span className="text-gray-700 text-lg">{feature.text}</span>
                    </div>
                  ))}
                </div>

                <div className="mb-8">
                  <label htmlFor="pricing-email" className="block text-gray-700 font-semibold mb-3 text-lg">
                    Get early access now:
                  </label>
                  <div className="flex gap-3">
                    <input
                      id="pricing-email"
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="your@email.com"
                      className="flex-1 px-6 py-4 border-2 border-gray-300 rounded-xl focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition text-lg"
                    />
                    <button
                      onClick={handleWaitlist}
                      className="px-8 py-4 bg-gradient-to-r from-blue-600 to-blue-700 text-white rounded-xl hover:from-blue-700 hover:to-blue-800 transition shadow-lg font-bold text-lg whitespace-nowrap"
                    >
                      Join Waitlist
                    </button>
                  </div>
                  <p className="text-sm text-gray-500 mt-3">We'll notify you when your account is ready. No spam, ever.</p>
                </div>

                <div className="flex items-center justify-center gap-8 pt-8 border-t border-gray-200 text-sm text-gray-600">
                  <div className="flex items-center">
                    <Shield className="w-5 h-5 mr-2 text-green-500" />
                    <span>Bank-level security</span>
                  </div>
                  <div className="flex items-center">
                    <Lock className="w-5 h-5 mr-2 text-green-500" />
                    <span>Your data is private</span>
                  </div>
                  <div className="flex items-center">
                    <Zap className="w-5 h-5 mr-2 text-green-500" />
                    <span>Cancel anytime</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Download Section */}
      <section id="download" className="py-24 px-4 sm:px-6 lg:px-8 bg-gradient-to-br from-blue-600 via-blue-700 to-indigo-900 text-white relative overflow-hidden">
        <div className="absolute inset-0 opacity-10">
          <div className="absolute top-20 right-20 w-96 h-96 bg-purple-500 rounded-full mix-blend-overlay filter blur-3xl animate-pulse"></div>
          <div className="absolute bottom-20 left-20 w-96 h-96 bg-pink-500 rounded-full mix-blend-overlay filter blur-3xl animate-pulse animation-delay-2000"></div>
        </div>
        
        <div className="max-w-7xl mx-auto relative">
          <div className="grid lg:grid-cols-2 gap-16 items-center">
            <div>
              <h2 className="text-4xl lg:text-5xl font-bold mb-6">
                Get Started Today
              </h2>
              <p className="text-xl text-blue-100 mb-8 leading-relaxed">
                Download SiteLedger now and start transforming your construction business. Available on iOS and web.
              </p>
              
              <div className="space-y-6 mb-8">
                <a 
                  href="https://apps.apple.com/us/app/siteledger/id123456789"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="group flex items-center p-6 bg-white/10 backdrop-blur-lg border-2 border-white/20 rounded-2xl hover:bg-white/20 hover:border-white/40 transition-all duration-300"
                >
                  <div className="w-14 h-14 bg-white rounded-xl flex items-center justify-center mr-5 group-hover:scale-110 transition-transform">
                    <Smartphone className="w-8 h-8 text-blue-600" />
                  </div>
                  <div className="flex-1">
                    <div className="text-sm text-blue-200 mb-1">Download on the</div>
                    <div className="text-2xl font-bold">App Store</div>
                  </div>
                  <Download className="w-6 h-6 text-blue-200 group-hover:translate-x-2 transition-transform" />
                </a>

                <a 
                  href="/auth/signin"
                  className="group flex items-center p-6 bg-white/10 backdrop-blur-lg border-2 border-white/20 rounded-2xl hover:bg-white/20 hover:border-white/40 transition-all duration-300"
                >
                  <div className="w-14 h-14 bg-white rounded-xl flex items-center justify-center mr-5 group-hover:scale-110 transition-transform">
                    <Monitor className="w-8 h-8 text-blue-600" />
                  </div>
                  <div className="flex-1">
                    <div className="text-sm text-blue-200 mb-1">Access from</div>
                    <div className="text-2xl font-bold">Web Browser</div>
                  </div>
                  <ArrowRight className="w-6 h-6 text-blue-200 group-hover:translate-x-2 transition-transform" />
                </a>
              </div>

              <div className="flex items-center gap-6 text-sm text-blue-100">
                <div className="flex items-center">
                  <Shield className="w-5 h-5 mr-2" />
                  <span>Secure & Private</span>
                </div>
                <div className="flex items-center">
                  <Zap className="w-5 h-5 mr-2" />
                  <span>Real-time Sync</span>
                </div>
                <div className="flex items-center">
                  <Lock className="w-5 h-5 mr-2" />
                  <span>Bank-Level Security</span>
                </div>
              </div>
            </div>

            <div className="relative">
              <div className="relative z-10">
                <img 
                  src="https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=800&q=80" 
                  alt="Worker using SiteLedger on phone" 
                  className="rounded-3xl shadow-2xl border-4 border-white/20"
                />
                <div className="absolute -top-6 -right-6 bg-white p-6 rounded-2xl shadow-2xl">
                  <div className="flex items-center space-x-3">
                    <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                      <Star className="w-6 h-6 text-blue-600 fill-blue-600" />
                    </div>
                    <div>
                      <div className="text-2xl font-bold text-gray-900">4.9/5</div>
                      <div className="text-xs text-gray-600">App Rating</div>
                    </div>
                  </div>
                </div>
                <div className="absolute -bottom-6 -left-6 bg-white p-6 rounded-2xl shadow-2xl">
                  <div className="flex items-center space-x-3">
                    <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                      <Users className="w-6 h-6 text-green-600" />
                    </div>
                    <div>
                      <div className="text-2xl font-bold text-gray-900">1,000+</div>
                      <div className="text-xs text-gray-600">Happy Users</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 px-4 sm:px-6 lg:px-8 bg-gray-900 text-gray-400">
        <div className="max-w-7xl mx-auto">
          <div className="grid md:grid-cols-4 gap-8 mb-8">
            <div>
              <div className="flex items-center space-x-2 mb-4">
                <img 
                  src="/logo-actual.png" 
                  alt="SiteLedger Logo" 
                  className="w-8 h-8 object-contain"
                />
                <span className="text-xl font-bold text-white">SiteLedger</span>
              </div>
              <p className="text-sm">The modern way to manage your construction business.</p>
            </div>
            <div>
              <h4 className="font-semibold text-white mb-4">Product</h4>
              <ul className="space-y-2 text-sm">
                <li><a href="#features" className="hover:text-white transition">Features</a></li>
                <li><a href="#demo" className="hover:text-white transition">Demo</a></li>
                <li><a href="#pricing" className="hover:text-white transition">Pricing</a></li>
                <li><a href="#download" className="hover:text-white transition">Download</a></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold text-white mb-4">Support</h4>
              <ul className="space-y-2 text-sm">
                <li><a href="mailto:support@siteledger.ai" className="hover:text-white transition">Contact Us</a></li>
                <li><Link href="/auth/signin" className="hover:text-white transition">Sign In</Link></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold text-white mb-4">Legal</h4>
              <ul className="space-y-2 text-sm">
                <li><a href="#" className="hover:text-white transition">Privacy Policy</a></li>
                <li><a href="#" className="hover:text-white transition">Terms of Service</a></li>
              </ul>
            </div>
          </div>
          <div className="border-t border-gray-800 pt-8 text-center text-sm">
            <p>&copy; 2026 SiteLedger. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
