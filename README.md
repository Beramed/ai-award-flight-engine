# Kiko: Wild Fury - Matajava

## Jogar no Windows (executável)

Não precisa do Godot. Baixe e dê dois cliques:

**https://github.com/Beramed/ai-award-flight-engine/raw/cursor/megadrive-rom-44a0/dist/pc/KikoWildFuryMatajava.exe**

Arquivo no repo: `dist/pc/KikoWildFuryMatajava.exe`

O SmartScreen do Windows pode avisar (o `.exe` não é assinado): **Mais informações → Executar assim mesmo**.

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
