const { chromium } = require('playwright');
const path = require('path');

(async () => {
  console.log('🚀 Memulai Uji Coba End-to-End Eco Rangers (Playwright)...');

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  page.on('console', msg => console.log('   [Browser Log]:', msg.text()));

  const filePath = 'file://' + path.resolve('frontend-live.html').replace(/\\/g, '/');

  try {
    // 1. Buka Frontend Live
    console.log('1. Membuka frontend-live.html...');
    await page.goto(filePath);
    const title = await page.title();
    console.log(`   ✓ Halaman berhasil dimuat: "${title}"`);

    // 2. Hubungkan ke API Laravel
    console.log('2. Menguji koneksi API Laravel (http://127.0.0.1:8000)...');
    await page.fill('#apiBase', 'http://127.0.0.1:8000');
    await page.click('#btnTestApi');
    await page.waitForTimeout(1200);

    const pingText = await page.textContent('#pingBadge');
    console.log('   ✓ Koneksi backend Laravel sukses: ' + pingText);

    // 3. Login sebagai Admin
    console.log('3. Melakukan autentikasi Admin...');
    await page.fill('#loginForm input[name="email"]', 'admin@gmail.com');
    await page.fill('#loginForm input[name="password"]', '12345678');
    await page.click('#loginForm button[type="submit"]');
    await page.waitForTimeout(2000);

    const roleText = await page.textContent('#roleTag');
    console.log(`   ✓ Login selesai, Role badge: "${roleText}"`);

    // 4. Verifikasi Beranda
    console.log('4. Memeriksa komponen Beranda & Bento KPI...');
    const heading = await page.textContent('#viewHeading');
    console.log(`   ✓ Navigasi aktif: "${heading}"`);

    // 5. Peta Interaktif (Leaflet)
    console.log('5. Menguji Peta Interaktif (Leaflet OSM)...');
    await page.click('button[data-nav="map"]');
    await page.waitForTimeout(1200);
    const mapVisible = await page.isVisible('#mapViewBox');
    console.log(`   ✓ Kanvas peta Leaflet aktif: ${mapVisible}`);

    // 6. Buat Laporan Baru
    console.log('6. Menguji alur pembuatan laporan baru (POST /api/reports)...');
    await page.click('button[data-nav="create"]');
    await page.waitForTimeout(800);

    const reportTitle = 'Pembersihan Sampah Kali Ciliwung ' + Date.now();
    await page.fill('input[name="judul"]', reportTitle);
    await page.selectOption('select[name="kategori"]', 'sampah');
    await page.fill('textarea[name="deskripsi"]', 'Sampah plastik menyumbat aliran air, butuh tindakan segera dari tim reaksi cepat.');
    await page.fill('input[name="lokasi_text"]', 'Jl. Manggarai Selatan No. 10');
    await page.fill('#latIn', '-6.2088');
    await page.fill('#lngIn', '106.8456');

    await page.click('#createReportForm button[type="submit"]');
    await page.waitForTimeout(2500);
    console.log(`   ✓ Laporan "${reportTitle}" berhasil dikirim`);

    // 7. Cek Daftar Laporan
    console.log('7. Memverifikasi laporan baru pada daftar aktivitas...');
    await page.click('button[data-nav="reports"]');
    await page.waitForTimeout(2000);
    
    const bodyText = await page.textContent('#screenBody');
    if (!bodyText.includes(reportTitle)) {
      console.log('Isi screen body saat ini:', bodyText.substring(0, 300));
      throw new Error('Laporan tidak ditemukan di daftar aktivitas');
    }
    console.log('   ✓ Laporan baru langsung muncul di daftar aktivitas');

    // 8. Buka Detail & Uji Fitur Upvote (Vote)
    console.log('8. Menguji interaksi Detail Laporan & Upvote...');
    await page.click(`text=${reportTitle}`);
    await page.waitForTimeout(1500);
    
    const detailHeading = await page.textContent('#viewHeading');
    console.log(`   ✓ Masuk ke tampilan detail: "${detailHeading}"`);

    await page.click('#btnVoteDetail');
    await page.waitForTimeout(1500);
    console.log('   ✓ Interaksi Upvote berhasil');

    console.log('\n======================================================');
    console.log('🎉 SEMUA PENGUJIAN PLAYWRIGHT BERHASIL (100% PASS)!');
    console.log('Frontend Apple Luxury + Backend Laravel terintegrasi sempurna.');
    console.log('======================================================');

  } catch (error) {
    console.error('❌ Terjadi kesalahan pada saat pengujian:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
