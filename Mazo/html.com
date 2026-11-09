<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Mazo de Cartas - Wordwall Pro Deluxe</title>
    <link rel="manifest" href="manifest.json">

    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/gsap.min.js"></script>
    <script src="https://unpkg.com/@phosphor-icons/web"></script>
    <link href="https://fonts.googleapis.com/css2?family=Fredoka:wght@600;700&family=Plus+Jakarta+Sans:wght@500;600;700;800&display=swap" rel="stylesheet">

    <style>
        :root {
            --font-display: 'Fredoka', sans-serif;
            --font-sans: 'Plus Jakarta Sans', sans-serif;
            --bg-main: #164e87;
            --bg-grad-1: #236cb2;
            --bg-grad-2: #154577;
            --bg-grad-3: #0b2644;
            --card-back-base: #d4ae44;
            --card-back-inner: #c49a2d;
            --card-back-border: #9c7311;
            --card-back-diamond: #dcba56;
            --card-back-circle: #ead07c;
            --card-front-border: #d4ae44;
        }

        * { box-sizing: border-box; user-select: none; -webkit-user-select: none; -webkit-tap-highlight-color: transparent; }

        body {
            font-family: var(--font-sans); overflow: hidden; margin: 0; padding: 0; width: 100vw; height: 100dvh;
            display: flex; flex-direction: column; background-color: var(--bg-main);
            background-image: radial-gradient(circle at 50% 40%, var(--bg-grad-1) 0%, var(--bg-grad-2) 65%, var(--bg-grad-3) 100%);
            color: #ffffff;
        }

        #stage-container { position: relative; flex: 1; width: 100%; overflow: hidden; contain: layout style paint; }
        .table-prop { position: absolute; pointer-events: none; z-index: 2; opacity: 0.9; }
        .gold-side-line { position: absolute; top: 0; bottom: 0; left: 22px; width: 2px; background: linear-gradient(to bottom, rgba(235, 208, 122, 0.2), rgba(235, 208, 122, 0.65), rgba(235, 208, 122, 0.2)); pointer-events: none; z-index: 2; }

        .card-element { position: absolute; top: 0; left: 0; perspective: 1200px; pointer-events: none; backface-visibility: hidden; -webkit-backface-visibility: hidden; }
        .card-element.is-elevated { will-change: transform; }
        .card-flipper { width: 100%; height: 100%; position: relative; transform-style: preserve-3d; -webkit-transform-style: preserve-3d; border-radius: 13px; box-shadow: 0 4px 10px rgba(0, 0, 0, 0.38); }
        .card-element.is-elevated .card-flipper { will-change: transform; box-shadow: 0 16px 28px rgba(0, 0, 0, 0.55); }
        .card-shadow { display: none; }
        .card-face { position: absolute; inset: 0; width: 100%; height: 100%; border-radius: 13px; backface-visibility: hidden; -webkit-backface-visibility: hidden; overflow: hidden; display: flex; flex-direction: column; justify-content: space-between; }

        .card-back { transform: rotateY(0deg) translateZ(1px); -webkit-transform: rotateY(0deg) translateZ(1px); background: var(--card-back-base); padding: 6px; border: 4px solid #f8fafc; }
        .card-back-outer-frame { width: 100%; height: 100%; border-radius: 5px; border: 2px solid var(--card-back-border); padding: 4px; position: relative; background: var(--card-back-base); display: flex; align-items: center; justify-content: center; }
        .card-back-inner { width: 100%; height: 100%; border-radius: 3px; position: relative; overflow: hidden; display: flex; align-items: center; justify-content: center; border: 2px solid var(--card-back-border); background-color: var(--card-back-inner); }
        .card-back-diamond { width: 62%; height: 62%; border: 2px solid var(--card-back-border); display: flex; align-items: center; justify-content: center; background: var(--card-back-diamond); transform: rotate(45deg); box-shadow: 0 0 0 3px var(--card-back-inner); }
        .card-back-circle { width: 52%; height: 52%; border-radius: 50%; background: var(--card-back-circle); border: 2px solid var(--card-back-border); }
        .corner-ornament { position: absolute; width: 16px; height: 16px; background: var(--card-back-base); border: 1.5px solid var(--card-back-border); z-index: 3; display: flex; align-items: center; justify-content: center; }
        .corner-ornament::after { content: '❖'; font-size: 9px; line-height: 1; color: var(--card-back-circle); }
        .co-tl { top: 2px; left: 2px; } .co-tr { top: 2px; right: 2px; } .co-bl { bottom: 2px; left: 2px; } .co-br { bottom: 2px; right: 2px; }

        .card-front { transform: rotateY(180deg) translateZ(1px); background: #f8fafc; color: #0f172a; border: 5px solid #ffffff; padding: 6px; }
        .card-front-frame { width: 100%; height: 100%; border-radius: 6px; border: 3px solid var(--card-front-border); background: linear-gradient(180deg, #ffffff 0%, #f1f5f9 100%); display: flex; flex-direction: column; justify-content: space-between; padding: 8px 10px; position: relative; overflow: hidden; box-shadow: inset 0 0 0 2px rgba(212, 174, 68, 0.2); }
        .card-title-font { font-family: var(--font-display); }

        #deck-zone-frame, #drop-zone-frame { position: absolute; border: 2px solid rgba(235, 208, 122, 0.55); border-radius: 13px; pointer-events: none; background: rgba(0, 0, 0, 0.16); box-shadow: inset 0 0 22px rgba(0, 0, 0, 0.28); z-index: 3; }
        #deck-zone-frame { border-style: dashed; border-color: rgba(235, 208, 122, 0.4); }

        #card-voice-btn { position: absolute; z-index: 8500; width: 50px; height: 34px; border-radius: 7px; background: rgba(20, 52, 88, 0.92); border: 1.5px solid rgba(235, 208, 122, 0.8); color: #ebd07a; display: none; align-items: center; justify-content: center; cursor: pointer; box-shadow: 0 4px 10px rgba(0, 0, 0, 0.45); transition: transform 0.12s ease, background 0.15s ease; }
        #card-voice-btn:hover { background: rgba(30, 72, 118, 1); transform: scale(1.06); } #card-voice-btn:active { transform: scale(0.95); }
        #deck-click-zone { position: absolute; z-index: 9000; cursor: pointer; border-radius: 13px; transition: transform 0.1s ease; }
        #deck-click-zone:hover { box-shadow: 0 0 0 3px rgba(251, 191, 36, 0.45); } #deck-click-zone:active { transform: scale(0.985); }
        #drop-click-zone { position: absolute; z-index: 9000; cursor: pointer; border-radius: 13px; background: transparent; }

        body.is-shuffling .card-element { perspective: none !important; will-change: transform; }
        body.is-shuffling .card-flipper { transform-style: flat !important; -webkit-transform-style: flat !important; box-shadow: 0 2px 5px rgba(0, 0, 0, 0.3) !important; }
        body.is-shuffling .card-front { display: none !important; }
        body.is-shuffling .corner-ornament { display: none !important; }

        #new-game-banner { position: fixed; inset: 0; z-index: 9500; pointer-events: none; display: flex; flex-direction: column; align-items: center; justify-content: center; background: radial-gradient(circle, rgba(0, 0, 0, 0.65) 0%, rgba(0, 0, 0, 0) 75%); opacity: 0; }
        .banner-title-3d { font-family: var(--font-display); font-size: clamp(2.6rem, 9vw, 6.2rem); font-weight: 800; text-transform: uppercase; letter-spacing: 2px; color: #ffffff; text-align: center; line-height: 1.05; text-shadow: 0 3px 0 #d97706, 0 6px 0 #92400e, 0 12px 25px rgba(0, 0, 0, 0.85), 0 0 40px rgba(251, 191, 36, 0.65); }

        .btn-wordwall { background: rgba(9, 25, 45, 0.9); border: 1.5px solid rgba(180, 195, 210, 0.55); box-shadow: 0 4px 10px rgba(0, 0, 0, 0.5); transition: all 0.14s ease; font-family: var(--font-sans); }
        .btn-wordwall:hover:not(:disabled) { background: rgba(20, 48, 82, 0.98); border-color: #ffffff; transform: translateY(-1px); }
        .btn-wordwall:active:not(:disabled) { transform: translateY(2px); } .btn-wordwall:disabled { opacity: 0.36; cursor: not-allowed; }
        .custom-scroll::-webkit-scrollbar { width: 6px; } .custom-scroll::-webkit-scrollbar-track { background: rgba(15, 23, 42, 0.6); border-radius: 8px; } .custom-scroll::-webkit-scrollbar-thumb { background: rgba(245, 158, 11, 0.5); border-radius: 8px; }

        .card-front { container-type: size; }
        .card-front-frame[class*="lay-"] { padding: 3.5cqw; gap: 2.5cqw; justify-content: flex-start; align-items: stretch; }
        .lay-img { width: 100%; height: 100%; object-fit: contain; display: block; }
        .lay-ph { width: 100%; height: 100%; display: flex; flex-direction: column; align-items: center; justify-content: center; background: linear-gradient(135deg, #fef3c7, #fde68a); color: #92400e; font-size: 12cqw; gap: 1cqw; }
        .lay-ph b { font-family: var(--font-display); font-size: 10cqw; }
        .lay-imgbox { background: #fff; border: 1px solid #e2e8f0; border-radius: 2.5cqw; overflow: hidden; padding: 1.5cqw; z-index: 10; display: flex; align-items: center; justify-content: center; min-height: 0; }
        .lay-text { display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 1.5cqw; text-align: center; min-height: 0; z-index: 10; }
        .lay-name { font-weight: 800; text-transform: uppercase; line-height: 1.12; color: #0f172a; text-align: center; width: 100%; margin: 0; font-size: 9cqw; overflow: hidden; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; word-break: break-word; }
        .lay-chip { display: inline-block; max-width: 100%; padding: 0.6cqw 3cqw; border-radius: 999px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; font-size: 4.2cqw; line-height: 1.35; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; z-index: 10; }
        .lay-chip-p { background: #e0f2fe; border: 1px solid #38bdf8; color: #0c4a6e; }
        .lay-chip-f { background: #fef3c7; border: 1px solid #fbbf24; color: #451a03; }
        .lay-chip.hidden { display: none !important; }
        .lay-chips { display: flex; gap: 2cqw; justify-content: center; flex-wrap: wrap; z-index: 10; }

        .lay-classic .lay-imgbox { height: 58%; flex: none; }
        .lay-classic .lay-text { flex: 1; }
        .lay-mini { padding: 3cqw !important; }
        .lay-mini .lay-imgbox { height: 52%; flex: none; }
        .lay-mini .lay-text { flex: 1; }
        .lay-mini .lay-name { font-size: 11cqw; }
        .lay-mini .lay-chip { font-size: 5.5cqw; padding: 0.2cqw 2.5cqw; }
        .lay-mini .lay-text { gap: 0.8cqw; }
        .lay-bigtext .lay-text { flex: 1; gap: 2.5cqw; }
        .lay-bigtext .lay-name { font-size: 15.5cqw; }
        .lay-bigtext .lay-chip { font-size: 5cqw; }
        .lay-bigtext .lay-imgbox { height: 36%; flex: none; }
        .lay-full { padding: 0 !important; gap: 0 !important; }
        .lay-bgimg { position: absolute; inset: 0; }
        .lay-bgimg .lay-img { object-fit: cover; }
        .lay-overlay { position: absolute; left: 0; right: 0; bottom: 0; padding: 16cqw 4cqw 4cqw; background: linear-gradient(to top, rgba(2, 6, 23, 0.92) 28%, rgba(2, 6, 23, 0)); display: flex; flex-direction: column; align-items: center; gap: 1.5cqw; z-index: 10; }
        .lay-overlay .lay-name { color: #fff; font-size: 10cqw; text-shadow: 0 2px 4px rgba(0, 0, 0, 0.6); }
        .lay-polaroid { padding: 6cqw 6cqw 4cqw !important; background: #fffdf7 !important; box-shadow: inset 0 0 0 1px #e7e0cc; gap: 3cqw !important; }
        .lay-polaroid .lay-imgbox { flex: 1; background: #111827; padding: 0; border-radius: 1cqw; border: 0; }
        .lay-polaroid .lay-img { object-fit: cover; }
        .lay-polaroid .lay-text { flex: none; height: 27%; }
        .lay-polaroid .lay-name { font-size: 9cqw; }
        .lay-ribbon .lay-imgbox { flex: 1; }
        .lay-ribbonbar { background: linear-gradient(90deg, #b45309, #f59e0b 50%, #b45309); border-radius: 2cqw; padding: 2cqw 3cqw; text-align: center; z-index: 10; border: 0.6cqw solid #78350f; }
        .lay-ribbonbar .lay-name { color: #fff; font-size: 9.5cqw; text-shadow: 0 1px 3px rgba(0, 0, 0, 0.55); -webkit-line-clamp: 1; }
        .lay-circle { background: radial-gradient(circle at 50% 30%, #ffffff, #e2e8f0) !important; align-items: center !important; }
        .lay-ring { width: 58cqw; height: 58cqw; border-radius: 50%; overflow: hidden; border: 1.4cqw solid #d4ae44; flex: none; margin-top: 1cqw; box-shadow: 0 2cqw 4cqw rgba(0, 0, 0, 0.25); background: #fff; z-index: 10; }
        .lay-circle .lay-img { object-fit: cover; }
        .lay-circle .lay-text { flex: 1; width: 100%; }
        .lay-circle .lay-name { font-size: 10cqw; }
        .lay-photoxl { padding: 0 !important; gap: 0 !important; }
        .lay-tag { position: absolute; left: 3cqw; right: 3cqw; bottom: 3cqw; background: rgba(255, 255, 255, 0.94); border-radius: 3cqw; padding: 1.5cqw 3cqw; z-index: 10; text-align: center; box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3); }
        .lay-tag .lay-name { font-size: 7cqw; -webkit-line-clamp: 1; }
        .lay-topchips { position: absolute; top: 3cqw; left: 3cqw; right: 3cqw; display: flex; gap: 2cqw; justify-content: center; z-index: 10; }
        .lay-topchips .lay-chip { font-size: 3.6cqw; box-shadow: 0 1px 4px rgba(0, 0, 0, 0.35); }
        .lay-ficha { padding: 0 !important; gap: 0 !important; }
        .lay-bar { background: #0f2a4a; padding: 2.5cqw 3cqw; border-bottom: 1.2cqw solid #d4ae44; z-index: 10; }
        .lay-bar .lay-name { color: #fff; font-size: 8.5cqw; -webkit-line-clamp: 1; }
        .lay-ficha .lay-imgbox { flex: 1; margin: 3cqw; border: 1.2cqw solid #d4ae44; }
        .lay-foot { display: flex; justify-content: space-between; gap: 2cqw; padding: 0 3cqw 3cqw; z-index: 10; min-height: 1cqw; }
        .lay-foot .lay-chip { font-size: 3.8cqw; }
        .lay-blur { padding: 0 !important; gap: 0 !important; background: linear-gradient(135deg, #1e3a8a, #7c3aed) !important; }
        .lay-blurbg { position: absolute; inset: -6%; filter: blur(12px) brightness(0.75); }
        .lay-blurbg .lay-img { object-fit: cover; }
        .lay-blur .lay-imgbox { position: absolute; left: 12cqw; right: 12cqw; top: 5cqw; height: 50cqw; box-shadow: 0 3cqw 6cqw rgba(0, 0, 0, 0.5); border-radius: 3cqw; }
        .lay-glass { position: absolute; left: 4cqw; right: 4cqw; bottom: 4cqw; background: rgba(15, 23, 42, 0.74); border: 1px solid rgba(255, 255, 255, 0.25); border-radius: 4cqw; padding: 3cqw; display: flex; flex-direction: column; align-items: center; gap: 1.5cqw; z-index: 10; }
        .lay-glass .lay-name { color: #fff; font-size: 9cqw; }

        body.img-rot-180 .card-front-frame { transform: rotate(180deg); }
        body.img-rot-90 .card-front-frame, body.img-rot-270 .card-front-frame {
            position: absolute; left: 50%; top: 50%;
            width: 100cqh; height: 100cqw; max-width: none;
            container-type: size;
        }
        body.img-rot-90 .card-front-frame { transform: translate(-50%, -50%) rotate(90deg); }
        body.img-rot-270 .card-front-frame { transform: translate(-50%, -50%) rotate(270deg); }
        .rot-btn { padding: 4px 10px; border-radius: 8px; font-size: 11px; font-weight: 700; border: 1px solid rgba(255,255,255,.2); background: #0f172a; color: #cbd5e1; transition: all .15s; }
        .rot-btn.active { background: #f59e0b; color: #0f172a; border-color: #fbbf24; }
        #rot-options.disabled { opacity: .4; pointer-events: none; }
        #player-name-label { position: absolute; width: max-content; white-space: normal; transform-origin: center center; z-index: 8400; display: none; pointer-events: none; font-family: var(--font-display); font-weight: 700; color: #ffffff; background: rgba(9, 25, 45, 0.94); border: 2px solid rgba(235, 208, 122, 0.85); border-radius: 12px; padding: 0.12em 0.6em; text-align: center; line-height: 1.15; word-break: break-word; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5); text-shadow: 0 1px 2px rgba(0,0,0,.5); }
        .opt-disabled { opacity: .4; pointer-events: none; }
        .seg-btn { padding: 6px 12px; border-radius: 8px; font-size: 11px; font-weight: 700; border: 1px solid rgba(255,255,255,.2); background: #0f172a; color: #cbd5e1; transition: all .15s; }
        .seg-btn.active { background: #f59e0b; color: #0f172a; border-color: #fbbf24; }
        .set-card { background: rgba(30, 41, 59, 0.7); border: 1px solid rgba(255,255,255,.1); border-radius: 14px; padding: 14px; }
        .set-title { display: flex; align-items: center; gap: 8px; font-size: 12px; font-weight: 800; text-transform: uppercase; letter-spacing: .06em; color: #fcd34d; padding-bottom: 10px; margin-bottom: 12px; border-bottom: 1px solid rgba(255,255,255,.1); }
        .set-title i { font-size: 16px; }
        .set-row { display: flex; align-items: center; justify-content: space-between; gap: 12px; }
        .set-row + .set-row, .set-sub { margin-top: 12px; }
        .set-name { font-size: 13px; font-weight: 700; color: #fff; }
        .set-desc { font-size: 11px; color: #94a3b8; margin-top: 2px; }

        #banner-rot { display: flex; flex-direction: column; align-items: center; }
        body.img-rot-180 #banner-rot { transform: rotate(180deg); }
        body.img-rot-90 #banner-rot { transform: rotate(90deg); max-width: 90vh; }
        body.img-rot-270 #banner-rot { transform: rotate(270deg); max-width: 90vh; }
        body.img-rot-90 .banner-title-3d, body.img-rot-270 .banner-title-3d { font-size: clamp(2.2rem, 8vmin, 5rem); }
    </style>
</head>
<body>

    <div id="new-game-banner">
        <div id="banner-inner" class="flex flex-col items-center px-6 py-4">
            <div id="banner-rot">
                <span class="px-4 py-1 rounded-full bg-amber-400 text-slate-950 font-extrabold text-xs sm:text-sm uppercase tracking-widest mb-2 shadow-lg" id="banner-theme-pill">¡Cartas Mezcladas al Azar!</span>
                <div class="banner-title-3d">¡JUEGO NUEVO!</div>
                <p id="banner-sub-info" class="mt-2 text-sm sm:text-lg font-bold text-amber-200 drop-shadow">Preparando el mazo...</p>
            </div>
        </div>
    </div>

    <header class="relative z-30 flex items-center justify-between px-2.5 sm:px-5 py-1.5 sm:py-2 bg-slate-950/90 border-b border-white/10">
        <div class="flex items-center gap-1.5 sm:gap-2">
            <button onclick="openSettingsModal('games')" class="px-2.5 py-1 rounded-lg bg-amber-500/20 hover:bg-amber-500/30 border border-amber-400/40 text-amber-300 text-xs font-extrabold flex items-center gap-1.5 transition" title="Mis Juegos">
                <i class="ph-bold ph-folder-open text-sm"></i>
                <span id="active-game-title" class="max-w-[90px] sm:max-w-[160px] truncate">Juego 50 Cartas</span>
            </button>
            <span id="deck-counter-badge" class="text-[11px] sm:text-xs font-extrabold px-2.5 py-1 rounded-full bg-sky-500/20 text-sky-300 border border-sky-400/35">50</span>
        </div>
        <div class="hidden md:flex items-center gap-2"><span id="shuffle-toast" class="text-xs font-bold px-3 py-1 rounded-full bg-white/10 text-amber-200 border border-white/15">Listo para jugar</span></div>
        <div class="flex items-center gap-1.5 sm:gap-2">
            <button onclick="startNewGameWithAnimation()" class="px-3 sm:px-4 py-1.5 rounded-xl bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-400 hover:to-teal-400 text-slate-950 text-xs font-extrabold flex items-center gap-1.5 transition shadow-lg"><i class="ph-fill ph-sparkle text-sm"></i><span>Juego Nuevo</span></button>
            <button onclick="openLayoutSheet()" class="px-2.5 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 border border-amber-400/50 text-amber-300 text-xs font-bold flex items-center gap-1 transition" title="Cambiar formato de las cartas"><i class="ph-bold ph-squares-four text-sm"></i><span class="hidden sm:inline">Formato</span></button>
                        <button onclick="openSettingsModal('general')" class="px-2.5 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 border border-white/20 text-amber-300 text-xs font-bold flex items-center gap-1 transition" title="Configuración, Temas y Mezclas"><i class="ph-bold ph-gear-six text-sm sm:text-base"></i><span class="hidden lg:inline">Configuración</span></button>
        </div>
    </header>

    <main id="stage-container">
        <div class="gold-side-line hidden sm:block"></div>
        <div class="table-prop hidden sm:flex flex-col justify-between w-9 h-16 bg-stone-100 rounded-md p-1.5 border border-stone-300" style="top: 26px; left: 36px; transform: rotate(16deg);"><div class="grid grid-cols-2 gap-1 place-items-center h-1/2 border-b border-stone-400 pb-1"><span class="w-1.5 h-1.5 rounded-full bg-stone-800"></span><span class="w-1.5 h-1.5 rounded-full bg-stone-800"></span></div><div class="grid grid-cols-3 gap-0.5 place-items-center h-1/2 pt-1"><span class="w-1.5 h-1.5 rounded-full bg-stone-800"></span><span></span><span class="w-1.5 h-1.5 rounded-full bg-stone-800"></span><span></span><span class="w-1.5 h-1.5 rounded-full bg-stone-800"></span><span></span></div></div>
        <div class="table-prop hidden sm:flex items-center" style="top: 34%; left: 28px; transform: rotate(-12deg);"><div class="w-4 h-4 rounded-full bg-amber-900 border border-amber-700"></div><div class="w-6 h-5 bg-amber-800 -ml-1 rounded-r-lg border-r-2 border-amber-200"></div></div>
        <div class="table-prop hidden md:block w-36 h-36 bg-amber-700/80 border-4 border-amber-200/70 rounded-lg p-2" style="top: -45px; right: -45px; transform: rotate(42deg);"><div class="w-full h-full grid grid-cols-3 grid-rows-3 gap-1 bg-slate-900/60 p-1"><div class="bg-amber-400/70"></div><div class="bg-sky-900/70"></div><div class="bg-amber-400/70"></div><div class="bg-sky-900/70"></div><div class="bg-amber-400/70"></div><div class="bg-sky-900/70"></div></div></div>

        <div id="deck-zone-frame"></div>
        <div id="drop-zone-frame"></div>
        <div id="player-name-label"></div>
        <button id="card-voice-btn" onclick="speakCurrentDrawnCard()" title="Escuchar voz de la carta"><i class="ph-fill ph-speaker-high text-lg"></i></button>
        <div id="deck-click-zone" onclick="drawNextCard()" title="Toca para sacar carta"></div>
        <div id="drop-click-zone" onclick="toggleAutoPlayFromDropZone()"></div>
        <div id="game-canvas" class="relative w-full h-full z-10"></div>
    </main>

    <footer class="relative z-30 grid grid-cols-[1fr_auto_1fr] items-center px-3 sm:px-6 py-2 sm:py-2.5 bg-slate-950/95 border-t border-white/15">
        <div></div>
        <div class="flex items-center justify-center gap-1.5 sm:gap-3">
            <button id="btn-shuffle" onclick="executeRandomCheckedShuffle()" class="btn-wordwall px-4 sm:px-8 py-2 rounded-lg text-white font-bold text-xs sm:text-sm">Mezclar</button>
            <button id="btn-undo" onclick="undoLastDraw()" class="btn-wordwall px-4 sm:px-8 py-2 rounded-lg text-white font-bold text-xs sm:text-sm" disabled>Deshacer</button>
            <button id="btn-deal" onclick="drawNextCard()" class="btn-wordwall px-4 sm:px-8 py-2 rounded-lg text-white font-bold text-xs sm:text-sm"><span id="deal-btn-label">Repartir</span></button>
        </div>
        <div class="flex items-center justify-end gap-1.5 sm:gap-2 shrink-0">
            <button id="voice-toggle-btn" onclick="toggleVoice()" title="Activar / desactivar la voz al voltear" class="w-11 h-11 sm:w-12 sm:h-12 rounded-xl text-white hover:bg-white/10 flex justify-center items-center transition"><i id="mute-icon" class="ph-bold ph-speaker-slash text-2xl sm:text-3xl text-rose-400"></i></button>
            <button onclick="toggleFullScreen()" title="Pantalla Completa" class="w-8 h-8 sm:w-9 sm:h-9 rounded-lg text-white hover:bg-white/10 flex justify-center items-center transition"><i class="ph-bold ph-corners-out text-lg sm:text-xl"></i></button>
        </div>
    </footer>

    <div id="layout-sheet" class="fixed inset-x-0 bottom-0 z-[10000] hidden flex-col bg-slate-950/95 border-t-2 border-amber-400/50 shadow-2xl">
        <div class="flex items-center justify-between px-3 py-2">
            <div class="flex items-center gap-2 text-sm font-extrabold text-white"><i class="ph-bold ph-squares-four text-amber-400"></i> Formato de carta: <span id="layout-current-label" class="text-amber-300"></span></div>
            <div class="flex items-center gap-1.5">
                <button onclick="cycleLayout(-1)" class="w-8 h-8 rounded-lg bg-slate-800 hover:bg-slate-700 text-white flex items-center justify-center" title="Anterior"><i class="ph-bold ph-caret-left"></i></button>
                <button onclick="cycleLayout(1)" class="w-8 h-8 rounded-lg bg-slate-800 hover:bg-slate-700 text-white flex items-center justify-center" title="Siguiente"><i class="ph-bold ph-caret-right"></i></button>
                <button onclick="closeLayoutSheet()" class="w-8 h-8 rounded-lg bg-slate-800 hover:bg-rose-600 text-white flex items-center justify-center" title="Cerrar"><i class="ph-bold ph-x"></i></button>
            </div>
        </div>
        <div id="layout-tiles" class="flex gap-2 overflow-x-auto custom-scroll px-3 pb-3"></div>
    </div>

    <div id="settings-modal" class="fixed inset-0 z-[10000] bg-black/80 backdrop-blur-sm hidden items-center justify-center p-2 sm:p-4">
        <div class="bg-slate-900 border border-white/20 rounded-2xl max-w-4xl w-full p-4 sm:p-6 shadow-2xl flex flex-col max-h-[94dvh]">
            <div class="flex items-center justify-between pb-3 border-b border-white/10">
                <h3 class="card-title-font text-base sm:text-xl font-bold text-white flex items-center gap-2"><i class="ph-bold ph-sliders text-amber-400"></i> Configuración del Juego</h3>
                <button onclick="closeSettingsModal()" class="w-8 h-8 rounded-lg bg-slate-800 text-slate-300 hover:text-white flex items-center justify-center"><i class="ph-bold ph-x"></i></button>
            </div>
            <div class="flex gap-1.5 sm:gap-2 my-3 border-b border-white/10 pb-3 overflow-x-auto">
                <button id="tab-btn-general" onclick="switchSettingsTab('general')" class="px-3 sm:px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 transition shrink-0"><i class="ph-bold ph-sliders-horizontal"></i> Ajustes</button>
                <button id="tab-btn-cards" onclick="switchSettingsTab('cards')" class="px-3 sm:px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 transition shrink-0"><i class="ph-bold ph-cards"></i> Cartas</button>
                <button id="tab-btn-themes" onclick="switchSettingsTab('themes')" class="px-3 sm:px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 transition shrink-0"><i class="ph-bold ph-palette"></i> Temas</button>
                <button id="tab-btn-shuffles" onclick="switchSettingsTab('shuffles')" class="px-3 sm:px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 transition shrink-0"><i class="ph-bold ph-shuffle"></i> Mezclas</button>
                <button id="tab-btn-games" onclick="switchSettingsTab('games')" class="px-3 sm:px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 transition shrink-0"><i class="ph-bold ph-folders"></i> Juegos</button>
            </div>

            <div id="tab-content-cards" class="hidden flex-1 overflow-y-auto custom-scroll pr-1 flex-col gap-3">
                <div class="bg-slate-800/70 p-3 rounded-xl border border-white/10 space-y-2.5">
                    <div class="flex flex-wrap items-center justify-between gap-2">
                        <span class="text-xs font-bold text-amber-300">Juego actual: <b id="editing-game-label" class="text-white"></b></span>
                        <div class="flex flex-wrap gap-1.5">
                            <button onclick="resizeCurrentDeckCount(20)" class="px-2.5 py-1 rounded-lg bg-sky-500/20 text-sky-300 border border-sky-400/30 text-[11px] font-bold">20 Cartas</button>
                            <button onclick="resizeCurrentDeckCount(40)" class="px-2.5 py-1 rounded-lg bg-sky-500/20 text-sky-300 border border-sky-400/30 text-[11px] font-bold">40 Cartas</button>
                            <button onclick="resizeCurrentDeckCount(60)" class="px-2.5 py-1 rounded-lg bg-sky-500/20 text-sky-300 border border-sky-400/30 text-[11px] font-bold">60 Cartas</button>
                            <button onclick="resizeCurrentDeckCount(100)" class="px-2.5 py-1 rounded-lg bg-sky-500/20 text-sky-300 border border-sky-400/30 text-[11px] font-bold">100 Cartas</button>
                            <button onclick="resizeCurrentDeckCount(200)" class="px-2.5 py-1 rounded-lg bg-sky-500/20 text-sky-300 border border-sky-400/30 text-[11px] font-bold">200 Cartas</button>
                        </div>
                    </div>
                    <div class="grid grid-cols-1 sm:grid-cols-3 gap-2 pt-2 border-t border-white/10">
                        <input id="new-card-text" type="text" placeholder="Nombre (Ej: VEGETA o Carta 1)" class="px-3 py-1.5 rounded-lg bg-slate-900 border border-white/20 text-white text-xs">
                        <div class="flex gap-1">
                            <input id="new-card-img-url" type="text" placeholder="URL o sube foto ->" class="flex-1 min-w-0 px-2.5 py-1.5 rounded-lg bg-slate-900 border border-white/20 text-amber-200 text-xs">
                            <label class="px-2.5 py-1.5 rounded-lg bg-amber-500 hover:bg-amber-400 text-slate-950 font-extrabold cursor-pointer flex items-center gap-1 text-xs shrink-0" title="Subir foto desde tu celular o PC"><i class="ph-bold ph-camera"></i> Foto<input type="file" accept="image/*" class="hidden" onchange="handleNewCardImageUpload(event)"></label>
                        </div>
                        <div class="flex gap-1">
                            <input id="new-card-voice-text" type="text" placeholder="Voz (Opcional)" class="flex-1 min-w-0 px-2.5 py-1.5 rounded-lg bg-slate-900 border border-white/20 text-white text-xs">
                            <button onclick="addNewCustomCard()" class="px-3 py-1.5 rounded-lg bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-extrabold text-xs shrink-0">+ Añadir</button>
                        </div>
                    </div>
                </div>
                <div class="flex items-center justify-between px-1"><span class="text-xs font-bold text-slate-300">Cartas colocadas (<span id="editor-card-count">0</span>)</span></div>
                <div id="cards-editor-list" class="space-y-2 pb-2"></div>
            </div>

            <div id="tab-content-themes" class="hidden flex-1 overflow-y-auto custom-scroll pr-1 space-y-3">
                <div class="flex flex-wrap items-center justify-between gap-2 bg-slate-800/60 p-3 rounded-xl border border-white/10"><p class="text-xs text-slate-300"><b class="text-amber-300">10 Temas al Azar en Juego Nuevo:</b></p><div class="flex gap-2"><button onclick="toggleAllThemes(true)" class="px-2.5 py-1 rounded-lg bg-amber-500/20 text-amber-300 border border-amber-400/30 text-xs font-bold">Marcar los 10</button><button onclick="toggleAllThemes(false)" class="px-2.5 py-1 rounded-lg bg-slate-700 text-slate-300 text-xs font-bold">Dejar 1</button></div></div>
                <div id="themes-checkbox-grid" class="grid grid-cols-1 sm:grid-cols-2 gap-2.5"></div>
                </div>

            <div id="tab-content-general" class="hidden flex-1 overflow-y-auto custom-scroll pr-1 flex-col gap-3">

                <!-- VOZ -->
                <div class="set-card">
                    <div class="set-title"><i class="ph-bold ph-speaker-high"></i> Voz</div>
                    <label class="set-row cursor-pointer">
                        <div>
                            <div class="set-name">Decir voz al voltear</div>
                            <div class="set-desc">Lee únicamente el nombre de la carta (ej: Marge, Bart, Perro...). También se activa con la bocina de abajo.</div>
                        </div>
                        <input id="auto-speak-toggle" type="checkbox" onchange="toggleAutoSpeak(this.checked)" class="w-5 h-5 accent-amber-500 shrink-0">
                    </label>
                    <div class="set-sub">
                        <div class="set-name mb-1.5">Voz en español</div>
                        <div class="flex gap-2">
                            <select id="voice-select" onchange="setSpeechVoice(this.value)" class="flex-1 min-w-0 px-3 py-2 rounded-lg bg-slate-900 border border-white/20 text-white text-xs"></select>
                            <button onclick="testSpeechVoice()" class="px-3 py-2 rounded-lg bg-sky-500 hover:bg-sky-400 text-slate-950 font-extrabold text-xs flex items-center gap-1.5 shrink-0"><i class="ph-bold ph-play"></i> Probar</button>
                        </div>
                        <div id="voice-hint" class="set-desc"></div>
                    </div>
                </div>

                <!-- NOMBRE DEL JUGADOR -->
                <div class="set-card">
                    <div class="set-title"><i class="ph-bold ph-user-circle"></i> Nombre del jugador (Firebase)</div>
                    <label class="set-row cursor-pointer">
                        <div>
                            <div class="set-name">Sacar el nombre fuera de la carta</div>
                            <div class="set-desc">Activado: el nombre sale fuera de la carta que salió. Desactivado: queda dentro de la carta con el formato que elegiste (Clásica, Foto gigante, etc.).</div>
                        </div>
                        <input id="player-outside-toggle" type="checkbox" onchange="setPlayerLabelOutside(this.checked)" class="w-5 h-5 accent-amber-500 shrink-0">
                    </label>
                    <div id="player-label-options" class="opt-disabled">
                        <div class="set-sub">
                            <div class="set-row">
                                <div class="set-name">Tamaño de la letra</div>
                                <span id="player-size-badge" class="px-2.5 py-1 rounded-lg bg-amber-500/20 border border-amber-400/40 text-amber-300 font-extrabold text-xs shrink-0">24 px</span>
                            </div>
                            <div class="flex items-center gap-3 mt-2">
                                <span class="text-[11px] font-bold text-slate-400">A</span>
                                <input id="player-size-slider" type="range" min="12" max="80" step="1" value="24" oninput="setPlayerLabelSize(this.value)" class="flex-1 accent-amber-400 cursor-pointer">
                                <span class="text-base font-bold text-slate-400">A</span>
                            </div>
                            <div class="flex flex-wrap gap-1.5 mt-2"><button onclick="setPlayerLabelSize(16)" class="px-2.5 py-1 rounded-lg bg-slate-900 hover:bg-slate-700 border border-white/15 text-[11px] font-bold text-amber-300">Pequeño</button><button onclick="setPlayerLabelSize(24)" class="px-2.5 py-1 rounded-lg bg-slate-900 hover:bg-slate-700 border border-white/15 text-[11px] font-bold text-amber-300">Normal</button><button onclick="setPlayerLabelSize(36)" class="px-2.5 py-1 rounded-lg bg-slate-900 hover:bg-slate-700 border border-white/15 text-[11px] font-bold text-amber-300">Grande</button><button onclick="setPlayerLabelSize(52)" class="px-2.5 py-1 rounded-lg bg-slate-900 hover:bg-slate-700 border border-white/15 text-[11px] font-bold text-amber-300">Muy grande</button></div>
                        </div>
                        <div class="set-sub">
                            <div class="set-name mb-1.5">Posición respecto a la carta</div>
                            <div class="flex flex-wrap gap-1.5">
                                <button type="button" id="pos-btn-north" onclick="setPlayerLabelPos('north')" class="seg-btn">⬆ Norte (arriba)</button>
                                <button type="button" id="pos-btn-south" onclick="setPlayerLabelPos('south')" class="seg-btn">⬇ Sur (abajo)</button>
                                <button type="button" id="pos-btn-east" onclick="setPlayerLabelPos('east')" class="seg-btn">➡ Derecha</button>
                                <button type="button" id="pos-btn-west" onclick="setPlayerLabelPos('west')" class="seg-btn">⬅ Izquierda</button>
                            </div>
                        </div>
                        <div class="set-sub">
                            <div class="set-row">
                                <div class="set-name">Separación de la carta</div>
                                <span id="player-gap-badge" class="px-2.5 py-1 rounded-lg bg-sky-500/20 border border-sky-400/40 text-sky-300 font-extrabold text-xs shrink-0">10 px</span>
                            </div>
                            <div class="flex items-center gap-3 mt-2">
                                <span class="text-[11px] font-bold text-slate-400">0</span>
                                <input id="player-gap-slider" type="range" min="0" max="80" step="1" value="10" oninput="setPlayerLabelGap(this.value)" class="flex-1 accent-sky-400 cursor-pointer">
                                <span class="text-[11px] font-bold text-slate-400">80</span>
                            </div>
                            <div class="flex flex-wrap gap-1.5 mt-2"><button onclick="setPlayerLabelGap(0)" class="px-2.5 py-1 rounded-lg bg-slate-900 hover:bg-slate-700 border border-white/15 text-[11px] font-bold text-sky-300">0 px</button><button onclick="setPlayerLabelGap(10)" class="px-2.5 py-1 rounded-lg bg-slate-900 hover:bg-slate-700 border border-white/15 text-[11px] font-bold text-sky-300">10 px</button><button onclick="setPlayerLabelGap(20)" class="px-2.5 py-1 rounded-lg bg-slate-900 hover:bg-slate-700 border border-white/15 text-[11px] font-bold text-sky-300">20 px</button><button onclick="setPlayerLabelGap(40)" class="px-2.5 py-1 rounded-lg bg-slate-900 hover:bg-slate-700 border border-white/15 text-[11px] font-bold text-sky-300">40 px</button></div>
                        </div>
                    </div>
                </div>

                <!-- GIRO DE CARTAS -->
                <div class="set-card">
                    <div class="set-title"><i class="ph-bold ph-arrows-clockwise"></i> Girar cartas</div>
                    <label class="set-row cursor-pointer">
                        <div>
                            <div class="set-name">Girar foto y textos de la carta</div>
                            <div class="set-desc">La foto, los textos, el nombre del jugador (si está fuera de la carta) y el aviso de "Juego Nuevo" salen girados (sirve en pantalla horizontal o vertical). Apagado = normal.</div>
                        </div>
                        <input id="rotate-img-toggle" type="checkbox" onchange="toggleImageRotation(this.checked)" class="w-5 h-5 accent-amber-500 shrink-0">
                    </label>
                    <div id="rot-options" class="flex flex-wrap items-center gap-1.5 set-sub disabled">
                        <span class="text-[11px] font-bold text-slate-400 mr-1">Giro:</span>
                        <button type="button" id="rot-btn-90" onclick="setImageRotation(90)" class="rot-btn">↻ 90° derecha</button>
                        <button type="button" id="rot-btn-270" onclick="setImageRotation(270)" class="rot-btn">↺ 90° izquierda</button>
                        <button type="button" id="rot-btn-180" onclick="setImageRotation(180)" class="rot-btn">⟲ 180°</button>
                    </div>
                </div>

                <!-- JUEGO AUTOMÁTICO -->
                <div class="set-card">
                    <div class="set-title"><i class="ph-bold ph-timer"></i> Juego automático</div>
                    <div class="set-row">
                        <div>
                            <div class="set-name">Velocidad</div>
                            <div class="set-desc">Se activa o pausa al tocar el lado donde caen las cartas salidas</div>
                        </div>
                        <span id="auto-speed-badge" class="px-2.5 py-1 rounded-lg bg-emerald-500/20 border border-emerald-400/40 text-emerald-300 font-extrabold text-xs shrink-0">Cada 3.5 s</span>
                    </div>
                    <div class="flex items-center gap-3 mt-2">
                        <span class="text-[11px] font-bold text-slate-400">Rápido (1s)</span>
                        <input id="auto-speed-slider" type="range" min="1" max="15" step="0.5" value="3.5" oninput="updateAutoPlaySpeed(this.value)" class="flex-1 accent-emerald-400 cursor-pointer">
                        <span class="text-[11px] font-bold text-slate-400">Lento (15s)</span>
                    </div>
                    <div class="flex flex-wrap gap-1.5 mt-2"><button onclick="updateAutoPlaySpeed(1.5)" class="px-2.5 py-1 rounded-lg bg-slate-900 hover:bg-slate-700 border border-white/15 text-[11px] font-bold text-amber-300">⚡ 1.5s</button><button onclick="updateAutoPlaySpeed(2.5)" class="px-2.5 py-1 rounded-lg bg-slate-900 hover:bg-slate-700 border border-white/15 text-[11px] font-bold text-amber-300">🚀 2.5s</button><button onclick="updateAutoPlaySpeed(3.5)" class="px-2.5 py-1 rounded-lg bg-slate-900 hover:bg-slate-700 border border-white/15 text-[11px] font-bold text-emerald-300">👍 3.5s</button><button onclick="updateAutoPlaySpeed(5)" class="px-2.5 py-1 rounded-lg bg-slate-900 hover:bg-slate-700 border border-white/15 text-[11px] font-bold text-sky-300">🐢 5s</button><button onclick="updateAutoPlaySpeed(7)" class="px-2.5 py-1 rounded-lg bg-slate-900 hover:bg-slate-700 border border-white/15 text-[11px] font-bold text-sky-300">🕒 7s</button><button onclick="updateAutoPlaySpeed(10)" class="px-2.5 py-1 rounded-lg bg-slate-900 hover:bg-slate-700 border border-white/15 text-[11px] font-bold text-sky-300">⏳ 10s</button></div>
                </div>

                <!-- AMARRE -->
                <div class="set-card">
                    <div class="set-title"><i class="ph-bold ph-lock-key"></i> Bloqueo por Amarre</div>
                    <label class="set-row cursor-pointer">
                        <div>
                            <div class="set-name">Bloquear mazo cuando amarre (falta 1 carta)</div>
                            <div class="set-desc">Impide sacar cartas por unos segundos cuando una familia queda a 1 carta en el Bingo</div>
                        </div>
                        <input id="amarre-lock-toggle" type="checkbox" checked onchange="toggleAmarreLock(this.checked)" class="w-5 h-5 accent-amber-500 shrink-0">
                    </label>
                    <div class="set-row set-sub">
                        <span class="set-name">Tiempo sin poder sacar cartas</span>
                        <span id="amarre-time-badge" class="px-2.5 py-1 rounded-lg bg-amber-500/20 border border-amber-400/40 text-amber-300 font-extrabold text-xs shrink-0">6 s</span>
                    </div>
                    <div class="flex items-center gap-3 mt-2">
                        <span class="text-[11px] font-bold text-slate-400">1s</span>
                        <input id="amarre-time-slider" type="range" min="1" max="30" step="1" value="6" oninput="updateAmarreLockTime(this.value)" class="flex-1 accent-amber-400 cursor-pointer">
                        <span class="text-[11px] font-bold text-slate-400">30s</span>
                    </div>
                    <div class="flex flex-wrap gap-1.5 mt-2"><button onclick="updateAmarreLockTime(3)" class="px-2.5 py-1 rounded-lg bg-slate-900 hover:bg-slate-700 border border-white/15 text-[11px] font-bold text-amber-300">⚡ 3s</button><button onclick="updateAmarreLockTime(5)" class="px-2.5 py-1 rounded-lg bg-slate-900 hover:bg-slate-700 border border-white/15 text-[11px] font-bold text-amber-300">⏱️ 5s</button><button onclick="updateAmarreLockTime(6)" class="px-2.5 py-1 rounded-lg bg-slate-900 hover:bg-slate-700 border border-white/15 text-[11px] font-bold text-emerald-300">👍 6s</button><button onclick="updateAmarreLockTime(8)" class="px-2.5 py-1 rounded-lg bg-slate-900 hover:bg-slate-700 border border-white/15 text-[11px] font-bold text-sky-300">⏳ 8s</button><button onclick="updateAmarreLockTime(10)" class="px-2.5 py-1 rounded-lg bg-slate-900 hover:bg-slate-700 border border-white/15 text-[11px] font-bold text-sky-300">🔒 10s</button><button onclick="updateAmarreLockTime(15)" class="px-2.5 py-1 rounded-lg bg-slate-900 hover:bg-slate-700 border border-white/15 text-[11px] font-bold text-rose-300">🛑 15s</button></div>
                </div>
            </div>

            <div id="tab-content-shuffles" class="hidden flex-1 overflow-y-auto custom-scroll pr-1 space-y-3">
                <div class="flex flex-wrap items-center justify-between gap-2 bg-slate-800/60 p-3 rounded-xl border border-white/10"><p class="text-xs text-slate-300"><b class="text-amber-300">10 Mezclas al Azar sin Repetición:</b></p><div class="flex gap-2"><button onclick="toggleAllShuffles(true)" class="px-2.5 py-1 rounded-lg bg-amber-500/20 text-amber-300 border border-amber-400/30 text-xs font-bold">Marcar las 10</button><button onclick="toggleAllShuffles(false)" class="px-2.5 py-1 rounded-lg bg-slate-700 text-slate-300 text-xs font-bold">Dejar 1</button></div></div>
                <div id="shuffle-checkbox-grid" class="grid grid-cols-1 sm:grid-cols-2 gap-2"></div>
            </div>

            <div id="tab-content-games" class="hidden flex-1 overflow-y-auto custom-scroll pr-1 space-y-4">
                <div class="bg-slate-800/80 p-3.5 rounded-xl border border-white/10 space-y-3">
                    <h4 class="text-xs font-bold uppercase tracking-wider text-amber-300">Crear un Nuevo Juego</h4>
                    <div class="flex flex-wrap gap-2">
                        <input id="new-game-name" type="text" placeholder="Nombre" class="flex-1 min-w-[180px] px-3 py-2 rounded-lg bg-slate-900 border border-white/20 text-white text-xs">
                        <select id="new-game-count" class="px-3 py-2 rounded-lg bg-slate-900 border border-white/20 text-amber-300 text-xs font-bold"><option value="20">20</option><option value="40">40</option><option value="50" selected>50</option><option value="100">100</option><option value="200">200</option></select>
                        <button onclick="createNewSavedGame()" class="px-4 py-2 rounded-xl bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-extrabold text-xs flex items-center gap-1.5 shadow"><i class="ph-bold ph-plus-circle"></i> Crear</button>
                    </div>
                </div>
                <div><h4 class="text-xs font-bold uppercase tracking-wider text-slate-300 mb-2">Mis Juegos Guardados</h4><div id="saved-games-list" class="grid grid-cols-1 sm:grid-cols-2 gap-2.5"></div></div>
                <div class="bg-sky-950/60 border border-sky-400/30 p-3.5 rounded-xl space-y-2.5">
                    <div class="flex flex-wrap gap-2 pt-1">
                        <button onclick="exportAllGamesJSON()" class="px-3 py-1.5 rounded-lg bg-sky-500 hover:bg-sky-400 text-slate-950 font-extrabold text-xs flex items-center gap-1.5"><i class="ph-bold ph-download-simple"></i> Exportar .json</button>
                        <label class="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 border border-white/20 text-white font-bold text-xs flex items-center gap-1.5 cursor-pointer"><i class="ph-bold ph-upload-simple text-amber-300"></i> Importar<input type="file" accept=".json" class="hidden" onchange="importAllGamesJSON(event)"></label>
                    </div>
                </div>
            </div>

            <div class="flex items-center justify-between pt-3 mt-2 border-t border-white/10">
                <button onclick="closeSettingsModal(); startNewGameWithAnimation();" class="px-4 py-2 rounded-xl bg-gradient-to-r from-emerald-500 to-teal-500 text-slate-950 font-extrabold text-xs sm:text-sm flex items-center gap-1.5 shadow-lg"><i class="ph-bold ph-sparkle"></i> Guardar y Lanzar</button>
                <button onclick="closeSettingsModal()" class="px-5 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-white font-bold text-xs sm:text-sm">Cerrar</button>
            </div>
        </div>
    </div>

    <script src="https://www.gstatic.com/firebasejs/9.22.2/firebase-app-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/9.22.2/firebase-database-compat.js"></script>

    <script>
        const firebaseConfig = {
            apiKey: "AIzaSyBgH2Bi3ihJLhSM6NVTM_r5WzNv3OlAypc",
            authDomain: "bingo-tik-tok.firebaseapp.com",
            databaseURL: "https://bingo-tik-tok-default-rtdb.firebaseio.com",
            projectId: "bingo-tik-tok",
            storageBucket: "bingo-tik-tok.firebasestorage.app",
            messagingSenderId: "264287384202",
            appId: "1:264287384202:web:f1b66815e24a88fcda7373",
            measurementId: "G-51121E4MBR"
        };
        firebase.initializeApp(firebaseConfig);
        const db = firebase.database();

        // ==========================================
        // LÓGICA DE FIREBASE - SINCRONIZACIÓN ESTABLE
        // ==========================================
        let ultimoTableroActivoFB = null;
        let ultimaSeleccionActualFB = null;
        let actualizacionPendienteFB = false;
        // NUEVO: control de sincronización estable
        let mazoYaSincronizado = false;
        let firmaSeleccionActual = '';
        let hayNuevaSeleccionPendiente = false;
        let jugadoresPorFilaFB = {};
        let casillasPorFamiliaFB = 7;
        const imagePreloadCache = new Map();

        function normalizarUrlImagen(rawUrl) {
            if (!rawUrl) return '';
            let u = String(rawUrl).trim().replace(/^["']+|["']+$/g, '');
            if (!u) return '';
            // Convertir links de GitHub blob a raw.githubusercontent.com automáticamente
            if (u.includes('github.com/') && u.includes('/blob/')) {
                u = u.replace('https://github.com/', 'https://raw.githubusercontent.com/').replace('/blob/', '/');
            }
            // Convertir links compartidos de Google Drive a enlace directo de imagen
            const driveMatch = u.match(/drive\.google\.com\/file\/d\/([^/\?]+)/);
            if (driveMatch && driveMatch[1]) {
                u = `https://lh3.googleusercontent.com/d/${driveMatch[1]}`;
            }
            // Convertir links de Dropbox ?dl=0 a ?raw=1
            if (u.includes('dropbox.com/') && u.includes('?dl=0')) {
                u = u.replace('?dl=0', '?raw=1');
            }
            return u;
        }

        function precargarImagenUrl(url) {
            const clean = normalizarUrlImagen(url);
            if (!clean || imagePreloadCache.has(clean)) return;
            const img = new Image();
            img.referrerPolicy = 'no-referrer';
            img.decoding = 'async';
            img.src = clean;
            imagePreloadCache.set(clean, img);
        }

let cartasInteligentesFB = { activo: false, familias: [] };
        let cantidadPremiosFB = 3;
        let mazoFueAcomodadoInteligente = false;

        function barajarArrayInteligente(arr) {
            for (let i = arr.length - 1; i > 0; i--) {
                const j = Math.floor(Math.random() * (i + 1));
                [arr[i], arr[j]] = [arr[j], arr[i]];
            }
            return arr;
        }

        function acomodarMazoInteligente() {
            if (!cartasInteligentesFB || !cartasInteligentesFB.activo) return false;
            const elegidasRaw = Array.isArray(cartasInteligentesFB.familias)
                ? cartasInteligentesFB.familias.map(Number).filter(n => !isNaN(n))
                : [];
            if (elegidasRaw.length === 0 || deckQueue.length <= 1) return false;

            const restantesPorFam = new Map();
            const sinFamilia = [];
            const todasLasFamiliasJuego = new Set();

            cardsData.forEach(c => {
                if (c && c.famIdx !== undefined && c.famIdx !== null) {
                    todasLasFamiliasJuego.add(Number(c.famIdx));
                }
            });

            deckQueue.forEach(cardId => {
                const cObj = allCardsMap.get(cardId);
                if (!cObj || !cObj.data || cObj.data.famIdx === undefined || cObj.data.famIdx === null) {
                    sinFamilia.push(cardId);
                    return;
                }
                const fIdx = Number(cObj.data.famIdx);
                if (!restantesPorFam.has(fIdx)) restantesPorFam.set(fIdx, []);
                restantesPorFam.get(fIdx).push(cardId);
            });

            if (restantesPorFam.size <= 1) return false;

            let yaGanaron = 0;
            todasLasFamiliasJuego.forEach(fIdx => {
                if (!restantesPorFam.has(fIdx) || restantesPorFam.get(fIdx).length === 0) {
                    yaGanaron++;
                }
            });

            const totalPremios = Math.max(1, cantidadPremiosFB || 3);
            const premiosDisponibles = Math.max(1, totalPremios - yaGanaron);

            const elegidasValidas = [];
            elegidasRaw.forEach(fIdx => {
                if (restantesPorFam.has(fIdx) && restantesPorFam.get(fIdx).length > 0 && !elegidasValidas.includes(fIdx)) {
                    elegidasValidas.push(fIdx);
                }
            });
            if (elegidasValidas.length === 0) return false;

            const ganadorasSeleccionadas = elegidasValidas.slice(0, premiosDisponibles);
            const otrasFamiliasDisponibles = Array.from(restantesPorFam.keys()).filter(fIdx => !ganadorasSeleccionadas.includes(fIdx));
            barajarArrayInteligente(otrasFamiliasDisponibles);

            while (ganadorasSeleccionadas.length < premiosDisponibles && otrasFamiliasDisponibles.length > 0) {
                ganadorasSeleccionadas.push(otrasFamiliasDisponibles.shift());
            }

            // Asignar al azar cualquiera de los 3 premios (1°, 2° o 3°)
            barajarArrayInteligente(ganadorasSeleccionadas);

            const perdedoras = Array.from(restantesPorFam.keys()).filter(fIdx => !ganadorasSeleccionadas.includes(fIdx));
            restantesPorFam.forEach(lista => barajarArrayInteligente(lista));

            const colaFinalPerdedoras = [];
            const cartasSegurasPerdedoras = [...sinFamilia];

            perdedoras.forEach(fIdx => {
                const lista = restantesPorFam.get(fIdx);
                if (!lista || lista.length === 0) return;
                colaFinalPerdedoras.push(lista.pop());
                cartasSegurasPerdedoras.push(...lista);
            });

            barajarArrayInteligente(cartasSegurasPerdedoras);
            barajarArrayInteligente(colaFinalPerdedoras);

            const cartasCierreGanadoras = [];
            const cartasAmarreGanadoras = [];
            const cartasInicialesGanadoras = [];

            ganadorasSeleccionadas.forEach(fIdx => {
                const lista = restantesPorFam.get(fIdx);
                if (!lista || lista.length === 0) return;
                cartasCierreGanadoras.push(lista.pop());
                if (lista.length > 0) {
                    cartasAmarreGanadoras.push(lista.pop());
                }
                cartasInicialesGanadoras.push(...lista);
            });

            const bloquesEntrePremios = cartasCierreGanadoras.map(() => {
                const cant = Math.min(cartasSegurasPerdedoras.length, 2 + Math.floor(Math.random() * 2));
                return cartasSegurasPerdedoras.splice(0, cant);
            });

            const corte = Math.floor(cartasSegurasPerdedoras.length * 0.75);
            const segurasInicio = cartasSegurasPerdedoras.slice(0, corte);
            const segurasPreFinal = cartasSegurasPerdedoras.slice(corte);

            const cuerpoPrincipal = barajarArrayInteligente([...cartasInicialesGanadoras, ...segurasInicio]);
            const zonaAmarres = barajarArrayInteligente([...cartasAmarreGanadoras, ...segurasPreFinal]);

            const nuevaCola = [...cuerpoPrincipal, ...zonaAmarres];
            cartasCierreGanadoras.forEach((cartaGanadora, idx) => {
                nuevaCola.push(...bloquesEntrePremios[idx]);
                nuevaCola.push(cartaGanadora);
            });
            nuevaCola.push(...colaFinalPerdedoras);

            if (nuevaCola.length === deckQueue.length) {
                deckQueue = nuevaCola;
                mazoFueAcomodadoInteligente = true;
                return true;
            }
            return false;
        }

        db.ref('bingo/configuracion/premios').on('value', snap => {
            const raw = snap.val();
            let lista = [];
            if (Array.isArray(raw)) lista = raw.filter(Boolean);
            else if (raw && typeof raw === 'object') lista = Object.values(raw).filter(Boolean);
            cantidadPremiosFB = lista.length > 0 ? lista.length : 3;
        });

        db.ref('bingo/anotarse/cartas_inteligentes').on('value', snap => {
            const val = snap.val();
            cartasInteligentesFB = (val && typeof val === 'object')
                ? {
                    activo: Boolean(val.activo),
                    familias: Array.isArray(val.familias) ? val.familias.map(Number).filter(n => !isNaN(n)) : []
                }
                : { activo: false, familias: [] };

            if (typeof isShuffling !== 'undefined' && !isShuffling && deckQueue.length > 1) {
                if (cartasInteligentesFB.activo && cartasInteligentesFB.familias.length > 0) {
                    barajarArrayInteligente(deckQueue);
                    if (acomodarMazoInteligente()) {
                        syncStaticPositions(false);
                    }
                } else if (mazoFueAcomodadoInteligente) {
                    barajarArrayInteligente(deckQueue);
                    mazoFueAcomodadoInteligente = false;
                    syncStaticPositions(false);
                }
            }
        });

        function precargarImagenesDelMazo() {
            if (cartasInteligentesFB && cartasInteligentesFB.activo && cartasInteligentesFB.familias.length > 0) {
                if (acomodarMazoInteligente()) {
                    syncStaticPositions(false);
                }
            }
            // Primero precargar las próximas 10 cartas a salir inmediatamente
            const primeras = deckQueue.slice(0, 10);
            primeras.forEach(id => {
                const c = allCardsMap.get(id);
                if (c && c.data && c.data.image) precargarImagenUrl(c.data.image);
            });
            // Luego precargar el resto en segundo plano sin bloquear el celular
            setTimeout(() => {
                cardsData.forEach(item => {
                    if (item && item.image) precargarImagenUrl(item.image);
                });
            }, 300);
        }

        function obtenerJugadorAnotadoEnFila(famIdx) {
            if (famIdx === undefined || famIdx === null) return '';
            const val = jugadoresPorFilaFB[famIdx] !== undefined ? jugadoresPorFilaFB[famIdx] : jugadoresPorFilaFB[String(famIdx)];
            return val ? String(val).trim() : '';
        }

        function actualizarNombresPersonasEnCartasVivas() {
            cardsData.forEach((item) => {
                if (item.famIdx !== undefined && item.famIdx !== null) {
                    const jugador = obtenerJugadorAnotadoEnFila(item.famIdx);
                    item.playerName = jugador;
                    const nombreImagen = item.photoName || item.text || '';
                    // La voz SOLO dice el nombre que se le dio en el ADMIN
                    item.voiceText = nombreImagen;
                }
            });

            allCardsMap.forEach((cardObj) => {
                if (!cardObj || !cardObj.el || !cardObj.data) return;
                const item = cardObj.data;
                const jugadorMostrar = item.playerName ? String(item.playerName).trim() : '';
                const personajeMostrar = (item.photoName && String(item.photoName).trim() !== '')
                    ? String(item.photoName).trim()
                    : (item.text || '');
                const familiaMostrar = item.family ? String(item.family).trim() : '';

                const playerEl = cardObj.el.querySelector('.card-player-name');
                if (playerEl) {
                    playerEl.textContent = jugadorMostrar;
                    playerEl.title = jugadorMostrar;
                    if (jugadorMostrar) {
                        playerEl.classList.remove('hidden');
                    } else {
                        playerEl.classList.add('hidden');
                    }
                }

                const photoEl = cardObj.el.querySelector('.card-photo-name');
                if (photoEl) {
                    photoEl.textContent = personajeMostrar;
                    photoEl.title = personajeMostrar;
                }

                const familyEl = cardObj.el.querySelector('.card-family-name');
                if (familyEl) {
                    familyEl.textContent = familiaMostrar;
                    familyEl.title = familiaMostrar;
                    if (familiaMostrar) {
                        familyEl.classList.remove('hidden');
                    } else {
                        familyEl.classList.add('hidden');
                    }
                }
            });
            if (typeof updatePlayerLabel === 'function') updatePlayerLabel();
        }

        function firmaDeSeleccion(seleccion) {
            try {
                const ordenada = {};
                Object.keys(seleccion || {}).sort().forEach(k => {
                    const v = seleccion[k];
                    ordenada[k] = Array.isArray(v) ? v.map(String) : Object.values(v || {}).map(String);
                });
                return JSON.stringify(ordenada);
            } catch (e) {
                return '';
            }
        }

        function mazoIntacto() {
            return drawnStack.length === 0 && deckQueue.length === cardsData.length;
        }

        function construirCartasDesdeFirebase(payload, seleccionActual) {
            const nombreJuego = payload.nombreJuego || 'Juego desde Admin';
            const idJuego = payload.idJuego || 'game-firebase-admin';
            const rawData = payload.data || [];
            const listaFamilias = Array.isArray(rawData) ? rawData : Object.values(rawData);
            const nuevasCartas = [];

            const mapaGlobalFotos = new Map();
            listaFamilias.forEach((famObj, idx) => {
                if (!famObj || !famObj.fotos) return;
                const nombreFam = String(famObj.nombre || `FAMILIA ${idx + 1}`).trim();
                const arrFotos = Array.isArray(famObj.fotos) ? famObj.fotos : Object.values(famObj.fotos || {});
                arrFotos.forEach((f, fIdx) => {
                    if (!f) return;
                    const rawUrl = typeof f === 'string' ? f : f.url;
                    const urlLimpia = normalizarUrlImagen(rawUrl);
                    if (!urlLimpia) return;
                    const idKey = (f.id && String(f.id).trim() !== '') ? String(f.id).trim() : `auto-${idx}-${fIdx}`;
                    const fotoNorm = {
                        id: idKey,
                        url: urlLimpia,
                        nombre: (f && f.nombre) ? String(f.nombre).trim() : ''
                    };
                    mapaGlobalFotos.set(idKey, { foto: fotoNorm, nombreFamilia: nombreFam, famIdx: idx });
                });
            });

            const tieneSeleccion = seleccionActual && typeof seleccionActual === 'object' && Object.keys(seleccionActual).length > 0;

            listaFamilias.forEach((familiaObj, famIdx) => {
                if (!familiaObj) return;
                const nombreFamilia = String(familiaObj.nombre || `FAMILIA ${famIdx + 1}`).trim();
                const arrFotosRaw = Array.isArray(familiaObj.fotos) ? familiaObj.fotos : Object.values(familiaObj.fotos || {});
                const arrFotos = arrFotosRaw.map((f, fIdx) => {
                    if (!f) return null;
                    const rawUrl = typeof f === 'string' ? f : f.url;
                    const urlLimpia = normalizarUrlImagen(rawUrl);
                    if (!urlLimpia) return null;
                    const idKey = (f.id && String(f.id).trim() !== '') ? String(f.id).trim() : `auto-${famIdx}-${fIdx}`;
                    return {
                        id: idKey,
                        url: urlLimpia,
                        nombre: (f && f.nombre) ? String(f.nombre).trim() : ''
                    };
                }).filter(Boolean);

                const usadosEnFamilia = new Set();
                const metaPorFamilia = Math.min(arrFotos.length, casillasPorFamiliaFB || 7);

                if (tieneSeleccion) {
                    const rawIds = seleccionActual[famIdx] !== undefined ? seleccionActual[famIdx] : seleccionActual[String(famIdx)];
                    const idsSeleccionados = rawIds ? (Array.isArray(rawIds) ? rawIds : Object.values(rawIds)) : [];

                    idsSeleccionados.forEach((idFoto, i) => {
                        const idBuscado = String(idFoto || '').trim();
                        if (!idBuscado) return;

                        let idxEncontrado = arrFotos.findIndex((f, idxF) => !usadosEnFamilia.has(idxF) && f.id === idBuscado);
                        let fotoEncontrada = idxEncontrado >= 0 ? arrFotos[idxEncontrado] : null;
                        if (idxEncontrado >= 0) usadosEnFamilia.add(idxEncontrado);

                        let familiaCarta = nombreFamilia;
                        let famIdxFinal = famIdx;

                        if (!fotoEncontrada && mapaGlobalFotos.has(idBuscado)) {
                            const matchGlobal = mapaGlobalFotos.get(idBuscado);
                            fotoEncontrada = matchGlobal.foto;
                            familiaCarta = matchGlobal.nombreFamilia;
                            famIdxFinal = matchGlobal.famIdx;
                        }

                        if (fotoEncontrada && fotoEncontrada.url) {
                            const idExacto = fotoEncontrada.id;
                            const nombrePersonajeAdmin = fotoEncontrada.nombre !== ''
                                ? fotoEncontrada.nombre
                                : (familiaCarta || idExacto);
                            const jugadorAnotado = obtenerJugadorAnotadoEnFila(famIdxFinal);

                            nuevasCartas.push({
                                uid: `fb-${famIdxFinal}-${i}-${idExacto}`,
                                id_foto: idExacto,
                                famIdx: famIdxFinal,
                                playerName: jugadorAnotado,
                                photoName: nombrePersonajeAdmin,
                                text: nombrePersonajeAdmin,
                                family: familiaCarta,
                                image: fotoEncontrada.url,
                                voiceText: nombrePersonajeAdmin
                            });
                        }
                    });
                }

                // Si seleccion_actual no tenía todas las fotos nuevas de esta familia (o no existía), completar con las fotos con link del Admin
                if (usadosEnFamilia.size < metaPorFamilia) {
                    arrFotos.forEach((fotoEncontrada, fIdx) => {
                        if (usadosEnFamilia.size >= metaPorFamilia) return;
                        if (usadosEnFamilia.has(fIdx)) return;
                        usadosEnFamilia.add(fIdx);

                        const idExacto = fotoEncontrada.id;
                        const nombrePersonajeAdmin = fotoEncontrada.nombre !== ''
                            ? fotoEncontrada.nombre
                            : (nombreFamilia || idExacto);
                        const jugadorAnotado = obtenerJugadorAnotadoEnFila(famIdx);

                        nuevasCartas.push({
                            uid: `fb-${famIdx}-extra-${fIdx}-${idExacto}`,
                            id_foto: idExacto,
                            famIdx: famIdx,
                            playerName: jugadorAnotado,
                            photoName: nombrePersonajeAdmin,
                            text: nombrePersonajeAdmin,
                            family: nombreFamilia,
                            image: fotoEncontrada.url,
                            voiceText: nombrePersonajeAdmin
                        });
                    });
                }
                return;

                // Fallback: si no hay seleccion_actual para esta fila, tomar las fotos con link directamente del tablero_activo
                arrFotos.slice(0, casillasPorFamiliaFB || 7).forEach((fotoEncontrada, i) => {
                    const idExacto = fotoEncontrada.id;
                    const nombrePersonajeAdmin = fotoEncontrada.nombre !== ''
                        ? fotoEncontrada.nombre
                        : (nombreFamilia || idExacto);
                    const jugadorAnotado = obtenerJugadorAnotadoEnFila(famIdx);

                    nuevasCartas.push({
                        uid: `fb-${famIdx}-${i}-${idExacto}`,
                        id_foto: idExacto,
                        famIdx: famIdx,
                        playerName: jugadorAnotado,
                        photoName: nombrePersonajeAdmin,
                        text: nombrePersonajeAdmin,
                        family: nombreFamilia,
                        image: fotoEncontrada.url,
                        voiceText: nombrePersonajeAdmin
                    });
                });
            });

            return { idJuego, nombreJuego, cartas: nuevasCartas };
        }

        function aplicarMazoDesdeFirebase(idJuego, nombreJuego, nuevasCartas) {
            const nuevoJuego = { id: idJuego, name: nombreJuego, cards: nuevasCartas };
            const idxExistente = savedGames.findIndex(g => g.id === idJuego);
            if (idxExistente >= 0) {
                savedGames[idxExistente] = nuevoJuego;
            } else {
                savedGames.unshift(nuevoJuego);
            }
            activeGameId = nuevoJuego.id;
            cardsData = nuevoJuego.cards;
            saveGamesToStorage();

            const titleEl = document.getElementById('active-game-title');
            if (titleEl) titleEl.textContent = nombreJuego;
            if (typeof shuffleToast !== 'undefined' && shuffleToast) {
                shuffleToast.textContent = `☁️ En vivo: ${nombreJuego} (${nuevasCartas.length} cartas)`;
            }
        }

        function reconstruirMazoDesdeFirebase(forzarAnimacion) {
            if (!ultimoTableroActivoFB) return false;

            const { idJuego, nombreJuego, cartas } = construirCartasDesdeFirebase(ultimoTableroActivoFB, ultimaSeleccionActualFB || {});

            if (cartas.length === 0) {
                if (typeof shuffleToast !== 'undefined' && shuffleToast) {
                    shuffleToast.textContent = '⚠️ El bingo no tiene cartas visibles todavía';
                }
                return false;
            }

            aplicarMazoDesdeFirebase(idJuego, nombreJuego, cartas);
            firmaSeleccionActual = firmaDeSeleccion(ultimaSeleccionActualFB || { fallbackTimestamp: ultimoTableroActivoFB.timestamp || 1 });
            mazoYaSincronizado = true;
            hayNuevaSeleccionPendiente = false;

            initDeckDOMOnly();
            for (let i = deckQueue.length - 1; i > 0; i--) {
                const j = Math.floor(Math.random() * (i + 1));
                [deckQueue[i], deckQueue[j]] = [deckQueue[j], deckQueue[i]];
            }
            syncStaticPositions(false);
            updateUI();
            precargarImagenesDelMazo();
            return true;
        }

        function sincronizarCartasConBingo() {
            if (!ultimoTableroActivoFB) return;

            const firmaNueva = firmaDeSeleccion(ultimaSeleccionActualFB || { fallbackTimestamp: ultimoTableroActivoFB.timestamp || 1 });

            // Si hay animación en curso, dejamos pendiente y se aplica al terminar
            if (isShuffling) {
                if (!mazoYaSincronizado || firmaNueva !== firmaSeleccionActual) {
                    actualizacionPendienteFB = true;
                    hayNuevaSeleccionPendiente = true;
                }
                return;
            }

            // Primera sincronización: siempre aplica
            if (!mazoYaSincronizado) {
                reconstruirMazoDesdeFirebase(false);
                return;
            }

            // Si la firma no cambió, no hacemos nada
            if (firmaNueva === firmaSeleccionActual) return;

            if (mazoIntacto()) {
                reconstruirMazoDesdeFirebase(false);
                if (typeof shuffleToast !== 'undefined' && shuffleToast) {
                    shuffleToast.textContent = '🔄 Mazo actualizado desde el bingo';
                }
            } else {
                hayNuevaSeleccionPendiente = true;
                if (typeof shuffleToast !== 'undefined' && shuffleToast) {
                    shuffleToast.textContent = '⚠️ El bingo cambió cartas. Pulsa "Juego Nuevo" para aplicar.';
                }
                firmaSeleccionActual = firmaNueva;
            }
        }

        function cargarTableroDesdeFirebase() {
            db.ref('bingo/tablero_activo').on('value', (snapshot) => {
                const payload = snapshot.val();
                if (!payload || !payload.data) return;
                ultimoTableroActivoFB = payload;
                sincronizarCartasConBingo();
            });

            db.ref('bingo/configuracion/casillas_por_familia').on('value', (snapCas) => {
                if (snapCas.exists()) {
                    casillasPorFamiliaFB = parseInt(snapCas.val(), 10) || 7;
                }
            });

            db.ref('bingo/configuracion/seleccion_actual').on('value', (snapSel) => {
                const seleccionActual = snapSel.val();
                if (!seleccionActual) return;
                ultimaSeleccionActualFB = seleccionActual;
                sincronizarCartasConBingo();
            });

            db.ref('bingo/anotarse/cartones').on('value', (snapCartones) => {
                const rawCartones = snapCartones.val() || [];
                const listaCartones = Array.isArray(rawCartones)
                    ? rawCartones
                    : (typeof rawCartones === 'object' ? Object.values(rawCartones) : []);

                const mapaJugadores = {};
                listaCartones.forEach((carton, idx) => {
                    if (!carton || !carton.lineas) return;
                    const arrLineas = Array.isArray(carton.lineas) ? carton.lineas : Object.values(carton.lineas);
                    const activos = arrLineas
                        .filter(l => l && l.nombre && String(l.nombre).trim() !== '' && l.estado !== 'libre')
                        .map(l => String(l.nombre).trim().toUpperCase());
                    if (activos.length > 0) {
                        mapaJugadores[idx] = activos.join(' / ');
                    }
                });

                jugadoresPorFilaFB = mapaJugadores;
                actualizarNombresPersonasEnCartasVivas();
            });

            // Escuchar configuración de pausa por amarre y eventos de amarre desde el Bingo
            db.ref('bingo/configuracion/pausa_amarre').on('value', (snapCfg) => {
                const cfg = snapCfg.val();
                if (!cfg) return;
                if (typeof cfg.activo === 'boolean') {
                    amarreLockEnabled = cfg.activo;
                    try { localStorage.setItem('mazo_amarre_enabled', String(amarreLockEnabled)); } catch (e) {}
                }
                if (cfg.segundos) {
                    const parsedSec = parseInt(cfg.segundos, 10);
                    if (!isNaN(parsedSec) && parsedSec >= 1 && parsedSec <= 30) {
                        amarreLockSeconds = parsedSec;
                        try { localStorage.setItem('mazo_amarre_sec', String(amarreLockSeconds)); } catch (e) {}
                    }
                }
                syncAmarreSettingsUI();
                if (!amarreLockEnabled && isAmarreLocked) {
                    liberarBloqueoPorAmarre();
                }
            });

            let primeraLecturaAmarre = true;
            db.ref('bingo/amarre').on('value', (snapAmarre) => {
                if (primeraLecturaAmarre) {
                    primeraLecturaAmarre = false;
                    return;
                }
                const datos = snapAmarre.val();
                if (!datos) {
                    if (isAmarreLocked) liberarBloqueoPorAmarre();
                    return;
                }
                if (!amarreLockEnabled) return;
                const duracionSeg = amarreLockSeconds || parseInt(datos.segundos, 10) || 6;
                activarBloqueoPorAmarre(duracionSeg, datos.familias || []);
            });
        }

        function enviarCartaAFirebase(cardData, accion = 'tapar') {
            if (!cardData) return;
            const familia = cardData.family || '';
            const texto = cardData.text || '';
            const id_foto = cardData.id_foto ? String(cardData.id_foto).trim() : '';

            db.ref('bingo/ultima_carta').set({
                familia: familia,
                texto_carta: texto,
                id_foto: id_foto,
                accion: accion,
                timestamp: Date.now()
            });
        }

        // ==========================================
        // EL RESTO DEL CÓDIGO (TEMAS, CARTAS, MEZCLAS, etc.)
        // ==========================================
        const THEMES_CATALOG = [
            { id: 'classic', name: '1. Azul Clásico', bgMain: '#164e87', bg1: '#236cb2', bg2: '#154577', bg3: '#0b2644', cBase: '#d4ae44', cInner: '#c49a2d', cBorder: '#9c7311', cDiamond: '#dcba56', cCircle: '#ead07c' },
            { id: 'casino', name: '2. Casino', bgMain: '#064e3b', bg1: '#059669', bg2: '#064e3b', bg3: '#022c22', cBase: '#b91c1c', cInner: '#991b1b', cBorder: '#fca5a5', cDiamond: '#dc2626', cCircle: '#fef08a' },
            { id: 'galaxy', name: '3. Galaxia', bgMain: '#1e1b4b', bg1: '#4338ca', bg2: '#1e1b4b', bg3: '#09071d', cBase: '#6d28d9', cInner: '#5b21b6', cBorder: '#c4b5fd', cDiamond: '#7c3aed', cCircle: '#38bdf8' },
            { id: 'wood', name: '4. Madera', bgMain: '#451a03', bg1: '#78350f', bg2: '#451a03', bg3: '#230c01', cBase: '#b45309', cInner: '#92400e', cBorder: '#fde68a', cDiamond: '#d97706', cCircle: '#fef3c7' },
            { id: 'royal', name: '5. Realeza', bgMain: '#4a044e', bg1: '#701a75', bg2: '#4a044e', bg3: '#270129', cBase: '#be185d', cInner: '#9d174d', cBorder: '#fbcfe8', cDiamond: '#db2777', cCircle: '#fde047' },
            { id: 'crimson', name: '6. Carmesí', bgMain: '#7f1d1d', bg1: '#991b1b', bg2: '#651212', bg3: '#380606', cBase: '#475569', cInner: '#334155', cBorder: '#e2e8f0', cDiamond: '#64748b', cCircle: '#f8fafc' },
            { id: 'cyber', name: '7. Cyberpunk', bgMain: '#090d16', bg1: '#0f172a', bg2: '#090d16', bg3: '#020408', cBase: '#0284c7', cInner: '#0369a1', cBorder: '#7dd3fc', cDiamond: '#0ea5e9', cCircle: '#f43f5e' },
            { id: 'ocean', name: '8. Océano', bgMain: '#115e59', bg1: '#0d9488', bg2: '#115e59', bg3: '#042f2e', cBase: '#ea580c', cInner: '#c2410c', cBorder: '#fed7aa', cDiamond: '#f97316', cCircle: '#fef9c3' },
            { id: 'sunset', name: '9. Atardecer', bgMain: '#7c2d12', bg1: '#c2410c', bg2: '#7c2d12', bg3: '#431407', cBase: '#eab308', cInner: '#ca8a04', cBorder: '#fef08a', cDiamond: '#facc15', cCircle: '#ffffff' },
            { id: 'obsidian', name: '10. Obsidiana', bgMain: '#18181b', bg1: '#27272a', bg2: '#18181b', bg3: '#09090b', cBase: '#ca8a04', cInner: '#a16207', cBorder: '#fef08a', cDiamond: '#eab308', cCircle: '#18181b' }
        ];

        let enabledThemes = new Set(THEMES_CATALOG.map(t => t.id));
        let themeBag = [];
        let currentThemeId = 'classic';

        function applyThemeById(themeId) {
            const t = THEMES_CATALOG.find(x => x.id === themeId) || THEMES_CATALOG[0];
            currentThemeId = t.id;
            const root = document.documentElement.style;
            root.setProperty('--bg-main', t.bgMain); root.setProperty('--bg-grad-1', t.bg1); root.setProperty('--bg-grad-2', t.bg2); root.setProperty('--bg-grad-3', t.bg3);
            root.setProperty('--card-back-base', t.cBase); root.setProperty('--card-back-inner', t.cInner); root.setProperty('--card-back-border', t.cBorder); root.setProperty('--card-back-diamond', t.cDiamond); root.setProperty('--card-back-circle', t.cCircle); root.setProperty('--card-front-border', t.cBase);
            return t;
        }

        function pickNextRandomCheckedTheme() {
            const activeList = Array.from(enabledThemes);
            if (activeList.length === 0) return applyThemeById('classic');
            if (activeList.length === 1) return applyThemeById(activeList[0]);
            themeBag = themeBag.filter(id => enabledThemes.has(id));
            if (themeBag.length === 0) {
                themeBag = [...activeList];
                for (let i = themeBag.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1));[themeBag[i], themeBag[j]] = [themeBag[j], themeBag[i]]; }
                if (themeBag.length > 1 && themeBag[themeBag.length - 1] === currentThemeId) { [themeBag[0], themeBag[themeBag.length - 1]] = [themeBag[themeBag.length - 1], themeBag[0]]; }
            }
            return applyThemeById(themeBag.pop());
        }

        const PRESET_GAMES = [
            { id: 'game-20', name: 'Juego Rápido (20)', cards: Array.from({ length: 20 }, (_, i) => ({ uid: `g20-${i}`, text: `Carta ${i + 1}`, image: '', voiceText: `Carta ${i + 1}` })) },
            { id: 'game-40', name: 'Juego Medio (40)', cards: Array.from({ length: 40 }, (_, i) => ({ uid: `g40-${i}`, text: `Carta ${i + 1}`, image: '', voiceText: `Carta ${i + 1}` })) },
            { id: 'game-100', name: 'Mazo Completo (100)', cards: Array.from({ length: 100 }, (_, i) => ({ uid: `g100-${i}`, text: `Carta ${i + 1}`, image: '', voiceText: `Carta ${i + 1}` })) }
        ];

        const STORAGE_KEY = 'wordwall_saved_games_v4';
        let savedGames = [];
        let activeGameId = '';
        let cardsData = [];

        function compressImageFile(file, callback) {
            const reader = new FileReader();
            reader.onload = e => {
                const img = new Image();
                img.onload = () => {
                    const canvas = document.createElement('canvas'); const maxDim = 420;
                    let w = img.width; let h = img.height;
                    if (w > h && w > maxDim) { h = Math.round((h * maxDim) / w); w = maxDim; } else if (h >= w && h > maxDim) { w = Math.round((w * maxDim) / h); h = maxDim; }
                    canvas.width = w; canvas.height = h;
                    canvas.getContext('2d').drawImage(img, 0, 0, w, h);
                    callback(canvas.toDataURL('image/jpeg', 0.8));
                };
                img.src = e.target.result;
            };
            reader.readAsDataURL(file);
        }

        function loadGamesFromStorage() {
            try { const raw = localStorage.getItem(STORAGE_KEY); if (raw) { const parsed = JSON.parse(raw); if (Array.isArray(parsed) && parsed.length > 0) savedGames = parsed; } } catch (e) { }
            if (savedGames.length === 0) savedGames = JSON.parse(JSON.stringify(PRESET_GAMES));
            activeGameId = savedGames[0].id; cardsData = savedGames[0].cards; updateActiveGameHeader();
        }

        function saveGamesToStorage() {
            try { const currentObj = savedGames.find(g => g.id === activeGameId); if (currentObj) currentObj.cards = cardsData; localStorage.setItem(STORAGE_KEY, JSON.stringify(savedGames)); } catch (e) { }
            updateActiveGameHeader();
        }

        function updateActiveGameHeader() {
            const currentObj = savedGames.find(g => g.id === activeGameId);
            if (currentObj) {
                document.getElementById('active-game-title').textContent = currentObj.name;
                const editLabel = document.getElementById('editing-game-label');
                if (editLabel) editLabel.textContent = `${currentObj.name} (${cardsData.length} cartas)`;
            }
        }

        class SoundFX {
            constructor() { this.ctx = null; this.muted = false; }
            init() { if (!this.ctx) { const AC = window.AudioContext || window.webkitAudioContext; if (AC) this.ctx = new AC(); } if (this.ctx && this.ctx.state === 'suspended') this.ctx.resume(); }
            playSlide(pitchMultiplier = 1) { if (this.muted) return; this.init(); if (!this.ctx) return; const now = this.ctx.currentTime; const bufSize = Math.floor(this.ctx.sampleRate * 0.06); const buf = this.ctx.createBuffer(1, bufSize, this.ctx.sampleRate); const data = buf.getChannelData(0); for (let i = 0; i < bufSize; i++) { data[i] = (Math.random() * 2 - 1) * Math.sin((i / bufSize) * Math.PI); } const src = this.ctx.createBufferSource(); src.buffer = buf; const filt = this.ctx.createBiquadFilter(); filt.type = 'bandpass'; filt.frequency.setValueAtTime(850 * pitchMultiplier, now); const gain = this.ctx.createGain(); gain.gain.setValueAtTime(0.01, now); gain.gain.linearRampToValueAtTime(0.13, now + 0.015); gain.gain.exponentialRampToValueAtTime(0.001, now + 0.06); src.connect(filt); filt.connect(gain); gain.connect(this.ctx.destination); src.start(now); }
            playFlip() { if (this.muted) return; this.init(); if (!this.ctx) return; const now = this.ctx.currentTime; const osc = this.ctx.createOscillator(); const gain = this.ctx.createGain(); osc.type = 'sine'; osc.frequency.setValueAtTime(330, now); osc.frequency.exponentialRampToValueAtTime(590, now + 0.09); gain.gain.setValueAtTime(0.001, now); gain.gain.linearRampToValueAtTime(0.1, now + 0.02); gain.gain.exponentialRampToValueAtTime(0.001, now + 0.1); osc.connect(gain); gain.connect(this.ctx.destination); osc.start(now); osc.stop(now + 0.1); }
            playFanfare() { if (this.muted) return; this.init(); if (!this.ctx) return; const notes = [261.63, 329.63, 392.00, 523.25]; notes.forEach((freq, idx) => { const now = this.ctx.currentTime + (idx * 0.07); const osc = this.ctx.createOscillator(); const gain = this.ctx.createGain(); osc.type = 'triangle'; osc.frequency.setValueAtTime(freq, now); gain.gain.setValueAtTime(0.001, now); gain.gain.linearRampToValueAtTime(0.12, now + 0.02); gain.gain.exponentialRampToValueAtTime(0.001, now + 0.28); osc.connect(gain); gain.connect(this.ctx.destination); osc.start(now); osc.stop(now + 0.29); }); }
        }
        const sfx = new SoundFX();
        let autoSpeakOnDraw = false;

        function speakCardData(cardItem) {
            if (!cardItem || !('speechSynthesis' in window)) return;
            window.speechSynthesis.cancel();
            // Solo decir el nombre que se le dio a la carta en el ADMIN (photoName / text)
            const textToRead = (cardItem.photoName && String(cardItem.photoName).trim() !== '')
                ? String(cardItem.photoName).trim()
                : ((cardItem.text && String(cardItem.text).trim() !== '') ? String(cardItem.text).trim() : (cardItem.voiceText || ''));
            if (!textToRead) return;
            const utter = new SpeechSynthesisUtterance(textToRead);
            const v = getSelectedSpeechVoice();
            if (v) { utter.voice = v; utter.lang = v.lang; } else { utter.lang = 'es-ES'; }
            window.speechSynthesis.speak(utter);
        }
        function speakCurrentDrawnCard() { if (drawnStack.length === 0) return; const topCardId = drawnStack[drawnStack.length - 1]; const cardObj = allCardsMap.get(topCardId); if (cardObj && cardObj.data) speakCardData(cardObj.data); }

        const SHUFFLE_MODES = [
            { id: 'riffle', name: '1. Cruce en Cascada', icon: 'ph-intersect' }, { id: 'wordwall', name: '2. Corte Lateral', icon: 'ph-cards' }, { id: 'hindu', name: '3. Hindú', icon: 'ph-stack' }, { id: 'fan', name: '4. Abanico 3D', icon: 'ph-fan' }, { id: 'vortex', name: '5. Torbellino', icon: 'ph-spinner-gap' }, { id: 'piles', name: '6. 4 Montones', icon: 'ph-squares-four' }, { id: 'wash', name: '7. Lavado Casino', icon: 'ph-arrows-out' }, { id: 'cut3', name: '8. Triple Corte', icon: 'ph-columns' }, { id: 'accordion', name: '9. Acordeón', icon: 'ph-wave-sine' }, { id: 'faro', name: '10. Peine Faro', icon: 'ph-arrows-merge' }
        ];

        let enabledShuffles = new Set(SHUFFLE_MODES.map(m => m.id));
        let shuffleBag = [];
        let lastShuffleId = '';

        function getNextTrueRandomShuffleMode() {
            const activeList = Array.from(enabledShuffles);
            if (activeList.length === 0) return 'riffle';
            if (activeList.length === 1) return activeList[0];
            shuffleBag = shuffleBag.filter(id => enabledShuffles.has(id));
            if (shuffleBag.length === 0) {
                shuffleBag = [...activeList];
                for (let i = shuffleBag.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1));[shuffleBag[i], shuffleBag[j]] = [shuffleBag[j], shuffleBag[i]]; }
                if (shuffleBag.length > 1 && shuffleBag[shuffleBag.length - 1] === lastShuffleId) { [shuffleBag[0], shuffleBag[shuffleBag.length - 1]] = [shuffleBag[shuffleBag.length - 1], shuffleBag[0]]; }
            }
            const chosen = shuffleBag.pop(); lastShuffleId = chosen; return chosen;
        }

        let deckQueue = []; let drawnStack = []; let allCardsMap = new Map(); let isShuffling = false; let drawZCounter = 2000;
        const canvasEl = document.getElementById('game-canvas'); const deckFrame = document.getElementById('deck-zone-frame'); const dropFrame = document.getElementById('drop-zone-frame'); const deckClickZone = document.getElementById('deck-click-zone'); const dropClickZone = document.getElementById('drop-click-zone'); const voiceBtn = document.getElementById('card-voice-btn'); const counterBadge = document.getElementById('deck-counter-badge'); const shuffleToast = document.getElementById('shuffle-toast'); const btnUndo = document.getElementById('btn-undo'); const btnDeal = document.getElementById('btn-deal'); const btnShuffle = document.getElementById('btn-shuffle');

        let isAutoPlaying = false;
        let autoPlayTimer = null;
        let autoPlayIntervalSec = 3.5;

        // Variables de bloqueo por Amarre (cuando a una familia le falta 1 carta en el Bingo)
        let isAmarreLocked = false;
        let amarreLockEnabled = true;
        let amarreLockSeconds = 6;
        let amarreCountdownInterval = null;
        let amarreRemainingSec = 0;

        function loadAutoPlaySettings() {
            try {
                const savedSpeed = parseFloat(localStorage.getItem('wordwall_auto_speed_sec'));
                if (!isNaN(savedSpeed) && savedSpeed >= 1 && savedSpeed <= 15) {
                    autoPlayIntervalSec = savedSpeed;
                }
                const savedAmarreEnabled = localStorage.getItem('mazo_amarre_enabled');
                if (savedAmarreEnabled !== null) {
                    amarreLockEnabled = savedAmarreEnabled !== 'false';
                }
                const savedAmarreSec = parseInt(localStorage.getItem('mazo_amarre_sec'), 10);
                if (!isNaN(savedAmarreSec) && savedAmarreSec >= 1 && savedAmarreSec <= 30) {
                    amarreLockSeconds = savedAmarreSec;
                }
            } catch (e) {}
            syncAutoPlaySpeedUI();
            syncAmarreSettingsUI();
        }

        function syncAutoPlaySpeedUI() {
            const slider = document.getElementById('auto-speed-slider');
            if (slider) slider.value = autoPlayIntervalSec;
            const badge = document.getElementById('auto-speed-badge');
            if (badge) badge.textContent = `Cada ${autoPlayIntervalSec} s`;
        }

        function syncAmarreSettingsUI() {
            const chk = document.getElementById('amarre-lock-toggle');
            if (chk) chk.checked = amarreLockEnabled;
            const slider = document.getElementById('amarre-time-slider');
            if (slider) slider.value = amarreLockSeconds;
            const badge = document.getElementById('amarre-time-badge');
            if (badge) badge.textContent = `${amarreLockSeconds} s`;
        }

        function toggleAmarreLock(enabled) {
            amarreLockEnabled = Boolean(enabled);
            try { localStorage.setItem('mazo_amarre_enabled', String(amarreLockEnabled)); } catch (e) {}
            syncAmarreSettingsUI();
            try {
                db.ref('bingo/configuracion/pausa_amarre').update({
                    activo: amarreLockEnabled,
                    segundos: amarreLockSeconds
                });
            } catch (e) {}
            if (!amarreLockEnabled && isAmarreLocked) {
                liberarBloqueoPorAmarre();
            }
        }

        function updateAmarreLockTime(val) {
            const parsed = parseInt(val, 10);
            if (isNaN(parsed)) return;
            amarreLockSeconds = Math.min(30, Math.max(1, parsed));
            try { localStorage.setItem('mazo_amarre_sec', String(amarreLockSeconds)); } catch (e) {}
            syncAmarreSettingsUI();
            try {
                db.ref('bingo/configuracion/pausa_amarre').update({
                    activo: amarreLockEnabled,
                    segundos: amarreLockSeconds
                });
            } catch (e) {}
        }

        function liberarBloqueoPorAmarre() {
            if (amarreCountdownInterval) {
                clearInterval(amarreCountdownInterval);
                amarreCountdownInterval = null;
            }
            isAmarreLocked = false;
            amarreRemainingSec = 0;
            if (shuffleToast) shuffleToast.textContent = '✅ Listo para seguir sacando cartas';
            updateUI();
        }

        function activarBloqueoPorAmarre(segundos, familias) {
            if (!amarreLockEnabled) return;
            if (amarreCountdownInterval) {
                clearInterval(amarreCountdownInterval);
                amarreCountdownInterval = null;
            }
            isAmarreLocked = true;
            amarreRemainingSec = Math.max(1, parseInt(segundos, 10) || amarreLockSeconds);
            const nomFam = Array.isArray(familias) && familias.length > 0 ? familias.join(', ') : '1 Familia';

            if (shuffleToast) {
                shuffleToast.textContent = `🚨 ¡AMARRE (${nomFam})! Mazo bloqueado ${amarreRemainingSec}s`;
            }
            updateUI();

            amarreCountdownInterval = setInterval(() => {
                amarreRemainingSec--;
                if (amarreRemainingSec <= 0) {
                    liberarBloqueoPorAmarre();
                } else {
                    if (shuffleToast) {
                        shuffleToast.textContent = `🚨 ¡AMARRE (${nomFam})! Espera ${amarreRemainingSec}s`;
                    }
                    updateUI();
                }
            }, 1000);
        }

        function updateAutoPlaySpeed(val) {
            const parsed = parseFloat(val);
            if (isNaN(parsed)) return;
            autoPlayIntervalSec = Math.min(15, Math.max(1, parsed));
            try {
                localStorage.setItem('wordwall_auto_speed_sec', String(autoPlayIntervalSec));
            } catch (e) {}
            syncAutoPlaySpeedUI();
            if (isAutoPlaying) {
                restartAutoPlayTimer();
            }
        }

        function stopAutoPlay() {
            if (autoPlayTimer) {
                clearInterval(autoPlayTimer);
                autoPlayTimer = null;
            }
            isAutoPlaying = false;
        }

        function restartAutoPlayTimer() {
            if (autoPlayTimer) {
                clearInterval(autoPlayTimer);
                autoPlayTimer = null;
            }
            if (!isAutoPlaying) return;
            autoPlayTimer = setInterval(() => {
                if (isShuffling || isAmarreLocked) return;
                if (deckQueue.length === 0) {
                    stopAutoPlay();
                    return;
                }
                drawNextCard();
                if (deckQueue.length === 0) {
                    stopAutoPlay();
                }
            }, Math.round(autoPlayIntervalSec * 1000));
        }

        function startAutoPlay() {
            if (isShuffling || isAmarreLocked || deckQueue.length === 0) return;
            isAutoPlaying = true;
            drawNextCard();
            if (deckQueue.length > 0) {
                restartAutoPlayTimer();
            } else {
                stopAutoPlay();
            }
        }

        function toggleAutoPlayFromDropZone() {
            if (isShuffling || isAmarreLocked) return;
            if (isAutoPlaying) {
                stopAutoPlay(false);
            } else {
                startAutoPlay();
            }
        }

        function getDeckCardOffset(indexFromTop, totalDeck, isPortrait) { const depthFromBottom = totalDeck - 1 - indexFromTop; const visualLayer = Math.min(depthFromBottom, 10); return { ox: isPortrait ? 0 : -visualLayer * 0.5, oy: visualLayer * 1.1 }; }
        function getDrawnCardOffset(indexInDrawn) { const layer = Math.min(indexInDrawn, 6); return { ox: layer * 0.6, oy: layer * 0.6 }; }

        // Oculta del renderizado GPU las cartas enterradas debajo del mazo o debajo de las cartas salidas
        function actualizarCullingDeCartas() {
            if (isShuffling) return;
            const MAX_VISIBLE_DECK = 6;
            const MAX_VISIBLE_DRAWN = 3;

            deckQueue.forEach((id, idx) => {
                const card = allCardsMap.get(id);
                if (!card || card.isMoving) return;
                card.el.style.display = idx < MAX_VISIBLE_DECK ? 'block' : 'none';
            });

            const totalDrawn = drawnStack.length;
            drawnStack.forEach((id, i) => {
                const card = allCardsMap.get(id);
                if (!card || card.isMoving) return;
                card.el.style.display = (i >= totalDrawn - MAX_VISIBLE_DRAWN) ? 'block' : 'none';
            });
        }

        function syncStaticPositions(animate = false) {
            const { isPortrait, width, height, deckX, deckY, dropX, dropY } = getStageLayout();
            deckFrame.style.width = `${width}px`; deckFrame.style.height = `${height}px`; deckFrame.style.left = `${deckX}px`; deckFrame.style.top = `${deckY}px`;
            dropFrame.style.width = `${width}px`; dropFrame.style.height = `${height}px`; dropFrame.style.left = `${dropX}px`; dropFrame.style.top = `${dropY}px`;
            deckClickZone.style.width = `${width + 16}px`; deckClickZone.style.height = `${height + 28}px`; deckClickZone.style.left = `${deckX - 8}px`; deckClickZone.style.top = `${deckY - 4}px`; deckClickZone.style.display = deckQueue.length > 0 ? 'block' : 'none';
            if (dropClickZone) {
                dropClickZone.style.width = `${width + 16}px`;
                dropClickZone.style.height = `${height + 28}px`;
                dropClickZone.style.left = `${dropX - 8}px`;
                dropClickZone.style.top = `${dropY - 4}px`;
                dropClickZone.style.display = 'block';
            }
            if (isPortrait) {
                voiceBtn.style.left = `${dropX + width + 10}px`;
                voiceBtn.style.top = `${dropY + (height / 2) - 17}px`;
            } else {
                voiceBtn.style.left = `${dropX + (width / 2) - 25}px`;
                voiceBtn.style.top = `${dropY + height + 10}px`;
            }
            voiceBtn.style.display = drawnStack.length > 0 ? 'flex' : 'none';
            const totalDeck = deckQueue.length;
            deckQueue.forEach((id, idx) => {
                const card = allCardsMap.get(id);
                if (!card) return;
                card.el.style.width = `${width}px`;
                card.el.style.height = `${height}px`;
                if (!card.isMoving) {
                    const { ox, oy } = getDeckCardOffset(idx, totalDeck, isPortrait);
                    card.el.style.zIndex = 500 - idx;
                    if (animate && idx < 6) {
                        gsap.to(card.el, { x: deckX + ox, y: deckY + oy, rotationZ: 0, scale: 1, autoAlpha: 1, duration: 0.22, overwrite: 'auto' });
                    } else {
                        gsap.set(card.el, { x: deckX + ox, y: deckY + oy, rotationZ: 0, scale: 1, autoAlpha: 1 });
                    }
                    gsap.set(card.flipperEl, { rotationY: 0 });
                    card.isFlipped = false;
                }
            });
            drawnStack.forEach((id, i) => {
                const card = allCardsMap.get(id);
                if (!card) return;
                card.el.style.width = `${width}px`;
                card.el.style.height = `${height}px`;
                card.el.style.zIndex = 1000 + i;
                if (!card.isMoving) {
                    const { ox, oy } = getDrawnCardOffset(i);
                    if (animate && i >= drawnStack.length - 3) {
                        gsap.to(card.el, { x: dropX + ox, y: dropY + oy, rotationZ: 0, scale: 1, autoAlpha: 1, duration: 0.22, overwrite: 'auto' });
                    } else {
                        gsap.set(card.el, { x: dropX + ox, y: dropY + oy, rotationZ: 0, scale: 1, autoAlpha: 1 });
                    }
                    gsap.set(card.flipperEl, { rotationY: 180 });
                    card.isFlipped = true;
                }
            });
            actualizarCullingDeCartas();
            updatePlayerLabel();
        }

        function updateUI() {
            const remaining = deckQueue.length; const drawn = drawnStack.length;
            const bloqueado = isShuffling || isAmarreLocked;
            counterBadge.textContent = `${remaining} cartas`;
            btnUndo.disabled = drawn === 0 || bloqueado;
            btnDeal.disabled = remaining === 0 || bloqueado;
            btnShuffle.disabled = bloqueado || (remaining + drawn <= 1);
            deckClickZone.style.pointerEvents = (remaining === 0 || bloqueado) ? 'none' : 'auto';
            if (dropClickZone) dropClickZone.style.pointerEvents = bloqueado ? 'none' : 'auto';
            voiceBtn.style.display = drawn > 0 && !isShuffling ? 'flex' : 'none';
            document.getElementById('deal-btn-label').textContent = (remaining === 0 ? 'Vacío' : 'Repartir');
            updatePlayerLabel();
        }

        function startNewGameWithAnimation() {
            if (isShuffling) return;
            stopAutoPlay(true);
            if (isAmarreLocked) liberarBloqueoPorAmarre();

            db.ref('bingo/amarre').set(null);
            db.ref('bingo/ultima_carta').set({
                accion: 'limpiar',
                timestamp: Date.now()
            });

            // Si tenemos datos de Firebase, reconstruir el mazo desde la ÚLTIMA selección conocida o del tablero activo
            if (ultimoTableroActivoFB) {
                const { idJuego, nombreJuego, cartas } = construirCartasDesdeFirebase(ultimoTableroActivoFB, ultimaSeleccionActualFB || {});
                if (cartas.length > 0) {
                    aplicarMazoDesdeFirebase(idJuego, nombreJuego, cartas);
                    firmaSeleccionActual = firmaDeSeleccion(ultimaSeleccionActualFB || { fallbackTimestamp: ultimoTableroActivoFB.timestamp || 1 });
                    mazoYaSincronizado = true;
                    hayNuevaSeleccionPendiente = false;
                }
            }

            isShuffling = true;
            document.body.classList.add('is-shuffling');
            const chosenTheme = pickNextRandomCheckedTheme();
            initDeckDOMOnly();
            for (let i = deckQueue.length - 1; i > 0; i--) {
                const j = Math.floor(Math.random() * (i + 1));
                [deckQueue[i], deckQueue[j]] = [deckQueue[j], deckQueue[i]];
            }

            const { W, H, isPortrait, width, height, deckX, deckY, dropX, dropY } = getStageLayout();
            deckFrame.style.width = `${width}px`;
            deckFrame.style.height = `${height}px`;
            deckFrame.style.left = `${deckX}px`;
            deckFrame.style.top = `${deckY}px`;
            dropFrame.style.width = `${width}px`;
            dropFrame.style.height = `${height}px`;
            dropFrame.style.left = `${dropX}px`;
            dropFrame.style.top = `${dropY}px`;
            updateUI();
            sfx.playFanfare();
            if (shuffleToast) shuffleToast.textContent = `🎨 ${chosenTheme.name}`;

            const banner = document.getElementById('new-game-banner');
            const bannerInner = document.getElementById('banner-inner');
            document.getElementById('banner-theme-pill').textContent = `Tema: ${chosenTheme.name}`;
            document.getElementById('banner-sub-info').textContent = `${deckQueue.length} cartas mezcladas al azar`;
            gsap.killTweensOf([banner, bannerInner]);
            gsap.set(banner, { opacity: 1 });
            gsap.fromTo(bannerInner, { scale: 0.25, rotationZ: -8, opacity: 0 }, { scale: 1.05, rotationZ: 0, opacity: 1, duration: 0.48, ease: 'back.out(1.8)' });
            gsap.to(banner, { opacity: 0, duration: 0.35, delay: 1.15 });

            const isMobileScreen = window.innerWidth < 768;
            const animLimit = Math.min(isMobileScreen ? 14 : 22, deckQueue.length);
            const animCards = deckQueue.slice(0, animLimit).map(id => allCardsMap.get(id));
            const restCards = deckQueue.slice(animLimit).map(id => allCardsMap.get(id));
            const centerX = (W - width) / 2;
            const centerY = (H - height) / 2;

            restCards.forEach((c, idx) => {
                c.isMoving = false;
                const realIdx = animLimit + idx;
                c.el.style.display = 'none';
                c.el.style.width = `${width}px`;
                c.el.style.height = `${height}px`;
                c.el.style.zIndex = 500 - realIdx;
                const { ox, oy } = getDeckCardOffset(realIdx, deckQueue.length, isPortrait);
                gsap.set(c.el, { x: deckX + ox, y: deckY + oy, rotationZ: 0, scale: 1, autoAlpha: 1 });
            });
            animCards.forEach((c, i) => {
                c.isMoving = true;
                c.el.style.display = 'block';
                c.el.style.width = `${width}px`;
                c.el.style.height = `${height}px`;
                c.el.style.zIndex = 600 - i;
                const angle = (i / animLimit) * Math.PI * 2;
                const rad = Math.max(W, H) * 0.65;
                gsap.set(c.el, { x: centerX + Math.cos(angle) * rad, y: centerY + Math.sin(angle) * rad, rotationZ: (angle * 180) / Math.PI + 90, scale: 0.45, autoAlpha: 1 });
            });

            const tl = gsap.timeline({
                onComplete: () => {
                    document.body.classList.remove('is-shuffling');
                    allCardsMap.forEach(c => { c.isMoving = false; });
                    isShuffling = false;
                    const habiaPendiente = actualizacionPendienteFB || hayNuevaSeleccionPendiente;
                    actualizacionPendienteFB = false;
                    hayNuevaSeleccionPendiente = false;
                    syncStaticPositions(false);
                    updateUI();
                    precargarImagenesDelMazo();
                    if (habiaPendiente) {
                        mazoYaSincronizado = false;
                        sincronizarCartasConBingo();
                    }
                }
            });

            animCards.forEach((c, idx) => {
                const spreadAngle = ((idx / Math.max(1, animLimit - 1)) - 0.5) * 60;
                tl.to(c.el, { x: centerX + (idx - animLimit / 2) * 3, y: centerY, rotationZ: spreadAngle, scale: 0.95, duration: 0.42, ease: 'power3.out' }, idx * 0.012);
            });
            tl.addLabel('stackHome', '+=0.06');
            animCards.forEach((c, idx) => {
                const { ox, oy } = getDeckCardOffset(idx, deckQueue.length, isPortrait);
                tl.to(c.el, { x: deckX + ox, y: deckY + oy, rotationZ: 0, scale: 1, duration: 0.32, ease: 'back.out(1.2)' }, `stackHome+=${idx * 0.008}`);
            });
        }

        function drawNextCard() {
            if (isShuffling || isAmarreLocked || deckQueue.length === 0) return;
            sfx.playSlide();
            const cardId = deckQueue.shift();
            const card = allCardsMap.get(cardId);
            if (!card) return;

            card.isMoving = true;
            card.el.style.display = 'block';
            drawnStack.push(cardId);
            const drawnIndex = drawnStack.length - 1;

            // Hacer visible la nueva carta que entra al top 6 del mazo y precargar próximas imágenes
            if (deckQueue.length >= 6) {
                const revealCard = allCardsMap.get(deckQueue[5]);
                if (revealCard) revealCard.el.style.display = 'block';
            }
            if (deckQueue.length > 0) {
                const nextToPreload = allCardsMap.get(deckQueue[Math.min(5, deckQueue.length - 1)]);
                if (nextToPreload && nextToPreload.data && nextToPreload.data.image) {
                    precargarImagenUrl(nextToPreload.data.image);
                }
            }

            drawZCounter++;
            card.el.style.zIndex = drawZCounter;
            card.el.classList.add('is-elevated');
            const { dropX, dropY } = getStageLayout();
            const { ox, oy } = getDrawnCardOffset(drawnIndex);
            updateUI();

            gsap.killTweensOf([card.el, card.flipperEl]);
            gsap.to(card.el, {
                x: dropX + ox,
                y: dropY + oy,
                rotationZ: 0,
                scale: 1,
                autoAlpha: 1,
                duration: 0.34,
                ease: 'power2.out',
                force3D: true,
                onComplete: () => {
                    card.isMoving = false;
                    card.el.classList.remove('is-elevated');
                    card.el.style.zIndex = 1000 + drawnIndex;
                    actualizarCullingDeCartas();
                    if (autoSpeakOnDraw) speakCardData(card.data);
                }
            });
            sfx.playFlip();
            gsap.to(card.flipperEl, {
                rotationY: 180,
                duration: 0.34,
                ease: 'power2.out',
                force3D: true,
                onComplete: () => { card.isFlipped = true; }
            });
            enviarCartaAFirebase(card.data, 'tapar');
        }

        function undoLastDraw() {
            if (isShuffling || drawnStack.length === 0) return;
            stopAutoPlay(true);
            sfx.playSlide(1.15);
            const cardId = drawnStack.pop(); const card = allCardsMap.get(cardId); if (!card) return;

            enviarCartaAFirebase(card.data, 'destapar');

            card.isMoving = true; card.el.style.display = 'block'; deckQueue.unshift(cardId); actualizarCullingDeCartas(); drawZCounter++; card.el.style.zIndex = drawZCounter; card.el.classList.add('is-elevated');
            const { isPortrait, deckX, deckY } = getStageLayout(); const { ox, oy } = getDeckCardOffset(0, deckQueue.length, isPortrait);
            updateUI();
            gsap.killTweensOf([card.el, card.flipperEl]);
            gsap.to(card.flipperEl, { rotationY: 0, duration: 0.3, ease: 'power2.inOut', onComplete: () => { card.isFlipped = false; } });
            gsap.to(card.el, { x: deckX + ox, y: deckY + oy, rotationZ: 0, scale: 1, autoAlpha: 1, duration: 0.34, ease: 'power2.out', onComplete: () => { card.isMoving = false; card.el.classList.remove('is-elevated'); syncStaticPositions(false); } });
        }

        function executeRandomCheckedShuffle() {
            if (isShuffling) return;
            stopAutoPlay();
            if (deckQueue.length <= 1 && drawnStack.length === 0) return;
            const chosenModeId = getNextTrueRandomShuffleMode();
            const modeObj = SHUFFLE_MODES.find(m => m.id === chosenModeId);
            if (modeObj && shuffleToast) shuffleToast.textContent = `🎲 ${modeObj.name}`;
            isShuffling = true;
            updateUI();

            allCardsMap.forEach(c => {
                gsap.killTweensOf([c.el, c.flipperEl]);
                c.isMoving = true;
                c.el.classList.remove('is-elevated');
            });

            const { W, H, isPortrait, width, height, deckX, deckY } = getStageLayout();
            const centerX = (W - width) / 2;
            const centerY = (H - height) / 2;

            // Voltear de regreso solo las cartas que estaban volteadas antes de pasar a modo 2D rápido
            const cardsToReturn = [...drawnStack].reverse();
            drawnStack = [];
            cardsToReturn.forEach(id => {
                const c = allCardsMap.get(id);
                if (c) {
                    gsap.set(c.flipperEl, { rotationY: 0 });
                    c.isFlipped = false;
                }
                deckQueue.unshift(id);
            });

            // Activar modo 2D ultraligero para que la mezcla corra a 60/120 FPS sin caras frontales pesadas
            document.body.classList.add('is-shuffling');

            for (let i = deckQueue.length - 1; i > 0; i--) {
                const j = Math.floor(Math.random() * (i + 1));
                [deckQueue[i], deckQueue[j]] = [deckQueue[j], deckQueue[i]];
            }

            const animCount = Math.min(12, deckQueue.length);
            const animCards = deckQueue.slice(0, animCount).map(id => allCardsMap.get(id));
            const baseCards = deckQueue.slice(animCount).map(id => allCardsMap.get(id));

            // Ocultar cartas profundas y posicionarlas ya en el mazo destino sin animarlas
            baseCards.forEach((c, idx) => {
                const realIdx = animCount + idx;
                c.isMoving = false;
                c.el.style.display = 'none';
                c.el.style.zIndex = 500 - realIdx;
                const { ox, oy } = getDeckCardOffset(realIdx, deckQueue.length, isPortrait);
                gsap.set(c.el, { x: deckX + ox, y: deckY + oy, rotationZ: 0, scale: 1, autoAlpha: 1 });
                gsap.set(c.flipperEl, { rotationY: 0 });
                c.isFlipped = false;
            });

            // Preparar únicamente las 12 cartas visibles de la coreografía con zIndex fijo
            animCards.forEach((c, i) => {
                c.el.style.display = 'block';
                c.el.style.zIndex = 650 - i;
                gsap.set(c.flipperEl, { rotationY: 0 });
                c.isFlipped = false;
            });

            sfx.playSlide(1.05);
            const tlLift = gsap.timeline({
                onComplete: () => {
                    runShuffleChoreography(chosenModeId, animCards, baseCards, W, H, isPortrait, width, height, deckX, deckY, centerX, centerY);
                }
            });

            animCards.forEach((c, i) => {
                tlLift.to(c.el, {
                    x: centerX + (i % 2 === 0 ? -3 : 3),
                    y: centerY - Math.min(i * 0.6, 8),
                    rotationZ: 0,
                    scale: 0.96,
                    autoAlpha: 1,
                    duration: 0.2,
                    ease: 'power2.out',
                    force3D: true
                }, i * 0.005);
            });
        }

        function runShuffleChoreography(mode, animCards, baseCards, W, H, isPortrait, width, height, deckX, deckY, centerX, centerY) {
            const tl = gsap.timeline({
                onComplete: () => {
                    document.body.classList.remove('is-shuffling');
                    allCardsMap.forEach(c => { c.isMoving = false; });
                    isShuffling = false;
                    if (actualizacionPendienteFB) {
                        actualizacionPendienteFB = false;
                        initDeckDOMOnly();
                        for (let i = deckQueue.length - 1; i > 0; i--) {
                            const j = Math.floor(Math.random() * (i + 1));
                            [deckQueue[i], deckQueue[j]] = [deckQueue[j], deckQueue[i]];
                        }
                    }
                    syncStaticPositions(false);
                    updateUI();
                    precargarImagenesDelMazo();
                }
            });

            for (let s = 0; s < 4; s++) tl.call(() => sfx.playSlide(0.95 + (s * 0.05)), null, s * 0.12);

            const spreadX = Math.min(width * 0.52, W * 0.24);
            const spreadY = Math.min(height * 0.32, H * 0.16);

            if (mode === 'riffle') {
                const half = Math.ceil(animCards.length / 2);
                animCards.forEach((c, i) => {
                    const isLeft = i < half;
                    tl.to(c.el, { x: centerX + (isLeft ? -spreadX : spreadX), y: centerY, rotationZ: isLeft ? -7 : 7, duration: 0.2, ease: 'power2.out', force3D: true }, i * 0.006);
                    tl.to(c.el, { x: centerX, y: centerY - i * 0.6, rotationZ: 0, duration: 0.18, ease: 'power2.inOut', force3D: true }, 0.22 + i * 0.012);
                });
            } else if (mode === 'wordwall') {
                animCards.forEach((c, i) => {
                    const isRight = i % 2 === 0;
                    tl.to(c.el, { x: centerX + (isRight ? spreadX : -spreadX * 0.6), y: centerY + (isRight ? -8 : 6), rotationZ: isRight ? 4 : -3, duration: 0.2, ease: 'power2.out', force3D: true }, i * 0.008);
                    tl.to(c.el, { x: centerX, y: centerY - i * 0.6, rotationZ: 0, duration: 0.18, ease: 'power2.inOut', force3D: true }, 0.24 + i * 0.01);
                });
            } else if (mode === 'hindu') {
                const pullX = isPortrait ? 0 : spreadX;
                const pullY = isPortrait ? -spreadY * 1.15 : -28;
                animCards.forEach((c, i) => {
                    const packet = i % 3;
                    tl.to(c.el, { x: centerX + pullX, y: centerY + pullY, rotationZ: 4, duration: 0.18, ease: 'power2.out', force3D: true }, 0);
                    tl.to(c.el, { x: centerX, y: centerY + packet * 2, rotationZ: (i % 2 === 0 ? -2 : 2), duration: 0.18, ease: 'power2.inOut', force3D: true }, 0.18 + packet * 0.08 + i * 0.006);
                });
            } else if (mode === 'fan') {
                const total = animCards.length;
                const radius = Math.min(W, H) * 0.24;
                animCards.forEach((c, i) => {
                    const norm = (i / Math.max(1, total - 1)) - 0.5;
                    const angle = norm * 96;
                    const rad = (angle * Math.PI) / 180;
                    tl.to(c.el, { x: centerX + Math.sin(rad) * radius, y: centerY + (1 - Math.cos(rad)) * (radius * 0.45) - 10, rotationZ: angle * 0.6, duration: 0.28, ease: 'power2.out', force3D: true }, i * 0.008);
                });
                tl.to({}, { duration: 0.1 });
            } else if (mode === 'vortex') {
                const total = animCards.length;
                const radius = Math.min(W, H) * 0.21;
                animCards.forEach((c, i) => {
                    const angle = (i / total) * Math.PI * 2;
                    tl.to(c.el, { x: centerX + Math.cos(angle) * radius, y: centerY + Math.sin(angle) * (radius * 0.65), rotationZ: (angle * 180) / Math.PI, scale: 0.88, duration: 0.26, ease: 'power2.out', force3D: true }, i * 0.008);
                    tl.to(c.el, { x: centerX, y: centerY, rotationZ: 0, scale: 0.95, duration: 0.2, ease: 'power2.inOut', force3D: true }, 0.26 + i * 0.008);
                });
            } else if (mode === 'piles') {
                const offsets = [{ x: -spreadX * 0.85, y: -spreadY * 0.85, r: -6 }, { x: spreadX * 0.85, y: -spreadY * 0.85, r: 6 }, { x: -spreadX * 0.85, y: spreadY * 0.85, r: 5 }, { x: spreadX * 0.85, y: spreadY * 0.85, r: -5 }];
                animCards.forEach((c, i) => {
                    const pile = offsets[i % 4];
                    tl.to(c.el, { x: centerX + pile.x, y: centerY + pile.y, rotationZ: pile.r, scale: 0.88, duration: 0.2, ease: 'power2.out', force3D: true }, i * 0.012);
                });
                tl.to({}, { duration: 0.08 });
            } else if (mode === 'wash') {
                animCards.forEach((c, i) => {
                    const angle = (i * 137.5 * Math.PI) / 180;
                    const rx1 = centerX + Math.cos(angle) * spreadX * 0.9;
                    const ry1 = centerY + Math.sin(angle) * spreadY * 0.9;
                    tl.to(c.el, { x: rx1, y: ry1, rotationZ: (i % 2 === 0 ? 18 : -18), duration: 0.22, ease: 'power2.out', force3D: true }, i * 0.006);
                    tl.to(c.el, { x: centerX + Math.sin(angle) * (spreadX * 0.4), y: centerY + Math.cos(angle) * (spreadY * 0.4), rotationZ: (i % 2 === 0 ? -8 : 8), duration: 0.2, ease: 'power2.inOut', force3D: true }, 0.22 + i * 0.006);
                });
            } else if (mode === 'cut3') {
                animCards.forEach((c, i) => {
                    const col = (i % 3) - 1;
                    tl.to(c.el, { x: centerX + col * spreadX, y: centerY + (col === 0 ? -16 : 12), rotationZ: col * 6, duration: 0.2, ease: 'power2.out', force3D: true }, i * 0.006);
                    tl.to(c.el, { x: centerX, y: centerY - i * 0.5, rotationZ: 0, duration: 0.2, ease: 'power2.inOut', force3D: true }, 0.22 + i * 0.008);
                });
            } else if (mode === 'accordion') {
                animCards.forEach((c, i) => {
                    const dir = i % 2 === 0 ? 1 : -1;
                    const offset = (i - animCards.length / 2) * 10;
                    tl.to(c.el, { x: centerX + (isPortrait ? dir * 36 : offset * 1.3), y: centerY + (isPortrait ? offset * 1.2 : dir * 28), rotationZ: dir * 9, duration: 0.22, ease: 'power2.out', force3D: true }, i * 0.008);
                    tl.to(c.el, { x: centerX, y: centerY, rotationZ: 0, duration: 0.18, ease: 'power2.inOut', force3D: true }, 0.24 + i * 0.006);
                });
            } else {
                const half = Math.ceil(animCards.length / 2);
                animCards.forEach((c, i) => {
                    const isLeft = i < half;
                    const posInBlock = isLeft ? i : (i - half);
                    tl.to(c.el, { x: centerX + (isLeft ? -spreadX * 0.8 : spreadX * 0.8), y: centerY + (posInBlock * 1.5) - 10, rotationZ: 0, duration: 0.2, ease: 'power2.out', force3D: true }, 0);
                    tl.to(c.el, { x: centerX, y: centerY + (posInBlock * 1) - 8, duration: 0.18, ease: 'power2.inOut', force3D: true }, 0.21 + posInBlock * 0.012);
                });
            }

            tl.addLabel('gather', '+=0.03');
            animCards.forEach((c, idx) => {
                const { ox, oy } = getDeckCardOffset(idx, deckQueue.length, isPortrait);
                tl.to(c.el, {
                    x: deckX + ox,
                    y: deckY + oy,
                    rotationZ: 0,
                    scale: 1,
                    autoAlpha: 1,
                    duration: 0.24,
                    ease: 'power2.out',
                    force3D: true
                }, `gather+=${idx * 0.006}`);
            });
        }

        // ==========================================
        // FORMATOS DE CARTA (10 formas)
        // ==========================================
        const LAYOUTS = [
            { id: 'classic',  name: 'Clásica',        desc: 'Foto arriba, texto abajo', scale: 1.0 },
            { id: 'full',     name: 'Foto Gigante',   desc: 'Foto a toda la carta',     scale: 1.15 },
            { id: 'mini',     name: 'Mini',           desc: 'Carta pequeña',            scale: 0.55 },
            { id: 'bigtext',  name: 'Texto Grande',   desc: 'Nombre enorme',            scale: 1.0 },
            { id: 'polaroid', name: 'Polaroid',       desc: 'Marco de foto instantánea', scale: 0.9 },
            { id: 'ribbon',   name: 'Cinta Dorada',   desc: 'Nombre en cinta arriba',   scale: 0.95 },
            { id: 'circle',   name: 'Círculo',        desc: 'Foto redonda',             scale: 0.85 },
            { id: 'photoxl',  name: 'Solo Foto XL',   desc: 'La más grande, mínimo texto', scale: 1.25 },
            { id: 'ficha',    name: 'Ficha',          desc: 'Estilo carta coleccionable', scale: 0.75 },
            { id: 'blur',     name: 'Fondo Difuminado', desc: 'Foto con fondo borroso', scale: 1.1 }
        ];
        let currentLayoutId = 'classic';
        function getCurrentLayout() { return LAYOUTS.find(l => l.id === currentLayoutId) || LAYOUTS[0]; }
        function loadLayoutPref() { try { const v = localStorage.getItem('wordwall_card_layout'); if (v && LAYOUTS.some(l => l.id === v)) currentLayoutId = v; } catch (e) { } }

        function escapeHTML(str) { return String(str).replace(/[&<>'\"]/g, tag => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;' }[tag])); }

        function frontInnerHTML(item, index, layoutId) {
            const hasImage = item.image && String(item.image).trim() !== '';
            const jugador = (item.playerName && String(item.playerName).trim() !== '')
                ? String(item.playerName).trim()
                : (item.famIdx !== undefined && item.famIdx !== null ? obtenerJugadorAnotadoEnFila(item.famIdx) : '');
            const personaje = (item.photoName && String(item.photoName).trim() !== '')
                ? String(item.photoName).trim()
                : (item.text || `Carta ${index + 1}`);
            const familia = (item.family && String(item.family).trim() !== '') ? String(item.family).trim() : '';
            const src = hasImage ? escapeHTML(normalizarUrlImagen(item.image)) : '';
            const img = hasImage
                ? `<img class="lay-img" src="${src}" alt="" referrerpolicy="no-referrer" loading="eager" decoding="sync" style="transform: translateZ(0);">`
                : `<div class="lay-ph"><i class="ph-fill ph-star"></i><b>#${index + 1}</b></div>`;
            const imgBlur = hasImage ? `<img class="lay-img" src="${src}" alt="" referrerpolicy="no-referrer" loading="eager" decoding="sync">` : '';
            const name = `<p class="card-photo-name lay-name card-title-font" title="${escapeHTML(personaje)}">${escapeHTML(personaje)}</p>`;
            const chipP = playerLabelOutside ? '' : `<span class="card-player-name lay-chip lay-chip-p ${jugador ? '' : 'hidden'}" title="${escapeHTML(jugador)}">${escapeHTML(jugador)}</span>`;
            const chipF = `<span class="card-family-name lay-chip lay-chip-f ${familia ? '' : 'hidden'}" title="${escapeHTML(familia)}">${escapeHTML(familia)}</span>`;
            const chips = `<div class="lay-chips">${chipP}${chipF}</div>`;
            let body = '';
            switch (layoutId) {
                case 'full':     body = `<div class="lay-bgimg">${img}</div><div class="lay-overlay">${chipP}${name}${chipF}</div>`; break;
                case 'bigtext':  body = `<div class="lay-text">${chipP}${name}${chipF}</div><div class="lay-imgbox">${img}</div>`; break;
                case 'polaroid': body = `<div class="lay-imgbox">${img}</div><div class="lay-text">${name}${chips}</div>`; break;
                case 'ribbon':   body = `<div class="lay-ribbonbar">${name}</div><div class="lay-imgbox">${img}</div>${chips}`; break;
                case 'circle':   body = `<div class="lay-ring">${img}</div><div class="lay-text">${name}${chips}</div>`; break;
                case 'photoxl':  body = `<div class="lay-bgimg">${img}</div><div class="lay-topchips">${chipP}${chipF}</div><div class="lay-tag">${name}</div>`; break;
                case 'ficha':    body = `<div class="lay-bar">${name}</div><div class="lay-imgbox">${img}</div><div class="lay-foot">${chipP}${chipF}</div>`; break;
                case 'blur':     body = `<div class="lay-blurbg">${imgBlur}</div><div class="lay-imgbox">${img}</div><div class="lay-glass">${chipP}${name}${chipF}</div>`; break;
                case 'mini':
                case 'classic':
                default:         body = `<div class="lay-imgbox">${img}</div><div class="lay-text">${chipP}${name}${chipF}</div>`; layoutId = layoutId === 'mini' ? 'mini' : 'classic';
            }
            return `<div class="card-front-frame lay-${layoutId}">${body}</div>`;
        }

        function buildCardInnerHTML(item, index) {
            return `<div class="card-shadow"></div><div class="card-flipper"><div class="card-face card-back"><div class="card-back-outer-frame"><div class="corner-ornament co-tl"></div><div class="corner-ornament co-tr"></div><div class="corner-ornament co-bl"></div><div class="corner-ornament co-br"></div><div class="card-back-inner"><div class="card-back-diamond"><div class="card-back-circle"></div></div></div></div></div><div class="card-face card-front">${frontInnerHTML(item, index, currentLayoutId)}</div></div></div>`;
        }

        function applyLayout(id) {
            if (typeof isShuffling !== 'undefined' && isShuffling) return;
            if (!LAYOUTS.some(l => l.id === id)) return;
            currentLayoutId = id;
            try { localStorage.setItem('wordwall_card_layout', id); } catch (e) { }
            allCardsMap.forEach((cardObj) => {
                const front = cardObj.el && cardObj.el.querySelector('.card-front');
                if (!front) return;
                const idx = Math.max(0, cardsData.indexOf(cardObj.data));
                front.innerHTML = frontInnerHTML(cardObj.data, idx, id);
            });
            actualizarNombresPersonasEnCartasVivas();
            syncStaticPositions(false);
            renderLayoutTiles();
        }
        function cycleLayout(dir) {
            const i = LAYOUTS.findIndex(l => l.id === currentLayoutId);
            applyLayout(LAYOUTS[(i + dir + LAYOUTS.length) % LAYOUTS.length].id);
        }
        function openLayoutSheet() { const s = document.getElementById('layout-sheet'); s.classList.remove('hidden'); s.classList.add('flex'); renderLayoutTiles(); }
        function closeLayoutSheet() { const s = document.getElementById('layout-sheet'); s.classList.add('hidden'); s.classList.remove('flex'); }
        function renderLayoutTiles() {
            const box = document.getElementById('layout-tiles'); if (!box) return;
            const prevScroll = box.scrollLeft;
            const first = cardsData.find(c => c && c.image) || cardsData[0] || {};
            const sample = { image: first.image || '', photoName: first.photoName || first.text || 'Nombre', family: first.family || 'Familia', playerName: 'Jugador' };
            document.getElementById('layout-current-label').textContent = getCurrentLayout().name;
            box.innerHTML = LAYOUTS.map((l, i) => {
                const s = Math.round(44 + 52 * (l.scale / 1.25));
                const active = l.id === currentLayoutId;
                return `<button onclick="applyLayout('${l.id}')" class="shrink-0 w-[122px] rounded-xl p-2 border ${active ? 'border-amber-400 bg-amber-400/15' : 'border-white/15 bg-slate-800/70 hover:bg-slate-700/80'} flex flex-col items-center gap-1 transition">
                    <div class="h-[100px] flex items-center justify-center"><div class="card-face card-front" style="position:relative;transform:none;-webkit-transform:none;width:${s}px;height:${s}px;border-radius:9px;border-width:3px;padding:3px;pointer-events:none;">${frontInnerHTML(sample, 0, l.id)}</div></div>
                    <span class="text-[11px] font-extrabold ${active ? 'text-amber-300' : 'text-white'}">${i + 1}. ${l.name}</span>
                    <span class="text-[10px] text-slate-400 leading-tight text-center">${l.desc}</span></button>`;
            }).join('');
            box.scrollLeft = prevScroll;
        }

        function getStageLayout() {
            const W = canvasEl.clientWidth; const H = canvasEl.clientHeight; const isPortrait = H > W;
            const scale = getCurrentLayout().scale;
            let size, deckX, deckY, dropX, dropY;
            if (isPortrait) {
                const gapY = Math.max(22, H * 0.045);
                const maxSide = Math.max(90, Math.min((H - gapY - 36) / 2 - 12, W * 0.92));
                const base = Math.min((H - gapY - 36) * 0.46, W * 0.78, 430);
                size = Math.max(90, Math.min(base * scale, maxSide));
                const totalPairHeight = (size * 2) + gapY;
                deckX = (W - size) / 2; deckY = (H - totalPairHeight) / 2;
                dropX = deckX; dropY = deckY + size + gapY;
            } else {
                const gapX = Math.min(W * 0.055, 62);
                const maxSide = Math.max(90, Math.min((W - gapX - 54) / 2 - 6, H * 0.80));
                const base = Math.min((W - gapX - 54) * 0.46, H * 0.72, 430);
                size = Math.max(90, Math.min(base * scale, maxSide));
                const totalPairWidth = (size * 2) + gapX;
                deckX = (W - totalPairWidth) / 2; deckY = (H - size) / 2 - 10;
                dropX = deckX + size + gapX; dropY = deckY;
            }
            return { W, H, isPortrait, width: size, height: size, deckX, deckY, dropX, dropY };
        }

        function initDeckDOMOnly() {
            canvasEl.innerHTML = ''; allCardsMap.clear(); deckQueue = []; drawnStack = [];
            const frag = document.createDocumentFragment();
            cardsData.forEach((item, index) => {
                if (item && item.image) item.image = normalizarUrlImagen(item.image);
                const id = item.uid || `card-${index}-${Date.now()}`; item.uid = id;
                const cardObj = { id, data: item, isFlipped: false, isMoving: false, el: null, flipperEl: null };
                const el = document.createElement('div'); el.className = 'card-element'; el.dataset.id = id; el.innerHTML = buildCardInnerHTML(item, index);
                frag.appendChild(el); cardObj.el = el; cardObj.flipperEl = el.querySelector('.card-flipper');
                allCardsMap.set(id, cardObj); deckQueue.push(id);
            });
            canvasEl.appendChild(frag);
            actualizarNombresPersonasEnCartasVivas();
        }

        function initDeck() { initDeckDOMOnly(); syncStaticPositions(false); updateUI(); }

        function openSettingsModal(defaultTab = 'general') { if (isShuffling) return; syncAutoPlaySpeedUI(); syncAmarreSettingsUI(); syncVoiceUI(); populateVoices(); syncPlayerLabelUI(); applyImageRotationClass(); renderSavedGamesList(); renderCardsEditorList(); renderThemesCheckboxes(); renderShuffleCheckboxes(); switchSettingsTab(defaultTab); const modal = document.getElementById('settings-modal'); modal.classList.remove('hidden'); modal.classList.add('flex'); }
        function closeSettingsModal() { const modal = document.getElementById('settings-modal'); modal.classList.add('hidden'); modal.classList.remove('flex'); }
        function switchSettingsTab(tabName) { ['general', 'cards', 'themes', 'shuffles', 'games'].forEach(t => { const content = document.getElementById(`tab-content-${t}`); const btn = document.getElementById(`tab-btn-${t}`); if (t === tabName) { content.classList.remove('hidden'); if (t === 'cards' || t === 'general') content.classList.add('flex'); btn.className = 'px-3 sm:px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 transition shrink-0 bg-amber-500 text-slate-950 shadow'; } else { content.classList.add('hidden'); content.classList.remove('flex'); btn.className = 'px-3 sm:px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 transition shrink-0 bg-slate-800 text-slate-300 hover:text-white'; } }); }

        function renderThemesCheckboxes() { const grid = document.getElementById('themes-checkbox-grid'); if (!grid) return; grid.innerHTML = THEMES_CATALOG.map(t => { const checked = enabledThemes.has(t.id); return `<div class="p-2.5 rounded-xl border transition flex items-center justify-between gap-2 ${checked ? 'bg-slate-800 border-amber-400 shadow' : 'bg-slate-800/40 border-white/10 opacity-65'}"><label onclick="toggleThemeMode('${t.id}', event)" class="flex items-start gap-2.5 cursor-pointer flex-1 min-w-0"><input type="checkbox" ${checked ? 'checked' : ''} class="mt-1 w-4 h-4 accent-amber-400 pointer-events-none"><div class="min-w-0"><div class="font-bold text-xs text-white truncate">${t.name}</div></div></label><button onclick="applyThemeById('${t.id}')" class="px-2.5 py-1.5 rounded-lg text-[11px] font-extrabold text-white border border-white/30 shrink-0 shadow" style="background: ${t.bgMain};">Probar</button></div>`; }).join(''); }
        function toggleThemeMode(id, ev) { ev.preventDefault(); if (enabledThemes.has(id)) { if (enabledThemes.size > 1) enabledThemes.delete(id); } else enabledThemes.add(id); themeBag = []; renderThemesCheckboxes(); }
        function toggleAllThemes(selectAll) { if (selectAll) enabledThemes = new Set(THEMES_CATALOG.map(t => t.id)); else enabledThemes = new Set([THEMES_CATALOG[0].id]); themeBag = []; renderThemesCheckboxes(); }

        function handleNewCardImageUpload(event) { const file = event.target.files[0]; if (!file) return; compressImageFile(file, base64Data => { document.getElementById('new-card-img-url').value = base64Data; }); }
        function uploadPhotoToExistingCard(index, event) { const file = event.target.files[0]; if (!file || !cardsData[index]) return; compressImageFile(file, base64Data => { cardsData[index].image = base64Data; saveGamesToStorage(); initDeck(); renderCardsEditorList(); }); }
        function clearPhotoFromExistingCard(index) { if (!cardsData[index]) return; cardsData[index].image = ''; saveGamesToStorage(); initDeck(); renderCardsEditorList(); }

        function renderCardsEditorList() {
            const listEl = document.getElementById('cards-editor-list'); if (!listEl) return;
            document.getElementById('editor-card-count').textContent = cardsData.length;
            updateActiveGameHeader();
            listEl.innerHTML = cardsData.map((item, idx) => `<div class="flex flex-wrap sm:flex-nowrap items-center gap-2 bg-slate-800/85 p-2 rounded-xl border border-white/10"><span class="text-xs font-extrabold text-amber-400 w-7 shrink-0">#${idx + 1}</span><label class="flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg bg-amber-500/20 border border-amber-400/50 text-amber-300 cursor-pointer shrink-0"><div class="w-7 h-7 rounded bg-slate-900 flex items-center justify-center overflow-hidden border border-white/15">${item.image ? `<img src="${escapeHTML(item.image)}" class="w-full h-full object-contain">` : `<i class="ph-bold ph-camera text-sm"></i>`}</div><span class="text-[11px] font-extrabold">${item.image ? 'Cambiar' : 'Subir'}</span><input type="file" accept="image/*" class="hidden" onchange="uploadPhotoToExistingCard(${idx}, event)"></label>${item.image ? `<button onclick="clearPhotoFromExistingCard(${idx})" class="p-1.5 rounded-lg bg-slate-700 hover:bg-rose-500/30 text-rose-300 text-xs shrink-0"><i class="ph-bold ph-x"></i></button>` : ''}<input type="text" value="${escapeHTML(item.text)}" onchange="updateCardField(${idx}, 'text', this.value)" placeholder="Texto" class="flex-1 min-w-[120px] px-2.5 py-1.5 rounded-lg bg-slate-900 border border-white/15 text-white text-xs font-bold"><input type="text" value="${escapeHTML(item.image && !item.image.startsWith('data:') ? item.image : '')}" onchange="updateCardField(${idx}, 'image', this.value)" placeholder="URL" class="w-36 sm:w-44 px-2 py-1.5 rounded-lg bg-slate-900 border border-white/15 text-amber-200 text-xs"><input type="text" value="${escapeHTML(item.voiceText || '')}" onchange="updateCardField(${idx}, 'voiceText', this.value)" placeholder="Voz" class="w-28 sm:w-32 px-2 py-1.5 rounded-lg bg-slate-900 border border-white/15 text-sky-200 text-xs"><button onclick="speakCardData(cardsData[${idx}])" class="p-1.5 rounded-lg bg-amber-500/20 text-amber-300 text-xs shrink-0" title="Probar voz"><i class="ph-fill ph-speaker-high"></i></button><button onclick="deleteCardAt(${idx})" class="p-1.5 rounded-lg bg-rose-500/20 text-rose-300 text-xs shrink-0"><i class="ph-bold ph-trash"></i></button></div>`).join('');
        }

        function addNewCustomCard() {
            if (cardsData.length >= 200) { alert('El límite máximo es de 200 cartas.'); return; }
            const textInput = document.getElementById('new-card-text'); const imgInput = document.getElementById('new-card-img-url'); const voiceInput = document.getElementById('new-card-voice-text');
            const textVal = textInput.value.trim() || `Carta ${cardsData.length + 1}`; const imgVal = imgInput.value.trim(); const voiceVal = voiceInput.value.trim() || textVal;
            cardsData.unshift({ uid: `c-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`, text: textVal, image: imgVal, voiceText: voiceVal });
            textInput.value = ''; imgInput.value = ''; voiceInput.value = '';
            saveGamesToStorage(); initDeck(); renderCardsEditorList();
        }

        function updateCardField(index, field, value) { if (!cardsData[index]) return; cardsData[index][field] = value; saveGamesToStorage(); initDeck(); if (field === 'image') renderCardsEditorList(); }
        function deleteCardAt(index) { if (cardsData.length <= 1) return; cardsData.splice(index, 1); saveGamesToStorage(); initDeck(); renderCardsEditorList(); }

        function resizeCurrentDeckCount(newCount) {
            const target = Math.min(200, Math.max(1, newCount));
            if (cardsData.length < target) { for (let i = cardsData.length; i < target; i++) { cardsData.push({ uid: `c-${Date.now()}-${i}`, text: `Carta ${i + 1}`, image: '', voiceText: `Carta ${i + 1}` }); } }
            else if (cardsData.length > target) { cardsData.length = target; }
            saveGamesToStorage(); initDeck(); renderCardsEditorList();
        }

        function renderSavedGamesList() { const list = document.getElementById('saved-games-list'); if (!list) return; list.innerHTML = savedGames.map(g => { const isActive = g.id === activeGameId; return `<div class="p-3 rounded-xl border ${isActive ? 'bg-amber-500/20 border-amber-400' : 'bg-slate-800/80 border-white/10'} flex items-center justify-between gap-2"><div class="min-w-0"><div class="font-bold text-xs sm:text-sm text-white truncate">${escapeHTML(g.name)}</div><div class="text-[11px] text-amber-300 font-semibold">${g.cards.length} cartas</div></div><div class="flex items-center gap-1.5 shrink-0"><button onclick="selectSavedGame('${g.id}')" class="px-3 py-1.5 rounded-lg ${isActive ? 'bg-amber-400 text-slate-950' : 'bg-sky-500/20 text-sky-300 border border-sky-400/30'} font-extrabold text-xs">${isActive ? 'Activo' : 'Cargar'}</button>${savedGames.length > 1 ? `<button onclick="deleteSavedGame('${g.id}')" class="p-1.5 rounded-lg bg-rose-500/20 text-rose-300 hover:bg-rose-500/30 text-xs"><i class="ph-bold ph-trash"></i></button>` : ''}</div></div>`; }).join(''); }

        function createNewSavedGame() { const nameInput = document.getElementById('new-game-name'); const countSelect = document.getElementById('new-game-count'); const count = Math.min(200, Math.max(1, parseInt(countSelect.value, 10) || 20)); const name = nameInput.value.trim() || `Juego de ${count} Cartas`; const newGame = { id: `game-${Date.now()}`, name, cards: Array.from({ length: count }, (_, i) => ({ uid: `c-${Date.now()}-${i}`, text: `Carta ${i + 1}`, image: '', voiceText: `Carta ${i + 1}` })) }; savedGames.push(newGame); activeGameId = newGame.id; cardsData = newGame.cards; nameInput.value = ''; saveGamesToStorage(); initDeck(); renderSavedGamesList(); renderCardsEditorList(); }
        function selectSavedGame(id) { const found = savedGames.find(g => g.id === id); if (!found) return; activeGameId = found.id; cardsData = found.cards; saveGamesToStorage(); initDeck(); renderSavedGamesList(); renderCardsEditorList(); }
        function deleteSavedGame(id) { if (savedGames.length <= 1) return; savedGames = savedGames.filter(g => g.id !== id); if (activeGameId === id) { activeGameId = savedGames[0].id; cardsData = savedGames[0].cards; } saveGamesToStorage(); initDeck(); renderSavedGamesList(); renderCardsEditorList(); }

        function renderShuffleCheckboxes() { const grid = document.getElementById('shuffle-checkbox-grid'); if (!grid) return; grid.innerHTML = SHUFFLE_MODES.map(m => { const checked = enabledShuffles.has(m.id); return `<label onclick="toggleShuffleMode('${m.id}', event)" class="p-2.5 rounded-xl border cursor-pointer transition flex items-start gap-2.5 ${checked ? 'bg-amber-500/20 border-amber-400 shadow' : 'bg-slate-800/60 border-white/10 opacity-65'}"><input type="checkbox" ${checked ? 'checked' : ''} class="mt-1 w-4 h-4 accent-amber-400 pointer-events-none"><div class="flex-1 min-w-0"><div class="font-bold text-xs text-white flex items-center gap-1.5"><i class="ph-bold ${m.icon} text-amber-300"></i><span class="truncate">${m.name}</span></div></div></label>`; }).join(''); }
        function toggleShuffleMode(id, ev) { ev.preventDefault(); if (enabledShuffles.has(id)) { if (enabledShuffles.size > 1) enabledShuffles.delete(id); } else enabledShuffles.add(id); shuffleBag = []; renderShuffleCheckboxes(); }
        function toggleAllShuffles(selectAll) { if (selectAll) enabledShuffles = new Set(SHUFFLE_MODES.map(m => m.id)); else enabledShuffles = new Set([SHUFFLE_MODES[0].id]); shuffleBag = []; renderShuffleCheckboxes(); }

        // ==========================================
        // VOZ: activar/desactivar y elegir voz en español
        // ==========================================
        let selectedVoiceURI = '';
        function saveVoicePrefs() {
            try { localStorage.setItem('mazo_auto_speak', autoSpeakOnDraw ? '1' : '0'); localStorage.setItem('mazo_voice_uri', selectedVoiceURI || ''); } catch (e) { }
        }
        function loadVoicePrefs() {
            try { autoSpeakOnDraw = localStorage.getItem('mazo_auto_speak') === '1'; selectedVoiceURI = localStorage.getItem('mazo_voice_uri') || ''; } catch (e) { }
            syncVoiceUI();
            populateVoices();
        }
        function syncVoiceUI() {
            const icon = document.getElementById('mute-icon');
            if (icon) icon.className = autoSpeakOnDraw
                ? 'ph-bold ph-speaker-high text-2xl sm:text-3xl text-emerald-300'
                : 'ph-bold ph-speaker-slash text-2xl sm:text-3xl text-rose-400';
            const btn = document.getElementById('voice-toggle-btn');
            if (btn) btn.title = autoSpeakOnDraw ? 'Voz activada (toca para desactivar)' : 'Voz desactivada (toca para activar)';
            const chk = document.getElementById('auto-speak-toggle');
            if (chk) chk.checked = autoSpeakOnDraw;
        }
        function setAutoSpeak(enabled) {
            autoSpeakOnDraw = !!enabled;
            if (!autoSpeakOnDraw && 'speechSynthesis' in window) window.speechSynthesis.cancel();
            saveVoicePrefs();
            syncVoiceUI();
        }
        function toggleAutoSpeak(enabled) { setAutoSpeak(enabled); }
        function toggleVoice() { setAutoSpeak(!autoSpeakOnDraw); }
        function getSpanishVoices() {
            if (!('speechSynthesis' in window)) return [];
            return window.speechSynthesis.getVoices().filter(v => (v.lang || '').toLowerCase().replace('_', '-').startsWith('es'))
                .sort((a, b) => (a.lang + a.name).localeCompare(b.lang + b.name));
        }
        function getSelectedSpeechVoice() {
            const list = getSpanishVoices();
            if (list.length === 0) return null;
            return list.find(v => v.voiceURI === selectedVoiceURI) || list[0];
        }
        function populateVoices() {
            const sel = document.getElementById('voice-select'); if (!sel) return;
            const hint = document.getElementById('voice-hint');
            const list = getSpanishVoices();
            if (list.length === 0) {
                sel.innerHTML = '<option value="">Voz predeterminada del dispositivo (es-ES)</option>';
                if (hint) hint.textContent = 'Este dispositivo no muestra voces en español para elegir. Se usará la voz predeterminada.';
                return;
            }
            const current = getSelectedSpeechVoice();
            sel.innerHTML = list.map(v => `<option value="${escapeHTML(v.voiceURI)}">${escapeHTML(v.name)} (${escapeHTML(v.lang)})</option>`).join('');
            if (current) sel.value = current.voiceURI;
            if (hint) hint.textContent = `${list.length} voz${list.length === 1 ? '' : 'ces'} en español disponible${list.length === 1 ? '' : 's'}.`;
        }
        function setSpeechVoice(uri) { selectedVoiceURI = uri || ''; saveVoicePrefs(); testSpeechVoice(); }
        function testSpeechVoice() { speakCardData({ text: 'Hola, así suena esta voz' }); }
        if ('speechSynthesis' in window) { try { window.speechSynthesis.onvoiceschanged = populateVoices; } catch (e) { } }

        // ==========================================
        // NOMBRE DEL JUGADOR (FIREBASE) FUERA DE LA CARTA
        // ==========================================
        let playerLabelOutside = false;
        let playerLabelSize = 24;
        let playerLabelPos = 'south';
        let playerLabelGap = 10;
        function loadPlayerLabelPrefs() {
            try {
                playerLabelOutside = localStorage.getItem('mazo_player_label_outside') === '1';
                const sz = parseInt(localStorage.getItem('mazo_player_label_size'), 10);
                if (!isNaN(sz) && sz >= 12 && sz <= 80) playerLabelSize = sz;
                const gp = parseInt(localStorage.getItem('mazo_player_label_gap'), 10);
                if (!isNaN(gp) && gp >= 0 && gp <= 80) playerLabelGap = gp;
                let ps = localStorage.getItem('mazo_player_label_pos');
                if (ps === 'bottom') ps = 'south'; else if (ps === 'top-left' || ps === 'top-right') ps = 'north';
                if (['north', 'south', 'east', 'west'].includes(ps)) playerLabelPos = ps;
            } catch (e) { }
            syncPlayerLabelUI();
        }
        function syncPlayerLabelUI() {
            const chk = document.getElementById('player-outside-toggle'); if (chk) chk.checked = playerLabelOutside;
            const opts = document.getElementById('player-label-options'); if (opts) opts.classList.toggle('opt-disabled', !playerLabelOutside);
            const slider = document.getElementById('player-size-slider'); if (slider) slider.value = playerLabelSize;
            const badge = document.getElementById('player-size-badge'); if (badge) badge.textContent = `${playerLabelSize} px`;
            const gs = document.getElementById('player-gap-slider'); if (gs) gs.value = playerLabelGap;
            const gb = document.getElementById('player-gap-badge'); if (gb) gb.textContent = `${playerLabelGap} px`;
            ['north', 'south', 'east', 'west'].forEach(p => { const b = document.getElementById('pos-btn-' + p); if (b) b.classList.toggle('active', p === playerLabelPos); });
        }
        function refreshCardFronts() {
            if (typeof isShuffling !== 'undefined' && isShuffling) return;
            allCardsMap.forEach((cardObj) => {
                const front = cardObj.el && cardObj.el.querySelector('.card-front');
                if (!front) return;
                const idx = Math.max(0, cardsData.indexOf(cardObj.data));
                front.innerHTML = frontInnerHTML(cardObj.data, idx, currentLayoutId);
            });
            actualizarNombresPersonasEnCartasVivas();
        }
        function setPlayerLabelOutside(v) {
            playerLabelOutside = !!v;
            try { localStorage.setItem('mazo_player_label_outside', playerLabelOutside ? '1' : '0'); } catch (e) { }
            syncPlayerLabelUI(); refreshCardFronts(); updatePlayerLabel();
        }
        function setPlayerLabelSize(v) {
            const n = Math.min(80, Math.max(12, parseInt(v, 10) || 24));
            playerLabelSize = n;
            try { localStorage.setItem('mazo_player_label_size', String(n)); } catch (e) { }
            syncPlayerLabelUI(); updatePlayerLabel();
        }
        function setPlayerLabelGap(v) {
            const n = Math.min(80, Math.max(0, parseInt(v, 10) || 0));
            playerLabelGap = n;
            try { localStorage.setItem('mazo_player_label_gap', String(n)); } catch (e) { }
            syncPlayerLabelUI(); updatePlayerLabel();
        }
        function setPlayerLabelPos(p) {
            if (!['north', 'south', 'east', 'west'].includes(p)) return;
            playerLabelPos = p;
            try { localStorage.setItem('mazo_player_label_pos', p); } catch (e) { }
            syncPlayerLabelUI(); updatePlayerLabel();
        }
        function getTopDrawnPlayerName() {
            if (!drawnStack.length) return '';
            const c = allCardsMap.get(drawnStack[drawnStack.length - 1]);
            if (!c || !c.data) return '';
            const it = c.data;
            if (it.playerName && String(it.playerName).trim() !== '') return String(it.playerName).trim();
            if (it.famIdx !== undefined && it.famIdx !== null) return obtenerJugadorAnotadoEnFila(it.famIdx);
            return '';
        }
        // La bocina de la carta se coloca en un lado; si el nombre ocupa ese lado, pasa al lado opuesto
        function positionVoiceBtn(side, L) {
            const { width, height, dropX, dropY } = L;
            let left, top;
            if (side === 'east') { left = dropX + width + 10; top = dropY + height / 2 - 17; }
            else if (side === 'west') { left = dropX - 10 - 50; top = dropY + height / 2 - 17; }
            else if (side === 'north') { left = dropX + width / 2 - 25; top = dropY - 10 - 34; }
            else { left = dropX + width / 2 - 25; top = dropY + height + 10; }
            voiceBtn.style.left = `${left}px`; voiceBtn.style.top = `${top}px`;
        }
        function updatePlayerLabel() {
            const el = document.getElementById('player-name-label'); if (!el) return;
            const L = getStageLayout();
            const { W, H, isPortrait, width, height, dropX, dropY } = L;
            const defSide = isPortrait ? 'east' : 'south';
            const opp = { east: 'west', west: 'east', south: 'north', north: 'south' };
            const name = (playerLabelOutside && !isShuffling) ? getTopDrawnPlayerName() : '';
            if (!name) { el.style.display = 'none'; positionVoiceBtn(defSide, L); return; }

            const side = playerLabelPos, g = playerLabelGap;
            const rot = (typeof imgRotEnabled !== 'undefined' && imgRotEnabled) ? imgRotAngle : 0;
            const swap = (rot === 90 || rot === 270);
            const space = { east: W - (dropX + width) - g - 4, west: dropX - g - 4, north: dropY - g - 4, south: H - (dropY + height) - g - 4 };
            let maxW;
            if (!swap) maxW = (side === 'north' || side === 'south') ? width : Math.max(70, space[side]);
            else maxW = (side === 'east' || side === 'west') ? height : Math.max(70, space[side]);

            el.style.transform = 'none'; el.style.left = '0px'; el.style.top = '0px';
            el.textContent = name;
            el.style.fontSize = `${playerLabelSize}px`;
            el.style.maxWidth = `${maxW}px`;
            el.style.display = 'block';
            const w = el.offsetWidth, h = el.offsetHeight;
            const bw = swap ? h : w, bh = swap ? w : h; // tamaño real ya girado
            let cx, cy;
            if (side === 'north') { cx = dropX + width / 2; cy = dropY - g - bh / 2; }
            else if (side === 'south') { cx = dropX + width / 2; cy = dropY + height + g + bh / 2; }
            else if (side === 'east') { cx = dropX + width + g + bw / 2; cy = dropY + height / 2; }
            else { cx = dropX - g - bw / 2; cy = dropY + height / 2; }
            cx = bw + 4 >= W ? W / 2 : Math.min(W - bw / 2 - 2, Math.max(bw / 2 + 2, cx));
            cy = bh + 4 >= H ? H / 2 : Math.min(H - bh / 2 - 2, Math.max(bh / 2 + 2, cy));
            el.style.left = `${cx - w / 2}px`; el.style.top = `${cy - h / 2}px`;
            el.style.transform = rot ? `rotate(${rot}deg)` : 'none';
            positionVoiceBtn(side === defSide ? opp[defSide] : defSide, L);
        }

        function toggleFullScreen() { if (!document.fullscreenElement) { document.documentElement.requestFullscreen().catch(() => { }); } else { document.exitFullscreen().catch(() => { }); } }

        // Exportar / Importar (faltaban en el original, los añadimos por completitud)
        function exportAllGamesJSON() {
            try {
                const dataStr = JSON.stringify(savedGames, null, 2);
                const blob = new Blob([dataStr], { type: 'application/json' });
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = `wordwall-games-${Date.now()}.json`;
                a.click();
                URL.revokeObjectURL(url);
            } catch (e) { alert('No se pudo exportar'); }
        }
        function importAllGamesJSON(event) {
            const file = event.target.files[0]; if (!file) return;
            const reader = new FileReader();
            reader.onload = e => {
                try {
                    const parsed = JSON.parse(e.target.result);
                    if (Array.isArray(parsed) && parsed.length > 0) {
                        savedGames = parsed;
                        activeGameId = savedGames[0].id;
                        cardsData = savedGames[0].cards;
                        saveGamesToStorage();
                        initDeck();
                        renderSavedGamesList();
                        renderCardsEditorList();
                        alert('Juegos importados correctamente');
                    }
                } catch (err) { alert('Archivo inválido'); }
            };
            reader.readAsText(file);
        }

        window.addEventListener('resize', () => { if (!isShuffling) syncStaticPositions(true); });
        window.addEventListener('orientationchange', () => { setTimeout(() => { if (!isShuffling) syncStaticPositions(true); }, 120); });

        // ==========================================
        // ROTACIÓN OPCIONAL DE IMÁGENES
        // ==========================================
        let imgRotEnabled = false;
        let imgRotAngle = 90;

        function applyImageRotationClass() {
            ['img-rot-90', 'img-rot-180', 'img-rot-270'].forEach(c => document.body.classList.remove(c));
            if (imgRotEnabled) document.body.classList.add('img-rot-' + imgRotAngle);
            const chk = document.getElementById('rotate-img-toggle');
            if (chk) chk.checked = imgRotEnabled;
            const opts = document.getElementById('rot-options');
            if (opts) opts.classList.toggle('disabled', !imgRotEnabled);
            [90, 180, 270].forEach(a => {
                const b = document.getElementById('rot-btn-' + a);
                if (b) b.classList.toggle('active', a === imgRotAngle);
            });
            if (typeof updatePlayerLabel === 'function') updatePlayerLabel();
        }
        function saveImageRotationPref() {
            try {
                localStorage.setItem('wordwall_img_rot_on', imgRotEnabled ? '1' : '0');
                localStorage.setItem('wordwall_img_rot_angle', String(imgRotAngle));
            } catch (e) { }
        }
        function loadImageRotationPref() {
            try {
                imgRotEnabled = localStorage.getItem('wordwall_img_rot_on') === '1';
                const a = parseInt(localStorage.getItem('wordwall_img_rot_angle'), 10);
                if ([90, 180, 270].includes(a)) imgRotAngle = a;
            } catch (e) { }
            applyImageRotationClass();
        }
        function toggleImageRotation(enabled) {
            imgRotEnabled = !!enabled;
            saveImageRotationPref();
            applyImageRotationClass();
        }
        function setImageRotation(angle) {
            imgRotAngle = angle;
            if (!imgRotEnabled) imgRotEnabled = true;
            saveImageRotationPref();
            applyImageRotationClass();
        }

        window.onload = () => {
            loadLayoutPref();
            loadImageRotationPref();
            loadAutoPlaySettings();
            loadVoicePrefs();
            loadPlayerLabelPrefs();
            loadGamesFromStorage();
            startNewGameWithAnimation();
            cargarTableroDesdeFirebase();
        };
    </script>
</body>
</html>
