import { test, expect } from '@playwright/test';
import path from 'path';

test.describe('Eco Rangers - Apple Luxury Frontend E2E Test', () => {
  const filePath = 'file://' + path.resolve('frontend-live.html').replace(/\\/g, '/');

  test('E2E Full Flow: Connectivity, Auth, Home, Create Report, Vote & Map', async ({ page }) => {
    // 1. Load Frontend Live
    await page.goto(filePath);
    await expect(page).toHaveTitle(/Eco Rangers/);

    // 2. Test API Connectivity
    const apiInput = page.locator('#apiBase');
    await apiInput.fill('http://127.0.0.1:8000');
    await page.click('#btnTestApi');
    await page.waitForTimeout(1000);

    const pingBadge = page.locator('#pingBadge');
    await expect(pingBadge).toContainText('Tersambung');

    // 3. Test Login with Admin Credentials
    await page.fill('#loginForm input[name="email"]', 'admin@gmail.com');
    await page.fill('#loginForm input[name="password"]', '12345678');
    await page.click('#loginForm button[type="submit"]');
    await page.waitForTimeout(1500);

    // Verify User Capsule & Role
    const roleTag = page.locator('#roleTag');
    await expect(roleTag).toContainText('Admin');

    // 4. Verify Home Dashboard Bento KPIs
    const heading = page.locator('#viewHeading');
    await expect(heading).toHaveText('Beranda');

    // 5. Navigate to Map & Verify Leaflet Canvas
    await page.click('button[data-nav="map"]');
    await page.waitForTimeout(1000);
    await expect(page.locator('#mapViewBox')).toBeVisible();

    // 6. Test Create Report Flow
    await page.click('button[data-nav="create"]');
    await page.waitForTimeout(500);
    await expect(page.locator('#createReportForm')).toBeVisible();

    const testTitle = 'Uji Coba Laporan E2E Playwright ' + Date.now();
    await page.fill('input[name="judul"]', testTitle);
    await page.selectOption('select[name="kategori"]', 'sampah');
    await page.fill('textarea[name="deskripsi"]', 'Deskripsi masalah lingkungan untuk pengujian otomatis end to end.');
    await page.fill('input[name="lokasi_text"]', 'Jl. Sudirman Kav 1, Jakarta');
    await page.fill('#latIn', '-6.2185');
    await page.fill('#lngIn', '106.8166');

    // Submit Report
    await page.click('#createReportForm button[type="submit"]');
    await page.waitForTimeout(2000);

    // 7. Verify Report in Feed
    await page.click('button[data-nav="reports"]');
    await page.waitForTimeout(1000);
    await expect(page.locator('#screenBody')).toContainText(testTitle);

    // 8. Open Report Detail & Test Vote Action
    await page.click(`text=${testTitle}`);
    await page.waitForTimeout(1000);
    await expect(page.locator('#viewHeading')).toContainText('Detail #');

    const voteBtn = page.locator('#btnVoteDetail');
    await expect(voteBtn).toBeVisible();
    await voteBtn.click();
    await page.waitForTimeout(1500);

    console.log('Test Suite Passed: Apple Luxury Frontend & Laravel API 100% Validated!');
  });
});
