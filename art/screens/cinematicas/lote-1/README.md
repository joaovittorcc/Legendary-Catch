# Cinemáticas de captura · Lote 1

Cada linha acompanha uma captura, da água até a pose frontal. Os tempos contam a partir do início da revelação, depois da confirmação do servidor.

| Criatura | Sequência | Entra em cena | Duração | Paleta | Play no PC |
| --- | --- | ---: | ---: | --- | --- |
| C23 Kraken Trovejante | Ondas, quatro raios na água, choque, fenda de duas bordas, tremor curto, portal e clarão violeta | 3,85 s | 8,3 s | Violeta `#7670FF` e gelo `#B8F8FF` | [Raios](pc-kraken-raios.jpg) · [Fenda](pc-kraken-fenda.jpg) · [Kraken](pc-kraken-final.jpg) |
| C24 Fênix das Marés | Ondas, erupção em arco, aproximação da câmera, coluna de fogo, abertura das asas, portal e clarão âmbar | 4,05 s | 8,6 s | Coral `#F26751` e ouro `#FFE39A` | [Erupção](pc-fenix-erupcao.jpg) · [Asas](pc-fenix-asas.jpg) · [Fênix](pc-fenix-final.jpg) |
| C93 Ouroboros Cósmico | Aurora, estrelas cadentes, órbita de estrelas, portal, túnel e silhueta que desacelera na travessia | 5,40 s | 11,6 s | Lilás `#9875E7` e marfim `#F9DFA3` | [Estrelas](pc-ouroboros-estrelas.jpg) · [Túnel](pc-ouroboros-tunel.jpg) · [Ouroboros](pc-ouroboros-final.jpg) |
| C94 Maré Primordial | Redemoinho, ondas concêntricas, névoa ascendente, coluna de água, bolhas, onda de choque e portal | 5,15 s | 11,2 s | Petróleo `#268CA7` e espuma `#B7FFD7` | [Redemoinho](pc-mare-vortice.jpg) · [Portal](pc-mare-portal.jpg) · [Maré](pc-mare-final.jpg) |

A silhueta e a criatura iluminada usam o mesmo modelo de primeiro plano. O card mantém a prévia independente, o texto da Coleção e os dados de captura. A biblioteca também inclui um efeito de congelamento radial para receitas de gelo.

As prévias em GIF mostram a travessia do portal em cinco quadros capturados no Play. [Kraken](travessia-kraken.gif) · [Fênix](travessia-fenix.gif) · [Ouroboros](travessia-ouroboros.gif) · [Maré](travessia-mare.gif)

## iPhone 17 Pro no simulador

| Criatura | Paisagem | Retrato |
| --- | --- | --- |
| Kraken | [Ver paisagem](paisagem-kraken-final.jpg) | [Ver retrato](retrato-kraken-final.jpg) |
| Fênix | [Ver paisagem](paisagem-fenix-final.jpg) | [Ver retrato](retrato-fenix-final.jpg) |
| Ouroboros | [Ver paisagem](paisagem-ouroboros-final.jpg) | [Ver retrato](retrato-ouroboros-final.jpg) |
| Maré | [Ver paisagem](paisagem-mare-final.jpg) | [Ver retrato](retrato-mare-final.jpg) |

## QA no Studio

A Maré foi pescada com a vara equipada, `DevForceRarity=Mystic` e `SubmitCatch` após a mordida. O card mostrou 167.009,55 kg e 11.400 moedas do servidor. O botão **Foto** abriu o modo de foto e **Fechar** devolveu o controle. Para reproduzir cada espécie e cada beat no mesmo instante, os outros prints chamam `Reveal.play` no cliente com peso, valor e descoberta de teste. Pedido de `DevForceCreature` registrado no Mural. [Captura pela vara](real-c94-pc.jpg)

**Leitura e acessibilidade.** A primeira exibição libera Pular em cerca de 2 s. Na recaptura, o botão já aparece no primeiro quadro. Um clique encerrou o Ouroboros em 1,23 s. Com Reduzir efeitos ligado, a sequência dura 3,25 s e mostra a criatura com fade e card. Morrer durante a erupção da Fênix encerrou a sequência aos 3,32 s e removeu tanto a interface quanto a pasta dos efeitos no mundo. [Revelação reduzida](reduzido-final.jpg)

**Desempenho.** PC com preset Windows de 1502 × 695, viewport lógico de 1501 × 694. Amostras de `RenderStepped` desde a criação da tela até o fechamento. Sem cinemática, a mediana foi de 60,1 FPS e o P95 do tempo de quadro equivaleu a 54,1 FPS. A tabela inclui a interface, câmeras, partes dos dois modelos e efeitos do mundo. O pico de instâncias foi amostrado a cada 0,12 s. As quatro receitas usaram zero emissores de partículas ativos.

| Criatura | FPS mediano | FPS equivalente no P95 | Pior quadro observado | Pico de descendentes | Destes, no mundo |
| --- | ---: | ---: | ---: | ---: | ---: |
| Kraken | 60 | 56 | 34,5 ms | 182 | 95 |
| Fênix | 60 | 56 | 35,9 ms | 128 | 48 |
| Ouroboros | 60 | 56 | 33,6 ms | 133 | 0 |
| Maré | 60 | 55 | 42,7 ms | 221 | 100 |

No iPhone 17 Pro simulado, a mediana também ficou em 60 FPS nas oito combinações. O P95 equivaleu a 55–56 FPS. O quadro mais lento foi de 45,3 ms no Kraken em retrato. O card e o viewport principal ficaram separados nas duas orientações. O congelamento de seis ramos criou 18 segmentos no teste isolado da biblioteca.

Uma pesca adicional em retrato trouxe o Leviatã Astral C10 pelo fluxo anterior. O Play terminou sem erros Lua dos scripts do projeto. O log continuou emitindo o aviso antigo de tipo de asset `203785492` da Sardinha Solar (A17 em `docs/NOITE.md`).

Place salvo na nuvem como versão 60, com `persistedToCloud=true`. StyLua, Selene e Luau LSP passaram nos cinco arquivos de código. Fora desta rodada ficaram celular físico, dois jogadores, outros avatares, desconexão real, experiência publicada e compartilhamento de fotos.
