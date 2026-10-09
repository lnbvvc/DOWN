#!/bin/bash
​echo "="
echo "   جاري إعداد محطة التحميل والتقسيم... "
echo "="
​1. إصلاح مشاكل الروابط القديمة لديبيان وتحديث النظام
​echo "1. جاري إصلاح الروابط وتحديث القوائم..."
echo "deb http://archive.debian.org/debian/ bullseye main" > /etc/apt/sources.list
echo "deb http://archive.debian.org/debian-security/ bullseye-security main" >> /etc/apt/sources.list
apt-get clean
rm -rf /var/lib/apt/lists/*
apt-get update -o Acquire::Check-Valid-Until=false
​2. تثبيت البرامج الأساسية (SSH، FFmpeg، Python)
​echo "2. جاري تثبيت البرامج الضرورية..."
apt-get install -y ssh ffmpeg python3-pip curl
​3. تثبيت المكتبات اللازمة لتحميل الفيديوهات وبناء الموقع
​echo "3. جاري تثبيت مكتبات بايثون..."
pip3 install Flask yt-dlp
​4. بناء هيكل المجلدات وملف الموقع
​echo "4. جاري إنشاء واجهة المستخدم..."
mkdir -p downloads
​cat << 'EOF' > app.py
import os, subprocess
from flask import Flask, request, render_template_string, send_from_directory, jsonify
​app = Flask(name)
DOWNLOAD_DIR = "downloads"
​HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<title>محطة تحميل وتقسيم الأفلام</title>
<script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-900 font-sans text-gray-100 min-h-screen flex items-center justify-center p-4">
<div class="w-full max-w-2xl bg-gray-800 p-8 rounded-xl shadow-2xl border border-gray-700">
<h1 class="text-3xl font-extrabold mb-6 text-center text-green-400">🚀 محطة التحميل السريعة</h1>
<form id="dlForm" class="space-y-6">
<div>
<label class="block mb-2 text-sm font-medium text-gray-300">رابط الفيلم / الفيديو:</label>
<input type="text" id="url" required placeholder="ضع الرابط هنا..." class="w-full bg-gray-700 border border-gray-600 text-white text-sm rounded-lg focus:ring-green-500 focus:border-green-500 block p-3">
</div>
<div>
<label class="block mb-2 text-sm font-medium text-gray-300">مدة كل جزء (بالدقائق):</label>
<input type="number" id="duration" value="25" min="1" required class="w-full bg-gray-700 border border-gray-600 text-white text-sm rounded-lg focus:ring-green-500 focus:border-green-500 block p-3">
</div>
<button type="submit" class="w-full text-white bg-green-600 hover:bg-green-700 focus:ring-4 focus:ring-green-800 font-medium rounded-lg text-lg px-5 py-3 text-center transition-all">بدء التحميل والتقسيم</button>
</form>
​<div id="status" class="mt-6 text-center hidden">
<div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-white mb-2"></div>
<p class="font-bold text-green-400">جاري التحميل والتقسيم بقوة السيرفر، المرجو الانتظار...</p>
</div>
<div id="results" class="mt-6 space-y-3"></div>
</div>
​<script>
document.getElementById('dlForm').onsubmit = async (e) => {
e.preventDefault();
document.getElementById('status').classList.remove('hidden');
document.getElementById('results').innerHTML = '';
​try {
const res = await fetch('/process', {
method: 'POST',
headers: {'Content-Type': 'application/json'},
body: JSON.stringify({
url: document.getElementById('url').value,
duration: document.getElementById('duration').value
})
});
const data = await res.json();
document.getElementById('status').classList.add('hidden');
​if (data.error) {
alert(data.error);
return;
}
​data.files.forEach((file, index) => {
document.getElementById('results').innerHTML +=  <a href="/download/${file}" class="flex items-center justify-between w-full bg-blue-600 text-white p-4 rounded-lg hover:bg-blue-700 transition-colors shadow-lg"> <span class="font-bold">الجزء ${index + 1}</span> <span class="bg-blue-800 px-3 py-1 rounded-md text-sm">📥 تحميل</span> </a>;
});
} catch (err) {
document.getElementById('status').classList.add('hidden');
alert("حدث خطأ في الاتصال");
}
};
</script>
</body>
</html>
"""
​@app.route('/')
def index():
return render_template_string(HTML_TEMPLATE)
​@app.route('/process', methods=['POST'])
def process():
data = request.json
url = data.get('url')
duration = int(data.get('duration', 25)) * 60 # تحويل الدقائق لثواني
​os.system(f"rm -rf {DOWNLOAD_DIR}/*") # تنظيف الملفات القديمة
​# تحميل الفيديو بأعلى جودة بصيغة mp4
subprocess.run(f"yt-dlp -o '{DOWNLOAD_DIR}/video.%(ext)s' -S 'ext:mp4:m4a' {url}", shell=True)
​files = os.listdir(DOWNLOAD_DIR)
if not files:
return jsonify({"error": "فشل التحميل، تأكد من الرابط"}), 400
​orig_path = os.path.join(DOWNLOAD_DIR, files[0])
​# تقسيم الفيديو بسرعة فائقة بدون إعادة إنتاج
split_cmd = f"ffmpeg -i '{orig_path}' -c copy -map 0 -segment_time {duration} -f segment -reset_timestamps 1 '{DOWNLOAD_DIR}/part_%03d.mp4'"
subprocess.run(split_cmd, shell=True)
​os.remove(orig_path) # مسح الفيديو الأصلي لتوفير المساحة
final_files = sorted(os.listdir(DOWNLOAD_DIR))
​return jsonify({"files": final_files})
​@app.route('/download/<filename>')
def download(filename):
return send_from_directory(DOWNLOAD_DIR, filename, as_attachment=True)
​if name == 'main':
app.run(host='0.0.0.0', port=80)
EOF
​5. تشغيل الموقع في الخلفية وإنشاء النفق الآمن
​echo "5. جاري تشغيل الموقع وإنشاء النفق الآمن..."
python3 app.py &
sleep 3
​echo -e "\n\n==========================================="
echo "تم إعداد كل شيء بنجاح! 🎉"
echo "الآن، لفتح الموقع، انسخ الرابط الذي سيظهر في السطور القادمة (ينتهي بـ localhost.run) والصقه في متصفحك:"
echo "===========================================\n\n"
​ssh -o StrictHostKeyChecking=no -R 80:localhost:80 localhost.run
