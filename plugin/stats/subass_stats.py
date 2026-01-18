#!/usr/bin/env python3
import json
import os
import sys
import glob
import time
import webbrowser
import threading
from datetime import datetime, timedelta
from http.server import HTTPServer, BaseHTTPRequestHandler
from collections import defaultdict

# -----------------------------------------------------------------------------
# CONFIG & CONSTANTS
# -----------------------------------------------------------------------------
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
STATS_DIR = os.path.join(SCRIPT_DIR, "../stats")  # Assuming script is in plugin/stats/
PORT = 8766
MAX_ATTEMPTS = 10

# -----------------------------------------------------------------------------
# HTML TEMPLATE
# -----------------------------------------------------------------------------
HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="uk">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Subass Statistics</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        :root {
            --primary: #4f46e5;
            --primary-dark: #4338ca;
            --bg: #f3f4f6;
            --card-bg: #ffffff;
            --text: #1f2937;
            --text-light: #6b7280;
            --border: #e5e7eb;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: var(--bg); color: var(--text); line-height: 1.5; padding: 20px; }
        
        .container { max-width: 1200px; margin: 0 auto; }
        
        /* Header */
        header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px; }
        h1 { font-size: 24px; font-weight: 700; color: var(--text); }
        .refresh-btn { background: var(--primary); color: white; border: none; padding: 10px 20px; border-radius: 6px; cursor: pointer; font-weight: 600; transition: background 0.2s; }
        .refresh-btn:hover { background: var(--primary-dark); }

        /* Tabs */
        .tabs { display: flex; gap: 10px; margin-bottom: 20px; border-bottom: 1px solid var(--border); padding-bottom: 10px; overflow-x: auto; }
        .tab-btn { background: none; border: none; padding: 8px 16px; font-size: 15px; font-weight: 500; color: var(--text-light); cursor: pointer; border-radius: 6px; transition: all 0.2s; }
        .tab-btn:hover { background: white; color: var(--primary); }
        .tab-btn.active { background: white; color: var(--primary); box-shadow: 0 1px 3px rgba(0,0,0,0.1); }

        /* Content */
        .tab-content { display: none; animation: fadeIn 0.3s ease; }
        .tab-content.active { display: block; }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(5px); } to { opacity: 1; transform: translateY(0); } }

        /* Scorecards */
        .scorecards { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .card { background: var(--card-bg); padding: 20px; border-radius: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.05); border: 1px solid var(--border); }
        .card h3 { font-size: 14px; font-weight: 500; color: var(--text-light); margin-bottom: 5px; text-transform: uppercase; letter-spacing: 0.5px; }
        .card .value { font-size: 28px; font-weight: 700; color: var(--text); }
        .card .sub { font-size: 12px; color: var(--text-light); margin-top: 5px; }

        /* Charts Section */
        .chart-container { background: var(--card-bg); padding: 20px; border-radius: 12px; border: 1px solid var(--border); height: 400px; margin-bottom: 30px; position: relative; }

        /* Data Tables */
        .table-container { background: var(--card-bg); border-radius: 12px; border: 1px solid var(--border); overflow: hidden; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 15px 20px; text-align: left; border-bottom: 1px solid var(--border); }
        th { background: #f9fafb; font-weight: 600; color: var(--text-light); font-size: 13px; text-transform: uppercase; }
        tr:last-child td { border-bottom: none; }
        
        .clickable-row { cursor: pointer; transition: background 0.2s; }
        .clickable-row:hover { background: #f0f4ff !important; }
        
        .actor-badge { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 12px; font-weight: 500; background: #e0e7ff; color: #4338ca; margin-right: 5px; margin-bottom: 5px; }
        .progress-bar { height: 6px; background: #e5e7eb; border-radius: 3px; overflow: hidden; margin-top: 8px; width: 100px; }
        .progress-fill { height: 100%; background: var(--primary); }

        /* Filter Buttons */
        .filter-group { display: flex; gap: 5px; margin-bottom: 10px; align-items: center; }
        .filter-btn { background: #f3f4f6; border: 1px solid var(--border); padding: 6px 12px; font-size: 13px; font-weight: 500; cursor: pointer; border-radius: 6px; color: var(--text-light); transition: all 0.2s; }
        .filter-btn:hover { background: #e5e7eb; }
        .filter-btn.active { background: var(--primary); color: white; border-color: var(--primary); }
        .date-input { border: 1px solid var(--border); padding: 5px 10px; border-radius: 6px; font-size: 13px; color: var(--text); background: white; outline: none; transition: border-color 0.2s; }
        .date-input:focus { border-color: var(--primary); }

        /* Modal */
        .modal-overlay { display: none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 1000; align-items: center; justify-content: center; backdrop-filter: blur(4px); }
        .modal { background: white; border-radius: 16px; width: 90%; max-width: 800px; max-height: 80vh; overflow-y: auto; padding: 30px; position: relative; box-shadow: 0 20px 25px -5px rgba(0,0,0,0.1); }
        .modal-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 20px; }
        .modal-close { background: none; border: none; font-size: 24px; cursor: pointer; color: var(--text-light); }
        .modal-title { font-size: 20px; font-weight: 700; }
        .modal-subtitle { color: var(--text-light); font-size: 14px; margin-top: 4px; }

        /* Heat Map */
        .heatmap-container { background: var(--card-bg); padding: 20px; border-radius: 12px; border: 1px solid var(--border); margin-bottom: 30px; }
        .heatmap-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
        
        .heatmap-wrapper { display: flex; gap: 8px; }
        .heatmap-days-labels { display: grid; grid-template-rows: repeat(7, 1fr); gap: 3px; font-size: 10px; color: var(--text-light); padding-top: 15px; } /* Offset for months */
        .heatmap-days-labels span { height: 10px; line-height: 10px; }

        .heatmap-main { flex: 1; overflow-x: auto; }
        .heatmap-grid { display: flex; justify-content: space-between; align-items: flex-start; }
        
        .month-unit { display: flex; flex-direction: column; gap: 5px; flex-shrink: 0; }
        .month-label { font-size: 10px; color: var(--text-light); height: 12px; }
        .month-weeks { display: flex; gap: 3px; }
        .heatmap-week { display: flex; flex-direction: column; gap: 3px; }
        
        .heatmap-cell { width: 13px; height: 13px; border-radius: 2px; background: #ebedf0; cursor: pointer; border: 1px solid rgba(0,0,0,0.03); }
        .heatmap-cell:hover { border-color: #6b7280; outline: 1px solid #6b7280; }
        
        /* Heatmap levels based on GitHub (using Primary Blue) */
        .lvl-0 { background: #ebedf0; }
        .lvl-1 { background: #9be9a8; }
        .lvl-2 { background: #40c463; }
        .lvl-3 { background: #30a14e; }
        .lvl-4 { background: #216e39; }
        
        /* Tooltip for Heatmap */
        #heatmap-tooltip { 
            position: fixed; 
            background: #24292f; 
            color: white; 
            padding: 8px 12px; 
            border-radius: 6px; 
            font-size: 11px; 
            z-index: 9999; 
            pointer-events: none; 
            white-space: pre-line; 
            box-shadow: 0 4px 12px rgba(0,0,0,0.2); 
            display: none;
            transform: translate(-50%, -100%);
            margin-top: -10px;
        }
        #heatmap-tooltip strong { color: #58a6ff; }

        .load-more-container { display: flex; justify-content: center; margin-top: 15px; }
        .load-more-btn { 
            background: var(--bg); 
            border: 1px solid var(--border); 
            color: var(--text-light); 
            padding: 8px 20px; 
            border-radius: 6px; 
            font-size: 13px; 
            cursor: pointer; 
            transition: all 0.2s; 
        }
        .load-more-btn:hover { background: var(--border); color: var(--text); border-color: var(--primary); }
    </style>
</head>
<body>
    <!-- MODAL -->
    <div id="project-modal" class="modal-overlay" onclick="closeModal(event)">
        <div class="modal" onclick="event.stopPropagation()">
            <div class="modal-header">
                <div>
                    <h2 id="modal-project-name" class="modal-title">Назва проекту</h2>
                    <p id="modal-project-path" class="modal-subtitle">Шлях до файлу</p>
                    <div style="margin-top: 15px;">
                        <label style="cursor: pointer; font-size: 13px; color: var(--text-light); display: flex; align-items: center; gap: 6px;">
                            <input type="checkbox" id="modal-show-hidden" onchange="refreshProjectModal()" style="accent-color: var(--primary);"> 
                            Показати всіх акторів (не тільки вибраних)
                        </label>
                    </div>
                </div>
                <button class="modal-close" onclick="closeProjectModal()">✕</button>
            </div>
            <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>Актор</th>
                            <th>Спроб (дублів)</th>
                            <th>Реплік (всього)</th>
                            <th>Слів (всього)</th>
                        </tr>
                    </thead>
                    <tbody id="modal-table-body">
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <div class="container">
        <header>
            <h1>📊 Subass Statistics</h1>
            <button class="refresh-btn" onclick="loadStats()">🔄 Оновити</button>
        </header>

        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; border-bottom: 1px solid var(--border); flex-wrap: wrap; gap: 15px;">
            <div class="tabs" style="border-bottom: none; margin-bottom: 0;">
                <button class="tab-btn active" id="tab-overview" onclick="switchTab('overview')">Огляд</button>
                <button class="tab-btn" id="tab-projects" onclick="switchTab('projects')">Проекти</button>
                <button class="tab-btn" id="tab-actors" onclick="switchTab('actors')">Актори</button>
            </div>
            <div class="filter-group">
                <button class="filter-btn active" id="filter-all" onclick="setPeriod('all')">Весь час</button>
                <button class="filter-btn" id="filter-today" onclick="setPeriod('today')">Сьогодні</button>
                <button class="filter-btn" id="filter-week" onclick="setPeriod('week')">Тиждень</button>
                <button class="filter-btn" id="filter-month" onclick="setPeriod('month')">Місяць</button>
                <div style="display: flex; align-items: center; gap: 5px; margin-left: 5px;">
                    <input type="date" id="date-from" class="date-input" onchange="setPeriod('custom')">
                    <span style="color: var(--text-light); font-size: 12px;">—</span>
                    <input type="date" id="date-to" class="date-input" onchange="setPeriod('custom')">
                </div>
            </div>
        </div>

        <!-- OVERVIEW TAB -->
        <div id="overview" class="tab-content active">
            <div class="scorecards">
                <div class="card">
                    <h3>Період: Записано</h3>
                    <div class="value" id="period-recorded">0</div>
                    <div class="sub">Унікальних реплік</div>
                </div>
                <div class="card">
                    <h3>Спроб (дублів)</h3>
                    <div class="value" id="period-attempts">0</div>
                    <div class="sub">За вибраний період</div>
                </div>
                <div class="card">
                    <h3>Реплік (Скрипт)</h3>
                    <div class="value" id="total-lines">0</div>
                    <div class="sub">Всього в активних</div>
                </div>
                <div class="card">
                    <h3>Слів (Скрипт)</h3>
                    <div class="value" id="total-words">0</div>
                    <div class="sub">Обсяг для запису</div>
                </div>
            </div>

            <div class="chart-container">
                <canvas id="overviewChart"></canvas>
            </div>

            <div class="heatmap-container">
                <div class="heatmap-header">
                    <h3 style="font-size: 14px; color: var(--text-light); text-transform: uppercase;">🔥 Активність за рік</h3>
                    <select id="heatmap-year-selector" onchange="renderHeatMap()" class="date-input" style="padding: 2px 8px; font-size: 12px;"></select>
                </div>
                <div class="heatmap-wrapper">
                    <div class="heatmap-days-labels">
                        <span></span><span>Пн</span><span></span><span>Ср</span><span></span><span>Пт</span><span></span>
                    </div>
                    <div class="heatmap-main">
                        <div id="heatmap-grid" class="heatmap-grid"></div>
                    </div>
                </div>
                <div id="heatmap-tooltip"></div>
                <div style="display: flex; align-items: center; justify-content: flex-end; gap: 5px; margin-top: 10px; font-size: 11px; color: var(--text-light);">
                    <span>Менше</span>
                    <div class="heatmap-cell lvl-0" title="0 спроб"></div>
                    <div class="heatmap-cell lvl-1" title="1-9 спроб"></div>
                    <div class="heatmap-cell lvl-2" title="10-49 спроб"></div>
                    <div class="heatmap-cell lvl-3" title="50-99 спроб"></div>
                    <div class="heatmap-cell lvl-4" title="100+ спроб"></div>
                    <span>Більше</span>
                </div>
            </div>

            <div style="margin-top: 30px;">
                <h3 style="margin-bottom: 15px;">📜 Останні дні (Спроби запису)</h3>
                <div class="table-container">
                    <table>
                        <thead>
                            <tr>
                                <th>Дата</th>
                                <th>Всього спроб</th>
                                <th>Унікальних реплік</th>
                                <th>Поза регіонами</th>
                            </tr>
                        </thead>
                        <tbody id="trends-table-body">
                            <!-- Filled by JS -->
                        </tbody>
                    </table>
                </div>
                <div class="load-more-container" id="load-more-container" style="display: none;">
                    <button class="load-more-btn" onclick="loadMoreRecentDays()">Завантажити ще</button>
                </div>
            </div>
        </div>

        <!-- PROJECTS TAB -->
        <div id="projects" class="tab-content">
            <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>Проект</th>
                            <th>Реплік (вибр.)</th>
                            <th>Слів (вибр.)</th>
                            <th>Спроб за період</th>
                            <th>Загальний прогрес</th>
                        </tr>
                    </thead>
                    <tbody id="projects-table-body">
                        <!-- Filled by JS -->
                    </tbody>
                </table>
            </div>
        </div>
        
        <!-- ACTORS TAB -->
        <div id="actors" class="tab-content">
             <div style="margin-bottom: 15px; display: flex; justify-content: space-between; align-items: center;">
                <label style="cursor: pointer; font-size: 14px; color: var(--text-light); display: flex; align-items: center; gap: 8px;">
                    <input type="checkbox" id="show-hidden-actors" onchange="renderActorsTable()" style="accent-color: var(--primary);"> 
                    Показати прихованих акторів (не активні)
                </label>
                <div style="font-size: 13px; color: var(--text-light);" id="actor-period-label">Активність за весь час</div>
             </div>
             <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>Актор</th>
                            <th>Спроб (за період)</th>
                            <th>Проект</th>
                            <th>Реплік (всього)</th>
                            <th>Слів (всього)</th>
                            <th>Статус</th>
                        </tr>
                    </thead>
                    <tbody id="actors-table-body">
                        <!-- Filled by JS -->
                    </tbody>
                </table>
            </div>
        </div>

    </div>

    <script>
        // --- LOGIC ---
        let chartInstance = null;
        let globalRawData = null;
        let globalActorsData = [];
        let globalProjectsData = [];
        let globalActorAttempts = {};
        let globalActivityByDate = {}; // { date: { total, projects: { name: count } } }
        let recentDaysLimit = 10;
        let currentProjectIndex = -1;
        let currentPeriod = 'all';

        document.addEventListener('DOMContentLoaded', loadStats);

        function switchTab(tabId) {
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
            
            const btn = document.getElementById(`tab-${tabId}`);
            if (btn) btn.classList.add('active');
            document.getElementById(tabId).classList.add('active');
        }

        async function loadStats() {
            try {
                const response = await fetch('/api/stats');
                const data = await response.json();
                globalRawData = data;
                
                // Pre-calculate full activity map (not filtered by period)
                globalActivityByDate = {};
                if (data.projects) {
                    data.projects.forEach(p => {
                        if (p.history) {
                            Object.entries(p.history).forEach(([date, histData]) => {
                                if (!globalActivityByDate[date]) globalActivityByDate[date] = { total: 0, projects: {} };
                                const lines = typeof histData === 'object' ? (histData.lines || 0) : histData;
                                const linesOutside = typeof histData === 'object' ? (histData.lines_outside || 0) : 0;
                                const count = lines + linesOutside;
                                
                                globalActivityByDate[date].total += count;
                                globalActivityByDate[date].projects[p.name] = (globalActivityByDate[date].projects[p.name] || 0) + count;
                            });
                        }
                    });
                }

                initHeatMapYearSelector();
                renderStats();
            } catch (e) {
                console.error("Failed to load stats:", e);
                alert("Не вдалося завантажити статистику. Перевірте, чи запущено скрипт.");
            }
        }

        function loadMoreRecentDays() {
            recentDaysLimit += 10;
            renderStats();
        }

        function initHeatMapYearSelector() {
            const selector = document.getElementById('heatmap-year-selector');
            const dates = Object.keys(globalActivityByDate).sort();
            const years = new Set(dates.map(d => d.split('-')[0]));
            if (years.size === 0) years.add(new Date().getFullYear().toString());
            
            selector.innerHTML = '';
            Array.from(years).sort().reverse().forEach(y => {
                const opt = document.createElement('option');
                opt.value = y;
                opt.textContent = y;
                selector.appendChild(opt);
            });
            selector.value = Array.from(years).sort().reverse()[0];
        }

        function renderHeatMap() {
            const container = document.getElementById('heatmap-grid');
            const tooltip = document.getElementById('heatmap-tooltip');
            const year = parseInt(document.getElementById('heatmap-year-selector').value);
            
            container.innerHTML = '';
            const startDate = new Date(year, 0, 1);
            const endDate = new Date(year, 11, 31);
            const months = ["Січ", "Лют", "Бер", "Квіт", "Трав", "Черв", "Лип", "Серп", "Вер", "Жовт", "Лист", "Груд"];

            let lastMonth = -1;
            let currentMonthWeeks = null;
            let currentWeek = null;

            const curr = new Date(startDate);
            while (curr <= endDate) {
                const dateStr = curr.toISOString().split('T')[0];
                const dayData = globalActivityByDate[dateStr] || { total: 0, projects: {} };
                const month = curr.getMonth();
                const dayOfWeek = curr.getDay(); // 0 is Sunday

                // New Month
                if (month !== lastMonth) {
                    const monthUnit = document.createElement('div');
                    monthUnit.className = 'month-unit';
                    
                    const label = document.createElement('div');
                    label.className = 'month-label';
                    label.innerText = months[month];
                    monthUnit.appendChild(label);
                    
                    currentMonthWeeks = document.createElement('div');
                    currentMonthWeeks.className = 'month-weeks';
                    monthUnit.appendChild(currentMonthWeeks);
                    
                    container.appendChild(monthUnit);
                    lastMonth = month;
                    currentWeek = null; // Force new week
                }

                // New Week
                if (dayOfWeek === 0 || !currentWeek) {
                    currentWeek = document.createElement('div');
                    currentWeek.className = 'heatmap-week';
                    currentMonthWeeks.appendChild(currentWeek);
                    
                    // Pad if month starts in the middle of a week
                    if (dayOfWeek > 0) {
                        for (let i = 0; i < dayOfWeek; i++) {
                            const pad = document.createElement('div');
                            pad.style.width = '13px';
                            pad.style.height = '13px';
                            pad.style.visibility = 'hidden';
                            currentWeek.appendChild(pad);
                        }
                    }
                }

                const cell = document.createElement('div');
                cell.className = 'heatmap-cell';
                let lvl = 0;
                if (dayData.total > 0) lvl = 1;
                if (dayData.total >= 10) lvl = 2;
                if (dayData.total >= 50) lvl = 3;
                if (dayData.total >= 100) lvl = 4;
                cell.classList.add(`lvl-${lvl}`);

                cell.onmouseenter = (e) => {
                    let text = `<strong>${dateStr}</strong>\\nВсього спроб: ${dayData.total}`;
                    if (dayData.total > 0) {
                        text += `\\n\\nРозбивка по проектах:`;
                        Object.entries(dayData.projects).forEach(([name, count]) => {
                            if (count > 0) text += `\\n${name}: ${count}`;
                        });
                    }
                    tooltip.innerHTML = text.replace(/\\n/g, '<br>');
                    tooltip.style.display = 'block';
                    const rect = cell.getBoundingClientRect();
                    tooltip.style.left = (rect.left + rect.width / 2) + 'px';
                    tooltip.style.top = rect.top + 'px';
                };
                cell.onmouseleave = () => { tooltip.style.display = 'none'; };

                currentWeek.appendChild(cell);
                curr.setDate(curr.getDate() + 1);
            }
        }

        function setPeriod(period) {
            currentPeriod = period;
            document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            if (period !== 'custom') {
                document.getElementById(`filter-${period}`).classList.add('active');
                document.getElementById('date-from').value = '';
                document.getElementById('date-to').value = '';
            }
            renderStats();
        }

        function isWithinPeriod(dateStr) {
            if (currentPeriod === 'all') return true;
            
            const [y, m, d] = dateStr.split('-').map(Number);
            const date = new Date(y, m - 1, d);
            const now = new Date();
            now.setHours(0,0,0,0);
            
            const toLocalISO = (d) => {
                return d.getFullYear() + '-' + 
                       String(d.getMonth() + 1).padStart(2, '0') + '-' + 
                       String(d.getDate()).padStart(2, '0');
            };

            if (currentPeriod === 'today') {
                return dateStr === toLocalISO(new Date());
            }
            if (currentPeriod === 'week') {
                const day = now.getDay() || 7; // Monday is 1
                const startOfWeek = new Date(now);
                startOfWeek.setDate(now.getDate() - day + 1);
                return date >= startOfWeek;
            }
            if (currentPeriod === 'month') {
                const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
                return date >= startOfMonth;
            }
            if (currentPeriod === 'custom') {
                const from = document.getElementById('date-from').value;
                const to = document.getElementById('date-to').value;
                if (!from && !to) return true;
                if (from && dateStr < from) return false;
                if (to && dateStr > to) return false;
                return true;
            }
            return true;
        }
        
        function refreshProjectModal() {
            if (currentProjectIndex !== -1) {
                showProjectDetails(currentProjectIndex);
            }
        }

        function showProjectDetails(index) {
            currentProjectIndex = index;
            const p = globalProjectsData[index];
            if (!p) return;

            document.getElementById('modal-project-name').innerText = p.name;
            document.getElementById('modal-project-path').innerText = p.path;
            
            const showAll = document.getElementById('modal-show-hidden').checked;
            const tbody = document.getElementById('modal-table-body');
            tbody.innerHTML = '';

            const actorsList = Array.from(new Set([
                ...(p.actors ? Object.keys(p.actors) : []),
                ...(p.actor_attempts_total ? Object.keys(p.actor_attempts_total) : [])
            ]))
                .filter(name => name.toLowerCase() !== 'all')
                .map(name => ({
                    name,
                    meta: (p.actors && p.actors[name]) || { lines: 0, words: 0, selected: false },
                    attempts: (p.actor_attempts_total && p.actor_attempts_total[name]) || 0
                }));

            actorsList.sort((a, b) => (b.meta.selected ? 1 : -1) - (a.meta.selected ? 1 : -1) || b.attempts - a.attempts);

            actorsList.forEach(a => {
                if (!showAll && !a.meta.selected) return;
                tbody.innerHTML += `<tr>
                    <td><strong>${a.name}</strong> ${a.meta.selected ? '' : '<span style="color:#9ca3af; font-size:11px;">(Hidden)</span>'}</td>
                    <td>${a.attempts.toLocaleString()}</td>
                    <td>${(a.meta.lines || 0).toLocaleString()}</td>
                    <td>${(a.meta.words || 0).toLocaleString()}</td>
                </tr>`;
            });

            document.getElementById('project-modal').style.display = 'flex';
        }

        function closeProjectModal() { document.getElementById('project-modal').style.display = 'none'; }
        function closeModal(event) { if (event.target === document.getElementById('project-modal')) closeProjectModal(); }

        function renderActorsTable() {
            const showHidden = document.getElementById('show-hidden-actors').checked;
            const actorsTbody = document.getElementById('actors-table-body');
            actorsTbody.innerHTML = '';

            globalActorsData.forEach(a => {
                if (!showHidden && !a.selected) return;
                const attempts = globalActorAttempts[a.name] || 0;
                actorsTbody.innerHTML += `<tr>
                    <td><strong>${a.name}</strong></td>
                    <td>${attempts.toLocaleString()}</td>
                    <td>${a.project}</td>
                    <td>${a.lines.toLocaleString()}</td>
                    <td>${a.words.toLocaleString()}</td>
                    <td>${a.selected ? '<span style="color:#10b981; font-weight:500">● Visible</span>' : '<span style="color:#9ca3af">○ Hidden</span>'}</td>
                </tr>`;
            });

            const labels = { all: 'Весь час', today: 'Сьогодні', week: 'Цей тиждень', month: 'Цей місяць', custom: 'Вибраний період' };
            document.getElementById('actor-period-label').innerText = `Активність: ${labels[currentPeriod] || 'Весь час'}`;
        }

        function renderStats() {
            const data = globalRawData;
            if (!data) return;

            // 1. Calculate Period Totals and Map History
            let periodRecorded = 0;
            let periodAttempts = 0;
            let periodWords = 0;
            const filteredProjects = JSON.parse(JSON.stringify(data.projects));
            const actorAttemptsByPeriod = {};
            const dateMap = {}; // { date: { total: 0, lines: 0, outside: 0, words: 0 } }

            filteredProjects.forEach(p => {
                p.period_attempts = 0;
                p.period_recorded = 0;
                p.period_words = 0;
                p.actor_attempts_period = {};
                p.actor_attempts_total = {}; // All-time attempts per actor for this project

                // First, calculate all-time attempts per actor to handle capping correctly
                if (p.history) {
                    const sortedHistory = Object.entries(p.history).sort((a,b) => b[0].localeCompare(a[0]));
                    sortedHistory.forEach(([date, histData]) => {
                        if (!dateMap[date]) dateMap[date] = { total: 0, lines: 0, outside: 0, words: 0, projects: {} };
                        const lines = typeof histData === 'object' ? (histData.lines || 0) : histData;
                        const linesOutside = typeof histData === 'object' ? (histData.lines_outside || 0) : 0;
                        dateMap[date].lines += lines;
                        dateMap[date].outside += linesOutside;
                        dateMap[date].total += (lines + linesOutside);
                        
                        if (!dateMap[date].projects[p.name]) dateMap[date].projects[p.name] = { total: 0, lines: 0, outside: 0, words: 0 };
                        dateMap[date].projects[p.name].lines += lines;
                        dateMap[date].projects[p.name].outside += linesOutside;
                        dateMap[date].projects[p.name].total += (lines + linesOutside);

                        const isPeriod = isWithinPeriod(date);
                        if (isPeriod) {
                            p.period_attempts += (lines + linesOutside);
                            periodAttempts += (lines + linesOutside);
                        }

                        if (typeof histData === 'object' && histData.actors) {
                            Object.entries(histData.actors).forEach(([actor, aData]) => {
                                const aAttempts = typeof aData === 'object' ? (aData.lines || 0) : aData;
                                p.actor_attempts_total[actor] = (p.actor_attempts_total[actor] || 0) + aAttempts;
                                if (isPeriod) {
                                    p.actor_attempts_period[actor] = (p.actor_attempts_period[actor] || 0) + aAttempts;
                                    actorAttemptsByPeriod[actor] = (actorAttemptsByPeriod[actor] || 0) + aAttempts;
                                }
                            });
                        }
                    });
                }

                // Second, calculate "Recorded" (Progress) based on capping logic per actor
                p.recorded = 0; // Total unique-ish lines recorded across project
                let recordedBefore = 0; // Progress before current period start
                
                if (p.actors) {
                    Object.entries(p.actors).forEach(([actor, meta]) => {
                        const totalAtt = p.actor_attempts_total[actor] || 0;
                        const periodAtt = p.actor_attempts_period[actor] || 0;
                        const beforeAtt = totalAtt - periodAtt;
                        const scriptLines = meta.lines || 0;

                        const cappedTotal = Math.min(totalAtt, scriptLines);
                        const cappedBefore = Math.min(beforeAtt, scriptLines);
                        
                        p.recorded += cappedTotal;
                        p.period_recorded += (cappedTotal - cappedBefore);

                        // Word estimation based on progress
                        if (scriptLines > 0) {
                            const progressGain = (cappedTotal - cappedBefore) / scriptLines;
                            p.period_words += Math.round(progressGain * (meta.words || 0));
                        }
                    });
                }
                periodRecorded += p.period_recorded;
                periodWords += p.period_words;
            });

            globalProjectsData = filteredProjects;
            globalActorAttempts = actorAttemptsByPeriod;

            // 2. Update Scorecards (Calculated from period activity)
            let displayTotalLines = 0;
            let displayTotalWords = 0;
            let activeProjectsCount = 0;
            
            filteredProjects.forEach(p => {
                if (currentPeriod === 'all' || p.period_attempts > 0) {
                    displayTotalLines += (p.selected_lines || 0);
                    displayTotalWords += (p.selected_words || 0);
                    if (p.period_attempts > 0) activeProjectsCount++;
                }
            });

            document.getElementById('period-recorded').innerText = periodRecorded.toLocaleString();
            document.getElementById('period-attempts').innerText = periodAttempts.toLocaleString();
            document.getElementById('total-lines').innerText = displayTotalLines.toLocaleString();
            document.getElementById('total-words').innerText = displayTotalWords.toLocaleString();
            
            // Update "sub" text to show how many projects are counted
            const subLines = document.querySelector('#total-lines + .sub');
            if (subLines) {
                subLines.innerText = currentPeriod === 'all' ? 'Всього в усіх проектах' : `Всього в ${activeProjectsCount} активних проектах`;
            }

            // 3. Render Projects Table
            const projTbody = document.getElementById('projects-table-body');
            projTbody.innerHTML = '';
            filteredProjects.forEach((p, idx) => {
                if (currentPeriod !== 'all' && p.period_attempts === 0) return;
                
                // Find original index in data.projects to keep modal working
                const originalIndex = data.projects.findIndex(origP => origP.project_id === p.project_id);
                
                const progress = (p.recorded / (p.selected_lines || 1)) * 100;
                projTbody.innerHTML += `<tr class="clickable-row" onclick="showProjectDetails(${originalIndex})">
                    <td><strong>${p.name}</strong><br><span style="font-size:12px;color:#888">${p.path.split('/').pop()}</span></td>
                    <td>${p.selected_lines}</td>
                    <td>${p.selected_words}</td>
                    <td><span style="font-weight:600; color:${p.period_attempts > 0 ? 'var(--primary)' : 'inherit'}">${p.period_attempts.toLocaleString()}</span></td>
                    <td>
                        <div style="font-size:12px;margin-bottom:2px">${Math.round(progress)}% (${p.recorded})</div>
                        <div class="progress-bar"><div class="progress-fill" style="width:${progress}%"></div></div>
                    </td>
                </tr>`;
            });

            // 4. Update Actors Table
            globalActorsData = [];
            filteredProjects.forEach(p => {
                if (p.actors) {
                    Object.values(p.actors).forEach(a => {
                        if (a.id === "all") return;
                        globalActorsData.push({ name: a.id, project: p.name, lines: a.lines, words: a.words, selected: a.selected });
                    });
                }
            });
            globalActorsData.sort((a, b) => (globalActorAttempts[b.name] || 0) - (globalActorAttempts[a.name] || 0) || b.lines - a.lines);
            renderActorsTable();

            const sortedDates = Object.keys(dateMap).sort();
            const filteredDates = sortedDates.filter(d => isWithinPeriod(d));
            const plotDates = filteredDates.length > 0 ? filteredDates : sortedDates.slice(-30);

            // 5. Render Overview Chart (Trend by day within period)
            const ctx = document.getElementById('overviewChart').getContext('2d');
            if (chartInstance) chartInstance.destroy();

            chartInstance = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: plotDates,
                    datasets: [
                        {
                            label: 'Слова',
                            data: plotDates.map(d => dateMap[d].words),
                            borderColor: '#3b82f6',
                            backgroundColor: 'rgba(59, 130, 246, 0.05)',
                            fill: true,
                            tension: 0.3,
                            yAxisID: 'y1',
                            key: 'words'
                        },
                        {
                            label: 'Спроби (дублів)',
                            data: plotDates.map(d => dateMap[d].total),
                            borderColor: '#f59e0b',
                            backgroundColor: 'rgba(245, 158, 11, 0.05)',
                            fill: true,
                            tension: 0.3,
                            yAxisID: 'y',
                            key: 'total'
                        },
                        {
                            label: 'Репліки (зовні)',
                            data: plotDates.map(d => dateMap[d].outside),
                            borderColor: '#ef4444',
                            borderDash: [5, 5],
                            tension: 0.3,
                            yAxisID: 'y',
                            key: 'outside'
                        },
                        {
                            label: 'Репліки (проект)',
                            data: plotDates.map(d => dateMap[d].lines),
                            borderColor: '#10b981',
                            backgroundColor: 'rgba(16, 185, 129, 0.05)',
                            fill: true,
                            tension: 0.3,
                            yAxisID: 'y',
                            key: 'lines'
                        }
                    ]
                },
                options: { 
                    responsive: true, 
                    maintainAspectRatio: false, 
                    stacked: false,
                    plugins: {
                        title: { display: true, text: 'Динаміка роботи за період' },
                        legend: { position: 'bottom' },
                        tooltip: {
                            callbacks: {
                                afterBody: function(context) {
                                    const date = context[0].label;
                                    const item = context[0];
                                    const metricKey = item.dataset.key;
                                    const dayInfo = dateMap[date];
                                    if (!dayInfo || !dayInfo.projects) return '';
                                    
                                    const lines = ['\\nРозбивка по проектах:'];
                                    Object.entries(dayInfo.projects).forEach(([name, projStats]) => {
                                        const val = projStats[metricKey] || 0;
                                        if (val > 0) {
                                            lines.push(`${name}: ${val.toLocaleString()}`);
                                        }
                                    });
                                    return lines.length > 1 ? lines.join('\\n') : '';
                                }
                            }
                        }
                    },
                    scales: { 
                        y: { type: 'linear', display: true, position: 'left', beginAtZero: true, title: { display: true, text: 'Репліки / Спроби' } },
                        y1: { type: 'linear', display: true, position: 'right', beginAtZero: true, grid: { drawOnChartArea: false }, title: { display: true, text: 'Слова' } }
                    } 
                }
            });

            // 6. Trends Table (reverses order, filtered)
            const tableDates = [...filteredDates].reverse();
            
            const trendsTbody = document.getElementById('trends-table-body');
            const loadMoreContainer = document.getElementById('load-more-container');
            
            trendsTbody.innerHTML = '';
            tableDates.slice(0, recentDaysLimit).forEach(date => {
                const info = dateMap[date];
                trendsTbody.innerHTML += `<tr>
                    <td><strong>${date}</strong></td>
                    <td>${info.total.toLocaleString()}</td>
                    <td>${info.lines.toLocaleString()}</td>
                    <td>${info.outside.toLocaleString()}</td>
                </tr>`;
            });

            if (tableDates.length > recentDaysLimit) {
                loadMoreContainer.style.display = 'flex';
            } else {
                loadMoreContainer.style.display = 'none';
            }
 
            // 7. Render Heat Map
            renderHeatMap();
        }
    </script>
</body>
</html>
"""

# -----------------------------------------------------------------------------
# LOGIC
# -----------------------------------------------------------------------------
def get_aggregated_stats():
    """Reads all JSON files in STATS_DIR and aggregates them."""
    stats = {
        "projects": [],
        "total_lines_script": 0,
        "total_words": 0,
        "total_selected_lines": 0,
        "total_selected_words": 0,
        "total_recorded": 0,
        "total_actor_attempts": defaultdict(int), # Global attempts per actor
        "period_stats": {
            "today": 0,
            "week": 0,
            "month": 0
        }
    }
    
    if not os.path.exists(STATS_DIR):
        try:
            os.makedirs(STATS_DIR, exist_ok=True)
        except:
            pass
        return stats

    json_files = glob.glob(os.path.join(STATS_DIR, "*.json"))
    
    now = datetime.now()
    today_str = now.strftime("%Y-%m-%d")
    week_start = (now - timedelta(days=now.weekday())).strftime("%Y-%m-%d") # Monday
    month_start = now.strftime("%Y-%m-01")

    for jf in json_files:
        try:
            with open(jf, 'r', encoding='utf-8') as f:
                data = json.load(f)
                meta = data.get("metadata", {})
                
                # Prepare Project Data
                proj = {
                    "name": data.get("project_name", "Unknown"),
                    "path": data.get("project_path", ""),
                    "updated": data.get("last_updated", 0),
                    "lines": meta.get("total_lines_in_script", 0),
                    "words": meta.get("total_words", 0),
                    "selected_lines": meta.get("selected_lines_count", 0),
                    "selected_words": meta.get("selected_words_count", 0),
                    "recorded": data.get("total", {}).get("lines_recorded", 0),
                    "actors": meta.get("actors", {}),
                    "history": data.get("daily_stats", {}),
                    "actor_attempts": defaultdict(int) 
                }
                
                # Period Aggregation (Attempts)
                if proj["history"]:
                    for date, hist_data in proj["history"].items():
                        lines = 0
                        lines_outside = 0
                        
                        if isinstance(hist_data, dict):
                            lines = hist_data.get("lines", 0)
                            lines_outside = hist_data.get("lines_outside", 0)
                            # Aggregate attempts per actor
                            day_actors = hist_data.get("actors", {})
                            for actor_name, actor_data in day_actors.items():
                                if isinstance(actor_data, dict):
                                    att = actor_data.get("lines", 0)
                                    proj["actor_attempts"][actor_name] += att
                                    stats["total_actor_attempts"][actor_name] += att
                        else:
                            lines = hist_data
                            
                        count = lines + lines_outside
                        
                        if date == today_str:
                            stats["period_stats"]["today"] += count
                        if date >= week_start:
                            stats["period_stats"]["week"] += count
                        if date >= month_start:
                            stats["period_stats"]["month"] += count

                # Finalize project data
                proj["actor_attempts"] = dict(proj["actor_attempts"])
                stats["projects"].append(proj)
                stats["total_lines_script"] += proj["lines"]
                stats["total_words"] += proj["words"]
                stats["total_selected_lines"] += proj["selected_lines"]
                stats["total_selected_words"] += proj["selected_words"]
                stats["total_recorded"] += proj["recorded"]
                            
        except Exception as e:
            print(f"Error reading {jf}: {e}")
            continue
            
    # Sort projects by last updated desc
    stats["projects"].sort(key=lambda x: x["updated"], reverse=True)
    stats["total_actor_attempts"] = dict(stats["total_actor_attempts"])
    
    return stats

# -----------------------------------------------------------------------------
# SERVER HANDLER
# -----------------------------------------------------------------------------
class StatsHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass  # Suppress logging

    def do_GET(self):
        if self.path == "/" or self.path == "/index.html":
            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(HTML_TEMPLATE.encode("utf-8"))
            
        elif self.path == "/api/stats":
            data = get_aggregated_stats()
            self.send_response(200)
            self.send_header("Content-type", "application/json; charset=utf-8")
            self.end_headers()
            self.wfile.write(json.dumps(data).encode("utf-8"))
            
        else:
            self.send_response(404)
            self.end_headers()

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------
def main():
    global PORT
    
    # Fix for file permissions
    if sys.platform != "win32":
        try:
             # Ensure script is executable
             os.chmod(os.path.abspath(__file__), 0o755)
        except:
             pass

    server = None
    for attempt in range(MAX_ATTEMPTS):
        try:
            server = HTTPServer(("localhost", PORT), StatsHandler)
            break
        except OSError as e:
            if e.errno == 48:  # Address in use
                PORT += 1
            else:
                raise

    if server is None:
        print(f"❌ Помилка: Не вдалося знайти вільний порт після {MAX_ATTEMPTS} спроб.")
        print(f"Спробуйте закрити інші програми або перезавантажити комп'ютер.")
        sys.exit(1)

    print(f"🚀 Subass Statistics запущено!")
    print(f"📱 Відкрийте у браузері: http://localhost:{PORT}")
    print(f"⌨️  Натисніть Ctrl+C для виходу\n")
    
    # Open browser in a separate thread to not block server startup
    def open_browser():
        time.sleep(0.5)
        webbrowser.open(f"http://localhost:{PORT}")
        
    threading.Thread(target=open_browser).start()

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n\n👋 Дякуємо за використання Subass Statistics!")
    finally:
        server.server_close()
        # On macOS, try to close the terminal window automatically
        if sys.platform == "darwin":
            try:
                # Use AppleScript to close the front window of Terminal without confirmation
                os.system("osascript -e 'tell application \"Terminal\" to close front window saving no' &")
            except:
                pass
        elif sys.platform == "win32":
            try:
                import ctypes
                # Post WM_CLOSE (0x10) to the console window
                hwnd = ctypes.windll.kernel32.GetConsoleWindow()
                if hwnd:
                    ctypes.windll.user32.PostMessageW(hwnd, 0x10, 0, 0)
                else:
                    # Fallback to killing the parent if possible
                    os.system("taskkill /F /PID " + str(os.getppid()) + " >nul 2>&1")
            except:
                pass
        sys.exit(0)

if __name__ == "__main__":
    main()
