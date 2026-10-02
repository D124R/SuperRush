# Super Rush

Um jogo original de speedrun 2D em pixel art, feito com Godot 4. A proposta mistura plataformas, obstáculos, atalhos e desafios de precisão.

## 📖 Sobre o projeto

**Super Rush** é um jogo de plataforma 2D focado em velocidade, precisão e fases desafiadoras.

O objetivo é completar cada fase no menor tempo possível, explorando movimentação rápida e controles responsivos.

O visual usa pixel art de estilo retrô e os recursos incluídos nos pacotes de arte do projeto.

---

## 🚀 Tecnologias utilizadas

- Godot Engine
- GDScript
- Pixel Art
- Física 2D da Godot

---

## 🎯 Funcionalidades

- Movimento com aceleração e desaceleração
- Pulo de altura fixa, tolerância de borda (coyote time) e buffer de pulo
- Câmera suave seguindo o jogador com limites configurados para cada fase
- Três fases em sequência: Gramado, Floresta e Trópicos
- Dash com recarga
- Cronômetro e recorde local da campanha completa
- Moedas, espinhos, checkpoint e linha de chegada
- Rotas bônus, plataformas, moedas e obstáculos com variações geradas por seed
- Reinício rápido da tentativa

## Controles

- **A/D** ou **setas:** mover
- **Espaço**, **W** ou **seta para cima:** pular
- **Shift** ou **X:** dash
- **R:** reiniciar a fase

Em **Geracao de mapa**, a seed `0` cria uma variação nova ao iniciar; informar outro valor permite repetir a mesma configuração.

O cronômetro começa no primeiro movimento e continua entre as três fases. O recorde da campanha fica salvo localmente no arquivo de configuração do usuário da Godot.

---
