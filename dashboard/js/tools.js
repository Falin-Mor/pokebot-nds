function updateClientInfo() {
    socketServerGet('clients', (error, clients) => {
        if (error) {
            console.error(error);
            return;
        }

        const clientCount = clients.length;

        if (clientCount === 0) {
            clearInterval(elapsedInterval);
            elapsedStart = null;

            $('#elapsed-time').text('0s');
            $('#encounter-rate').text('0/h');
            setBadgeClientCount(0);

            // Reset binomial when no games connected
            const seen = document.getElementById("seen-count");
            if (seen) {
                seen.value = 0;
                updateBinomial();
            }

            return;
        }

        // NEW: pull stats and update binomial
        socketServerGet('stats', (err, payload) => {
            if (!err && payload?.stats) {
                const phaseSeen = payload.stats.phase.seen;

                const seen = document.getElementById("seen-count");
                if (seen) {
                    seen.value = phaseSeen;
                    updateBinomial();
                }
            }
        });

        // Start elapsed timer if a game is connected
        if (!elapsedStart) {
            socketServerGet('elapsed_start', function (error, start) {
                if (error) {
                    console.error(error);
                    return;
                }

                elapsedStart = start;
                elapsedInterval = setInterval(updateStatBadges, 1000);
                updateStatBadges();
            });
        }

        setBadgeClientCount(clientCount);
    });
}

updateClientInfo();

// -------------------------------
// Refresh Button for Binomial
// -------------------------------

document.getElementById("refresh-binomial")?.addEventListener("click", () => {
    socketServerGet('stats', (err, payload) => {
        if (!err && payload?.stats) {
            const phaseSeen = payload.stats.phase.seen;

            const seen = document.getElementById("seen-count");
            if (seen) {
                seen.value = phaseSeen;
                updateBinomial();
            }
        }
    });
});

// -------------------------------
// Simple Calculator
// -------------------------------

let calcBuffer = "";

function calcPress(val) {
    calcBuffer += val;
    document.getElementById("calc-display").value = calcBuffer;
}

function calcClear() {
    calcBuffer = "";
    document.getElementById("calc-display").value = "";
}

function calcEquals() {
    try {
        calcBuffer = eval(calcBuffer).toString();
        document.getElementById("calc-display").value = calcBuffer;
    } catch {
        calcBuffer = "";
        document.getElementById("calc-display").value = "Error";
    }
}

// -------------------------------
// Binomial Probability + Graph
// -------------------------------

function updateBinomial() {
    const rate = parseFloat(document.getElementById("shiny-rate")?.value);
    const seen = parseFloat(document.getElementById("seen-count")?.value);

    if (!rate || rate <= 0 || seen < 0) return;

    const p = 1 / rate;
    const chance = 1 - Math.pow(1 - p, seen);

    const out = document.getElementById("bnp");
    if (out) out.innerText = (chance * 100).toFixed(4) + "%";

    drawBinomialGraph(rate, seen);
}

function drawBinomialGraph(rate, seen) {
    const canvas = document.getElementById("binom-graph");
    if (!canvas) return;

    const ctx = canvas.getContext("2d");
    const w = canvas.width;
    const h = canvas.height;

    if (seen <= 0) seen = 1;

    ctx.clearRect(0, 0, w, h);

    // Background
    ctx.fillStyle = "#111";
    ctx.fillRect(0, 0, w, h);

    // -------------------------------
    // Centered X-axis range
    // -------------------------------
    const minX = 0;
    const maxX = seen * 2;   // extends graph to the right
    const p = 1 / rate;

    // -------------------------------
    // Grid lines + Y-axis labels
    // -------------------------------
    ctx.strokeStyle = "rgba(255,255,255,0.08)";
    ctx.fillStyle = "rgba(255,255,255,0.5)";
    ctx.font = "12px sans-serif";
    ctx.lineWidth = 1;

    const yLabels = [0, 0.25, 0.5, 0.75, 1];

    yLabels.forEach(v => {
        const y = h - v * h;

        // grid line
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(w, y);
        ctx.stroke();

        // label
        ctx.fillText((v * 100).toFixed(0) + "%", 4, y - 2);
    });

    // -------------------------------
    // Draw curve
    // -------------------------------
    ctx.strokeStyle = "#ff8c00";
    ctx.lineWidth = 2;
    ctx.beginPath();

    const steps = 1000;

    for (let i = 0; i <= steps; i++) {
        const x = minX + (i / steps) * (maxX - minX);
        const chance = 1 - Math.pow(1 - p, x);

        const px = ((x - minX) / (maxX - minX)) * w;
        const py = h - (chance * h);

        if (i === 0) ctx.moveTo(px, py);
        else ctx.lineTo(px, py);
    }

    ctx.stroke();

    // -------------------------------
    // Vertical marker line (centered)
    // -------------------------------
    const markerX = ((seen - minX) / (maxX - minX)) * w;

    ctx.strokeStyle = "#00ffcc";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(markerX, 0);
    ctx.lineTo(markerX, h);
    ctx.stroke();

    // -------------------------------
    // Dot at current seen
    // -------------------------------
    const chanceAtSeen = 1 - Math.pow(1 - p, seen);
    const dotY = h - (chanceAtSeen * h);

    ctx.fillStyle = "#00ffcc";
    ctx.beginPath();
    ctx.arc(markerX, dotY, 4, 0, Math.PI * 2);
    ctx.fill();
}

// -------------------------------
// Live Input Listeners
// -------------------------------

document.getElementById("shiny-rate")?.addEventListener("input", updateBinomial);
document.getElementById("seen-count")?.addEventListener("input", updateBinomial);
document.getElementById("shiny-rate").addEventListener("input", updateBinomial);

// Initial draw (safe even if elements missing)
updateBinomial();

