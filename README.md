# Kiko: Wild Fury - Matajava

Projeto Godot 4 próprio (run and gun estilo Metal Slug). Esta pasta **é a raiz do jogo** — não fica dentro do `ai-award-flight-engine`.

## Abrir no Godot

1. Instale o [Godot 4.4+](https://godotengine.org/download).
2. Importe `project.godot` (ou use `JOGAR.bat` no Windows).
3. Pressione Enter na tela inicial para a Fase 1.

## Controles

| Ação | Teclas |
| --- | --- |
| Andar / mirar 8 direções | A D W S ou setas |
| Agachar | S (no chão) |
| Pular | Espaço / Z |
| Atirar (faca automática perto do inimigo) | J / X |
| Granada | G / C |
| Trocar arma | Q / Tab |
| Rage | R / Shift |

## Fonte da verdade

`scripts/roteiro.gd` (autoload `Roteiro`) guarda fases, diálogos, arenas, spawns e o chefe da Fazenda Tomada. `scripts/stage_1.gd` chama `boot(1)` e o `StageController` executa esses eventos.

## Estrutura

```
project.godot
scripts/     GDScript (player, inimigos, câmera, diálogos, fase 1)
scenes/      cenas Godot
assets/      frames, tiles, UI
tools/prepare_assets.py
```

Para regenerar os sprites de gameplay:

```bash
python3 tools/prepare_assets.py
```

## Mega Drive / Genesis

Há uma ROM nativa (não é o Godot exportado) em `dist/`:

- `dist/KikoWildFuryMatajava.bin` — Kega Fusion
- `dist/KikoWildFuryMatajava.md` — RetroArch (Genesis Plus GX / PicoDrive)

Controles: **A** atira, **B** pula, **C** rage, **Start** pausa. Instruções em `megadrive/README.md`.
