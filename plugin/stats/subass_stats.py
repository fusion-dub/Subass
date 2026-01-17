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

        /* Modal */
        .modal-overlay { display: none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 1000; align-items: center; justify-content: center; backdrop-filter: blur(4px); }
        .modal { background: white; border-radius: 16px; width: 90%; max-width: 800px; max-height: 80vh; overflow-y: auto; padding: 30px; position: relative; box-shadow: 0 20px 25px -5px rgba(0,0,0,0.1); }
        .modal-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 20px; }
        .modal-close { background: none; border: none; font-size: 24px; cursor: pointer; color: var(--text-light); }
        .modal-title { font-size: 20px; font-weight: 700; }
        .modal-subtitle { color: var(--text-light); font-size: 14px; margin-top: 4px; }
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

        <div class="tabs">
            <button class="tab-btn active" onclick="switchTab('overview')">Огляд</button>
            <button class="tab-btn" onclick="switchTab('projects')">Проекти</button>
            <button class="tab-btn" onclick="switchTab('actors')">Актори</button>
            <button class="tab-btn" onclick="switchTab('trends')">Динаміка</button>
        </div>

        <!-- OVERVIEW TAB -->
        <div id="overview" class="tab-content active">
            <div class="scorecards">
                <div class="card">
                    <h3>Реплік (вибрано)</h3>
                    <div class="value" id="total-lines">0</div>
                    <div class="sub">Для активних акторів</div>
                </div>
                <div class="card">
                    <h3>Слів (вибрано)</h3>
                    <div class="value" id="total-words">0</div>
                    <div class="sub">Обсяг для запису</div>
                </div>
                <div class="card">
                    <h3>Записано</h3>
                    <div class="value" id="recorded-lines">0</div>
                    <div class="sub">Унікальних реплік</div>
                </div>
                <div class="card">
                    <h3>Проектів</h3>
                    <div class="value" id="project-count">0</div>
                    <div class="sub">Активних</div>
                </div>
            </div>

            <div class="chart-container">
                <canvas id="overviewChart"></canvas>
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
                            <th>Прогрес</th>
                            <th>Оновлено</th>
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
             <div style="margin-bottom: 15px;">
                <label style="cursor: pointer; font-size: 14px; color: var(--text-light); display: flex; align-items: center; gap: 8px;">
                    <input type="checkbox" id="show-hidden-actors" onchange="renderActorsTable()" style="accent-color: var(--primary);"> 
                    Показати прихованих акторів (не активні)
                </label>
             </div>
             <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>Актор</th>
                            <th>Спроб (всього)</th>
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

        <!-- TRENDS TAB -->
        <div id="trends" class="tab-content">
             <div class="scorecards">
                <div class="card">
                    <h3>Сьогодні</h3>
                    <div class="value" id="today-lines">0</div>
                    <div class="sub">Спроб (дублів)</div>
                </div>
                 <div class="card">
                    <h3>Цей тиждень</h3>
                    <div class="value" id="week-lines">0</div>
                    <div class="sub">Спроб (дублів)</div>
                </div>
                 <div class="card">
                    <h3>Цей місяць</h3>
                    <div class="value" id="month-lines">0</div>
                    <div class="sub">Спроб (дублів)</div>
                </div>
            </div>
            
            <div style="margin-bottom: 10px; font-weight: 600; color: var(--text-light);">📈 Графік інтенсивності запису:</div>
            <div class="chart-container" style="height: 350px;">
                 <canvas id="trendsChart"></canvas>
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
            </div>
        </div>
    </div>

    <script>
        // --- LOGIC ---
        let chartInstance = null;
        let trendsChartInstance = null;
        let globalActorsData = [];
        let globalProjectsData = [];
        let globalActorAttempts = {};
        let currentProjectIndex = -1;

        document.addEventListener('DOMContentLoaded', loadStats);

        function switchTab(tabId) {
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
            
            document.querySelector(`button[onclick="switchTab('${tabId}')"]`).classList.add('active');
            document.getElementById(tabId).classList.add('active');
        }

        async function loadStats() {
            try {
                const response = await fetch('/api/stats');
                const data = await response.json();
                renderStats(data);
            } catch (e) {
                console.error("Failed to load stats:", e);
                alert("Не вдалося завантажити статистику. Перевірте, чи запущено скрипт.");
            }
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

            // Get all unique actors
            const actorNames = new Set([
                ...(p.actors ? Object.keys(p.actors) : []),
                ...(p.actor_attempts ? Object.keys(p.actor_attempts) : [])
            ]);

            const actorsList = Array.from(actorNames)
                .filter(name => name.toLowerCase() !== 'all')
                .map(name => ({
                    name,
                    meta: (p.actors && p.actors[name]) || { lines: 0, words: 0, selected: false },
                    attempts: (p.actor_attempts && p.actor_attempts[name]) || 0
                }));

            // Sorting: Selected first, then by attempts
            actorsList.sort((a, b) => {
                if (a.meta.selected !== b.meta.selected) {
                    return b.meta.selected ? 1 : -1;
                }
                return b.attempts - a.attempts;
            });

            actorsList.forEach(a => {
                if (!showAll && !a.meta.selected) return;

                const row = `<tr>
                    <td><strong>${a.name}</strong> ${a.meta.selected ? '' : '<span style="color:#9ca3af; font-size:11px;">(Hidden)</span>'}</td>
                    <td>${a.attempts.toLocaleString()}</td>
                    <td>${(a.meta.lines || 0).toLocaleString()}</td>
                    <td>${(a.meta.words || 0).toLocaleString()}</td>
                </tr>`;
                tbody.innerHTML += row;
            });

            document.getElementById('project-modal').style.display = 'flex';
        }

        function closeProjectModal() {
            document.getElementById('project-modal').style.display = 'none';
        }

        function closeModal(event) {
            if (event.target === document.getElementById('project-modal')) {
                closeProjectModal();
            }
        }

        function renderActorsTable() {
            const showHidden = document.getElementById('show-hidden-actors').checked;
            const actorsTbody = document.getElementById('actors-table-body');
            actorsTbody.innerHTML = '';

            globalActorsData.forEach(a => {
                if (!showHidden && !a.selected) return;

                const attempts = globalActorAttempts[a.name] || 0;

                const row = `<tr>
                    <td><strong>${a.name}</strong></td>
                    <td>${attempts.toLocaleString()}</td>
                    <td>${a.project}</td>
                    <td>${a.lines.toLocaleString()}</td>
                    <td>${a.words.toLocaleString()}</td>
                    <td>${a.selected ? '<span style="color:#10b981; font-weight:500">● Visible</span>' : '<span style="color:#9ca3af">○ Hidden</span>'}</td>
                </tr>`;
                actorsTbody.innerHTML += row;
            });
        }

        function renderStats(data) {
            globalProjectsData = data.projects;
            globalActorAttempts = data.total_actor_attempts || {};
            
            // 1. Update Scorecards
            document.getElementById('total-lines').innerText = data.total_selected_lines.toLocaleString();
            document.getElementById('total-words').innerText = data.total_selected_words.toLocaleString();
            document.getElementById('recorded-lines').innerText = data.total_recorded.toLocaleString();
            document.getElementById('project-count').innerText = data.projects.length;

            document.getElementById('today-lines').innerText = data.period_stats.today.toLocaleString();
            document.getElementById('week-lines').innerText = data.period_stats.week.toLocaleString();
            document.getElementById('month-lines').innerText = data.period_stats.month.toLocaleString();

            // 2. Render Projects Table
            const projTbody = document.getElementById('projects-table-body');
            projTbody.innerHTML = '';
            data.projects.forEach((p, index) => {
                const progress = (p.recorded / (p.selected_lines || 1)) * 100;
                const row = `<tr class="clickable-row" onclick="showProjectDetails(${index})">
                    <td><strong>${p.name}</strong><br><span style="font-size:12px;color:#888">${p.path.split('/').pop()}</span></td>
                    <td>${p.selected_lines}</td>
                    <td>${p.selected_words}</td>
                    <td>
                        <div style="font-size:12px;margin-bottom:2px">${Math.round(progress)}% (${p.recorded})</div>
                        <div class="progress-bar"><div class="progress-fill" style="width:${progress}%"></div></div>
                    </td>
                    <td>${new Date(p.updated * 1000).toLocaleDateString()}</td>
                </tr>`;
                projTbody.innerHTML += row;
            });

            // 3. Prepare Actors Data (Rendered by separate function)
            globalActorsData = [];
            data.projects.forEach(p => {
                if (p.actors) {
                    Object.values(p.actors).forEach(a => {
                        if (a.id === "all") return; // Skip aggregate
                        globalActorsData.push({
                            name: a.id,
                            project: p.name,
                            lines: a.lines,
                            words: a.words,
                            selected: a.selected
                        });
                    });
                }
            });
            
            // Sort by lines descending
            globalActorsData.sort((a, b) => b.lines - a.lines);
            renderActorsTable();

            // 4. Render Overview Chart (Project breakdown)
            const ctx = document.getElementById('overviewChart').getContext('2d');
            if (chartInstance) chartInstance.destroy();
            
            chartInstance = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: data.projects.map(p => p.name),
                    datasets: [{
                        label: 'Реплік (вибрано)',
                        data: data.projects.map(p => p.selected_lines),
                        backgroundColor: '#4f46e5'
                    }, {
                        label: 'Записано',
                        data: data.projects.map(p => p.recorded),
                        backgroundColor: '#10b981'
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: { y: { beginAtZero: true } }
                }
            });

            // 5. Render Trends Chart (Daily recording activity)
            const trendCtx = document.getElementById('trendsChart').getContext('2d');
            if (trendsChartInstance) trendsChartInstance.destroy();

            // Prepare daily data
            const dateMap = {}; // { date: { total: 0, lines: 0, outside: 0 } }
            data.projects.forEach(p => {
                if (p.history) {
                    Object.entries(p.history).forEach(([date, histData]) => {
                        if (!dateMap[date]) dateMap[date] = { total: 0, lines: 0, outside: 0 };
                        
                        const lines = typeof histData === 'object' ? (histData.lines || 0) : histData;
                        const linesOutside = typeof histData === 'object' ? (histData.lines_outside || 0) : 0;
                        
                        dateMap[date].lines += lines;
                        dateMap[date].outside += linesOutside;
                        dateMap[date].total += (lines + linesOutside);
                    });
                }
            });
            
            const sortedDates = Object.keys(dateMap).sort();
            const last30Dates = sortedDates.slice(-30);
            
            // Populate Trends Table
            const trendsTbody = document.getElementById('trends-table-body');
            trendsTbody.innerHTML = '';
            
            // Show latest dates first in table
            [...sortedDates].reverse().forEach(date => {
                const info = dateMap[date];
                const row = `<tr>
                    <td><strong>${date}</strong></td>
                    <td>${info.total.toLocaleString()}</td>
                    <td>${info.lines.toLocaleString()}</td>
                    <td>${info.outside.toLocaleString()}</td>
                </tr>`;
                trendsTbody.innerHTML += row;
            });

            trendsChartInstance = new Chart(trendCtx, {
                type: 'line',
                data: {
                    labels: last30Dates,
                    datasets: [{
                        label: 'Спроб (дублів)',
                        data: last30Dates.map(d => dateMap[d].total),
                        borderColor: '#f59e0b',
                        backgroundColor: 'rgba(245, 158, 11, 0.1)',
                        fill: true,
                        tension: 0.3,
                        pointRadius: last30Dates.length === 1 ? 5 : 2 // Larger radius if only one point
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: { 
                        y: { 
                            beginAtZero: true,
                            ticks: { stepSize: 1 } 
                        } 
                    }
                }
            });
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
