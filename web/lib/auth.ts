import axios from 'axios';
import APIService from './api';
import { setUser, clearUser } from './sentry';
import { User } from '../types/models';

/**
 * Auth Service - Matches iOS AuthService.swift exactly
 * Handles user authentication and session management
 */
class AuthService {
  private static instance: AuthService;
  private baseURL: string = 'https://api.siteledger.ai/api/auth';
  private currentUser: User | null = null;

  private constructor() {
    this.loadCurrentUser();
  }

  static get shared(): AuthService {
    if (!AuthService.instance) {
      AuthService.instance = new AuthService();
    }
    return AuthService.instance;
  }

  // MARK: - User Session

  getCurrentUser(): User | null {
    return this.currentUser;
  }

  private loadCurrentUser(): void {
    if (typeof window !== 'undefined') {
      const userJSON = localStorage.getItem('current_user');
      if (userJSON) {
        try {
          this.currentUser = JSON.parse(userJSON);
        } catch (error) {
          this.currentUser = null;
        }
      } else {
        this.currentUser = null;
      }
    }
  }

  saveCurrentUser(user: User): void {
    this.currentUser = user;
    if (typeof window !== 'undefined') {
      localStorage.setItem('current_user', JSON.stringify(user));
      // Set Sentry user context for error tracking
      if (user.id) {
        setUser({
          id: user.id,
          email: user.email,
          username: user.name,
          role: user.role,
        });
      }
    }
  }

  private clearCurrentUser(): void {
    this.currentUser = null;
    if (typeof window !== 'undefined') {
      localStorage.removeItem('current_user');
      // Clear Sentry user context
      clearUser();
    }
  }

  // MARK: - Authentication Methods

  async signIn(email: string, password: string): Promise<User> {
    try {
      const response = await axios.post<{ accessToken: string; user: User }>(
        `${this.baseURL}/login`,
        { email, password }
      );

      const { accessToken, user } = response.data;

      // Save token to API service
      APIService.setAccessToken(accessToken);

      // Save current user
      this.saveCurrentUser(user);

      return user;
    } catch (error: any) {
      throw new Error(error.response?.data?.error || error.response?.data?.message || 'Sign in failed');
    }
  }

  async signUp(
    name: string,
    email: string,
    password: string,
    role: string,
    companyInfo?: {
      companyName?: string;
      addressStreet?: string;
      addressCity?: string;
      addressState?: string;
      addressZip?: string;
    }
  ): Promise<{ user: User; accessToken: string }> {
    try {
      const response = await axios.post<{ accessToken: string; user: User }>(
        `${this.baseURL}/signup`,
        { 
          name, 
          email, 
          password, 
          role,
          ...(companyInfo || {})
        }
      );

      const { accessToken, user } = response.data;

      // Save token to API service
      APIService.setAccessToken(accessToken);

      // Save current user
      this.saveCurrentUser(user);

      return { user, accessToken };
    } catch (error: any) {
      throw new Error(error.response?.data?.message || 'Sign up failed');
    }
  }

  async signOut(): Promise<void> {
    try {
      // Call backend sign out
      await axios.post(`${this.baseURL}/signout`);
    } catch (error) {
      // Silently fail - local cleanup happens regardless
    } finally {
      // Clear local data regardless of API response
      APIService.clearToken();
      this.clearCurrentUser();

      // Redirect to sign in page
      if (typeof window !== 'undefined') {
        window.location.href = '/auth/signin';
      }
    }
  }

  async resetPassword(email: string): Promise<void> {
    try {
      await axios.post(`${this.baseURL}/reset-password`, { email });
    } catch (error: any) {
      throw new Error(error.response?.data?.message || 'Password reset failed');
    }
  }

  // MARK: - User Profile

  async updateProfile(updates: Partial<User>): Promise<User> {
    try {
      const response = await APIService.request<User>(
        'PUT',
        '/auth/profile',
        updates
      );

      // Update stored user
      if (this.currentUser) {
        this.currentUser = { ...this.currentUser, ...response };
        this.saveCurrentUser(this.currentUser);
      }

      return response;
    } catch (error: any) {
      throw new Error(error.response?.data?.message || 'Profile update failed');
    }
  }

  async updatePassword(
    currentPassword: string,
    newPassword: string
  ): Promise<void> {
    try {
      await axios.put(`${this.baseURL}/password`, {
        currentPassword,
        newPassword,
      });
    } catch (error: any) {
      throw new Error(error.response?.data?.message || 'Password update failed');
    }
  }

  // MARK: - Session Check

  async checkSession(): Promise<boolean> {
    try {
      const response = await axios.get<{ user: User }>(
        `${this.baseURL}/me`,
        {
          headers: {
            Authorization: `Bearer ${localStorage.getItem('accessToken')}`,
          },
        }
      );

      this.saveCurrentUser(response.data.user);
      return true;
    } catch (error) {
      this.clearCurrentUser();
      APIService.clearToken();
      return false;
    }
  }

  isAuthenticated(): boolean {
    // Always reload from storage to get latest state
    this.loadCurrentUser();
    const hasToken = typeof window !== 'undefined' && localStorage.getItem('accessToken') !== null;
    const hasUser = this.currentUser !== null;

    return hasToken && hasUser;
  }
}

export default AuthService.shared;
