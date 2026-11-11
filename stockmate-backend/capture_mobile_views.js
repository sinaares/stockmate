const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');

const ARTIFACT_DIR = 'C:\\Users\\ares\\.gemini\\antigravity-ide\\brain\\15b99de7-9d01-4cc6-ae6a-1ac2104fc880';
const CHROME_PATH = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';

async function loginApi(email, password) {
  const res = await fetch('http://127.0.0.1:3000/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  return await res.json();
}

async function main() {
  const bossData = await loginApi('boss@stockmate.local', 'boss123');
  const empData = await loginApi('ahmet@stockmate.local', 'emp123');

  const browser = await puppeteer.launch({
    executablePath: CHROME_PATH,
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  const page = await browser.newPage();
  await page.setViewport({
    width: 390,
    height: 844,
    deviceScaleFactor: 2,
    isMobile: true,
    hasTouch: true,
  });

  // 1. Boss Dashboard
  await page.goto('http://localhost:8080/#/boss/dashboard');
  await page.evaluate((tok, usr) => {
    localStorage.setItem('flutter.auth_token', JSON.stringify(tok));
    localStorage.setItem('flutter.user_data', JSON.stringify(JSON.stringify(usr)));
    localStorage.setItem('flutter.server_url', JSON.stringify('http://localhost:3000'));
  }, bossData.token, bossData.user);
  await page.goto('http://localhost:8080/#/boss/dashboard', { waitUntil: 'networkidle2' });
  await new Promise(r => setTimeout(r, 4500));
  await page.screenshot({ path: path.join(ARTIFACT_DIR, 'mobile_dashboard.png') });
  console.log('Saved mobile_dashboard.png');

  // 2. Boss Products Screen
  await page.goto('http://localhost:8080/#/boss/products', { waitUntil: 'networkidle2' });
  await new Promise(r => setTimeout(r, 4000));
  await page.screenshot({ path: path.join(ARTIFACT_DIR, 'mobile_products.png') });
  console.log('Saved mobile_products.png');

  // 3. Boss Technical Service Screen
  await page.goto('http://localhost:8080/#/boss/technical-service', { waitUntil: 'networkidle2' });
  await new Promise(r => setTimeout(r, 4000));
  await page.screenshot({ path: path.join(ARTIFACT_DIR, 'mobile_service.png') });
  console.log('Saved mobile_service.png');

  // 4. Employee Home Screen (Ahmet)
  await page.evaluate((tok, usr) => {
    localStorage.setItem('flutter.auth_token', JSON.stringify(tok));
    localStorage.setItem('flutter.user_data', JSON.stringify(JSON.stringify(usr)));
  }, empData.token, empData.user);
  await page.goto('http://localhost:8080/#/employee/home', { waitUntil: 'networkidle2' });
  await new Promise(r => setTimeout(r, 4500));
  await page.screenshot({ path: path.join(ARTIFACT_DIR, 'mobile_employee_home.png') });
  console.log('Saved mobile_employee_home.png');

  await browser.close();
  console.log('All mobile screenshots generated successfully!');
}

main().catch(err => {
  console.error('Error running capture:', err);
  process.exit(1);
});
