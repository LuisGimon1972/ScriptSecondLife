// Configuração dos Jogadores (0: Vermelho, 1: Azul, 2: Amarelo, 3: Verde)
list CORES_NOMES = ["Vermelho", "Azul", "Amarelo", "Verde"];
list jogadores_keys = [NULL_KEY, NULL_KEY, NULL_KEY, NULL_KEY];
list jogadores_nomes = ["Vazio", "Vazio", "Vazio", "Vazio"];

integer turno_atual = 0; // Começa pelo jogador Vermelho
integer dado_rolado = 0;
integer aguardando_movimento = FALSE;

// Canal de comunicação interno do jogo (Peças e Dado)
integer CANAL_JOGO = -987654; 

// Função para avançar o turno para o próximo jogador ativo
proximoTurno()
{
    aguardando_movimento = FALSE;
    dado_rolado = 0;
    
    integer loop_seguranca = 0;
    
    // Loop para pular as cores que não têm nenhum jogador registrado
    do {
        turno_atual = (turno_atual + 1) % 4;
        loop_seguranca++;
    } while (llList2Key(jogadores_keys, turno_atual) == NULL_KEY && loop_seguranca < 4);
    
    // Se rodou 4 vezes e não achou ninguém, o jogo está vazio.
    if (loop_seguranca >= 4) {
        return; 
    }
    
    string proximo_nome = llList2String(jogadores_nomes, turno_atual);
    string proxima_cor = llList2String(CORES_NOMES, turno_atual);
    
    llSay(0, "--------------------------------------------------");
    llSay(0, "Vez do jogador " + proxima_cor + " (" + proximo_nome + ")! Role o dado.");
}

default
{
    state_entry()
    {
        llSay(0, "Sistema de Ludo Inicializado. Clicar no tabuleiro para registrar jogadores.");
        llListen(CANAL_JOGO, "", NULL_KEY, "");
    }

    touch_start(integer total_number)
    {
        key id_clique = llDetectedKey(0);
        string nome_clique = llDetectedName(0);
        
        // Verifica se o jogador já está em alguma cor
        integer index_existente = llListFindList(jogadores_keys, [id_clique]);
        
        if (index_existente != -1)
        {
            // CORREÇÃO: Responde diretamente a quem clicou, e não ao dono da mesa.
            llRegionSayTo(id_clique, 0, "Você já está registrado como jogador " + llList2String(CORES_NOMES, index_existente) + ".");
            return;
        }

        // Procura uma vaga livre
        integer vaga = llListFindList(jogadores_keys, [NULL_KEY]);
        if (vaga != -1)
        {
            jogadores_keys = llListReplaceList(jogadores_keys, [id_clique], vaga, vaga);
            jogadores_nomes = llListReplaceList(jogadores_nomes, [nome_clique], vaga, vaga);
            
            llSay(0, nome_clique + " entrou no jogo como " + llList2String(CORES_NOMES, vaga) + "!");
            
            // Se foi o primeiro jogador a entrar (Vaga 0), avisa que ele já pode jogar
            if (vaga == 0) {
                llSay(0, "O jogador Vermelho já pode rolar o dado para começar!");
            }
        }
        else
        {
            llRegionSayTo(id_clique, 0, "O jogo já está cheio com 4 jogadores.");
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        list dados = llParseString2List(message, [":"], []);
        string comando = llList2String(dados, 0);

        // 1. O DADO FOI ROLADO
        if (comando == "DADO")
        {
            key avatar_dado = (key)llList2String(dados, 1);
            integer valor = (integer)llList2String(dados, 2);

            key jogador_esperado = llList2Key(jogadores_keys, turno_atual);
            
            // CORREÇÃO: Verifica se o jogo sequer tem alguém na vaga atual antes de aceitar o dado
            if (jogador_esperado == NULL_KEY)
            {
                llRegionSayTo(avatar_dado, 0, "Aguarde os jogadores entrarem no jogo!");
                return;
            }

            // Valida se quem rolou o dado é o jogador do turno atual
            if (avatar_dado != jogador_esperado)
            {
                llRegionSayTo(avatar_dado, 0, "Não é a sua vez de jogar!");
                return;
            }

            if (aguardando_movimento)
            {
                llRegionSayTo(avatar_dado, 0, "Você já rolou o dado. Mova uma peça!");
                return;
            }

            dado_rolado = valor;
            aguardando_movimento = TRUE;
            
            string cor = llList2String(CORES_NOMES, turno_atual);
            llSay(0, cor + " tirou " + (string)dado_rolado + " no dado! Selecione a peça para mover.");
            
            // Notifica as peças de qual é o valor disponível
            llRegionSay(CANAL_JOGO, "TURNO_VALOR:" + (string)turno_atual + ":" + (string)dado_rolado);
        }

        // 2. UMA PEÇA FOI MOVIDA
        else if (comando == "PECA_MOVIDA")
        {
            integer id_cor = (integer)llList2String(dados, 1);
            
            if (id_cor == turno_atual)
            {
                // Se o jogador tirou 6, tem direito a jogar novamente
                if (dado_rolado == 6)
                {
                    llSay(0, "Você tirou 6 e joga novamente! Role o dado.");
                    aguardando_movimento = FALSE;
                    dado_rolado = 0;
                }
                else
                {
                    proximoTurno();
                }
            }
        }
        
        // 3. CAPTURA DE PEÇA (COMEU PEÇA ADVERSÁRIA)
        else if (comando == "CAPTURA")
        {
            string cor_capturada = llList2String(CORES_NOMES, (integer)llList2String(dados, 1));
            llSay(0, "Uma peça " + cor_capturada + " foi capturada e voltou para a base!");
        }
    }
}