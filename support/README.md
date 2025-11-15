# HemoAI Support Page

Modern, responsive support page for HemoAI application with 9-language support.

## 🌐 Features

- ✅ **9 Language Support**: TR, EN, ES, FR, DE, AR, IT, PT, RU
- ✅ **Dark Mode**: Toggle between light and dark themes
- ✅ **Responsive Design**: Works on mobile, tablet, and desktop
- ✅ **RTL Support**: Full right-to-left support for Arabic
- ✅ **Form Validation**: Client-side validation with error messages
- ✅ **Spam Protection**: Honeypot field to prevent spam
- ✅ **Accessibility**: WCAG compliant, semantic HTML
- ✅ **SEO Optimized**: Meta tags and Open Graph support

## 🚀 Deployment

### Option 1: GitHub Pages (Recommended)

1. Create a new repository on GitHub:
   - Repository name: `hemoai-support`
   - Description: `HemoAI Support Page`
   - Public: ✅ (required for GitHub Pages)

2. Upload `index.html` to the repository

3. Enable GitHub Pages:
   - Go to Repository → Settings → Pages
   - Source: Deploy from a branch
   - Branch: `main` (or `master`)
   - Folder: `/ (root)`
   - Click Save

4. Your site will be available at:
   ```
   https://meloshemo.github.io/hemoai-support/
   ```

### Option 2: Custom Domain

If you want to use `support.hemoai.app`:

1. Follow GitHub Pages steps above
2. Add a `CNAME` file to the repository:
   ```
   support.hemoai.app
   ```
3. Configure DNS:
   - Add CNAME record: `support` → `meloshemo.github.io`

## 📝 Formspree Setup

1. **Create Formspree Account:**
   - Visit: https://formspree.io/accounts/signup
   - Sign up for free account

2. **Create New Form:**
   - Click "New Form"
   - Form name: `HemoAI Support`
   - Email: `support@hemoai.org`
   - Get your Form ID (e.g., `xxxxxxxxxxxx`)

3. **Update HTML:**
   - Open `index.html`
   - Find line: `action="https://formspree.io/f/YOUR_FORM_ID"`
   - Replace `YOUR_FORM_ID` with your actual Form ID
   - Save the file

4. **Test:**
   - Submit a test form
   - Check your email at `support@hemoai.org`

**Formspree Free Plan Limits:**
- 50 submissions per month
- Spam protection included
- Email notifications

**Alternative Services:**
- **EmailJS** (https://www.emailjs.com) - 200 emails/month free
- **Getform** (https://getform.io) - 50 submissions/month free
- **Netlify Forms** (if using Netlify hosting)

## 🔧 Customization

### Change Support Email

In `index.html`, find and replace:
```html
action="https://formspree.io/f/YOUR_FORM_ID"
```
And update the email link:
```html
href="mailto:support@hemoai.org"
```

### Add More FAQ Items

In the FAQ section, add new items:
```html
<div class="faq-item">
    <div class="faq-question" id="faq5Q">Your Question</div>
    <div class="faq-answer" id="faq5A">Your Answer</div>
</div>
```

Then add translations in the `translations` object in JavaScript.

### Change Colors

Update CSS variables in the `<style>` section:
```css
:root {
    --primary-color: #E53E3E;
    --primary-dark: #C53030;
    /* ... */
}
```

## 📧 Email Format

Formspree will send emails in this format:

**Subject:** `HemoAI Support Request`

**Body:**
```
Name: [User Name]
Email: [User Email]
Subject: [Selected Subject]
Message: [User Message]
Version: [App Version]
Device: [Device Type]
```

## 🔒 Privacy & Security

- **No tracking**: No analytics or tracking scripts
- **Spam protection**: Honeypot field prevents automated spam
- **HTTPS**: GitHub Pages serves over HTTPS
- **No cookies**: Only localStorage for theme/language preference

## 📱 Mobile Optimization

- Touch-friendly buttons
- Responsive form inputs
- Optimized for small screens
- Fast loading (< 100KB total)

## 🌍 Multi-Language Support

The page automatically detects and saves user language preference. All text is translated in 9 languages including:
- RTL (Right-to-Left) support for Arabic
- Proper text direction handling
- Cultural adaptations

## 🎨 Design Features

- **Material Design 3** inspired
- **Gradient headers** for visual appeal
- **Smooth animations** and transitions
- **Accessible colors** (WCAG AA compliant)
- **Modern typography** (system fonts for performance)

## 📞 Support

If you need help with this support page:
   - Email: support@hemoai.org
- Check Formspree documentation: https://help.formspree.io

## 📄 License

This support page is part of the HemoAI application.

---

**Last Updated:** 2025  
**Version:** 1.0

