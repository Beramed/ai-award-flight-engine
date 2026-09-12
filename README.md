# Kiko: Wild Fury - Matajava

## Jogar no Windows (executável)

Não precisa do Godot nem do `.bat`. Baixe este arquivo e dê **dois cliques**:

**https://github.com/Beramed/ai-award-flight-engine/raw/cursor/sprite-enemy-sheets-44a0/KikoWildFuryMatajava.exe**

No zip/clone do projeto o arquivo é `KikoWildFuryMatajava.exe` (na raiz).

O SmartScreen do Windows pode avisar (o `.exe` não é assinado): **Mais informações → Executar assim mesmo**.

Na abertura: **Enter**, **Espaço** ou **clique** começa a Fase 1. Também há botões **1 JOGADOR**, **2 JOGADORES** e **OPÇÕES**.

## Arte

O personagem usa as **sprite sheets de pixel art** em `assets/sprites/kiko_ref_sheet.jpg` (idle, walk, agachar, tiro 90° abaixo, dano, morte). Javali, pássaro e drone vêm de `javali_ref_sheet.png`, `passaro_ref_sheet.jpg` e `drone.png`.

```bash
python3 tools/extract_reference_sheets.py
```

A tela de abertura usa o **pôster completo** `assets/sprites/title_keyart.jpg` — sem corte. O viewport 16:9 mostra o pôster inteiro com faixas laterais.

## Abrir no Godot (opcional)

1. Instale o [Godot 4.4+](https://godotengine.org/download).
2. Importe `project.godot`.
3. Pressione Enter na tela inicial para a Fase 1.

## Controles

| Ação | Teclas |
| --- | --- |
| Andar / mirar 8 direções | A D W S ou setas |
| Agachar | S (no chão) |
| Pular | Espaço / Z |
| Atirar (golpe pesado se o inimigo estiver perto) | J / X |
| Granada | G / C |
| Trocar arma (revólver / metralhadora / espingarda) | Q / Tab |
| Rage (barra azul cheia) | R / Shift |

Vida: **3 hits**. Cada hit tira 33% da barra laranja e zera a **RAGE**. A RAGE sobe ao matar inimigos. HUD no topo (vida / vidas / score), armas e munição na base.

No meio da fazenda abre o **Armazém do Mineiro** (loja no palco, sem trocar de cena). **EXIT**, Esc ou Enter volta ao jogo.

S + atirar no chão dispara **90° para baixo** (agachado). Diagonais continuam diagonais.

## Fonte da verdade

`scripts/roteiro.gd` (autoload `Roteiro`) guarda fases, diálogos, arenas, spawns e o chefe da Fazenda Tomada. `scripts/stage_1.gd` chama `boot(1)` e o `StageController` executa esses eventos.

## Mega Drive / Genesis

Há uma ROM nativa (não é o Godot exportado) em `dist/`:

- `dist/KikoWildFuryMatajava.bin` — Kega Fusion
- `dist/KikoWildFuryMatajava.md` — RetroArch (Genesis Plus GX / PicoDrive)

Controles: **A** atira, **B** pula, **C** rage, **Start** pausa. Instruções em `megadrive/README.md`.
