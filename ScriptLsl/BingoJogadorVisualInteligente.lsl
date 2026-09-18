list numeros_cartela = [];
list numeros_marcados = [];
integer canal_bingo = 7777;
integer ja_venceu = FALSE;
string modo_atual = "LINHA"; // Recebe do Globo automaticamente

list sortear_coluna(integer min, integer max) {
    list coluna = [];
    while (llGetListLength(coluna) < 5) {
        integer num = min + (integer)llFrand(max - min + 1);
        if (llListFindList(coluna, [num]) == -1) coluna += [num];
    }
    return coluna;
}

gerar_cartela() {
    numeros_cartela = [];
    numeros_marcados = [];
    ja_venceu = FALSE;
    list B = sortear_coluna(1, 15); list I = sortear_coluna(16, 30);
    list N = sortear_coluna(31, 45); list G = sortear_coluna(46, 60); list O = sortear_coluna(61, 75);
    
    integer i;
    for (i = 0; i < 5; i++) {
        numeros_cartela += [llList2Integer(B, i)];
        numeros_cartela += [llList2Integer(I, i)];
        if (i == 2) numeros_cartela += [0]; // Posição central livre (valor 0)
        else numeros_cartela += [llList2Integer(N, i)];
        numeros_cartela += [llList2Integer(G, i)];
        numeros_cartela += [llList2Integer(O, i)];
    }
}

integer ta_marcado(integer idx) {
    if (idx == 12) return TRUE;
    integer num = llList2Integer(numeros_cartela, idx);
    return (llListFindList(numeros_marcados, [num]) != -1);
}

integer checar_vitoria() {
    if (modo_atual == "CHEIA") {
        return (llGetListLength(numeros_marcados) >= 24);
    } 
    else { // Modo LINHA
        // Linhas horizontais
        if (ta_marcado(0) && ta_marcado(1) && ta_marcado(2) && ta_marcado(3) && ta_marcado(4)) return TRUE;
        if (ta_marcado(5) && ta_marcado(6) && ta_marcado(7) && ta_marcado(8) && ta_marcado(9)) return TRUE;
        if (ta_marcado(10) && ta_marcado(11) && ta_marcado(12) && ta_marcado(13) && ta_marcado(14)) return TRUE;
        if (ta_marcado(15) && ta_marcado(16) && ta_marcado(17) && ta_marcado(18) && ta_marcado(19)) return TRUE;
        if (ta_marcado(20) && ta_marcado(21) && ta_marcado(22) && ta_marcado(23) && ta_marcado(24)) return TRUE;
        
        // Colunas verticais
        if (ta_marcado(0) && ta_marcado(5) && ta_marcado(10) && ta_marcado(15) && ta_marcado(20)) return TRUE;
        if (ta_marcado(1) && ta_marcado(6) && ta_marcado(11) && ta_marcado(16) && ta_marcado(21)) return TRUE;
        if (ta_marcado(2) && ta_marcado(7) && ta_marcado(12) && ta_marcado(17) && ta_marcado(22)) return TRUE;
        if (ta_marcado(3) && ta_marcado(8) && ta_marcado(13) && ta_marcado(18) && ta_marcado(23)) return TRUE;
        if (ta_marcado(4) && ta_marcado(9) && ta_marcado(14) && ta_marcado(19) && ta_marcado(24)) return TRUE;
        
        // Diagonais
        if (ta_marcado(0) && ta_marcado(6) && ta_marcado(12) && ta_marcado(18) && ta_marcado(24)) return TRUE;
        if (ta_marcado(4) && ta_marcado(8) && ta_marcado(12) && ta_marcado(16) && ta_marcado(20)) return TRUE;
    }
    return FALSE;
}

atualizar_visual(integer venceu) {
    string texto = "✨ SUA CARTELA (" + modo_atual + ") ✨\n\n B    I    N    G    O\n";
    vector cor = <0.0, 1.0, 1.0>;
    if (venceu) { texto = "🎉 BINGO (" + modo_atual + ") VENCEU! 🎉\n\n B    I    N    G    O\n"; cor = <0.0, 1.0, 0.0>; }
    
    integer i;
    for (i = 0; i < 25; i++) {
        if (i == 12) texto += "[X]  ";
        else {
            integer num = llList2Integer(numeros_cartela, i);
            if (llListFindList(numeros_marcados, [num]) != -1) texto += "[X]  ";
            else {
                string s = (string)num;
                if (llStringLength(s) == 1) s = "0" + s;
                texto += s + "   ";
            }
        }
        if ((i + 1) % 5 == 0) texto += "\n";
    }
    llSetText(texto, cor, 1.0);
}

default
{
    state_entry() { 
        llSetObjectName("Cartela Bingo Original Visual");
        gerar_cartela(); atualizar_visual(FALSE); llListen(canal_bingo, "", NULL_KEY, ""); }
    on_rez(integer start_param) { llResetScript(); }

    listen(integer channel, string name, key id, string message)
    {
        if (ja_venceu || llSubStringIndex(message, "VENCEDOR:") != -1) return;

        // O Globo envia a configuração do modo no início
        if (llSubStringIndex(message, "CONFIG_MODO:") == 0) {
            modo_atual = llGetSubString(message, 12, -1);
            gerar_cartela(); // Reinicia e limpa marcas para a nova rodada
            atualizar_visual(FALSE);
            llOwnerSay("🎮 Nova rodada iniciada! Modo: " + modo_atual);
            return;
        }

        integer num = (integer)message;
        
        // Filtro de segurança: garante que é um número válido (1 a 75) para não marcar o zero da posição central por engano
        if (num >= 1 && num <= 75 && llListFindList(numeros_cartela, [num]) != -1 && llListFindList(numeros_marcados, [num]) == -1) {
            numeros_marcados += [num];
            llOwnerSay("🎯 Você marcou: " + (string)num);
            
            if (checar_vitoria()) {
                ja_venceu = TRUE;
                string nome = llKey2Name(llGetOwner());
                if (nome == "") nome = "Jogador"; // Tratamento caso o nome não esteja no cache do sim
                
                llSay(0, "🎉 BINGO (" + modo_atual + ")! " + nome + " VENCEU O JOGO! 🎉");
                llRegionSay(canal_bingo, "VENCEDOR:" + nome);
                atualizar_visual(TRUE);
            } else {
                atualizar_visual(FALSE);
            }
        }
    }
}