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
        tr:hover { background: #f9fafb; }
        
        .actor-badge { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 12px; font-weight: 500; background: #e0e7ff; color: #4338ca; margin-right: 5px; margin-bottom: 5px; }
        .progress-bar { height: 6px; background: #e5e7eb; border-radius: 3px; overflow: hidden; margin-top: 8px; width: 100px; }
        .progress-fill { height: 100%; background: var(--primary); }
    </style>
</head>
<body>
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
                    <h3>Всього реплік</h3>
                    <div class="value" id="total-lines">0</div>
                    <div class="sub">В усіх проектах</div>
                </div>
                <div class="card">
                    <h3>Всього слів</h3>
                    <div class="value" id="total-words">0</div>
                    <div class="sub">Орієнтовний обсяг</div>
                </div>
                <div class="card">
                    <h3>Записано</h3>
                    <div class="value" id="recorded-lines">0</div>
                    <div class="sub">Реплік озвучено</div>
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
                            <th>Реплік</th>
                            <th>Слів</th>
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
                            <th>Проект</th>
                            <th>Реплік</th>
                            <th>Слів</th>
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
                    <div class="sub">Реплік записано</div>
                </div>
                 <div class="card">
                    <h3>Цей тиждень</h3>
                    <div class="value" id="week-lines">0</div>
                    <div class="sub">Реплік записано</div>
                </div>
                 <div class="card">
                    <h3>Цей місяць</h3>
                    <div class="value" id="month-lines">0</div>
                    <div class="sub">Реплік записано</div>
                </div>
            </div>
            <div class="chart-container">
                 <canvas id="trendsChart"></canvas>
            </div>
        </div>
    </div>

    <script>
        // --- LOGIC ---
        let chartInstance = null;
        let trendsChartInstance = null;
        let globalActorsData = [];

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
        
        function renderActorsTable() {
            const showHidden = document.getElementById('show-hidden-actors').checked;
            const actorsTbody = document.getElementById('actors-table-body');
            actorsTbody.innerHTML = '';

            globalActorsData.forEach(a => {
                if (!showHidden && !a.selected) return;

                const row = `<tr>
                    <td><strong>${a.name}</strong></td>
                    <td>${a.project}</td>
                    <td>${a.lines}</td>
                    <td>${a.words}</td>
                    <td>${a.selected ? '<span style="color:#10b981; font-weight:500">● Visible</span>' : '<span style="color:#9ca3af">○ Hidden</span>'}</td>
                </tr>`;
                actorsTbody.innerHTML += row;
            });
        }

        function renderStats(data) {
            // 1. Update Scorecards
            document.getElementById('total-lines').innerText = data.total_lines_script.toLocaleString();
            document.getElementById('total-words').innerText = data.total_words.toLocaleString();
            document.getElementById('recorded-lines').innerText = data.total_recorded.toLocaleString();
            document.getElementById('project-count').innerText = data.projects.length;

            document.getElementById('today-lines').innerText = data.period_stats.today.toLocaleString();
            document.getElementById('week-lines').innerText = data.period_stats.week.toLocaleString();
            document.getElementById('month-lines').innerText = data.period_stats.month.toLocaleString();

            // 2. Render Projects Table
            const projTbody = document.getElementById('projects-table-body');
            projTbody.innerHTML = '';
            data.projects.forEach(p => {
                const progress = (p.recorded / (p.lines || 1)) * 100;
                const row = `<tr>
                    <td><strong>${p.name}</strong><br><span style="font-size:12px;color:#888">${p.path.split('/').pop()}</span></td>
                    <td>${p.lines}</td>
                    <td>${p.words}</td>
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
                        label: 'Реплік',
                        data: data.projects.map(p => p.lines),
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
            // Need to aggregate daily stats from all projects
            const trendCtx = document.getElementById('trendsChart').getContext('2d');
            if (trendsChartInstance) trendsChartInstance.destroy();

            // Prepare daily data
            const dateMap = {};
            data.projects.forEach(p => {
                if (p.history) {
                    Object.entries(p.history).forEach(([date, histData]) => {
                        const count = typeof histData === 'object' ? (histData.lines || 0) : histData;
                        dateMap[date] = (dateMap[date] || 0) + count;
                    });
                }
            });
            
            const sortedDates = Object.keys(dateMap).sort().slice(-30); // Last 30 days
            
            trendsChartInstance = new Chart(trendCtx, {
                type: 'line',
                data: {
                    labels: sortedDates,
                    datasets: [{
                        label: 'Записано реплік',
                        data: sortedDates.map(d => dateMap[d]),
                        borderColor: '#f59e0b',
                        backgroundColor: 'rgba(245, 158, 11, 0.1)',
                        fill: true,
                        tension: 0.3
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: { y: { beginAtZero: true } }
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
        "total_recorded": 0,
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
                
                # Basic Project Info
                proj = {
                    "name": data.get("project_name", "Unknown"),
                    "path": data.get("project_path", ""),
                    "updated": data.get("last_updated", 0),
                    "lines": data.get("metadata", {}).get("total_lines_in_script", 0),
                    "words": data.get("metadata", {}).get("total_words", 0),
                    "recorded": data.get("total", {}).get("lines_recorded", 0),
                    "actors": data.get("metadata", {}).get("actors", {}),
                    "history": data.get("daily_stats", {})
                }
                
                stats["projects"].append(proj)
                stats["total_lines_script"] += proj["lines"]
                stats["total_words"] += proj["words"]
                stats["total_recorded"] += proj["recorded"]
                
                # Period Aggregation
                if proj["history"]:
                    for date, hist_data in proj["history"].items():
                        # Support both legacy integer count and new dictionary format
                        count = hist_data.get("lines", 0) if isinstance(hist_data, dict) else hist_data
                        
                        if date == today_str:
                            stats["period_stats"]["today"] += count
                        if date >= week_start:
                            stats["period_stats"]["week"] += count
                        if date >= month_start:
                            stats["period_stats"]["month"] += count
                            
        except Exception as e:
            print(f"Error reading {jf}: {e}")
            continue
            
    # Sort projects by last updated desc
    stats["projects"].sort(key=lambda x: x["updated"], reverse=True)
    
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
