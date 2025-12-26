# SSH Access Setup for DigitalOcean Server

## Problem
Your server only accepts SSH key authentication, but your Mac doesn't have SSH keys configured.

## Solution Options

### Option 1: Generate SSH Keys (RECOMMENDED)

#### Step 1: Generate SSH Key on Your Mac
```bash
# Generate a new ED25519 key (most secure)
ssh-keygen -t ed25519 -C "your_email@example.com"

# When prompted:
# - File location: Press Enter (use default ~/.ssh/id_ed25519)
# - Passphrase: Enter a secure passphrase or leave empty
```

#### Step 2: Copy Public Key to Server
You need to add your public key to the server. **Use DigitalOcean Console:**

1. Go to https://cloud.digitalocean.com
2. Find your droplet → "Console" → "Launch Droplet Console"
3. Run these commands:

```bash
# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Create authorized_keys file if it doesn't exist
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Open editor to add your key
nano ~/.ssh/authorized_keys
```

4. **On your Mac**, copy your public key:
```bash
cat ~/.ssh/id_ed25519.pub
```

5. **In the server console**, paste the key into nano:
   - Paste on a new line
   - Press `Ctrl+X`, then `Y`, then `Enter` to save

#### Step 3: Test SSH Connection
```bash
ssh root@68.183.25.130
```

If successful, you should connect without password!

---

### Option 2: Enable Password Authentication (LESS SECURE)

**Warning:** This is less secure but faster to set up.

#### Using DigitalOcean Console:

1. Go to https://cloud.digitalocean.com
2. Find your droplet → "Console" → "Launch Droplet Console"
3. Edit SSH config:

```bash
# Backup original config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Edit config
nano /etc/ssh/sshd_config
```

4. Find and change these lines:
```
PasswordAuthentication yes
PermitRootLogin yes
```

5. Save and restart SSH:
```bash
# Save with Ctrl+X, Y, Enter
systemctl restart sshd
```

6. Test from your Mac:
```bash
ssh root@68.183.25.130
# Enter your root password
```

---

## Recommended Next Steps

**I strongly recommend Option 1 (SSH keys)** because:
- ✅ More secure
- ✅ No password needed for deployments
- ✅ Industry best practice
- ✅ Protects against brute force attacks

After setting up SSH access, you can deploy with:
```bash
cd /Users/zia/Desktop/SiteLedger
./deploy-all.sh
```

---

## Quick Reference

### Test SSH Connection
```bash
ssh root@68.183.25.130
```

### View Your Public Key
```bash
cat ~/.ssh/id_ed25519.pub
```

### Check Server SSH Status
```bash
ssh root@68.183.25.130 "systemctl status sshd"
```

### Deploy After SSH is Working
```bash
cd /Users/zia/Desktop/SiteLedger
./deploy-backend.sh    # Deploy backend only
./deploy-web.sh        # Deploy web only
./deploy-all.sh        # Deploy both
```
