#!/usr/bin/env node
'use strict';
/*
 * study-tree · 管理员重置密码（应急用）
 *
 * 用法：
 *   node reset-password.js <用户名> <新密码>
 *
 * 数据目录默认是脚本旁边的 data/，部署环境用环境变量覆盖：
 *   TT_DATA_DIR=/var/lib/study-tree node reset-password.js zhangsan NewPassw0rd
 *
 * 会同时注销这个账号的所有登录会话，强制重新登录。
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const DATA_DIR = process.env.TT_DATA_DIR
  ? path.resolve(process.env.TT_DATA_DIR)
  : path.join(__dirname, 'data');
const USERS_FILE = path.join(DATA_DIR, 'users.json');
const SESSIONS_FILE = path.join(DATA_DIR, 'sessions.json');

function hashPassword(password, salt) {
  return crypto.scryptSync(password, salt, 64).toString('hex');
}

const name = String(process.argv[2] || '').trim();
const password = String(process.argv[3] || '');

if (!name || !password) {
  console.error('用法: node reset-password.js <用户名> <新密码>');
  process.exit(1);
}
if (password.length < 8) {
  console.error('新密码至少 8 位');
  process.exit(1);
}

let users;
try {
  users = JSON.parse(fs.readFileSync(USERS_FILE, 'utf8'));
} catch (e) {
  console.error('读不到 ' + USERS_FILE);
  console.error('请确认服务已初始化过，或用 TT_DATA_DIR 指向正确的数据目录');
  process.exit(1);
}
if (!Array.isArray(users) || !users.length) {
  console.error('users.json 里没有账号');
  process.exit(1);
}

const target = users.find((u) => String(u.name || '').toLowerCase() === name.toLowerCase());
if (!target) {
  console.error('没有这个用户：' + name);
  console.error('现有账号：' + users.map((u) => u.name).join(', '));
  process.exit(1);
}

const salt = crypto.randomBytes(16).toString('hex');
target.salt = salt;
target.hash = hashPassword(password, salt);
target.passwordChangedAt = Date.now();

const tmp = USERS_FILE + '.tmp';
fs.writeFileSync(tmp, JSON.stringify(users, null, 2));
fs.renameSync(tmp, USERS_FILE);

let killed = 0;
try {
  const sessions = JSON.parse(fs.readFileSync(SESSIONS_FILE, 'utf8'));
  if (sessions && typeof sessions === 'object') {
    Object.keys(sessions).forEach((t) => {
      if (sessions[t] && sessions[t].uid === target.id) {
        delete sessions[t];
        killed++;
      }
    });
    const stmp = SESSIONS_FILE + '.tmp';
    fs.writeFileSync(stmp, JSON.stringify(sessions, null, 2));
    fs.renameSync(stmp, SESSIONS_FILE);
  }
} catch (e) { /* 没有 sessions.json 也无所谓 */ }

console.log('已重置「' + target.name + '」的密码' + (killed ? '，并注销了 ' + killed + ' 个登录会话' : ''));
console.log('现在可以用新密码登录了。');
