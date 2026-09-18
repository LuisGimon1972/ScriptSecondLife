// CONFIGURAÇÕES DA PEÇA
integer CANAL_JOGO = -987654; // Mesmo canal do Controlador e do Dado

// IMPORTANTE: Mude este valor para cada cor de peça!
// 0 = Vermelho | 1 = Azul | 2 = Amarelo | 3 = Verde
integer MINHA_COR = 0; 

// Exemplo de caminho (Você deve colocar as coordenadas reais do seu tabuleiro aqui)
list caminho = [
    <128.0, 128.0, 25.0>, // Casa 1 (Saída da base)
    <129.0, 128.0, 25.0>, // Casa 2
    <130.0, 128.0, 25.0>, // Casa 3
    <130.0, 129.0, 25.0>  // Casa 4
];

integer casa_atual = -1; // -1 significa que está na base
integer valor_do_dado = 0;
vector posicao_base; // Vai guardar a posição inicial para caso seja capturada

default
{
    state_entry()
    {
        // Grava a posição exata de onde a peça foi colocada no chão (A Base)
        posicao_base = llGetPos();
        
        // Fica escutando os comandos do Controlador
        llListen(CANAL_JOGO, "", NULL_KEY, "");
    }

    listen(integer channel, string name, key id, string message)
    {
        list dados = llParseString2List(message, [":"], []);
        string comando = llList2String(dados, 0);

        // O Controlador avisou que alguém rolou o dado
        if (comando == "TURNO_VALOR")
        {
            integer turno_cor = (integer)llList2String(dados, 1);
            
            // Se for a vez da cor DESTA peça, ela "grava" o valor do dado
            if (turno_cor == MINHA_COR)
            {
                valor_do_dado = (integer)llList2String(dados, 2);
            }
        }
    }

    touch_start(integer total_number)
    {
        key id_clique = llDetectedKey(0);

        // Se a peça não tem um valor de dado, não é a vez dela
        if (valor_do_dado == 0)
        {
            llRegionSayTo(id_clique, 0, "Não é a sua vez ou o dado ainda não foi rolado!");
            return;
        }

        // Lógica de sair da base (precisa de um 6)
        if (casa_atual == -1)
        {
            if (valor_do_dado != 6)
            {
                llRegionSayTo(id_clique, 0, "Você precisa de um 6 para sair da base! Escolha outra peça (se tiver) ou passe a vez.");
                return;
            }
            else
            {
                // Se tirou 6 e está na base, ela vai para a casa "0" (Casa 1 da lista)
                casa_atual = 0;
            }
        }
        else
        {
            // Se já está no tabuleiro, apenas soma as casas
            casa_atual = casa_atual + valor_do_dado;
        }
        
        // Verifica se chegou ao centro (fim do caminho)
        integer tamanho_caminho = llGetListLength(caminho);
        if (casa_atual >= tamanho_caminho)
        {
            casa_atual = tamanho_caminho - 1; // Para na última casa (Centro)
            llSay(0, "A peça chegou ao centro do tabuleiro!");
        }

        // Pega a coordenada da lista e move a peça magicamente para lá
        vector nova_posicao = llList2Vector(caminho, casa_atual);
        llSetRegionPos(nova_posicao);
        
        // Zera o dado local para evitar duplo-clique
        valor_do_dado = 0; 
        
        // AVISA O CONTROLADOR QUE O MOVIMENTO TERMINOU
        // Isso é o que faz o turno passar para o próximo jogador!
        llRegionSay(CANAL_JOGO, "PECA_MOVIDA:" + (string)MINHA_COR);
    }
}