# 🚀 اسکریپت نصب Phantom Tunnel

این اسکریپت Bash به‌صورت خودکار ابزار [Phantom Tunnel](https://github.com/webwizards-team/Phantom-Tunnel) را روی سرور لینوکسی شما نصب می‌کند و موارد زیر را انجام می‌دهد:

- ✅ دریافت آخرین نسخه از GitHub
- ✅ نصب باینری در مسیر سیستم
- ✅ ایجاد سرویس systemd برای اجرا در پس‌زمینه
- ✅ تشخیص خودکار معماری (x86_64 / arm64)
- ✅ باز کردن پورت پنل در فایروال (در صورت فعال بودن)
- ✅ ساخت symlink برای دسترسی آسان‌تر
- ✅ قابلیت ریستارت سریع و حذف کامل سرویس

---

## 📥 نصب

برای نصب کافیست دستور زیر را اجرا کنید:


bash <(curl -Ls https://raw.githubusercontent.com/Mohammad1724/webtunnel/main/install.sh)
