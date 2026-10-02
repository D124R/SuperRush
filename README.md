# Super Rush

Jogo de plataforma 2D em pixel art feito com Godot 4.7. Corra pela fase, colete moedas, desvie dos inimigos e use poderes temporários.

## Executar

Abra este diretório no Godot 4.7 e execute o projeto. A tela inicial oferece idioma, tela cheia e acesso às opções.

## Controles

- **Setas esquerda/direita:** mover
- **Espaço ou Enter:** pular
- **Shift:** dash
- **Esc ou P:** abrir/fechar pausa
- **F:** atirar fogo enquanto o poder de fogo estiver ativo
- **Seta para cima/baixo junto a uma parede:** escalar enquanto o poder de escalada estiver ativo
- **R:** gerar novamente a extensao WFC

## Funcionalidades

- Trilha chiptune original em loop, iniciada no menu e mantida entre cenas
- Menu de pausa com continuar, reiniciar, opções de áudio/tela cheia e retorno ao título
- Cinco vidas, cronômetro, moedas e tela de fim de jogo
- Corações que concedem escalada ou fogo por 15 segundos
- Câmera que acompanha o jogador
- Extensão de fase gerada com Wave Function Collapse e seed configurável

O Wave Function Collapse gera até 40 tiles de extensão a partir dos padrões da fase e reduz a largura se necessário para encontrar uma solução válida.
