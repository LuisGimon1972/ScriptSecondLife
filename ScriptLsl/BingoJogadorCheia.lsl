list numeros_cartela = [];
list numeros_marcados = [];
integer canal_bingo = 7777; // Deve ser o mesmo canal do Globo

// Função para sortear números sem repetição para cada coluna
list sortear_coluna(integer min, integer max) {
    list coluna = [];
    while (llGetListLength(coluna) < 5) {
        integer num = min + (integer)llFrand(max - min + 1);
        if (llListFindList(coluna, [num]) == -1) {
            coluna += [num];
        }
    }
    return coluna;
}

// Gera a tabela completa 5x5 de bingo
gerar_cartela() {
    numeros_cartela = [];
    numeros_marcados = [];
    
    list B = sortear_coluna(1, 15);
    list I = sortear_coluna(16, 30);
    list N = sortear_coluna(31, 45);
    list G = sortear_coluna(46, 60);
    list O = sortear_coluna(61, 75);
    
    integer i;
    for (i = 0; i < 5; i++) {
        numeros_cartela += [llList2Integer(B, i)];
        numeros_cartela += [llList2Integer(I, i)];
        if (i == 2) {
            numeros_cartela += [0]; // Espaço central LIVRE
        } else {
            numeros_cartela += [llList2Integer(N, i)];
        }
        numeros_cartela += [llList2Integer(G, i)];
        numeros_cartela += [llList2Integer(O, i)];
    }
}

// Atualiza o texto flutuante desenhando a cartela
atualizar_visual() {
    string texto = "✨ SUA CARTELA ✨\n\n";
    texto += " B   I   N   G   O\n";
    
    integer i;
    for (i = 0; i < 25; i++) {
        if (i == 12) {
            texto += "[X] "; // Centro é o espaço livre
        } else {
            integer num = llList2Integer(numeros_cartela, i);
            // Se o número já foi sorteado, vira um X
            if (llListFindList(numeros_marcados, [num]) != -1) {
                texto += "[X] ";
            } else {
                string s = (string)num;
                if (llStringLength(s) == 1) s = "0" + s; // Coloca zero à esquerda (ex: 09)
                texto += s + " ";
            }
        }
        
        // Quebra a linha a cada 5 números
        if ((i + 1) % 5 == 0) texto += "\n";
    }
    
    texto += "\nFaltam: " + (string)(24 - llGetListLength(numeros_marcados)) + " números!";
    
    // Mostra o texto projetado na cor ciano
    llSetText(texto, <0.0, 1.0, 1.0>, 1.0);
}

default
{
    state_entry()
    {
        gerar_cartela();
        atualizar_visual();
        llListen(canal_bingo, "", NULL_KEY, "");
    }
    
    // Toda vez que alguém tira uma cópia do inventário ou veste, gera uma cartela nova
    on_rez(integer start_param)
    {
        llResetScript(); 
    }

    listen(integer channel, string name, key id, string message)
    {
        integer numero_sorteado = (integer)message;
        
        // Verifica se o jogador tem o número na cartela
        if (llListFindList(numeros_cartela, [numero_sorteado]) != -1)
        {
            // Verifica se já não marcou antes
            if (llListFindList(numeros_marcados, [numero_sorteado]) == -1)
            {
                numeros_marcados += [numero_sorteado];
                llOwnerSay("🎯 Você marcou o número: " + message);
                atualizar_visual();
                
                // Se marcou os 24 números, grita Bingo!
                if (llGetListLength(numeros_marcados) >= 24)
                {
                    llSay(0, "🎉 BINGO!!! " + llKey2Name(llGetOwner()) + " COMPLETOU A CARTELA! 🎉");
                    llSetText("🎉 BINGO! VOCÊ VENCEU! 🎉\n\n" + llGetText(), <0.0, 1.0, 0.0>, 1.0); // Fica verde
                }
            }
        }
    }
}