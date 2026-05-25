document.body.classList.add("dark-mode");
halfmoon.toggleDarkMode = function() {};

let doneOfflineWarning = false;

class Header extends HTMLElement {
    constructor() {
    super();
    }
  
	connectedCallback() {
		this.innerHTML = `
			<nav class="navbar">
				<div class="navbar-brand text-nowrap">
					<img src="assets/pokemon-icon/201-27.png" class="icon" id="icon">
					PokéBot NDS
				</div>
				<span class="navbar-text text-monospace font-size-12">v1.2c</span>
				<ul class="navbar-nav d-flex d-md-flex">
					<li class="nav-item nav-link px-10">
						<a href="dashboard.html">
							<button type="button" class="btn position-relative px-10">
								<i class="fa fa-user-circle"></i>
								Dashboard
								<span id="dashboard-badge" class="badge badge-primary translate-middle text-bg-primary px-5">0</span>
							</button>
						</a>
					</li>
					<li class="nav-item nav-link px-10">
						<a href="config.html">
							<button type="button" class="btn position-relative px-10">
								<i class="fa fa-gear"></i>
								Config
							</button>
						</a>
					</li>
					<li class="nav-item nav-link px-10">
						<a href="tools.html">
							<button type="button" class="btn position-relative px-10">
							<svg class="nav-icon" viewBox="0 0 32 32">
								<g transform="translate(32 0) scale(-1 1)">
									<path fill="currentColor"
										d="m16.154 3.901l-2.492 2.492l1.768 1.768a1.5 1.5 0 0 1 .293 1.707l1.357 1.358l1.939-1.952a6.07 6.07 0 0 1 1.715-5.567l.003-.003a6.06 6.06 0 0 1 5.65-1.53c1.214.296 1.617 1.8.75 2.668L24.88 7.1l1.026 1.026l2.254-2.254c.89-.908 2.384-.435 2.672.745l.001.003a6.06 6.06 0 0 1-7.122 7.371l-1.925 1.94l7.16 7.16a4 4 0 1 1-5.657 5.656l-7.14-7.14l-1.375 1.384a6.07 6.07 0 0 1-1.727 5.512l-.003.003a6.06 6.06 0 0 1-5.651 1.53c-1.213-.297-1.616-1.802-.75-2.668l2.259-2.258l-1.026-1.026l-2.253 2.253c-.89.909-2.385.436-2.673-.745l-.001-.003A6.06 6.06 0 0 1 6.8 18.444a1 1 0 0 1-.096-.087L.366 12.02a1.25 1.25 0 0 1 0-1.768l.788-.788a3 3 0 0 1 2.52-.852q.041-.05.089-.1l7.073-7.073a1.5 1.5 0 0 1 1.219-.43l3.2.338a1.5 1.5 0 0 1 .904 2.555zM5.53 9.575l3.894 3.888l4.242-4.243l-1.6-1.6a1.69 1.69 0 0 1-.466-1.626c.15-.606.566-1 1.31-1.704c.306-.29.668-.634 1.09-1.066l-1.918-.2zm3.205 8.518c.466-.008.933.038 1.39.137l1.318-1.327l-1.31-1.31a3 3 0 0 1-.874 1.975zm4.118-2.61l2.818-2.838l-1.302-1.302l-2.828 2.828zm4.704 4.704l7.145 7.145a2 2 0 0 0 2.828-2.828l-7.155-7.154zM2.569 10.879l-.258.258l5.276 5.276l.258-.258a1 1 0 0 0 0-1.414l-3.862-3.862a1 1 0 0 0-1.414 0m19.556-5.734a4.08 4.08 0 0 0-1.043 4.136l.179.575L10.699 20.49l-.587-.194a4.06 4.06 0 0 0-4.145.986a4.05 4.05 0 0 0-1.185 3.067l1.971-1.971c.62-.62 1.624-.62 2.244 0l1.61 1.61c.62.62.62 1.623 0 2.244l-1.973 1.973a4.07 4.07 0 0 0 3.021-1.14a4.08 4.08 0 0 0 1.056-4.094l-.17-.57l10.586-10.66l.582.185a4.06 4.06 0 0 0 4.104-.998a4.05 4.05 0 0 0 1.185-3.067l-1.97 1.97a1.586 1.586 0 0 1-2.245 0l-1.61-1.61a1.585 1.585 0 0 1 0-2.243l1.973-1.973a4.07 4.07 0 0 0-3.021 1.139"></path>
								</g>
							</svg>
								Tools
							</button>
						</a>
					</li>
					<li class="nav-item nav-link px-10">
						<a href="https://discord.gg/g52tXE7Hyc" target="_blank">
							<button type="button" class="btn position-relative px-10">
								<svg class="nav-icon" viewBox="0 0 24 24">
									<path fill="currentColor"
										d="M20.317 4.369a19.79 19.79 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.249a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.249.077.077 0 0 0-.079-.037 19.736 19.736 0 0 0-4.885 1.515.07.07 0 0 0-.032.027C2.18 9.045 1.64 13.58 2.093 18.057a.082.082 0 0 0 .031.056 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.027c.461-.63.873-1.295 1.226-1.994a.076.076 0 0 0-.041-.105 13.1 13.1 0 0 1-1.872-.878.077.077 0 0 1-.008-.128c.125-.094.25-.192.37-.291a.074.074 0 0 1 .077-.01c3.927 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.009c.12.099.245.198.37.292a.077.077 0 0 1-.006.128 12.299 12.299 0 0 1-1.873.878.076.076 0 0 0-.04.106c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.9 19.9 0 0 0 6.002-3.03.076.076 0 0 0 .03-.055c.5-5.177-.838-9.682-3.548-13.661a.061.061 0 0 0-.031-.03Z" />
								</svg>
								Discord
							</button>
						</a>
					</li>
					<li class="nav-item nav-link px-10">
						<a href="https://github.com/Falin-Mor/pokebot-nds" target="_blank">
							<button type="button" class="btn position-relative px-10">
								<i class="fa-brands fa-github"></i>
								Github
							</button>
						</a>
					</li>
					<li class="nav-item nav-link px-10">
						<a href="https://ko-fi.com/falinmor_" target="_blank">
							<button type="button" class="btn position-relative px-10">
								<i class="fa-solid fa-heart"></i>
								Donate
							</button>
						</a>
					</li>
				</ul>
				<div style="position: absolute; right: 15px; display: flex;">
					<div class="text-center mx-5">
						<i class="fa fa-stopwatch mr-10" style="margin-top: 3px"></i>
						<span id="elapsed-time" class="badge text-bg-secondary">0s</span>
					</div>
					<div class="text-center mx-5">
						<i class="fa fa-tachometer mr-10" style="margin-top: 3px"></i>
						<span id="encounter-rate" class="badge text-bg-secondary">0/h</span>
					</div>
				</div>
			</nav>
		`;
	}
}

