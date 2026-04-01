# 🎮 GameHub G24 Edition (Root)

O **GameHub** é um ecossistema de otimização de baixo nível desenvolvido especificamente para extrair o máximo de performance da linha Moto G24.

## ⚠️ AVISO DE COMPATIBILIDADE (LEIA!)

Este módulo **NÃO** é genérico. Ele foi projetado sob medida:
*   **📱 Dispositivo Alvo:** Exclusivo para **Moto G24**.
*   **⚡ Compatibilidade:** Não testado porem em tese deve ra ser compativel não recomendado o uso deste modulo para **Moto G24 Power** e qualquer outro dispositivo.
*   **🛠️ Ambiente:** Desenvolvido e otimizado em **GSI: CrDroid**.
*   **🚧 Versão Stock:** A versão para a ROM Original (Stock) ainda está em fase de desenvolvimento e testes. Use por sua conta e risco em ROMs Stock.

## 🛡️ REQUISITO OBRIGATÓRIO

Este módulo funciona em simbiose com o gerenciamento de memória. É **obrigatória** a instalação do:
👉 **[ZramTG24](https://github.com/inrryoff/ZramTG24)**

O GameHub aciona o motor `ram.sh` do ZramTG24 para garantir que a swap esteja limpa e comprimida antes de injetar os perfis de performance no kernel.

## 🚀 Funcionalidades Principais

*   **⚡ Sincronização ZRAM:** Reset automático via ZramTG24.
*   **🔥 CPU Performance Boost:** Força o governor de performance em todos os núcleos do G24.
*   **🚫 Extermínio de Apps (Modo Bruto):** Limpeza profunda de processos em segundo plano para liberar RAM.
*   **🛡️ Proteção de Processo (OOM):** Define o Score OOM do jogo para `-1000` (Imortal).
*   **💎 Prioridade de Hardware:** Aplica `renice -20` e `ionice` de tempo real no PID do jogo via Termux.

## 🛠️ Como Utilizar

O módulo já configura o binário no sistema via `service.sh`.
1. Abra o **Termux**.
2. Digite `game`.
3. Siga o menu para adicionar jogos, configurar a whitelist ou iniciar a jogatina.

---
## 👤 Créditos e Licença*
* **Desenvolvedor**: [@inrryoff](https://github.com/inrryoff)
* **Licença:** MIT (Pode usar e modificar, desde que mantenha os créditos ao autor original).
* **Projeto**: Game Hub ProX G24

