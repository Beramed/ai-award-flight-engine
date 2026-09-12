# Porta Mega Drive / Genesis

Homebrew de **Kiko: Wild Fury - Matajava** para Sega Mega Drive, feito em C com [SGDK](https://github.com/Stephane-D/SGDK). Roda no **Kega Fusion** e no **RetroArch** (Genesis Plus GX, PicoDrive ou BlastEm).

Não é um conversor do Godot: é uma ROM nativa 68000, 320×224, Fase 1 (A Fazenda Tomada).

## ROM pronta (não precisa compilar)

Arquivos em `dist/`:

| Arquivo | Uso |
| --- | --- |
| `KikoWildFuryMatajava.bin` | Fusion, emuladores genéricos |
| `KikoWildFuryMatajava.md` | RetroArch / Genesis Plus GX |
| `KikoWildFuryMatajava.gen` | Alguns front-ends Windows |

Os três são a mesma imagem. Qualquer um serve.

## Kega Fusion

1. Abra o Fusion.
2. **File → Open ROM** (ou arraste o `.bin`).
3. Se pedir região, escolha **USA** ou **Europe**.
4. Joystick: D-Pad, **A** atira, **B** pula, **C** especial (rage), **Start** pausa / confirma.

No teclado o Fusion costuma mapear as setas + `A`/`S`/`D` para A/B/C (confira **Options → Config Joystick**).

## RetroArch

1. Instale o core **Sega - Mega Drive / Genesis (Genesis Plus GX)** — PicoDrive e BlastEm também funcionam.
2. **Load Core** → Genesis Plus GX.
3. **Load Content** → `KikoWildFuryMatajava.md` (ou `.bin`).
4. Em **Quick Menu → Controls**, deixe o dispositivo como RetroPad.

Atalho típico no teclado do RetroArch: setas, `Z`/`X`/`A` = A/B/C, `Enter` = Start (pode variar com o remap).

## O que tem nesta ROM

- Tela **PRESS START** e menu 1P / 2P / Options (Fácil, Normal, Difícil)
- Fase 1 com scroll só para a frente, arenas com LOCK e **GO!**
- Javalis corredores, saltadores e blindados
- Chefe **Mãe Javali**
- Caixas de vida, diálogo do roteiro, continues

## Controles

| Ação | Controle |
| --- | --- |
| Andar / agachar | D-Pad |
| Atirar (faca se o inimigo estiver perto) | A |
| Pular | B |
| Rage | C |
| Confirmar / pausar | Start |

Jogador 2 usa o controle 2, mesmos botões.

## Compilar de novo

Precisa do [marsdev](https://github.com/andwn/marsdev) (ou SGDK + `m68k-elf-gcc`) e Java para o `rescomp.jar`:

```bash
export GDK=/opt/toolchains/mars/m68k-elf
cd megadrive
make
```

Isso gera `out/rom.bin` e copia de novo para `dist/`.
