integer canal_bingo = 7777;
integer canal_dialog = -881122;
float intervalo_sorteio = 6.0;

list numeros_sorteados = [];
integer jogando = FALSE;
string modo_jogo = "LINHA"; // Padrão inicial ("LINHA" ou "CHEIA")

// Função para identificar a letra correspondente ao número
string obter_letra(integer num) {
    if (num <= 15) return "B";
    if (num <= 30) return "I";
    if (num <= 45) return "N";
    if (num <= 60) return "G";
    return "O";
}

atualizar_painel() {
    string status = "PAUSADO";
    if (jogando) status = "EM ANDAMENTO";
    llSetText("🎱 BINGO MASTER PRO 🎱\nModo: " + modo_jogo + " | Status: " + status + "\nClique para opções", <1.0, 1.0, 1.0>, 1.0);
}

default
{
    state_entry()
    {
        llListen(canal_bingo, "", NULL_KEY, "");
        atualizar_painel();
    }

    touch_start(integer total_number)
    {
        key dono = llDetectedKey(0);
        if (dono == llGetOwner())
        {
            llListen(canal_dialog, "", dono, "");
            string btn_jogo = "Iniciar Jogo";
            if (jogando) btn_jogo = "Pausar Jogo";
            
            llDialog(dono, "\n[ PAINEL DO GLOBO ]\nModo Atual: " + modo_jogo, [btn_jogo, "Modo LINHA", "Modo CHEIA"], canal_dialog);
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel == canal_dialog)
        {
            if (message == "Modo LINHA") {
                modo_jogo = "LINHA";
                llOwnerSay("Modalidade alterada para: LINHA");
                atualizar_painel();
            }
            else if (message == "Modo CHEIA") {
                modo_jogo = "CHEIA";
                llOwnerSay("Modalidade alterada para: CARTELA CHEIA");
                atualizar_painel();
            }
            else if (message == "Iniciar Jogo") {
                jogando = TRUE;
                numeros_sorteados = [];
                // Transmite a modalidade para TODAS as cartelas da região
                llRegionSay(canal_bingo, "CONFIG_MODO:" + modo_jogo);
                llSay(0, "📣 O Bingo começou! Modalidade da rodada: " + modo_jogo);
                atualizar_painel();
                llSetTimerEvent(intervalo_sorteio);
            }
            else if (message == "Pausar Jogo") {
                jogando = FALSE;
                llSetTimerEvent(0.0);
                llSay(0, "Sorteio pausado.");
                atualizar_painel();
            }
        }
        else if (channel == canal_bingo && llSubStringIndex(message, "VENCEDOR:") == 0)
        {
            llSetTimerEvent(0.0);
            jogando = FALSE;
            string nome_vencedor = llGetSubString(message, 9, -1);
            llSay(0, "🏆 O GLOBO PAROU! Vencedor (" + modo_jogo + "): " + nome_vencedor);
            llSetText("🏆 VENDEDOR DA RODADA: " + nome_vencedor + " 🏆\nModo: " + modo_jogo, <0.0, 1.0, 0.0>, 1.0);
        }
    }

    timer()
    {
        if (llGetListLength(numeros_sorteados) >= 75) {
            llSetTimerEvent(0.0);
            jogando = FALSE;
            llSay(0, "Todos os números foram sorteados!");
            return;
        }

        integer num;
        do { num = 1 + (integer)llFrand(75.0); } 
        while (llListFindList(numeros_sorteados, [num]) != -1);
        
        numeros_sorteados += [num];
        
        // Formata a chamada com Letra e Número (ex: B15, N34, O75)
        string chamamento = obter_letra(num) + (string)num;
        
        // Canta no Chat Local com a Letra
        llSay(0, "📣 Sorteado: " + chamamento);
        
        // Envia apenas o número inteiro para as cartelas marcarem automaticamente
        llRegionSay(canal_bingo, (string)num);
        
        // Atualiza o texto flutuante no Globo
        llSetText("🎱 SORTEANDO 🎱\nÚltimo número: " + chamamento + "\nModo: " + modo_jogo, <0.0, 1.0, 1.0>, 1.0);
    }
}