customElements.define('header-component', Header);

function socketServerCommunicate(method, url, callback) {
    const http = new XMLHttpRequest();

    http.open(method, url);
    http.responseType = 'json';

    http.onload = function (e) {
        if (http.status === 200) {
            doneOfflineWarning = false;

            const response = http.response;
            callback(null, response);
        } else {
            callback(method + ' request failed. Status: ' + http.status, null);
        }
    };
    http.onerror = function () {
        if (!doneOfflineWarning) {
            halfmoon.initStickyAlert({
                content: 'NOTE: The dashboard cannot be accessed by opening the .html pages directly in the browser. The node backend must be running.',
                title: "Couldn't reach API endpoint",
                alertType: 'alert-danger',
                timeShown: 15000
            })

            doneOfflineWarning = true;
        }
    }

    http.send();
}

function socketServerGet(endpoint, callback) {
    const method = 'GET'
    const url = `http://localhost:3000/api/${encodeURIComponent(endpoint)}`
    
    socketServerCommunicate(method, url, callback)   
}

function socketServerSend(endpoint, data, callback) {
    const method = 'POST'
    const url = `http://localhost:3000/api/${encodeURIComponent(endpoint)}?data=${JSON.stringify(data)}`
    
    socketServerCommunicate(method, url, callback)
}

function randomisePageIcon() {
    const randomRange = (min, max) => min + Math.floor(Math.random() * (max - min));

    // Make the API request and handle the response in a callback
    socketServerGet('clients', function (error, clients) {
        if (error) {
            console.error(error);
            return;
        }

        if (Array.isArray(clients) && clients.length > 0) {
            let icon = 0;
            
            switch (clients[0].version) {
                case 'D':
                case 'P':
                case 'PL':
                    icon = randomRange(387, 493);
                    break;
                case 'HG':
                case 'SS':
                    icon = randomRange(152, 251);
                    break;
                case 'B':
                case 'W':
                case 'B2':
                case 'W2':
                    icon = randomRange(494, 649);
                    break;
            }
            
            const iconURL = 'assets/pokemon-icon/' + icon.toString().padStart(3, '0') + '.png';
            document.getElementById('icon').src = iconURL;
        } else {
            console.error('No clients connected.');
        }
    });
}

const dashboardBadge = $('#dashboard-badge');

function setBadgeClientCount(clientCount) {
    if (clientCount == 0) {
        dashboardBadge.text('0')
        dashboardBadge.hide()
        return
    }

    const value = clientCount.toString()

    if (dashboardBadge.text() != value) {
        dashboardBadge.text(value)
        dashboardBadge.show()
    }
}

const encounterRate = $('#encounter-rate');

function updateEncounterRate() {
    socketServerGet('encounter_rate', function (error, rate) {
        if (error) {
            console.error(error);
            return;
        }

        encounterRate.text(`${rate}/h`)
    })
}

let elapsedStart;
let elapsedInterval;
const elapsedTime = $('#elapsed-time');

function updateElapsedTime() {
    const elapsed = Math.floor((Date.now() - elapsedStart) / 1000);
    const s = elapsed;
    const m = Math.floor(s / 60);
    const h = Math.floor(m / 60);
    const time = `${h}h ${m % 60}m ${s % 60}s`;

    elapsedTime.text(time)
}

function updateStatBadges() {
    updateEncounterRate()
    updateElapsedTime()
}

randomisePageIcon();
