integer canal_bingo = 7777;
list B = []; list I = []; list N = []; list G = []; list O = [];

// Função para formatar os números separados por vírgula
string formatar(list l) {
    if (llGetListLength(l) == 0) return "-";
    return llDumpList2String(l, ", ");
}

atualizar_painel() {
    integer total = llGetListLength(B) + llGetListLength(I) + llGetListLength(N) + llGetListLength(G) + llGetListLength(O);
    
    string texto = "📊 PAINEL DE NÚMEROS SORTEADOS 📊\n";
    texto += "----------------------------------------\n";
    texto += "B: " + formatar(B) + "\n";
    texto += "I: " + formatar(I) + "\n";
    texto += "N: " + formatar(N) + "\n";
    texto += "G: " + formatar(G) + "\n";
    texto += "O: " + formatar(O) + "\n";
    texto += "----------------------------------------\n";
    texto += "Total chamados: " + (string)total + " / 75";

    // Texto flutuante em Dourado
    llSetText(texto, <1.0, 0.84, 0.0>, 1.0); 
}

default
{
    state_entry() {
        atualizar_painel();
        llListen(canal_bingo, "", NULL_KEY, "");
    }

    listen(integer channel, string name, key id, string message) {
        // Reseta o painel ao iniciar novo jogo no Globo
        if (llSubStringIndex(message, "CONFIG_MODO:") == 0) {
            B = []; I = []; N = []; G = []; O = [];
            atualizar_painel();
            return;
        }

        integer num = (integer)message;
        if (num >= 1 && num <= 75) {
            if (num <= 15) { if (llListFindList(B, [num]) == -1) B += [num]; }
            else if (num <= 30) { if (llListFindList(I, [num]) == -1) I += [num]; }
            else if (num <= 45) { if (llListFindList(N, [num]) == -1) N += [num]; }
            else if (num <= 60) { if (llListFindList(G, [num]) == -1) G += [num]; }
            else { if (llListFindList(O, [num]) == -1) O += [num]; }
            
            atualizar_painel();
        }
    }
}