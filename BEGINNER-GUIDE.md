# 🎯 Oracle Foundry - Complete Beginner's Guide
## Deploy Your Own Free App Platform in 3 Clicks (No Technical Knowledge Required!)

---

## 🌟 What You'll Get

In about 15 minutes, you'll have your own **personal Heroku/Vercel** that:

✅ **Deploys ANY website or app** from GitHub with one click  
✅ **Costs $0 per month** (forever!)  
✅ **More powerful** than most $20-50/month services  
✅ **No coding required** to set up  
✅ **Includes a super-fast CORS proxy** (if you need one)  

**Real-world comparison:**
- Your free Oracle server: 4 CPU cores, 24GB RAM
- Heroku free tier (discontinued): 512MB RAM
- Render free tier: 512MB RAM, sleeps after 15 minutes
- **Your setup is 48x more powerful!**

---

## 📋 What You Need Before Starting

1. **An email address** (Gmail, Outlook, anything works)
2. **A phone number** (for verification)
3. **A credit/debit card** (Oracle won't charge you - it's just $1 for identity verification)
4. **15 minutes of your time**

**⚠️ IMPORTANT: Oracle will ask for a credit card but will NEVER charge you, just $1 for authorization. This has been free since 2019 and Oracle has committed to keeping it free forever.**

---

## 🚀 Part 1: Create Your Oracle Cloud Account (5 minutes)

### Step 1: Go to Oracle Cloud Free Tier

Open your web browser and go to:
**https://www.oracle.com/cloud/free/**

Click the big **"Start for free"** button.

---

### Step 2: Fill Out the Sign-Up Form

You'll see a form asking for:

**Your Information:**
- **Country**: Select your country
- **First Name** and **Last Name**: Your real name
- **Email**: Use an email you can access (they'll send a verification)

Click **"Verify my email"**

---

### Step 3: Check Your Email

1. Go to your email inbox
2. Look for an email from Oracle (check spam folder too!)
3. Click the **"Verify email"** link inside

---

### Step 4: Complete Your Profile

After clicking the verification link, you'll create a password:

- **Password**: Make it strong (mix of letters, numbers, symbols)
- **Confirm Password**: Type it again

- **Company/Idividual*: Select Individual for simpler verification
- **Cloud Account Name**: This will be part of your login. Choose something you'll remember (like "myfoundry" or your first name)
- **Home Server**: Choose US East for greater availability

Click **"Continue"**

---

### Step 5: Enter Payment Info (Don't Worry - It's Still Free!)

Now comes the part that confuses people:

**Oracle asks for a credit card, but here's why you won't be charged:**

1. Oracle separates resources into "Always Free" and "Paid"
2. We're ONLY using Always Free resources
3. Oracle cannot charge you unless you manually upgrade
4. Millions of people have used this for years without being charged

**Fill in your payment information:**
- Card number
- Expiration date
- CVV (3-digit code on back)
- Billing address

**Oracle will make a $1 temporary authorization to verify the card is real. This charge will disappear in 2-5 days.**

Click **"Finish"**

---

### Step 6: Wait for Account Approval

You'll see a message like:
> "Your account is being provisioned. This may take up to 10 minutes."

**This is normal!** Oracle is setting up your cloud account. 

When it's ready, you'll see the Oracle Cloud homepage with a dashboard.

---

## 🎯 Part 2: Deploy Your Foundry (Literally 3 Clicks!)

### Step 1: Click the Magic Deploy Button

Click this button:

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/shapefuture/oracle-foundry/archive/refs/heads/main.zip)

**What this does:** Opens Oracle Cloud and automatically loads all the setup instructions for your Foundry.

---

### Step 2: Configure Your Foundry (2 minutes)

You'll see a page titled **"Create Stack"**. Don't panic! You only need to fill in TWO things:

