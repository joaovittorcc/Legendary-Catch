from PIL import Image, ImageDraw, ImageFont
import os, io
W = 860
FONT = "C:/Windows/Fonts/arialbd.ttf"
REG = "C:/Windows/Fonts/arial.ttf"
def font(s, bold=True): return ImageFont.truetype(FONT if bold else REG, s)
pages = [
 ("01-hud-base.jpg", "1. HUD base (mundo aberto)", "Moedas (topo esq), Nivel + XP, Proxima meta (pilula azul), botao hamburguer (topo dir, badge rosa), Poder de Pesca (caixa preta, dir), hotbar da Vara (base centro). Tudo isso precisa de redesign."),
 ("02-menu-hamburguer.jpg", "2. Menu hamburguer  --  ESTILO ALVO", "Estes icones sao a REFERENCIA de estilo: coloridos, gordinhos, brilho, borda grossa, gradiente, rotulo na base. Colecao, Oficina, Desafios, Conquistas, Mare Nova, Placar, Ajustes."),
 ("03-colecao.jpg", "3. Colecao (bestiario)", "Painel creme + borda azul. Aba Aquario, barra de progresso, grade por raridade, cartas de criatura. Circulos laranja soltos = icones faltando (placeholders)."),
 ("04-oficina.jpg", "4. Oficina de varas", "Preview 3D da vara, stats Controle/Sorte, botao Equipar/Comprar, lista de varas embaixo, saldo, botao Loja de Robux."),
 ("05-desafios.jpg", "5. Desafios diarios", "Cartas de missao com emoji, barra rosa, botao Resgatar (verde) / Em andamento (cinza), contador de renovacao."),
 ("06-conquistas.jpg", "6. Conquistas", "Grade de conquistas: icone, nome, descricao, barra, recompensa. Estado Desbloqueada / progresso."),
 ("07-mare-nova.jpg", "7. Mare Nova (Prestigio)", "Texto denso, requisitos com barras, o que zera / mantem, botao de prestigiar."),
 ("08-placar.jpg", "8. Placar", "Abas Capturas / Especies / Nivel, sua pontuacao, linhas de ranking com medalha e avatar."),
 ("09-ajustes.jpg", "9. Ajustes", "Sliders de Musica e Efeitos, toggle Reduzir efeitos, codigos promocionais."),
 ("10-aquario.jpg", "10. Aquario", "Abas Vagas / Expansao / Metas, preview 3D do tanque, renda, recife, saldo, botao Chamar criaturas, grade de vagas."),
 ("11-loja-robux.jpg", "11. Loja de Robux", "Produtos: moedas, bonus de sorte, Passe VIP. Hoje 'Fora de venda' (Studio)."),
 ("13-barra-forca.jpg", "12. Barra de Forca (lancamento)", "6 skins desbloqueadas pelo Poder de Pesca. Barra vertical, faixas de cor (roxo=PERFEITO, verde=OTIMO, laranja, vermelho=ruim, azul=BOM), marcador. Texto 'BARRA NOVA'."),
 ("12-pesca-fluxo.png", "13. Fluxo de pesca (frames reais)", "Barra de Forca com PERFEITO!/Fraco... -> tela de sorte '1 em N' por raridade (Comum verde, Incomum azul, Raro roxo, Epico rosa, Lendario dourado, Cosmico vermelho, Impossivel preto) com silhueta + nome revelando letra a letra + 'Toque para pular'."),
 ("15-catchshow.png", "14. Roleta da Sorte + show da captura", "Roleta de mutacao/tamanho (NADA / TAMANHO x2 x10 / MUTACAO NEON GELO DIAMANTE), chip com resultado, silhueta, '1 em N', 'Toque para acelerar'."),
]
def wrap(d, text, f, maxw):
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = (cur+" "+w).strip()
        if d.textlength(t, font=f) <= maxw: cur = t
        else: lines.append(cur); cur = w
    lines.append(cur); return lines
def page(title, note, img=None):
    imgh = 0
    if img:
        im = Image.open(img).convert("RGB")
        r = W/im.width; im = im.resize((W, int(im.height*r)), Image.LANCZOS); imgh = im.height
    tf, nf = font(34), font(21, False)
    tmp = ImageDraw.Draw(Image.new("RGB",(W,10)))
    lines = wrap(tmp, note, nf, W-60)
    head = 30 + 44 + len(lines)*28 + 20
    p = Image.new("RGB", (W, head+imgh), (255,248,230))
    d = ImageDraw.Draw(p)
    d.text((30,24), title, font=tf, fill=(30,40,90))
    y = 24+46
    for l in lines: d.text((30,y), l, font=nf, fill=(70,55,40)); y += 28
    if img: p.paste(im, (0, head))
    return p
out = []
idx = ("INDICE: todas as telas do Legendary Catch (Roblox, mobile-first, publico infantil). Capturas reais do Studio em Play. "
       "Paginas 1-14 = telas com imagem. Pagina final = telas que existem no codigo mas nao tem captura aqui (descritas em texto).")
out.append(page("Legendary Catch - Mapa de TODAS as interfaces", idx))
for f,t,n in pages: out.append(page(t, n, f"src/{f}"))
rest = [
 "HUD sempre visivel: Coins (contador), FishingLevel (nivel+barra XP+coroa), NextGoal (pilula 'Proxima meta'), RecentRarity (selo da ultima raridade), Perks (bonus ativos), Toast e AdventureNotifications (avisos), NotificationBadge (bolinha rosa no hamburguer), RodHotbar (slot da vara), FishingPower (caixa 'Poder de Pesca'), ZoneHud (nome da zona/ilha).",
 "Pesca: Ui.luau (HUD de pesca), PowerBar (barra de forca), 3 minigames (Reel, Precision, Rhythm) + ReelLesson (tutorial), Omen (aviso antes da mordida), Roulette e OddsMoment (roleta + '1 em N'), RevealCard (carta da criatura), CatchShow, CastCutscene, PhotoMode, Cinematics (revelacao).",
 "Paineis (todos usam Panel.create: cabecalho colorido com icone + botao X vermelho + corpo creme): Collection, Aquarium (+AquariumCandy, AquariumIncome, AquariumProgression), Shop, Robux (+StarterOffer), Missions, Achievements, Prestige, Leaderboard, Settings, Treino (Training/Power - painel de campo).",
 "Sociais/eventos: DailyGift (presente diario), Announcements (anuncios), Events (banner de evento do oceano + temporada), Tutorial, Guide (balao do pescador NPC), Arrival (chegada), Portals (UI de portais/destinos), Training HUD (barra de treino, nivel, efeitos).",
 "Mundo (3D, nao-ScreenGui, fora do escopo da HUD): WorldText, placares fisicos, trofeu.",
]
out.append(page("Telas sem captura (so descritas)", " ".join(rest)))
out[0].save("../LegendaryCatch-Interfaces.pdf", "PDF", save_all=True, append_images=out[1:], quality=42, resolution=100)
print(len(out), os.path.getsize("../LegendaryCatch-Interfaces.pdf")//1024, "KB")
