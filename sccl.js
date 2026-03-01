/* C4SCL Logica */
function toggleSCCL() {
    const screen = document.getElementById('sccl-screen');
    if (screen.style.display === 'none' || screen.style.display === '') {
        screen.style.display = 'block';
        updateSCCL();
    } else {
        screen.style.display = 'none';
    }
}

function updateSCCL() {
    const request = indexedDB.open("Coronate");
    request.onsuccess = (e) => {
        const db = e.target.result;
        const tx = db.transaction(["Tournaments", "Players"], "readonly");
        tx.objectStore("Tournaments").getAll().onsuccess = (ev) => {
            const tourney = ev.target.result[0];
            tx.objectStore("Players").getAll().onsuccess = (ev2) => {
                const players = {};
                ev2.target.result.forEach(p => { players[p.id || p.Id] = p; });
                if (tourney) {
                    const tName = tourney.Name || tourney.name || "Onbekend Toernooi";
                    document.getElementById('sccl-title-text').innerText = "🏆 C4SCL Stand: " + tName;
                    renderSCCL(tourney, players);
                }
            };
        };
    };
}

function renderSCCL(tourney, players) {
    const rounds = tourney.RoundList || tourney.roundList || [];
    const totalRounds = rounds.length;
    
    let stats = Object.keys(players).filter(id => !id.includes("DUMMY")).map(id => {
        let p = players[id];
        let rating = p.Rating || p.rating || 0;
        let wG=0, bG=0, won=0, dr=0, loss=0, pres=0, byes=0, extern=0;
        
        rounds.forEach(r => {
            const m = r.find(match => (match.WhiteId || match.whiteId) === id || (match.BlackId || match.blackId) === id);
            if (m) {
                pres++;
                const isWhite = (m.WhiteId || m.whiteId) === id;
                const oppId = isWhite ? (m.BlackId || m.blackId) : (m.WhiteId || m.whiteId);
                const opponent = players[oppId];
                const res = m.Result || m.result;
                const ratingDiff = isWhite ? (m.WhiteRatingDiff || m.whiteRatingDiff || 0) : (m.BlackRatingDiff || m.blackRatingDiff || 0);
                const hasEarnedPoints = Math.abs(ratingDiff) > 0.1;
                const isOppDummy = oppId && oppId.includes("DUMMY");
                const isNamedExtern = opponent && (opponent.FirstName || opponent.firstName || "").toUpperCase().includes("EXTERN");

                if (isOppDummy) {
                    if (hasEarnedPoints || isNamedExtern) extern++; else byes++;
                } else {
                    if (isWhite) {
                        wG++; if (res === 'whiteWon') won++; else if (res === 'blackWon') loss++; else if (res === 'draw') dr++;
                    } else {
                        bG++; if (res === 'blackWon') won++; else if (res === 'whiteWon') loss++; else if (res === 'draw') dr++;
                    }
                }
            }
        });

        let gemist = totalRounds - pres;
        let x = gemist - 2;
        let aftrek = x > 0 ? (x * (x + 1)) / 2 : 0;
        let netto = rating - aftrek;

        return { name: ((p.FirstName || p.firstName || "") + " " + (p.LastName || p.lastName || "")).trim(), rating, wG, bG, won, dr, loss, byes, extern, gemist, aftrek, netto };
    }).sort((a, b) => b.netto - a.netto);

    let html = `<table class="sccl-table"><thead><tr>
        <th>Pos</th><th>Naam</th><th>Rating (Aftrek)</th>
        <th class="sccl-highlight">+</th><th class="sccl-highlight">=</th><th class="sccl-highlight">-</th>
        <th title="Vrij">B</th><th title="Extern">E</th><th>W</th><th>Z</th><th>G</th><th class="sccl-netto">Netto</th>
    </tr></thead><tbody>`;
    
    stats.forEach((s, i) => {
        html += `<tr><td>${i+1}</td><td><b>${s.name}</b></td>
            <td>${Math.round(s.rating)}<span class="sccl-deduction-inline">(-${s.aftrek})</span></td>
            <td class="sccl-highlight">${s.won}</td><td class="sccl-highlight">${s.dr}</td><td class="sccl-highlight">${s.loss}</td>
            <td>${s.byes}</td><td>${s.extern}</td><td>${s.wG}</td><td>${s.bG}</td><td>${s.gemist}</td><td class="sccl-netto">${Math.round(s.netto)}</td></tr>`;
    });
    document.getElementById('sccl-table-render').innerHTML = html + "</tbody></table>";
}