#### 2a. Select Compartment
- Click the **"Compartment"** dropdown
- Select **(root)** (it's at the top of the list)

#### 2b. Add Your SSH Key

**"What's an SSH key?"** - It's like a super-secure password that lets you access your server in emergencies. You probably won't ever need it, but Oracle requires it.

**Three options to get an SSH key:**

**OPTION A: Don't Have an SSH Key Yet? (Most Common)**

1. Click the **"Generate SSH Key Pair"** button below the text box
2. Oracle will create one for you automatically
3. Click **"Save Private Key"** - save this file somewhere safe (like your Documents folder)
4. Click **"Save Public Key"** - save this too
5. The public key will auto-fill into the text box ✓

**OPTION B: Already Have an SSH Key?**

1. Click **"Choose SSH Key Files"**
2. Select your `.pub` file (the PUBLIC key, not the private one!)

**OPTION C: Using Mac/Linux Terminal? (Advanced)**

1. Open Terminal
2. Run: `cat ~/.ssh/id_rsa.pub` (or `id_ed25519.pub`)
3. Copy the output
4. Paste into the text box

---

#### 2c. Leave Everything Else as Default

Don't touch the other settings. They're already set to:
- **4 CPU cores** (maximum free)
- **24GB RAM** (maximum free)
- **100GB disk** (recommended)

These are perfect!

Click **"Next"** at the bottom.

---

### Step 3: Review and Deploy

You'll see a summary page. Just check:
- ✓ Region is selected
- ✓ Compartment shows "(root)"
- ✓ SSH key is filled in

**Check the box** that says:
□ Run apply (this makes it deploy immediately)

Click **"Create"**

---

### Step 4: Wait for the Magic to Happen (8-10 minutes)

You'll see a page with a yellow box that says "Accepted" and then "In Progress".

**What's happening behind the scenes:**
1. Oracle is creating a virtual server for you
2. Installing Ubuntu Linux
3. Installing Dokploy (your app platform)
4. Installing FastCORS (your CORS proxy)
5. Setting up automatic security
6. Configuring firewall rules
7. Enabling auto-updates

**Go grab a coffee! ☕** This takes about 8-10 minutes.

When it turns GREEN and says **"Succeeded"**, you're ready!

---

### Step 5: Get Your Server's Address

After it succeeds:

1. Look for the **"Outputs"** section (left sidebar or scroll down)
2. You'll see something like:

```
foundry_public_ip: 123.456.789.012
dokploy_dashboard: http://123.456.789.012:3000
fastcors_proxy: http://123.456.789.012:8080
```

**Copy these URLs!** These are your:
- **Dokploy Dashboard**: Where you'll deploy apps
- **FastCORS Proxy**: Your CORS proxy address

---

## 🎨 Part 3: Access Your Dokploy Dashboard (Your New App Platform!)

### Step 1: Open Dokploy

Click the **dokploy_dashboard** link from the outputs above (or paste it into your browser).

**Example:** `http://123.456.789.012:3000`

**⚠️ If you see "This site can't be reached":**
- Wait 2-3 more minutes (the server might still be finishing setup)
- Try refreshing the page

---

### Step 2: Create Your Admin Account

When Dokploy loads, you'll see a welcome screen:

**Create your admin account:**
- **Email**: Your email address
- **Password**: Choose a strong password
- **Confirm Password**: Type it again

Click **"Create Account"**

**🎉 Congratulations! You now own a personal PaaS platform!**

---

## 🚢 Part 4: Deploy Your First App (3 Clicks!)

Let's deploy a real app from GitHub to prove this works.

### Example: Deploy a Node.js API

**Step 1: Create a Project**

1. In Dokploy, click **"Create Project"**
2. Give it a name: **"My First App"**
3. Click **"Create"**

---

**Step 2: Add a Service**

1. Click **"Create Service"**
2. Select **"GitHub"** (or **"Docker Image"** if you prefer)

---

**Step 3: Configure GitHub Source**

1. Click **"Connect GitHub"** (first time only)
2. Authorize Dokploy to access your GitHub
3. Select a repository (or paste any public GitHub repo URL)

**Don't have a repo to test? Use this:**
```
https://github.com/vercel/next.js/tree/canary/examples/hello-world
```

---

**Step 4: Deploy!**

1. Click **"Deploy"**
2. Watch the build logs (you'll see Dokploy automatically detecting the language and building)

After 30-60 seconds, you'll see:
✅ **"Deployment successful"**

---

**Step 5: Open Your App**

1. In Dokploy, go to your service
2. Click the **"Open"** button or copy the URL
3. Your app is LIVE on the internet!

**You just deployed a real app!** 🎉

---

## 💡 Common Questions

### Q: "What can I deploy with this?"

**Anything!** Seriously:
- Node.js APIs (Express, Nest.js, Next.js)
- Python apps (Flask, Django, FastAPI)
- Static websites (HTML/CSS/JS)
- React, Vue, Svelte apps
- Go applications
- PHP websites
- Ruby apps
- And more!

Dokploy automatically detects the language and builds it.

---

### Q: "Do I need to know Docker?"

**No!** Dokploy handles everything. You just:
1. Paste GitHub URL
2. Click Deploy
3. Done!

---

### Q: "How do I add a custom domain?"

1. Buy a domain (Namecheap, Cloudflare, Google Domains, etc.)
2. Point the domain's A record to your server IP
3. In Dokploy: Service → Domains → Add Domain
4. Enable SSL (Dokploy does this automatically with Let's Encrypt)

---

### Q: "What's the CORS proxy for?"

If you're building a website that needs to make requests to other APIs, sometimes browsers block those requests. The CORS proxy fixes that.

**Your CORS proxy is at:** `http://YOUR_IP:8080`

**How to use it:**
```javascript
// Instead of:
fetch('https://some-api.com/data')

// Use:
fetch('http://YOUR_IP:8080/https://some-api.com/data')
```

It handles 60,000+ requests per second, so it's production-ready!

---

### Q: "Will Oracle ever charge me?"

**No**, as long as you only use the Always Free resources (which is all we're using). Oracle has kept these free since 2019 and has committed to keeping them free forever.

**Your setup uses:**
- ✓ 4 ARM CPU cores (free)
- ✓ 24GB RAM (free)
- ✓ 100GB disk (free, up to 200GB)
- ✓ 10TB bandwidth per month (free)

---

### Q: "What if I mess something up?"

**You can always start over!**

1. In Oracle Cloud Console: Compute → Instances
2. Select your instance
3. Click "Terminate"
4. Click the Deploy button again

You'll get a fresh setup in 10 minutes.

---

### Q: "Can I deploy multiple apps?"

**Yes!** Each app you deploy in Dokploy gets its own URL. You can run 20-30 small apps on your 24GB server.

---

### Q: "How do I update my apps?"

**Automatic!** If you:
1. Push new code to GitHub
2. Dokploy can auto-deploy on every push (enable webhooks in settings)

Or manually: Click **"Redeploy"** in Dokploy.

---

## 🔒 Security Tips

### Change Your Password
After first login to Dokploy, go to Settings → Security and change your admin password to something strong.

### Keep Your SSH Key Safe
The SSH private key you saved is like a master key to your server. Keep it in a secure location (password manager is best).

### Enable 2FA (Optional)
For extra security, you can enable two-factor authentication in Dokploy settings.

---

## 🆘 Troubleshooting

### "I can't access the Dokploy dashboard"

**Solution 1: Wait Longer**
The setup takes 8-10 minutes. If it's been less than that, wait a bit more.

**Solution 2: Check Oracle Firewall**
Sometimes Oracle's firewall needs manual adjustment:

1. Go to: Oracle Console → Networking → Virtual Cloud Networks
2. Click your VCN (probably called "foundry-vcn")
3. Click "Security Lists"
4. Click "Default Security List"
5. Make sure these ports are open:
   - Port 3000 (Dokploy)
   - Port 8080 (FastCORS)
   - Port 80 (HTTP)
   - Port 443 (HTTPS)

If any are missing, click "Add Ingress Rule" and add them.

---

### "Oracle says 'Out of host capacity'"

This happens when too many people are trying to create ARM servers in your region.

**Solutions:**

**Option 1: Try a Different Region**
Go back and click the Deploy button again, but select a different region (like US West, US East, EU Frankfurt, etc.)

**Option 2: Try at Different Times**
ARM capacity is more available during off-peak hours (late night or weekends in US time)

**Option 3: Keep Retrying**
People delete instances all the time. Try every few hours.

---

### "My app build is failing"

1. Check the build logs in Dokploy (they're very detailed)
2. Common issues:
   - **Wrong Node.js version**: Add a file called `.nvmrc` to your repo with the version number
   - **Missing dependencies**: Make sure your `package.json` (Node) or `requirements.txt` (Python) lists everything
   - **Wrong start command**: Check your Procfile or Dokploy service settings

---

### "I need help!"

1. Check the full troubleshooting guide: [FOUNDRY-GUIDE.md](FOUNDRY-GUIDE.md)
2. Ask in Dokploy Discord: https://discord.gg/dokploy
3. Search /r/selfhosted on Reddit
4. Open an issue on our GitHub

---

## 🎓 What's Next?

### Learn More About Dokploy
- Official docs: https://dokploy.com/docs
- Tutorial videos: Search "Dokploy tutorial" on YouTube

### Deploy Popular Apps
Dokploy has one-click templates for:
- WordPress
- Ghost (blogging)
- n8n (automation)
- Plausible (analytics)
- And 50+ more!

Just click "Templates" in Dokploy.

### Add Databases
Need a database? In Dokploy:
1. Click "Create Service"
2. Select "Database"
3. Choose: Postgres, MySQL, Redis, or MongoDB
4. Done!

Dokploy handles all the setup.

---

## 📊 What You Accomplished

Let's recap what you did:

✅ Created a free Oracle Cloud account  
✅ Deployed a production-grade server (4 cores, 24GB RAM)  
✅ Installed Dokploy (a $0 Heroku/Vercel alternative)  
✅ Got a high-performance CORS proxy  
✅ Deployed your first app  

**All without touching a terminal or writing a single line of infrastructure code!**

**Your setup would cost approximately $40-80/month on AWS, Google Cloud, or DigitalOcean. You're getting it for $0.**

---

## 🎉 Welcome to the Self-Hosting Community!

You now have full control over your own app platform. No vendor lock-in, no surprise bills, no arbitrary limits.

**Share your success!** If you found this helpful, share it with others who want to escape expensive cloud platforms.

**Happy deploying!** 🚀

---

## 📚 Additional Resources

- **Complete Guide** (advanced users): [FOUNDRY-GUIDE.md](FOUNDRY-GUIDE.md)
- **Quick Reference** (command cheat sheet): [QUICKREF.md](QUICKREF.md)
- **Dokploy Documentation**: https://dokploy.com/docs
- **Oracle Cloud Docs**: https://docs.oracle.com/cloud

---

**Built with ❤️ for absolute beginners by the self-hosting community**
