# 🎮 GameHub-PRO-X G24

[![Magisk](https://img.shields.io/badge/Magisk-27.0+-green.svg)](https://github.com/topjohnwu/Magisk)
[![Android](https://img.shields.io/badge/Android-12+-blue.svg)](https://www.android.com)
[![Device](https://img.shields.io/badge/Device-Moto_G24-orange.svg)](https://motorola.com)

O **GameHub** é um ecossistema de otimização de baixo nível desenvolvido especificamente para extrair o máximo de performance da linha Moto G24.

---

## ⚠️ AVISO DE COMPATIBILIDADE (LEIA!)

Este módulo **NÃO** é genérico. Ele foi projetado sob medida:
*   **📱 Dispositivo Alvo:** Exclusivo para **Moto G24**.
*   **⚡ Compatibilidade:** Não testado porem em tese deve ra ser compativel não recomendado o uso deste modulo para **Moto G24/Power** e qualquer outro dispositivo.
*   **🛠️ Ambiente:** Desenvolvido e testado em **GSI: CrDroid**.

## ⚠️ Avisos importantes

> **🔥 Este módulo é EXTREMAMENTE AGRESSIVO!**
> 
> - **Superaquecimento**: Use com cooler externo (obrigatório para sessões longas)
> - **Bateria**: O consumo será maior devido à prioridade máxima da CPU
> - **Estabilidade**: Pode causar lentidão no sistema fora do jogo

## 📱 Dispositivos compatíveis

| Dispositivo | Codinome | Modelo | SoC |
|-------------|----------|--------|-----|
| Moto G24 | fogorow | XT2423, XT2425 | Helio G85 |
| Moto G24 Power | fogorow | XT2425 | Helio G85 |
| Outros Helio G85/G80 | - | - | MT6768/MT6769 |

## 📊 Otimizações aplicadas

| Recurso | O que faz | Comando |
|---------|-----------|---------|
| CPU | Prioridade máxima | `chrt -f -p 99` + `renice -20` |
| I/O | Tempo real | `ionice -c 1 -n 0` |
| Memória | Proteção OOM | `oom_score_adj -1000` |
| GPU | Vulkan forçado | `debug.hwui.renderer skiavk` |

## 🐛 Reportar problemas

Abra uma issue no GitHub com:
- Modelo do celular
- ROM (Stock/GSI)
- Log do módulo: `/data/local/tmp/logs/gamehub.log`

---

## 🛡️ REQUISITO OBRIGATÓRIO

Este módulo funciona em simbiose com o gerenciamento de memória. É **obrigatória** a instalação do:
👉 **[ZramTG24](https://github.com/inrryoff/ZramTG24)**

O GameHub-PRO-X aciona o motor `ram.sh` do ZramTG24 para garantir que a swap esteja limpa e comprimida antes de injetar os perfis de performance no kernel.

---

### Instalação recomendada

Recomendo baixar o módulo [Kreapic Desativar Térmico Universal](https://github.com/mahisataruna/Kreapic-Disable-Thermal) 

---

## 🛠️ Como Utilizar

O módulo já configura o binário no sistema via `customize.sh`.
1. Abra o **[Termux](https://github.com/termux/termux-app)**.
2. Digite `play` ou`su -c /data/adb/modules/GameHub-PRO-X/system/bin/booster.sh`
3. Siga o menu para adicionar jogos, configurar a whitelist ou iniciar a jogatina.

---

## 👤 Créditos e Licença*
* **Desenvolvedor**: [@inrryoff](https://github.com/inrryoff)
* **Licença:** MIT (Pode usar e modificar, desde que mantenha os créditos ao autor original).
* **Projeto**: GameHub PRO-X


## 🙏 Agradecimentos

- **[Termux](https://github.com/termux)** - Terminal emulador para Android (GPL v3.0)
- **[Mahisataruna](https://github.com/mahisataruna/)** - Pelo módulo universal que inspirou partes deste projeto
- **[Magisk](https://github.com/topjohnwu/magisk/releases)** - A base de tudo
